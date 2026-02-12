#- Templated section: start ------------------------------------------------------------------------
import os
import sys
import traceback

from bifrostlib import common
from bifrostlib.datahandling import SampleReference
from bifrostlib.datahandling import Sample
from bifrostlib.datahandling import ComponentReference
from bifrostlib.datahandling import Component
from bifrostlib.datahandling import SampleComponentReference
from bifrostlib.datahandling import SampleComponent

os.umask(0o2)

try:
    sample_ref = SampleReference(_id=config.get('sample_id', None), name=config.get('sample_name', None))
    sample: Sample = Sample.load(sample_ref)
    if sample is None:
        raise Exception("invalid sample passed")

    component_ref = ComponentReference(name=config['component_name'])
    component: Component = Component.load(reference=component_ref)
    if component is None:
        raise Exception("invalid component passed")

    samplecomponent_ref = SampleComponentReference(
        name=SampleComponentReference.name_generator(sample.to_reference(), component.to_reference())
    )
    samplecomponent = SampleComponent.load(samplecomponent_ref)
    if samplecomponent is None:
        samplecomponent = SampleComponent(
            sample_reference=sample.to_reference(),
            component_reference=component.to_reference()
        )

    # Only set status here
    common.set_status_and_save(sample, samplecomponent, "Running")

except Exception:
    print(traceback.format_exc(), file=sys.stderr)
    raise Exception("failed to set sample, component and/or samplecomponent")

onerror:
    if not samplecomponent.has_requirements():
        common.set_status_and_save(sample, samplecomponent, "Requirements not met")
    if samplecomponent['status'] == "Running":
        common.set_status_and_save(sample, samplecomponent, "Failure")

envvars:
    "BIFROST_INSTALL_DIR",
    "CONDA_PREFIX"

# -------------------------------------------------------------------------
# MAIN RULES FIRST
# -------------------------------------------------------------------------

rule all:
    input:
        f"{component['name']}/datadump_complete"
    run:
        common.set_status_and_save(sample, samplecomponent, "Success")

# -------------------------------------------------------------------------
# FILE-BASED TIMING
# -------------------------------------------------------------------------

rule set_time_start:
    output:
        start_file = temp(f"{component['name']}/time_start.txt")
    run:
        import time
        with open(output.start_file, "w") as fh:
            fh.write(str(time.time()))

rule setup:
    input:
        rules.set_time_start.output.start_file
    output:
        init_file = touch(temp(f"{component['name']}/initialized"))
    run:
        samplecomponent['path'] = os.path.join(os.getcwd(), component['name'])
        samplecomponent.save()

rule_name = "check_requirements"
rule check_requirements:
    message:
        f"Running step:{rule_name}"
    log:
        out_file = f"{component['name']}/log/{rule_name}.out.log",
        err_file = f"{component['name']}/log/{rule_name}.err.log",
    benchmark:
        f"{component['name']}/benchmarks/{rule_name}.benchmark"
    input:
        folder = rules.setup.output.init_file,
    output:
        check_file = f"{component['name']}/requirements_met",
    params:
        samplecomponent
    run:
        if samplecomponent.has_requirements():
            with open(output.check_file, "w") as fh:
                fh.write("")

#* Dynamic section: start **************************************************************************

rule_name = "setup__filter_reads_with_fastp"
rule setup__filter_reads_with_fastp:
    message:
        f"Running step:{rule_name}"
    log:
        out_file = f"{component['name']}/log/{rule_name}.out.log",
        err_file = f"{component['name']}/log/{rule_name}.err.log",
    benchmark:
        f"{component['name']}/benchmarks/{rule_name}.benchmark"
    input:
        rules.check_requirements.output.check_file,
        reads = sample['categories']['paired_reads']['summary']['data']
    output:
        filtered_reads = [
            f"{component['name']}/{sample['name']}.R1.trim.fastq.gz",
            f"{component['name']}/{sample['name']}.R2.trim.fastq.gz",
        ]
    threads: 8
    params:
        options = "-q 30 -e 30 -l 30 -y 30"
    shell:
        """
        fastp --in1 {input.reads[0]} --in2 {input.reads[1]} \
              --out1 {output.filtered_reads[0]} \
              --out2 {output.filtered_reads[1]} \
              --thread {threads} {params.options} \
              >> {log.out_file} 2>&1
        """

rule_name = "greater_than_min_reads_check"
rule greater_than_min_reads_check:
    message:
        f"Running step:{rule_name}"
    log:
        out_file = f"{component['name']}/log/{rule_name}.out.log",
        err_file = f"{component['name']}/log/{rule_name}.err.log",
    benchmark:
        f"{component['name']}/benchmarks/{rule_name}.benchmark"
    input:
        reads = rules.setup__filter_reads_with_fastp.output.filtered_reads
    params:
        min_reads_threshold = 10000
    output:
        _file = f"{component['name']}/has_min_num_of_reads"
    shell:
        r"""
        set -euo pipefail
        num_reads=$(zcat {input.reads[0]} | awk 'END {{ print int(NR/4) }}')
        if [[ "$num_reads" -gt {params.min_reads_threshold} ]]; then
            has_min="True"
        else
            has_min="False"
        fi
        echo "has_min_num_of_reads:$has_min" > {output._file}.tmp
        echo "num_of_reads:$num_reads" >> {output._file}.tmp
        mv {output._file}.tmp {output._file}
        """

#* Dynamic section: end ****************************************************************************

# -------------------------------------------------------------------------
# END TIME + RUNTIME (FILE-BASED)
# -------------------------------------------------------------------------

rule set_time_end:
    input:
        rules.greater_than_min_reads_check.output._file
    output:
        end_file = temp(f"{component['name']}/time_end.txt")
    run:
        import time
        with open(output.end_file, "w") as fh:
            fh.write(str(time.time()))

rule compute_runtime:
    input:
        start_file = rules.set_time_start.output.start_file,
        end_file = rules.set_time_end.output.end_file
    output:
        runtime_flag = temp(f"{component['name']}/runtime_set")
    run:
        import time
        from bifrostlib.datahandling import SampleComponentReference, SampleComponent

        # Load timestamps
        with open(input.start_file) as fh:
            t_start = float(fh.read().strip())

        with open(input.end_file) as fh:
            t_end = float(fh.read().strip())

        runtime_minutes = (t_end - t_start) / 60.0
	print(f"runtime in minutes {runtime_minutes}")

        # Save to SampleComponent
        sc = SampleComponent.load(samplecomponent.to_reference())
        sc["time_running"] = round(runtime_minutes, 3)
        sc.save()

        with open(output.runtime_flag, "w") as fh:
            fh.write("done")

# -------------------------------------------------------------------------
# DATADUMP
# -------------------------------------------------------------------------

rule_name = "datadump"
rule datadump:
    message:
        f"Running step:{rule_name}"
    log:
        out_file = f"{component['name']}/log/{rule_name}.out.log",
        err_file = f"{component['name']}/log/{rule_name}.err.log",
    benchmark:
        f"{component['name']}/benchmarks/{rule_name}.benchmark"
    input:
        rules.greater_than_min_reads_check.output._file,
        rules.setup__filter_reads_with_fastp.output.filtered_reads,
        rules.compute_runtime.output.runtime_flag
    output:
        complete = f"{component['name']}/datadump_complete"
    params:
        samplecomponent_ref_json = samplecomponent.to_reference().json,
        trimmed_reads_paths = rules.setup__filter_reads_with_fastp.output.filtered_reads
    script:
        os.path.join(os.path.dirname(workflow.snakefile), "datadump.py")

