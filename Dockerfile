FROM \
    ssidk/bifrost-base:2.1

LABEL \
    name="bifrost-min_read_check" \
    description="Docker environment for min_read_check in bifrost" \
    version="2.1" \
    DBversion="31/07/2019" \
    maintainer="kimn@ssi.dk;"

RUN \
    conda install -yq -c conda-forge -c bioconda -c default bbmap==38.58;

ADD https://raw.githubusercontent.com/ssi-dk/bifrost/master/setup/adapters.fasta /bifrost_resources/
ADD https://raw.githubusercontent.com/ssi-dk/bifrost/dockerfiles/components/min_read_check/pipeline.smk /bifrost/
ADD https://raw.githubusercontent.com/ssi-dk/bifrost/dockerfiles/components/min_read_check/scripts/rule__greater_than_min_reads_check.py /bifrost/scripts/
ADD https://raw.githubusercontent.com/ssi-dk/bifrost/dockerfiles/components/min_read_check/datadump.py /bifrost/

ENTRYPOINT \
    ["/bifrost_resources/docker_umask_002.sh"]