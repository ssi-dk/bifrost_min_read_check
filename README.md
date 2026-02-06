# bifrost_min_read_check

The input data to this initial component will already be adapter trimmed, so this component when given a sample id and requirements checks will perform additional trimming of the received sequencing files - nucleotide quality trimming - low complexity reads and so on. 

## Nucleotide quality trimming (see pipeline.smk)
```
fastp --in1 xx --in2 xx --out1 xx --out2 xx --threads xx -q 30 -e 30 -l 30 -y 30
```
### the parameters as taken from the fastp documentation (https://github.com/OpenGene/fastp)
```
-q, --qualified_quality_phred      the quality value that a base is qualified. Default 15 means phred quality >=Q15 is qualified. (int [=15])
-e, --average_qual                 if one read's average quality score <avg_qual, then this read/pair is discarded. Default 0 means no requirement (int [=0])
-l, --length_required              reads shorter than length_required will be discarded, default is 15. (int [=15])
-y, --low_complexity_filter          enable low complexity filter. The complexity is defined as the percentage of base that is different from its next base (base[i] != base[i+1]).
```
## Check number of reads (see pipeline.smk and config.yaml)
in rule greater_than_min_reads_check it will ensure all the trimmed reads have more than 10000 reads, if not it will be discarded
```
specified in {params.min_reads_threshold}
```

# data storage
The input are the received adapter trimmed sequences which are present in this component collection in the database
```
sample['categories']['paired_reads']['summary']['data']
```
The output are the quality trimmed sequences used throughout all of the remaining components, stored within

```
sample['categories']['paired_reads']["summary"]["trimmed"]
```

# Rerun this sole component as a module for dev/test
```
snakemake --nolock --cores all -s path/bifrost_min_read_check/bifrost_min_read_check/pipeline.smk --config sample_name=sample_id component_name=min_read_check__v2.2.8
```

