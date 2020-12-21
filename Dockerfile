FROM alpine:3.12.3

RUN apt-get update
RUN apt-get install -y dnsutils
