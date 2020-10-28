from bifrostlib import common
from bifrostlib.datahandling import Sample
from bifrostlib.datahandling import Component
from bifrostlib.datahandling import SampleComponent
import re
from typing import Dict


def extract_has_min_num_of_reads(summary: Dict, results: Dict) -> None:
    file_name = "has_min_num_of_reads"
    results[file_name]["has_min_num_of_reads"] = "True" in common.get_group_from_file("has_min_num_of_reads:(True|False)", file_name)
    results[file_name]["num_of_reads"] = int(common.get_group_from_file("min_read_num:\s*([0-9]+)", file_name))
    summary["has_min_num_of_reads"] = results[file_name]["has_min_num_of_reads"]


def datadump(sample: Sample, component: Component, samplecomponent: SampleComponent):
    category: Dict = samplecomponent["categories"].get("size_check", {})
    if category == {}:
        samplecomponent["categories"]["size_check"] = {
            "2.1": {
                "component": {"id": component["_id"], "name": component["name"]},
                "summary": {},
                "report": {}
            }
        }
    elif category != {} and category.get("2.1", {}) == {}:
        samplecomponent["categories"]["size_check"]["2.1"] = {
            "component": {"id": component["_id"], "name": component["name"]},
            "summary": {},
            "report": {}
        }
    summary: Dict = samplecomponent["categories"]["size_check"]["2.1"]["summary"]
    report: Dict = samplecomponent["categories"]["size_check"]["2.1"]["report"]
    results: Dict = samplecomponent["results"]
    extract_has_min_num_of_reads(summary, results)
    samplecomponent["status"] = "Success"
    samplecomponent.save()

datadump(
    snakemake.params.sample,
    snakemake.params.component,
    snakemake.params.samplecomponent,
    snakemake.log)
