FROM golang:1.11.5 AS build-env

WORKDIR /go/src
COPY . .

ENV GO111MODULE=on
RUN rm -f go.sum && go get -d -v ./...
RUN go test ./...
RUN CGO_ENABLED=0 go build -o app

FROM gcr.io/distroless/base
COPY --from=build-env /go/src/app /
CMD ["/app"]
