FROM mambaorg/micromamba:alpine3.21

ARG TOOL_VERSION=2.0.3

RUN micromamba install -y -n base -c bioconda -c conda-forge \
        trnascan-se=${TOOL_VERSION} \
    && micromamba clean --all --yes \
    && find /opt/conda -follow -type f -name '*.a' -delete \
    && find /opt/conda -follow -type f -name '*.pyc' -delete \
    && sed -i 's|temp_dir: /tmp|temp_dir: /tscan_tmp|g' /opt/conda/bin/tRNAscan-SE.conf

USER root
RUN mkdir -p /tscan_tmp && chmod 777 /tscan_tmp
USER $MAMBA_USER

ENV PATH="/opt/conda/bin:${PATH}" \
    LD_LIBRARY_PATH="/opt/conda/lib" \
    TMPDIR="/tscan_tmp"
WORKDIR /data

ENTRYPOINT ["tRNAscan-SE"]