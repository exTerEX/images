FROM mambaorg/micromamba:alpine3.21

ARG TOOL_VERSION=0.0.21

RUN micromamba install -y -n base -c bioconda -c conda-forge \
        clinker-py=${TOOL_VERSION} \
    && micromamba clean --all --yes \
    && find /opt/conda -follow -type f -name '*.a' -delete \
    && find /opt/conda -follow -type f -name '*.pyc' -delete

ENV PATH="/opt/conda/bin:${PATH}"
WORKDIR /data

ENTRYPOINT ["clinker"]
