FROM golang:1.11-stretch

COPY [ "convert-api.go", "glide.yaml", "glide.lock", "/go/src/github.com/abousselmi/doxtak-convert/" ]

WORKDIR /go/src/github.com/abousselmi/doxtak-convert/

RUN apt-get update \
  && apt-get install -y ca-certificates curl \
  && cd /tmp && curl -L https://glide.sh/get -O -J && sh ./get \
  && rm /tmp/get && rm -rf /var/lib/apt/lists/*

RUN glide install

RUN CGO_ENABLED=0 go build -a -installsuffix nocgo -o /go/bin/convert-api .

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
COPY --from=0 /go/bin/convert-api /convert-api

VOLUME [ "/data" ]

EXPOSE 9000

HEALTHCHECK --interval=15s \
            --timeout=3s \
            --start-period=5s \
            --retries=5 \
            CMD [[ $(curl -s -o /dev/null -w "%{http_code}" "http://localhost:9000/api/v1/swagger.json") -eq 200 ]]

CMD [ "/convert-api" ]