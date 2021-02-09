# script for use with snakemake
import traceback
from typing import Dict
from bifrostlib import common

def rule__greater_than_min_reads_check(input: object, output: object, component_json: Dict, log: object) -> None:
    try:
        num_of_reads: int = int(common.get_group_from_file("Result:\s*([0-9]+)\sreads", input.stats_file))
        min_read_number: int = component_json["options"]["min_num_reads"]
        has_min_num_of_reads: bool = False
        if num_of_reads > min_read_number:
            has_min_num_of_reads = True
        with open(output._file, "w") as fh:
            fh.write(f"has_min_num_of_reads:{has_min_num_of_reads}\nnum_of_reads:{num_of_reads}\n")
    except Exception:
        with open(log.err_file, "w+") as fh:
            fh.write(traceback.format_exc())

rule__greater_than_min_reads_check(
    snakemake.input,
    snakemake.output,
    snakemake.params.component_json,
    snakemake.log)
