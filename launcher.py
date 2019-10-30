#!/usr/bin/env python3
"""
Launcher file for accessing dockerfile commands
"""
import argparse
import json
import subprocess
import os
from bifrostlib import datahandling

COMPONENT = datahandling.load_yaml(os.path.join(os.path.dirname(__file__), 'config.yaml'))


def parse_args():
    """
    Arg parsing via argparse
    """
    description = (
        f"{COMPONENT['details']['description']}\n"
        f"docker run -v <input_path>:/input -v <output_path>:/output \ \n"
        f"{COMPONENT['dockerfile']} -id <sample_id>"
    )
    parser = argparse.ArgumentParser(description=description, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('-id', '--sample_id',
                        action='store',
                        type=str,
                        help='Sample ID of sample in bifrost, sample has already been added to the bifrost DB')
    parser.add_argument('-info', '--info',
                        action='store_true',
                        help='Provides basic information on component')
    args = parser.parse_args()

    if args.info:
        show_info()
    if args.sample_id is not None:
        run_sample(args)


def show_info():
    """
    Shows information about the component
    """
    message = (
        f"Component: {COMPONENT['name']}\n"
        f"Version: {COMPONENT['version']}\n"
        f"Details: {json.dumps(COMPONENT['details'], indent=4)}\n"
    )
    print(message)


def run_sample(args: object):
    """
    Runs sample ID through snakemake pipeline
    """
    sample_id = datahandling.get_samples(sample_ids=args.id)
    component_id = datahandling.get_components(component_names=COMPONENT['name'], component_versions=COMPONENT['version'])
    if len(sample_id) != 1 or len(component_id) != 1:
        print(f"Error with sample_id or component_id:"
              f"sample_id: {' '.join(sample_id)}"
              f"component_id: {' '.join(component_id)}"
              )
    else:
        process = subprocess.Popen(f"snakemake -s /bifrost/min_read_check/pipeline.smk --config sample_id={sample_id} component_id={component_id}",
                                   stdout=subprocess.PIPE,
                                   stderr=subprocess.STDOUT,
                                   shell=True)
        process_out, process_err = process.communicate()
        print(process_out, process_err)


if __name__ == '__main__':
    parse_args()
