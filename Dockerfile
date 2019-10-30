FROM \
    ssidk/bifrost-base:2.0.5

LABEL \
    name="bifrost-min_read_check" \
    description="Docker environment for min_read_check in bifrost" \
    version="2.0.5" \
    DBversion="31/07/2019" \
    maintainer="kimn@ssi.dk;"

RUN \
    conda install -yq -c conda-forge -c bioconda -c default bbmap==38.58; \
    cd bifrost; \
    git clone https://github.com/ssi-dk/bifrost-min_read_check.git

ADD https://raw.githubusercontent.com/ssi-dk/bifrost/master/setup/adapters.fasta /bifrost_resources/

RUN \
    cd /; \
    ln -s /bifrost/bifrost-min_read_check/launcher.py min_read_check

ENTRYPOINT [ "/min_read_check"]