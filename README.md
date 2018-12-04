# DoXtak-convert

Converts all files into markdown before the doxtak build.

## Install

You can use it like this:

``` console
docker run -it --rm -p 9000:9000 -v /path/to/data:/data abousselmi/doxtak-convert
```

## Usage

To fire up the conversion:

``` console
curl -X POST http://your.ip.address:9000/api/v1/convert | jq
```

Response:

``` json
{
  "timestamp": "2018-12-04T16:18:20.146848547Z",
  "duration": 1.145996924,
  "id": 3
}
```

To ping the API, you can do:

``` console
curl -X GET http://your.ip.address:9000/api/v1/ping
```

Response:

``` console
pong
```

The swagger specification is available here:

``` console
http://your.ip.address:9000/swagger.json
```

## Build image

You can build your own image like this:

``` console
docker build \
  --build-arg http_proxy=$http_proxy \
  --build-arg https_proxy=$https_proxy \
  -t doxtak-convert .
```

## License

MIT
