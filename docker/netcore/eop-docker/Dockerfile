FROM ubuntu AS final

# Build as normal.

FROM ubuntu:bionic AS contrast-builder

RUN set -xe \
    && apt-get update \
    && apt-get install -y wget unzip

RUN set -xe \
    && wget \
    --header=Accept:application/json   \
    --header=API-Key:<API_KEY>  \
    --header=Authorization:<AUTHKEY> \
    https://<TEAMSERVER>/Contrast/api/ng/<ORG_NAME>/agents/default/DOTNET_CORE \
    -O /dotnet-core.zip \
    && unzip /dotnet-core.zip -d /contrast

FROM final AS contrast-final

COPY --from=contrast-builder /contrast /contrast
