# Get latest CA certs
FROM alpine:latest as builder
RUN apk --update add ca-certificates

RUN mkdir /user && \
    echo 'appuser:x:2000:2000:appuser:/:' > /user/passwd && \
    echo 'appuser:x:2000:' > /user/group
RUN mkdir -p tmp

# Final image
FROM scratch
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=builder /user/group /user/passwd /etc/

ADD webhook /webhook

USER appuser:appuser

# appuser must be an owner of the tmp dir to write there
COPY --from=builder --chown=appuser /tmp /tmp

ENTRYPOINT ["/webhook"]
