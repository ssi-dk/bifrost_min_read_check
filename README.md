# bifrost_min_read_check

This component is run given a sample id already added into the bifrostDB.From this it'll pull the paired_reads and run a check to ensure that the raw data has a minimum set of reads as to allow other programs in the workflow to work. The output of this is a simple boolean on if it 'has_min_num_of_reads'
