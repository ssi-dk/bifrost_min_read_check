# script for use with snakemake
import traceback
from bifrostlib import common

def rule__greater_than_min_reads_check(input, output, samplecomponent, log):
    try:
        num_of_reads = int(common.get_group_from_regex("Result:\s*([0-9]+)\sreads", input.stats_file))
        min_read_number = samplecomponent["options"]["min_num_reads"]
        has_min_num_of_reads = False
        if num_of_reads > min_read_number:
            has_min_num_of_reads = True
        with open(output._file, "w") as fh:
            fh.write(f"has_min_num_of_reads:{has_min_num_of_reads}\num_of_reads:{num_of_reads}")
    except Exception:
        with open(log.err_file, "w+") as fh:
            fh.write(traceback.format_exc())

rule__greater_than_min_reads_check(
    snakemake.input,
    snakemake.output,
    snakemake.params.samplecomponent,
    snakemake.log)
