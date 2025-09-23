#!/usr/bin/env bash
set -euo pipefail

K3S_VERSION="${1:-v1.29.6+k3s1}"
INSTALL_OPTS="${2:---disable traefik --disable servicelb --disable metrics-server}"

log() {
  echo "[install_k3s] $1"
}

if command -v k3s >/dev/null 2>&1; then
  INSTALLED_VERSION=$(k3s -v | awk '{print $3}')
  if [[ "$INSTALLED_VERSION" == "$K3S_VERSION" ]]; then
    log "k3s $K3S_VERSION ya está instalado."
  else
    log "k3s ya está instalado ($INSTALLED_VERSION); omitiendo reinstalación."
  fi
  exit 0
fi

log "Actualizando paquetes..."
apt-get update -y
apt-get install -y curl git

log "Instalando k3s $K3S_VERSION"
INSTALL_K3S_VERSION="$K3S_VERSION" INSTALL_K3S_EXEC="server $INSTALL_OPTS" sh -s - < <(curl -sfL https://get.k3s.io)

log "Habilitando k3s"
systemctl enable k3s >/dev/null
systemctl restart k3s

log "Creando acceso kubeconfig para root"
mkdir -p /root/.kube
cp /etc/rancher/k3s/k3s.yaml /root/.kube/config
chmod 600 /root/.kube/config

if ! command -v kubectl >/dev/null 2>&1; then
  ln -sf /usr/local/bin/k3s /usr/local/bin/kubectl
fi

log "Instalación completada"
