#- Templated section: start ------------------------------------------------------------------------
import os

from bifrostlib.datahandling import BifrostObjectReference
from bifrostlib.datahandling import Sample
from bifrostlib.datahandling import Component
from bifrostlib.datahandling import SampleComponent
os.umask(0o2)

try:
    sample = Sample(reference=BifrostObjectReference(_id=config["sample_id"])) # schema 2.1
    component = Component(reference=BifrostObjectReference(_id=config["component_id"])) # schema 2.1
    samplecomponent = SampleComponent(sample.to_reference(), component.to_reference()) # schema 2.1
except Exception as error:
    print(error)

onerror:
    component["status"] = "Failure"
    component.save()

rule all:
    input:
        # file is defined by datadump function
        f"{component["name"]}/datadump_complete"

rule setup:
    output:
        init_file = touch(temp(f"{component["name"]}/initialized")),
    params:
        folder = component["name"]
    run:
        samplecomponent["status"] = "Running"
        samplecomponent["path"] = os.path.join(os.getcwd(), component["name"])
        samplecomponent.save()


rule_name = "check_requirements"
rule check_requirements:
    message:
        f"Running step:{rule_name}"
    log:
        out_file = f"{component["name"]}/log/{rule_name}.out.log",
        err_file = f"{component["name"]}/log/{rule_name}.err.log",
    benchmark:
        f"{component["name"]}/benchmarks/{rule_name}.benchmark"
    input:
        folder = rules.setup.output.init_file,
    output:
        check_file = f"{component["name"]}/requirements_met",
    params:
        samplecomponent
    run:
        if not samplecomponent.has_requirements():
            samplecomponent["status"] = "Requirements not met"
            samplecomponent.save()

#- Templated section: end --------------------------------------------------------------------------

#* Dynamic section: start **************************************************************************
rule_name = "setup__filter_reads_with_bbduk"
rule setup__filter_reads_with_bbduk:
    message:
        f"Running step:{rule_name}"
    log:
        out_file = f"{component["name"]}/log/{rule_name}.out.log",
        err_file = f"{component["name"]}/log/{rule_name}.err.log",
    benchmark:
        f"{component["name"]}/benchmarks/{rule_name}.benchmark"
    input:
        rules.check_requirements.output.check_file,
        reads = sample["properties"]["paired_reads"]["2.1"]["summary"]["data"]
    output:
        stats_file = f"{component["name"]}/stats.txt"
    params:
        adapters = component["resources"]["adapters_fasta"]  # This is now done to the root of the continuum container
    shell:
        "bbduk.sh in={input.reads[0]} in2={input.reads[1]} ref={params.adapters} ktrim=r k=23 mink=11 hdist=1 tbo qtrim=r minlength=30 1> {log.out_file} 2> {output.stats_file}"


rule_name = "greater_than_min_reads_check"
rule greater_than_min_reads_check:
    message:
        f"Running step:{rule_name}"
    log:
        out_file = f"{component["name"]}/log/{rule_name}.out.log",
        err_file = f"{component["name"]}/log/{rule_name}.err.log",
    benchmark:
        f"{component["name"]}/benchmarks/{rule_name}.benchmark"
    input:
        stats_file = rules.setup__filter_reads_with_bbduk.output.stats_file,
    params:
        samplecomponent
    output:
        _file = f"{component["name"]}/has_min_num_of_reads"
    script:
        os.path.join(os.path.dirname(workflow.snakefile), "rule__greater_than_min_reads_check.py")
#* Dynamic section: end ****************************************************************************

#- Templated section: start ------------------------------------------------------------------------
rule_name = "datadump"
rule datadump:
    message:
        f"Running step:{rule_name}"
    log:
        out_file = f"{component["name"]}/log/{rule_name}.out.log",
        err_file = f"{component["name"]}/log/{rule_name}.err.log",
    benchmark:
        f"{component["name"]}/benchmarks/{rule_name}.benchmark"
    input:
        #* Dynamic section: start ******************************************************************
        rules.greater_than_min_reads_check.output.check_file  # Needs to be output of final rule
        #* Dynamic section: end ********************************************************************
    output:
        complete = rules.all.input
    params:
        sample,
        component,
        samplecomponent
    script:
        os.path.join(os.path.dirname(workflow.snakefile), "datadump.py")
#- Templated section: end --------------------------------------------------------------------------
