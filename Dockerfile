FROM java:8-jre

LABEL maintainer="https://github.com/abousselmi"

ENV DATA_DIR="/data"
ENV S2M_CLI_URL="central.maven.org/maven2/io/github/swagger2markup/swagger2markup-cli"
ENV S2M_CLI_VERSION="1.3.3"
ENV S2M_CLI_PATH="/s2m"

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
  && apt-get install --no-install-recommends -y \
    bash \
    curl \
    pandoc \
  && mkdir -p $S2M_CLI_PATH \
  && curl -s $S2M_CLI_URL/$S2M_CLI_VERSION/swagger2markup-cli-$S2M_CLI_VERSION.jar > $S2M_CLI_PATH/cli.jar \
  && apt-get remove -y curl \
  && apt-get clean

COPY [ "./config.properties", "$S2M_CLI_PATH/config.properties" ]
COPY [ "./convert.sh", "/" ]

VOLUME [ "/data" ]

ENTRYPOINT [ "/convert.sh" ]