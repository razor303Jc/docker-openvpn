#!/bin/bash

#
# OpenVPN Docker Helper Script
# Simplifies common OpenVPN Docker operations
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="${OPENVPN_IMAGE:-kylemanna/openvpn}"
DATA_VOLUME="${OVPN_DATA:-ovpn-data}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_usage() {
    cat << EOF
OpenVPN Docker Helper Script

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    init [SERVER_URL]     - Initialize OpenVPN configuration and PKI
    start                 - Start OpenVPN server
    stop                  - Stop OpenVPN server
    status                - Show server status
    logs                  - Show server logs
    client-add [NAME]     - Add a new client certificate
    client-get [NAME]     - Get client configuration file
    client-list           - List all clients
    client-revoke [NAME]  - Revoke a client certificate
    backup [PATH]         - Backup OpenVPN configuration and certificates
    restore [PATH]        - Restore from backup
    update                - Update OpenVPN Docker image

Options:
    -h, --help           - Show this help message
    -v, --verbose        - Enable verbose output
    -d, --data-volume    - Specify data volume name (default: $DATA_VOLUME)
    -i, --image          - Specify Docker image (default: $IMAGE_NAME)

Examples:
    $0 init udp://vpn.example.com
    $0 client-add john-laptop
    $0 client-get john-laptop > john-laptop.ovpn
    $0 backup /backup/openvpn-$(date +%Y%m%d)

Environment Variables:
    OVPN_DATA           - Data volume name
    OPENVPN_IMAGE       - Docker image to use
    DEBUG               - Enable debug output (1 to enable)

EOF
}

