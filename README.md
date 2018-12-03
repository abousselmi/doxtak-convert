# DoXtak-convert

Converts all files into markdown before the doxtak build.

## Usage

You can use it like this:

``` console
docker run -v /path/to/data:/data abousselmi/doxtak-convert
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
