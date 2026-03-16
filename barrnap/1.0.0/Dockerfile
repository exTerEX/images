FROM mambaorg/micromamba:alpine3.21

ARG TOOL_VERSION=1.0.0

RUN wget -qO /tmp/barrnap.tar.gz \
        https://github.com/tseemann/barrnap/archive/refs/tags/v${TOOL_VERSION}.tar.gz \
    && tar xzf /tmp/barrnap.tar.gz -C /tmp \
    && micromamba install -y -n base \
        --file /tmp/barrnap-${TOOL_VERSION}/environment.yml \
    && cp /tmp/barrnap-${TOOL_VERSION}/bin/barrnap /opt/conda/bin/ \
    && cp -r /tmp/barrnap-${TOOL_VERSION}/db /opt/conda/db \
    && micromamba clean --all --yes \
    && find /opt/conda -follow -type f -name '*.a' -delete \
    && find /opt/conda -follow -type f -name '*.pyc' -delete \
    && rm -rf /tmp/barrnap.tar.gz /tmp/barrnap-${TOOL_VERSION}

ENV PATH="/opt/conda/bin:${PATH}"
WORKDIR /data

ENTRYPOINT ["barrnap"]
