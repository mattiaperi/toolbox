# toolbox
Docker image with useful tools for troubleshooting purposes in Kubernetes

> :warning: **Running scripts directly from a URL or docker images from a container registry is a big security no-no**: that's the reason why the source of the project is hosted on gitHub, so you can review it.

## how-to
```bash
$ git add .
$ git commit -m "Fix dnstools"
$ git push origin main

$ docker build -t mattiaperi/toolbox:latest -t mattiaperi/toolbox:0.0.3 -f Dockerfile .
$ docker push mattiaperi/toolbox:0.0.3
$ docker push mattiaperi/toolbox:latest
```

### test locally
```bash
$ docker run -it --rm mattiaperi/toolbox:latest
$ PORT="8090"; docker run -it --rm -p 8080:${PORT} --env PORT=${PORT} mattiaperi/toolbox:latest
$ curl -XGET -H'Custom-Header: true' http://localhost:8080
```
