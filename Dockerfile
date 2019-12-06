# Build the manager binary
FROM golang:1.10.3 as builder

# Copy in the go src
WORKDIR /go/src/github.com/jpeeler/podpreset-crd
COPY pkg/    pkg/
COPY cmd/    cmd/
COPY vendor/ vendor/

RUN mkdir /user && \
    echo 'appuser:x:2000:2000:appuser:/:' > /user/passwd && \
    echo 'appuser:x:2000:' > /user/group
RUN mkdir -p tmp

# Build
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o manager github.com/jpeeler/podpreset-crd/cmd/manager

# Copy the controller-manager into a thin image
FROM scratch
WORKDIR /root/

COPY --from=builder /user/group /user/passwd /etc/
COPY --from=builder /go/src/github.com/jpeeler/podpreset-crd/manager .

USER appuser:appuser

# appuser must be an owner of the tmp dir to write there
COPY --from=builder --chown=appuser /tmp /tmp

ENTRYPOINT ["./manager"]
