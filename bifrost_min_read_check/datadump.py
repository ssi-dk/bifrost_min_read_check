from bifrostlib import common
from bifrostlib.datahandling import Sample
from bifrostlib.datahandling import SampleComponentReference
from bifrostlib.datahandling import SampleComponent
from bifrostlib.datahandling import Category
from typing import Dict, List
import os


def extract_has_min_num_of_reads(size_check: Category, results: Dict, component_name: str) -> None:
    file_name = "has_min_num_of_reads"
    file_key = common.json_key_cleaner(file_name)
    file_path = os.path.join(component_name, file_name)

    results[file_key] = {}
    results[file_key]["has_min_num_of_reads"] = "True" in common.get_group_from_file(
        "has_min_num_of_reads:(True|False)", file_path
    )
    results[file_key]["num_of_reads"] = common.get_group_from_file(
        r"num_of_reads:\s*([0-9]+)", file_path
    )

    size_check["summary"]["has_min_num_of_reads"] = results[file_key]["has_min_num_of_reads"]
    size_check["summary"]["num_of_reads"] = results[file_key]["num_of_reads"]


def set_trimmed_reads_category(trimmed_reads: Category, trimmed_paths: List[str]) -> None:
    trimmed_R1 = os.path.abspath(trimmed_paths[0]) if len(trimmed_paths) > 0 else None
    trimmed_R2 = os.path.abspath(trimmed_paths[1]) if len(trimmed_paths) > 1 else None

    trimmed_reads["summary"]["data"] = [p for p in [trimmed_R1, trimmed_R2] if p]
    trimmed_reads["summary"]["trimmed_R1"] = trimmed_R1
    trimmed_reads["summary"]["trimmed_R2"] = trimmed_R2


def datadump(samplecomponent_ref_json: Dict, trimmed_reads_paths: List[str]):
    samplecomponent_ref = SampleComponentReference(value=samplecomponent_ref_json)
    samplecomponent = SampleComponent.load(samplecomponent_ref)
    sample = Sample.load(samplecomponent.sample)

    # ---- size_check category ----
    size_check = samplecomponent.get_category("size_check")
    if size_check is None:
        size_check = Category(
            value={
                "name": "size_check",
                "component": {
                    "id": samplecomponent["component"]["_id"],
                    "name": samplecomponent["component"]["name"],
                },
                "summary": {},
                "report": {},
            }
        )

    extract_has_min_num_of_reads(size_check, samplecomponent["results"], samplecomponent["component"]["name"])
    samplecomponent.set_category(size_check)
    sample.set_category(size_check)

    # ---- trimmed_reads category ----
    trimmed_reads = samplecomponent.get_category("trimmed_reads")
    if trimmed_reads is None:
        trimmed_reads = Category(
            value={
                "name": "trimmed_reads",
                "component": {
                    "id": samplecomponent["component"]["_id"],
                    "name": samplecomponent["component"]["name"],
                },
                "summary": {},
                "report": {},
            }
        )

    set_trimmed_reads_category(trimmed_reads, trimmed_reads_paths)
    samplecomponent.set_category(trimmed_reads)
    sample.set_category(trimmed_reads)

    # ---- save everything ----
    common.set_status_and_save(sample, samplecomponent, "Success")

    # ---- write completion flag ----
    with open(os.path.join(samplecomponent["component"]["name"], "datadump_complete"), "w+", encoding="utf-8") as fh:
        fh.write("done")


# Snakemake call
datadump(
    snakemake.params.samplecomponent_ref_json,
    snakemake.params.trimmed_reads_paths
)
