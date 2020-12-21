FROM alpine:3.12.3

MAINTAINER "Mattia Peri"

WORKDIR /app

RUN apk add --update --no-cache bind-tools

