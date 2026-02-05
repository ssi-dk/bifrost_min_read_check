from bifrostlib import common
from bifrostlib.datahandling import Sample
from bifrostlib.datahandling import SampleComponentReference
from bifrostlib.datahandling import SampleComponent
from bifrostlib.datahandling import Category
from typing import Dict
import os


def extract_has_min_num_of_reads(
    size_check: Category, results: Dict, component_name: str
) -> None:
    file_name = "has_min_num_of_reads"
    file_key = common.json_key_cleaner(file_name)
    file_path = os.path.join(component_name, file_name)
    results[file_key] = {}
    results[file_key]["has_min_num_of_reads"] = "True"
    results[file_key]["num_of_reads"] = common.get_group_from_file(
        r"([0-9]+)", file_path
    )
    size_check["summary"]["has_min_num_of_reads"] = results[file_key][
        "has_min_num_of_reads"
    ]
    size_check["summary"]["num_of_reads"] = results[file_key]["num_of_reads"]

def save_trimmed_reads_location(paired_reads: Category, component_name: str, sample_name: str) -> None:
    file_paths = [os.path.join(os.getcwd, f"{sample_name}.R1.trim.fastq.gz"),
                  os.path.join(os.getcwd, f"{sample_name}.R2.trim.fastq.gz")]
    paired_reads["summary"]["trimmed"] = file_paths


def datadump(samplecomponent_ref_json: Dict):
    samplecomponent_ref = SampleComponentReference(value=samplecomponent_ref_json)
    samplecomponent = SampleComponent.load(samplecomponent_ref)
    sample = Sample.load(samplecomponent.sample)
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
    paired_reads = samplecomponent.get_category("paired_reads")
    if paired_reads is None:
        paired_reads = Category(value={
            "name": "paired_reads",
            "component": {"id": samplecomponent["component"]["_id"], "name": samplecomponent["component"]["name"]},
            "summary": {},
            "report": {}
        })
    extract_has_min_num_of_reads(
        size_check, samplecomponent["results"], samplecomponent["component"]["name"]
    )
    save_trimmed_reads_location(paired_reads, samplecomponent)
    samplecomponent.set_category(paired_reads)
    samplecomponent.set_category(size_check)
    sample.set_category(paired_reads)
    sample.set_category(size_check)
    common.set_status_and_save(sample, samplecomponent, "Success")

    with open(
        os.path.join(samplecomponent["component"]["name"], "datadump_complete"),
        "w+",
        encoding="utf-8",
    ) as fh:
        fh.write("done")


datadump(
    snakemake.params.samplecomponent_ref_json,
)
