FROM golang:1.11-stretch as builder

COPY [ "convert-api.go", "glide.yaml", "glide.lock", "/go/src/github.com/abousselmi/doxtak-convert/" ]

WORKDIR /go/src/github.com/abousselmi/doxtak-convert/

RUN apt-get update \
  && apt-get install -y ca-certificates curl \
  && cd /tmp && curl -L https://glide.sh/get -O -J && sh ./get \
  && rm /tmp/get && rm -rf /var/lib/apt/lists/*

RUN glide install

RUN CGO_ENABLED=0 go build -a -installsuffix nocgo -o /go/bin/convert-api .

FROM java:8-jre-alpine

LABEL maintainer="https://github.com/abousselmi"

ARG PANDOC_VERSION="2.7.2"
ENV DATA_DIR="/data" \
 S2M_CLI_URL="central.maven.org/maven2/io/github/swagger2markup/swagger2markup-cli" \
 S2M_CLI_VERSION="1.3.3" \
 S2M_CLI_PATH="/s2m" \
 PANDOC_VERSION=$PANDOC_VERSION \
 PANDOC_DOWNLOAD_URL="https://github.com/jgm/pandoc/releases/download/"${PANDOC_VERSION}"/pandoc-"${PANDOC_VERSION}"-linux.tar.gz"\
 PANDOC_ROOT="/usr/local/"

RUN apk -U --no-cache add \
    bash \
    curl \
  && mkdir -p $S2M_CLI_PATH \
  && curl -L $S2M_CLI_URL/$S2M_CLI_VERSION/swagger2markup-cli-$S2M_CLI_VERSION.jar -o $S2M_CLI_PATH/cli.jar \
  && curl -L $PANDOC_DOWNLOAD_URL -o /tmp/pandoc-$PANDOC_VERSION-linux.tar.gz \
  && tar xvfz /tmp/pandoc-$PANDOC_VERSION-linux.tar.gz pandoc-$PANDOC_VERSION/bin/ -C /tmp \
  && cp /tmp/pandoc-$PANDOC_VERSION/bin/* $PANDOC_ROOT/bin\
  && rm -rf /tmp/*

COPY [ "./config.properties", "$S2M_CLI_PATH/config.properties" ]
COPY [ "./convert.sh", "/" ]
COPY --from=builder /go/bin/convert-api /convert-api

VOLUME [ "/data" ]

EXPOSE 9000

HEALTHCHECK --interval=15s \
            --timeout=3s \
            --start-period=5s \
            --retries=5 \
            CMD [[ $(curl -s -o /dev/null -w "%{http_code}" "http://localhost:9000/api/v1/swagger.json") -eq 200 ]]

CMD [ "/convert-api" ]
