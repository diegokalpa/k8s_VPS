#!/usr/bin/env bash
set -euo pipefail

DEFAULT_BRANCH="main"
DEFAULT_PATH="clusters/hostinger"
DEFAULT_KUBECONFIG="../artifacts/kubeconfig"

usage() {
  cat <<USAGE
Uso: $0 --owner <org> --repo <repo> [--branch main] [--path clusters/hostinger] [--kubeconfig ../artifacts/kubeconfig] [--personal]

Requiere que la variable de entorno GITHUB_TOKEN esté definida y que el binario 'flux' esté instalado.
USAGE
}

OWNER=""
REPO=""
BRANCH="$DEFAULT_BRANCH"
PATH_ARG="$DEFAULT_PATH"
KUBECONFIG_PATH="$DEFAULT_KUBECONFIG"
PERSONAL="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --owner)
      OWNER="$2"
      shift 2
      ;;
    --repo)
      REPO="$2"
      shift 2
      ;;
    --branch)
      BRANCH="$2"
      shift 2
      ;;
    --path)
      PATH_ARG="$2"
      shift 2
      ;;
    --kubeconfig)
      KUBECONFIG_PATH="$2"
      shift 2
      ;;
    --personal)
      PERSONAL="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Argumento desconocido: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$OWNER" || -z "$REPO" ]]; then
  echo "--owner y --repo son obligatorios" >&2
  usage
  exit 1
fi

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  echo "GITHUB_TOKEN no está definido" >&2
  exit 1
fi

if ! command -v flux >/dev/null 2>&1; then
  echo "El binario 'flux' no está instalado" >&2
  exit 1
fi

export KUBECONFIG="$KUBECONFIG_PATH"

flux check --pre || true

flux bootstrap github \
  --owner "$OWNER" \
  --repository "$REPO" \
  --branch "$BRANCH" \
  --path "$PATH_ARG" \
  --personal="$PERSONAL"
