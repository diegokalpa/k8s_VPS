provider "null" {}
provider "local" {}

locals {
  inline_private_key    = trimspace(var.ssh_private_key)
  expanded_key_path     = var.ssh_private_key_path != "" ? pathexpand(var.ssh_private_key_path) : ""
  file_private_key      = local.expanded_key_path != "" ? trimspace(file(local.expanded_key_path)) : ""
  ssh_private_key       = local.inline_private_key != "" ? local.inline_private_key : local.file_private_key
  ssh_password          = trimspace(var.ssh_password)
  has_private_key       = local.ssh_private_key != ""
  has_password          = local.ssh_password != ""
  private_key_temp_dir  = "${path.module}/.tmp"
  private_key_temp_path = "${local.private_key_temp_dir}/id_rsa"
  effective_key_path    = local.has_private_key ? (local.expanded_key_path != "" ? local.expanded_key_path : local.private_key_temp_path) : ""
  kubeconfig_path       = pathexpand(var.kubeconfig_output_path)
  kubeconfig_dir        = dirname(local.kubeconfig_path)
  api_server_addr       = var.apiserver_public_address != "" ? var.apiserver_public_address : var.ssh_host
  install_script_remote = "/tmp/install_k3s.sh"
  flux_personal_flag    = var.flux_github_personal ? "true" : "false"
}

resource "local_sensitive_file" "ssh_key" {
  count                = local.inline_private_key != "" ? 1 : 0
  filename             = local.effective_key_path
  content              = local.inline_private_key
  file_permission      = "0600"
  directory_permission = "0700"
}

resource "null_resource" "k3s_cluster" {
  depends_on = [local_sensitive_file.ssh_key]

  triggers = {
    ssh_host     = var.ssh_host
    ssh_user     = var.ssh_user
    ssh_port     = tostring(var.ssh_port)
    k3s_version  = var.k3s_version
    install_opts = var.k3s_install_options
  }

  lifecycle {
    precondition {
      condition     = local.has_private_key || local.has_password
      error_message = "Debe proporcionar ssh_private_key/ssh_private_key_path o ssh_password."
    }
  }

  connection {
    type        = "ssh"
    user        = var.ssh_user
    host        = var.ssh_host
    port        = var.ssh_port
    private_key = local.has_private_key ? local.ssh_private_key : null
    password    = local.has_password ? var.ssh_password : null
    timeout     = "2m"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/install_k3s.sh"
    destination = local.install_script_remote
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x ${local.install_script_remote}",
      "${local.install_script_remote} ${var.k3s_version} '${var.k3s_install_options}'"
    ]
  }

  provisioner "local-exec" {
    command = "mkdir -p '${local.kubeconfig_dir}'"
  }

  provisioner "local-exec" {
    working_dir = path.module
    command     = <<EOC
bash ./scripts/fetch_kubeconfig.sh \
  '${var.ssh_user}' \
  '${var.ssh_host}' \
  '${var.ssh_port}' \
  '${local.kubeconfig_path}' \
  '${local.effective_key_path}'
EOC
    environment = {
      SSH_PASSWORD = local.has_private_key ? "" : var.ssh_password
    }
  }

  provisioner "local-exec" {
    command = <<EOC
sed -i.bak 's/127.0.0.1/${local.api_server_addr}/' '${local.kubeconfig_path}'
rm -f '${local.kubeconfig_path}.bak'
EOC
  }
}

resource "null_resource" "flux_bootstrap" {
  count = var.flux_bootstrap_enabled ? 1 : 0

  triggers = {
    repo   = "${var.flux_github_owner}/${var.flux_github_repository}"
    branch = var.flux_github_branch
    path   = var.flux_github_path
  }

  lifecycle {
    precondition {
      condition     = var.flux_github_owner != "" && var.flux_github_repository != ""
      error_message = "Define flux_github_owner y flux_github_repository para habilitar el bootstrap."
    }
  }

  depends_on = [null_resource.k3s_cluster]

  provisioner "local-exec" {
    working_dir = path.module
    command     = <<EOC
set -euo pipefail
export KUBECONFIG='${local.kubeconfig_path}'
PERSONAL_FLAG=""
if [ "${local.flux_personal_flag}" = "true" ]; then
  PERSONAL_FLAG="--personal"
fi
flux check --pre || true
flux bootstrap github \
  --owner '${var.flux_github_owner}' \
  --repository '${var.flux_github_repository}' \
  --branch '${var.flux_github_branch}' \
  --path '${var.flux_github_path}' \
  $${PERSONAL_FLAG}
EOC
  }
}
