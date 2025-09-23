# Hostinger K3s Bootstrap

Infraestructura mínima para aprovisionar un clúster k3s (v1.29.6+k3s1) en la VPS de Hostinger y preparar la base para GitOps con FluxCD.

## Componentes

- **Terraform**: instala k3s sobre Ubuntu vía SSH y recupera el kubeconfig (soporta clave privada o contraseña).
- **FluxCD (opcional)**: bootstrap hacia un repositorio GitOps (`clusters/hostinger`).
- **GitHub Actions**: workflow `infra` para validar (`plan`) y aplicar Terraform (`workflow_dispatch`).

## Requerimientos locales

- Terraform >= 1.5
- `flux` CLI >= 2.2 si usarás bootstrap
- Acceso SSH a la VPS (`root@72.60.140.107`)
- **Recomendado:** crear clave SSH sin passphrase y deshabilitar login por contraseña
- Si usarás contraseña, instala `sshpass` (`brew install hudochenkov/sshpass/sshpass` o `sudo apt install sshpass`)

## Uso rápido (clave privada)

```bash
cd terraform
terraform init
terraform plan \
  -var "ssh_host=72.60.140.107" \
  -var "ssh_user=root" \
  -var "ssh_private_key_path=~/.ssh/id_rsa_hostinger"

terraform apply -auto-approve \
  -var "k3s_version=v1.29.6+k3s1" \
  -var "ssh_private_key_path=~/.ssh/id_rsa_hostinger"
```

## Uso con contraseña temporal

> ⚠️ Para producción se recomienda migrar a autenticación por clave y desactivar contraseña.

```bash
cd terraform
terraform init
terraform apply \
  -var "ssh_host=72.60.140.107" \
  -var "ssh_user=root" \
  -var "ssh_password=<se solicitará si se deja vacío>"
```

Durante `terraform apply`, si no exportas `TF_VAR_ssh_password`, se te pedirá la contraseña en la consola. El script `scripts/fetch_kubeconfig.sh` usa `sshpass` para copiar el kubeconfig.

## kubeconfig

El kubeconfig ajustado se guarda en `artifacts/kubeconfig`. Exporta `KUBECONFIG` para interactuar con el clúster:

```bash
export KUBECONFIG=$(pwd)/artifacts/kubeconfig
kubectl get nodes
```

Consulta `terraform/variables.tf` para ver todas las variables disponibles.

## Bootstrap Flux (opcional)

Terraform puede ejecutar `flux bootstrap` si defines:

```bash
terraform apply \
  -var "flux_bootstrap_enabled=true" \
  -var "flux_github_owner=tu-usuario" \
  -var "flux_github_repository=tu-repo" \
  -var "ssh_private_key_path=~/.ssh/id_rsa_hostinger"
```

Si decides usar contraseña, exporta `TF_VAR_ssh_password` y verifica que `sshpass` esté instalado antes de aplicar. Además exporta `GITHUB_TOKEN` con permisos sobre el repositorio GitOps:

```bash
export TF_VAR_ssh_password=$(read -s -p 'SSH Password: ' pwd; echo "$pwd")
export GITHUB_TOKEN=ghp_xxx
```

Alternativamente ejecuta manualmente el script:

```bash
cd terraform
./scripts/bootstrap_flux.sh --owner tu-usuario --repo tu-repo --branch main
```

## GitHub Actions

Configura en el repositorio los siguientes secretos:

- `SSH_PRIVATE_KEY`: clave privada en formato PEM (sin passphrase). O bien `SSH_PASSWORD` si decides usar contraseña (no recomendado).
- `FLUX_GITHUB_TOKEN`: token con permisos `repo` si usarás bootstrap desde la acción.

El workflow `infra` ejecuta:

1. `push`/`pull_request`: `terraform fmt`, `terraform validate`, `terraform plan`.
2. `workflow_dispatch`: `terraform apply` (aplica cambios en la VPS y publica el kubeconfig como artefacto).

Para lanzar el apply manualmente, ve a **Actions → infra → Run workflow**, define si deseas bootstrap de Flux y los datos del repositorio.

## Estructura principal

```
k8s_VPS1/
├── terraform/             # IaC para instalar k3s y opcionalmente Flux
├── clusters/hostinger/    # Manifiestos base sincronizados por Flux
├── artifacts/             # Kubeconfig generado
└── .github/workflows/     # Pipeline de CI/CD
```
