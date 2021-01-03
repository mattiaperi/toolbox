FROM golang:latest as builder
WORKDIR /build

ADD main.go /build/main.go
RUN go get -d
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags '-extldflags "-static"' -o main .


FROM alpine:3.12.3
LABEL maintainer "Mattia Peri <mattia@mattiaperi.it>"
WORKDIR /app

COPY --from=builder /build/main /app/
RUN apk --no-cache --update --verbose add \
       bind-tools \
       bash \
       tcpdump \
       curl \
    && rm -rf /var/cache/apk/* /tmp/* 

RUN addgroup --gid 1100 toolbox \
    && adduser --disabled-password -u 1100 -g toolbox -G toolbox -G wheel -H -s /bin/bash toolbox \
    && echo 'toolbox ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers 
USER toolbox

CMD ["./main"]
