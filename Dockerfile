# This is intended to run in Github Actions
# Arg can be set to dev for testing purposes
ARG BUILD_ENV="prod"
ARG NAME="bifrost_min_read_check"
ARG CODE_VERSION="unspecified"
ARG RESOURCE_VERSION="unspecified"

# For dev build include testing modules via pytest done on github and in development.
# Watchdog is included for docker development (intended method) and should preform auto testing 
# while working on *.py files
FROM continuumio/miniconda3:4.7.10 as build_dev
ONBUILD ARG NAME
ONBUILD RUN pip install pytest \
    pytest-cov \
    pytest-profiling \
    coverage \
    pyyaml \
    argh \
    watchdog;
ONBUILD COPY tests /${NAME}/tests

FROM continuumio/miniconda3:4.7.10 as build_prod
ONBUILD ARG NAME
ONBUILD RUN echo ${BUILD_ENV}

FROM build_${BUILD_ENV}
ARG NAME
LABEL \
    name=${NAME} \
    description="Docker environment for ${NAME}" \
    code_version="${CODE_VERSION}" \
    resource_version="${RESOURCE_VERSION}" \
    environment="${BUILD_ENV}" \
    maintainer="kimn@ssi.dk;"

#- Tools to install:start---------------------------------------------------------------------------
RUN \
    conda install -yq -c conda-forge -c bioconda -c default snakemake-minimal==5.7.1; \
    conda install -yq -c conda-forge -c bioconda -c default bbmap==38.58;
#- Tools to install:end ----------------------------------------------------------------------------

#- Additional resources (files/DBs): start ---------------------------------------------------------
# adapters.fasta included with src
#- Additional resources (files/DBs): end -----------------------------------------------------------

#- Source code:start -------------------------------------------------------------------------------
COPY ${NAME} /${NAME}/${NAME}
COPY setup.py /${NAME}
RUN \
    sed -i'' 's/<code_version>/'"${CODE_VERSION}"'/g' /${NAME}/${NAME}/config.yaml; \
    sed -i'' 's/<resource_version>/'"${RESOURCE_VERSION}"'/g' /${NAME}/${NAME}/config.yaml; \
    cd /${NAME}; \
    pip install -e .; 
#- Source code:end ---------------------------------------------------------------------------------

#- Set up entry point:start ------------------------------------------------------------------------
ENTRYPOINT ["python3", "-m", "bifrost_min_read_check"]
CMD ["python3", "-m", "bifrost_min_read_check", "--help"]
#- Set up entry point:end --------------------------------------------------------------------------