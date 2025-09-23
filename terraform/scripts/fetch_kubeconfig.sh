#!/usr/bin/env bash
set -euo pipefail

SSH_USER=${1:-}
SSH_HOST=${2:-}
SSH_PORT=${3:-22}
DEST_PATH=${4:-}
KEY_PATH=${5:-}

if [[ -z "$SSH_USER" || -z "$SSH_HOST" || -z "$DEST_PATH" ]]; then
  echo "Uso: $0 <user> <host> <port> <dest_path> [key_path]" >&2
  exit 1
fi

PASSWORD=${SSH_PASSWORD:-}

if [[ -z "$KEY_PATH" && -z "$PASSWORD" ]]; then
  read -s -p "SSH Password for ${SSH_USER}@${SSH_HOST}: " PASSWORD
  echo
fi

mkdir -p "$(dirname "$DEST_PATH")"

if [[ -n "$KEY_PATH" ]]; then
  if [[ ! -f "$KEY_PATH" ]]; then
    echo "La clave privada en $KEY_PATH no existe" >&2
    exit 1
  fi
  scp -i "$KEY_PATH" \
    -P "$SSH_PORT" \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    "${SSH_USER}@${SSH_HOST}:/etc/rancher/k3s/k3s.yaml" \
    "$DEST_PATH"
else
  if ! command -v sshpass >/dev/null 2>&1; then
    echo "sshpass no está instalado. Instálalo (ej. sudo apt install sshpass) o proporciona una clave privada." >&2
    exit 1
  fi
  sshpass -p "$PASSWORD" scp \
    -P "$SSH_PORT" \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    "${SSH_USER}@${SSH_HOST}:/etc/rancher/k3s/k3s.yaml" \
    "$DEST_PATH"
fi

chmod 600 "$DEST_PATH"
