# Original credit: https://github.com/jpetazzo/dockvpn

# Use specific Alpine version for reproducible builds
FROM alpine:3.22

LABEL maintainer="Kyle Manna <kyle@kylemanna.com>"

# Install required packages with simpler repository configuration
RUN apk update && \
    apk add --no-cache \
        openvpn \
        iptables \
        bash \
        easy-rsa \
        openssl \
        curl \
        ca-certificates \
        net-tools && \
    ln -s /usr/share/easy-rsa/easyrsa /usr/local/bin && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/*

# Needed by scripts
ENV OPENVPN=/etc/openvpn
ENV EASYRSA=/usr/share/easy-rsa \
    EASYRSA_CRL_DAYS=3650 \
    EASYRSA_PKI=$OPENVPN/pki

# Copy scripts and set permissions
COPY ./bin /usr/local/bin
RUN chmod a+x /usr/local/bin/*

# Add support for OTP authentication using a PAM module
COPY ./otp/openvpn /etc/pam.d/

VOLUME ["/etc/openvpn"]

# Internally uses port 1194/udp, remap using `docker run -p 443:1194/tcp`
EXPOSE 1194/udp

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD netstat -lun | grep :1194 > /dev/null || exit 1

CMD ["ovpn_run"]
