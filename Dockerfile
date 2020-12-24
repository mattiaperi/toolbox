FROM golang:latest as builder

WORKDIR /build 
ADD main.go /build/main.go

RUN go get -d
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags '-extldflags "-static"' -o main .


FROM alpine:3.12.3

WORKDIR /app
COPY --from=builder /build/main /app/

RUN apk add --update --no-cache bind-tools
CMD ["./main"]

