#!/usr/bin/env bash
set -euo pipefail

# Simple helper to SSH into the VPS and/or connect to the k8s cluster
# and port-forward n8n's UI to localhost:8001.

# Defaults (edit if needed)
SSH_USER="root"
SSH_HOST="72.60.140.107"
SSH_PORT="22"
NAMESPACE="n8n"
SERVICE="n8n"
LOCAL_PORT="8001"
REMOTE_PORT="80"
# KUBECONFIG is relative to repo root by default
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KUBECONFIG_PATH="$REPO_ROOT/artifacts/kubeconfig"

usage() {
  cat <<USAGE
Usage: $(basename "$0") [--ssh] [--open] [--namespace n8n] [--kubeconfig <path>] [--ssh-user root] [--ssh-host <ip>] [--ssh-port 22]

Options:
  --ssh                 Open SSH session to the VPS and exit.
  --open                Open browser to http://localhost:${LOCAL_PORT} after port-forward succeeds (macOS 'open').
  --namespace <ns>      Namespace where n8n Service lives (default: ${NAMESPACE}).
  --kubeconfig <path>   Path to kubeconfig (default: ${KUBECONFIG_PATH}).
  --ssh-user <user>     SSH user (default: ${SSH_USER}).
  --ssh-host <host>     SSH host/IP (default: ${SSH_HOST}).
  --ssh-port <port>     SSH port (default: ${SSH_PORT}).

Examples:
  # Port-forward n8n UI to localhost:${LOCAL_PORT}
  $(basename "$0")

  # Open SSH session only
  $(basename "$0") --ssh
USAGE
}

OPEN_BROWSER=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ssh)
      SSH_ONLY=true
      shift
      ;;
    --open)
      OPEN_BROWSER=true
      shift
      ;;
    --namespace)
      NAMESPACE="$2"; shift 2 ;;
    --kubeconfig)
      KUBECONFIG_PATH="$2"; shift 2 ;;
    --ssh-user)
      SSH_USER="$2"; shift 2 ;;
    --ssh-host)
      SSH_HOST="$2"; shift 2 ;;
    --ssh-port)
      SSH_PORT="$2"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

SSH_ONLY=${SSH_ONLY:-false}

if [[ "$SSH_ONLY" == true ]]; then
  echo "🔐 Connecting via SSH to ${SSH_USER}@${SSH_HOST}:${SSH_PORT}..."
  exec ssh -p "$SSH_PORT" "${SSH_USER}@${SSH_HOST}"
fi

if [[ ! -f "$KUBECONFIG_PATH" ]]; then
  echo "❌ Kubeconfig not found at: $KUBECONFIG_PATH" >&2
  echo "   Adjust with --kubeconfig <path> or generate it via Terraform." >&2
  exit 1
fi

export KUBECONFIG="$KUBECONFIG_PATH"

echo "✅ Using KUBECONFIG=$KUBECONFIG"

# Quick cluster check
if ! kubectl version --short >/dev/null 2>&1; then
  echo "❌ Cannot reach cluster API with provided kubeconfig." >&2
  exit 1
fi

# Ensure namespace exists (no-op if present)
kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create ns "$NAMESPACE"

# Check service exists
if ! kubectl -n "$NAMESPACE" get svc "$SERVICE" >/dev/null 2>&1; then
  echo "⚠️  Service '$SERVICE' not found in namespace '$NAMESPACE'." >&2
  echo "   Make sure n8n is deployed and the Service exists." >&2
fi

# Handle cleanup on exit
cleanup() {
  [[ -n "${PF_PID:-}" ]] && kill "$PF_PID" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

# Start port-forward in background with retries
ATTEMPTS=0
MAX_ATTEMPTS=5
while : ; do
  echo "🔌 Port-forwarding ${NAMESPACE}/${SERVICE} ${LOCAL_PORT}:${REMOTE_PORT} (attempt $((ATTEMPTS+1))/${MAX_ATTEMPTS})..."
  set +e
  kubectl -n "$NAMESPACE" port-forward svc/"$SERVICE" "$LOCAL_PORT":"$REMOTE_PORT" >/dev/null 2>&1 &
  PF_PID=$!
  set -e
  # wait a bit and test
  sleep 2
  if lsof -nP -iTCP:"$LOCAL_PORT" -sTCP:LISTEN >/dev/null 2>&1; then
    echo "🎉 n8n UI available at: http://localhost:${LOCAL_PORT}"
    [[ "$OPEN_BROWSER" == true ]] && command -v open >/dev/null 2>&1 && open "http://localhost:${LOCAL_PORT}" || true
    wait "$PF_PID"
    exit 0
  fi
  kill "$PF_PID" >/dev/null 2>&1 || true
  ATTEMPTS=$((ATTEMPTS+1))
  if (( ATTEMPTS >= MAX_ATTEMPTS )); then
    echo "❌ Failed to establish port-forward after ${MAX_ATTEMPTS} attempts." >&2
    exit 1
  fi
  sleep 2
done
