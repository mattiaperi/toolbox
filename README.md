# toolbox
Docker image with useful tools for troubleshooting purposes in Kubernetes

> :warning: **Running scripts directly from a URL or docker images from a container registry is a big security no-no**: that's the reason why the source of the project is hosted on gitHub, so you can review it.

## users
As a best practice, Kubernetes clusters should not allow running containers as root, therefore the toolbox image uses a "toolbox" (UID=1100) user and a "toolbox" group (GID=1100) 

## packages
Please find hereunder the list of packages on top of the alpine base image:
- bind-tools
- bash
- tcpdump
- curl
- jq

## custom tool
The image comes with a custom tool in golang. The purpose of the tool is to create a simple webservice and print the following information:
- Version
- Hostname
- Environment variables
- HTTP request headers

## Runtime (locally)
```bash
# Simple test, running the custom tool:
$ docker run -it --rm mattiaperi/toolbox:latest # and visit http://localhost:8080
# Simple test, opening a shell:
$ docker run -it --rm mattiaperi/toolbox:latest /bin/bash
# Simple test, running the custom tool on a specific port and testing the custom header:
$ PORT="8090"; docker run -it --rm -p 8080:${PORT} --env PORT=${PORT} mattiaperi/toolbox:latest
$ curl -XGET -H'Custom-Header: true' http://localhost:8080
```

## Runtime (Kubernetes)
```bash
$ kubectl run -it --rm --restart=Never --image=mattiaperi/toolbox:latest toolbox -n kube-system -- /bin/bash
# Example of commands:
$ nc -vz -w1 google.com 443
$ curl -XGET -H'Custom-Header: true' http://google.com:443
$ ./main # to start the custom tool
```
## TO BE REMOVED SOON OR LATER - JUST MY REF UNTIL I CREATE THE Makefile
```bash
$ git add .
$ git commit -m "Fix dnstools"
$ git push origin main

$ docker build -t mattiaperi/toolbox:latest -t mattiaperi/toolbox:0.0.6 -f Dockerfile .
$ docker push mattiaperi/toolbox:0.0.6
$ docker push mattiaperi/toolbox:latest
```

## References
- 
- https://github.com/christianhxc/prometheus-tutorial/