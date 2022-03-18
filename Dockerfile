FROM golang:latest as builder
WORKDIR /build

ADD main.go /build/main.go
# https://github.com/golang/go/issues/31997#issuecomment-782864390
RUN go env -w GO111MODULE=auto
RUN go get -d
# CGO_ENABLE=0 creates a standalone binary which is ideal for docker images
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -installsuffix cgo -ldflags '-extldflags "-static"' -o main .


FROM alpine:3.15
LABEL maintainer "Mattia Peri <mattia@mattiaperi.it>"
WORKDIR /app

COPY --from=builder /build/main /app/
RUN apk --no-cache --update --verbose add \
       bind-tools \
       bash \
       tcpdump \
       curl \
       jq \
       tshark \
       py3-jwt \
       sudo \
    && rm -rf /var/cache/apk/* /tmp/* 

# kubectl
RUN curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
RUN chmod +x ./kubectl \
    && mv ./kubectl /usr/local/bin/kubectl
RUN kubectl version --client

# aws-cli
RUN apk add --no-cache \
        python3 \
        py3-pip \
    && pip3 install --upgrade pip \
    && pip3 install \
        awscli \
    && rm -rf /var/cache/apk/*
RUN aws --version

# hey
RUN curl -L -o hey "https://hey-release.s3.us-east-2.amazonaws.com/hey_linux_amd64"
RUN chmod +x ./hey \
    && mv ./hey /usr/local/bin/hey

# user
RUN addgroup --gid 1100 toolbox \
    && adduser --disabled-password -u 1100 -g toolbox -G toolbox -G wheel -H -s /bin/bash toolbox \
    && echo 'toolbox ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers \
    && echo '%wheel ALL=(ALL) ALL' > /etc/sudoers.d/wheel

USER 1100:1100

ENV PS1="\h:\[\e[0;32m\]\w\[\e[m\] \u \$ " 

CMD ["./main"]