log() {
    echo -e "${GREEN}[INFO]${NC} $*" >&2
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

debug() {
    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $*" >&2
    fi
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        error "Cannot connect to Docker daemon. Is Docker running?"
        exit 1
    fi
}

check_volume_exists() {
    if ! docker volume inspect "$DATA_VOLUME" &> /dev/null; then
        log "Creating Docker volume: $DATA_VOLUME"
        docker volume create "$DATA_VOLUME"
    fi
}

init_openvpn() {
    local server_url="${1:-}"
    
    if [[ -z "$server_url" ]]; then
        error "Server URL is required for initialization"
        echo "Example: $0 init udp://vpn.example.com"
        exit 1
    fi
    
    check_volume_exists
    
    log "Initializing OpenVPN configuration for $server_url"
    docker run -v "$DATA_VOLUME":/etc/openvpn --rm "$IMAGE_NAME" ovpn_genconfig -u "$server_url"
    
    log "Initializing PKI (you will be prompted for CA passphrase)"
    docker run -v "$DATA_VOLUME":/etc/openvpn --rm -it "$IMAGE_NAME" ovpn_initpki
    
    log "OpenVPN initialization complete!"
}

start_server() {
    check_volume_exists
    
    if docker ps --filter "name=openvpn" --filter "status=running" | grep -q openvpn; then
        warn "OpenVPN server is already running"
        return 0
    fi
    
    log "Starting OpenVPN server"
    docker run -v "$DATA_VOLUME":/etc/openvpn \
        -d -p 1194:1194/udp \
        --cap-add=NET_ADMIN \
        --cap-drop=ALL \
        --restart=unless-stopped \
        --name=openvpn \
        "$IMAGE_NAME"
    
    log "OpenVPN server started successfully"
}

stop_server() {
    if docker ps --filter "name=openvpn" --filter "status=running" | grep -q openvpn; then
        log "Stopping OpenVPN server"
        docker stop openvpn
        docker rm openvpn
        log "OpenVPN server stopped"
    else
        warn "OpenVPN server is not running"
    fi
}

show_status() {
    if docker ps --filter "name=openvpn" --filter "status=running" | grep -q openvpn; then
        echo -e "${GREEN}OpenVPN server is running${NC}"
        docker ps --filter "name=openvpn"
        echo
        echo "Recent log entries:"
        docker logs --tail 10 openvpn
    else
        echo -e "${RED}OpenVPN server is not running${NC}"
    fi
}

show_logs() {
    if docker ps --filter "name=openvpn" | grep -q openvpn; then
        docker logs -f openvpn
    else
        error "OpenVPN container is not running"
        exit 1
    fi
}

add_client() {
    local client_name="${1:-}"
    
    if [[ -z "$client_name" ]]; then
        error "Client name is required"
        exit 1
    fi
    
    log "Adding client certificate for: $client_name"
    docker run -v "$DATA_VOLUME":/etc/openvpn --rm -it "$IMAGE_NAME" easyrsa build-client-full "$client_name"
    log "Client certificate created for: $client_name"
}

get_client_config() {
    local client_name="${1:-}"
    
    if [[ -z "$client_name" ]]; then
        error "Client name is required"
        exit 1
    fi
    
    debug "Retrieving client configuration for: $client_name"
    docker run -v "$DATA_VOLUME":/etc/openvpn --rm "$IMAGE_NAME" ovpn_getclient "$client_name"
}

list_clients() {
    log "Listing client certificates"
    docker run -v "$DATA_VOLUME":/etc/openvpn --rm "$IMAGE_NAME" ovpn_listclients
}

revoke_client() {
    local client_name="${1:-}"
    
    if [[ -z "$client_name" ]]; then
        error "Client name is required"
        exit 1
    fi
    
    log "Revoking client certificate for: $client_name"
    docker run -v "$DATA_VOLUME":/etc/openvpn --rm -it "$IMAGE_NAME" ovpn_revokeclient "$client_name" remove
    log "Client certificate revoked for: $client_name"
}

backup_config() {
    local backup_path="${1:-./openvpn-backup-$(date +%Y%m%d-%H%M%S).tar.gz}"
    
    log "Creating backup at: $backup_path"
    docker run -v "$DATA_VOLUME":/etc/openvpn --rm "$IMAGE_NAME" tar czf - /etc/openvpn > "$backup_path"
    log "Backup created successfully: $backup_path"
}

restore_config() {
    local backup_path="${1:-}"
    
    if [[ -z "$backup_path" ]] || [[ ! -f "$backup_path" ]]; then
        error "Backup file path is required and must exist"
        exit 1
    fi
    
    warn "This will overwrite existing configuration. Continue? (y/N)"
    read -r confirm
    if [[ "$confirm" != "y" ]] && [[ "$confirm" != "Y" ]]; then
        log "Restore cancelled"
        exit 0
    fi
    
    log "Restoring from backup: $backup_path"
    docker run -v "$DATA_VOLUME":/etc/openvpn --rm -i "$IMAGE_NAME" tar xzf - < "$backup_path"
    log "Restore completed successfully"
}

update_image() {
    log "Updating OpenVPN Docker image: $IMAGE_NAME"
    docker pull "$IMAGE_NAME"
    log "Image updated successfully"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            print_usage
            exit 0
            ;;
        -v|--verbose)
            export DEBUG=1
            shift
            ;;
        -d|--data-volume)
            DATA_VOLUME="$2"
            shift 2
            ;;
        -i|--image)
            IMAGE_NAME="$2"
            shift 2
            ;;
        init)
            check_docker
            init_openvpn "$2"
            exit 0
            ;;
        start)
            check_docker
            start_server
            exit 0
            ;;
        stop)
            check_docker
            stop_server
            exit 0
            ;;
        status)
            check_docker
            show_status
            exit 0
            ;;
        logs)
            check_docker
            show_logs
            exit 0
            ;;
        client-add)
            check_docker
            add_client "$2"
            exit 0
            ;;
        client-get)
            check_docker
            get_client_config "$2"
            exit 0
            ;;
        client-list)
            check_docker
            list_clients
            exit 0
            ;;
        client-revoke)
            check_docker
            revoke_client "$2"
            exit 0
            ;;
        backup)
            check_docker
            backup_config "$2"
            exit 0
            ;;
        restore)
            check_docker
            restore_config "$2"
            exit 0
            ;;
        update)
            check_docker
            update_image
            exit 0
            ;;
        *)
            error "Unknown command: $1"
            print_usage
            exit 1
            ;;
    esac
done

# No command provided
print_usage
exit 1