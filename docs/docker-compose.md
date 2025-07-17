# Quick Start with docker-compose

## Modern Docker Compose Configuration

Create a `docker-compose.yml` file with improved security settings:

```yaml
version: '3.8'

services:
  openvpn:
    image: kylemanna/openvpn:latest  # Pin to specific version in production
    container_name: openvpn
    cap_add:
      - NET_ADMIN
    cap_drop:
      - ALL
    ports:
      - "1194:1194/udp"
    restart: unless-stopped
    volumes:
      - openvpn-data:/etc/openvpn
    environment:
      - DEBUG=0  # Set to 1 for debugging
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
    healthcheck:
      test: ["CMD", "netstat", "-an", "|", "grep", "1194"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

volumes:
  openvpn-data:
    driver: local
```

## Production-Ready Configuration

For production environments, consider this enhanced configuration:

```yaml
version: '3.8'

services:
  openvpn:
    image: kylemanna/openvpn:2.4  # Use specific version
    container_name: openvpn-prod
    cap_add:
      - NET_ADMIN
    cap_drop:
      - ALL
    ports:
      - "1194:1194/udp"
    restart: unless-stopped
    volumes:
      - openvpn-data:/etc/openvpn:Z  # SELinux context
    environment:
      - DEBUG=0
    logging:
      driver: syslog
      options:
        syslog-address: "tcp://your-log-server:514"
        tag: "openvpn"
    healthcheck:
      test: ["CMD", "netstat", "-an", "|", "grep", "1194"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
        reservations:
          memory: 256M
          cpus: '0.25'

volumes:
  openvpn-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/openvpn-data  # Use dedicated storage
```


* Initialize the configuration files and certificates

```bash
docker-compose run --rm openvpn ovpn_genconfig -u udp://VPN.SERVERNAME.COM
docker-compose run --rm openvpn ovpn_initpki
```

* Fix ownership (depending on how to handle your backups, this may not be needed)

```bash
sudo chown -R $(whoami): ./openvpn-data
```

* Start OpenVPN server process

```bash
docker-compose up -d openvpn
```

* You can access the container logs with

```bash
docker-compose logs -f
```

* Generate a client certificate

```bash
export CLIENTNAME="your_client_name"
# with a passphrase (recommended)
docker-compose run --rm openvpn easyrsa build-client-full $CLIENTNAME
# without a passphrase (not recommended)
docker-compose run --rm openvpn easyrsa build-client-full $CLIENTNAME nopass
```

* Retrieve the client configuration with embedded certificates

```bash
docker-compose run --rm openvpn ovpn_getclient $CLIENTNAME > $CLIENTNAME.ovpn
```

* Revoke a client certificate

```bash
# Keep the corresponding crt, key and req files.
docker-compose run --rm openvpn ovpn_revokeclient $CLIENTNAME
# Remove the corresponding crt, key and req files.
docker-compose run --rm openvpn ovpn_revokeclient $CLIENTNAME remove
```

## Debugging Tips

* Create an environment variable with the name DEBUG and value of 1 to enable debug output (using "docker -e").

```bash
docker-compose run -e DEBUG=1 -p 1194:1194/udp openvpn
```
