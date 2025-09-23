# Manifiestos base (hostinger)

Este directorio contiene los recursos mínimos que Flux debe sincronizar contra el clúster k3s.

- `namespaces.yaml`: namespaces iniciales (`apps`, `platform`, `gitops`).
- `kustomization.yaml`: entrada principal referenciada por Flux (`--path clusters/hostinger`).

Puedes extender este árbol con overlays adicionales (por ejemplo `apps/web`, `platform/ingress`) y Flux los aplicará automáticamente.
