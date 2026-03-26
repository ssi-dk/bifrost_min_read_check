# bifrost_min_read_check
This component is used to trim low-quality nucleotides and short sequencing reads, and to remove low-complexity sequence reads. This is the first component to handle the initial input, which is adapter-trimmed. 

## Requirements
- The component trims the input paired-end sequence reads [fastp](https://github.com/OpenGene/fastp).
- The versions are described in the [environment.yaml](https://github.com/ssi-dk/bifrost_min_read_check/blob/master/environment.yml)

## Download
```bash
git clone https://github.com/ssi-dk/bifrost_min_read_check.git
cd bifrost_min_read_check
git submodule init
git submodule update
bash install.sh -i LOCAL
conda activate bifrost_min_read_check_vx.x.x
export BIFROST_INSTALL_DIR='/your/path/'
BIFROST_DB_KEY="/your/key/here/" python -m bifrost_min_read_check -h
```
## Run the snakemake analysis
Each component can be run on a single sample using a single snakemake command, replacing the string passed to the **--config sample_name=" "** with the appropriate dataset name. The provided **component_name=** takes as an argument *<component_name>__<version_number>*. The component name aligns with the GitHub repo name, which is structured like *bifrost_<component_name>* (e.g. *bifrost_min_read_check* -> component name *min_read_check*), and the version number aligns with the current [GitHub tag](https://github.com/ssi-dk/bifrost_min_read_check/tags) / or conda environment [version](https://github.com/ssi-dk/bifrost_min_read_check/blob/master/setup.py) (e.g. *v.2.2.10*) defined during the bifrost component setup. 
```bash
snakemake --nolock --cores all -s <github_path>/pipeline.smk --config sample_name="insert sample name" component_name=min_read_check__v2.2.10 --rerun-incomplete
```
## Analysis
The fastp command is defined in the [pipeline](https://github.com/ssi-dk/bifrost_min_read_check/blob/master/bifrost_min_read_check/pipeline.smk), using the parameters *-q -e -l -y*
defined in ([fastp documentation](https://github.com/OpenGene/fastp?tab=readme-ov-file#all-options)).

Once trimmed, the rule *rule greater_than_min_reads_check* checks if the trimmed sequence reads have more than the defined 10000 reads to ensure enough data for additional analysis through other components. If the trimmed sequence reads have a lower amount, the dataset will be discarded and remain unused for further analysis.
