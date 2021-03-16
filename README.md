# bifrost_min_read_check

This component is run given a sample id already added into the bifrostDB.From this it'll pull the paired_reads and run a check to ensure that the raw data has a minimum set of reads as to allow other programs in the workflow to work. The output of this is a simple boolean on if it 'has_min_num_of_reads'

## Programs: (see Dockerfile) 
```
snakemake-minimal==5.7.1; \
bbmap==38.58; 
```

## Summary of c run: (see pipeline.smk and config.yaml)
```
java -ea -cp /opt/conda/opt/bbmap-38.58-0/current/ jgi.BBDuk in={input.reads[0]} in2={input.reads[1]} ref={params.adapters} ktrim=r k=23 mink=11 hdist=1 tbo qtrim=r minlength=30 1> {log.out_file} 2> {output.stats_file}
rule__greater_than_min_reads_check.py
```
