variable "ssh_host" {
  description = "Dirección pública o privada del nodo k3s"
  type        = string
  default     = "72.60.140.107"
}

variable "ssh_user" {
  description = "Usuario SSH con permisos de sudo"
  type        = string
  default     = "root"
}

variable "ssh_port" {
  description = "Puerto SSH"
  type        = number
  default     = 22
}

variable "ssh_private_key_path" {
  description = "Ruta al archivo de clave privada SSH"
  type        = string
  default     = ""
}

variable "ssh_private_key" {
  description = "Contenido de la clave privada SSH (alternativa a la ruta)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ssh_password" {
  description = "Contraseña SSH (se usará si no se proporciona clave privada)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "k3s_version" {
  description = "Versión de k3s a instalar"
  type        = string
  default     = "v1.29.6+k3s1"
}

variable "k3s_install_options" {
  description = "Flags adicionales para INSTALL_K3S_EXEC"
  type        = string
  default     = "--disable traefik --disable servicelb --disable metrics-server"
}

variable "kubeconfig_output_path" {
  description = "Ruta local donde guardar el kubeconfig ajustado"
  type        = string
  default     = "../artifacts/kubeconfig"
}

variable "apiserver_public_address" {
  description = "Dirección que se escribirá en el kubeconfig para acceder al API Server"
  type        = string
  default     = ""
}

variable "flux_bootstrap_enabled" {
  description = "Si es true, Terraform ejecutará flux bootstrap tras crear el clúster"
  type        = bool
  default     = false
}

variable "flux_github_owner" {
  description = "Organización o usuario de GitHub donde vive el repo GitOps"
  type        = string
  default     = ""
}

variable "flux_github_repository" {
  description = "Nombre del repositorio GitOps"
  type        = string
  default     = ""
}

variable "flux_github_branch" {
  description = "Rama de GitOps"
  type        = string
  default     = "main"
}

variable "flux_github_path" {
  description = "Ruta dentro del repo donde se alojan los manifiestos"
  type        = string
  default     = "clusters/hostinger"
}

variable "flux_github_personal" {
  description = "Indica si el repositorio es personal (no organizacional)"
  type        = bool
  default     = true
}
