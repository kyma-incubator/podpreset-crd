# Get latest CA certs
FROM alpine:latest as certs
RUN apk --update add ca-certificates

# Final image
FROM scratch
COPY --from=certs /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

ADD webhook /webhook
ENTRYPOINT ["/webhook"]
