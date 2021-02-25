FROM golang:latest as builder
WORKDIR /build

ADD main.go /build/main.go
RUN go get -d
# CGO_ENABLE=0 creates a standalone binary which is ideal for docker images
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 GO111MODULE=off go build -a -installsuffix cgo -ldflags '-extldflags "-static"' -o main .


FROM alpine:3.12.3
LABEL maintainer "Mattia Peri <mattia@mattiaperi.it>"
WORKDIR /app

COPY --from=builder /build/main /app/
RUN apk --no-cache --update --verbose add \
       bind-tools \
       bash \
       tcpdump \
       curl \
       jq \
    && rm -rf /var/cache/apk/* /tmp/* 

RUN addgroup --gid 1100 toolbox \
    && adduser --disabled-password -u 1100 -g toolbox -G toolbox -G wheel -H -s /bin/bash toolbox \
    && echo 'toolbox ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers 

USER toolbox
ENV PS1="\h:\[\e[0;32m\]\w\[\e[m\] \u \$ " 

CMD ["./main"]
