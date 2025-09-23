# n8n en Hostinger k3s

Este directorio contiene la configuración base para ejecutar n8n en el clúster k3s. Utiliza Kustomize y despliega:

- Namespace dedicado (`n8n`).
- ConfigMap con variables no sensibles.
- `secretGenerator` que crea el Secret `n8n-secrets` a partir de un archivo local (`secret.env`).
- PVC `n8n-data` (10 GiB, storage class `local-path`).
- Deployment, Service e Ingress (ingress-class `nginx`).

## Preparación

1. **Instala ingress-nginx y cert-manager** (si aún no existen) para manejar el Ingress y TLS.
2. Copia la plantilla de secretos y coloca tus credenciales reales:
   ```bash
   cp clusters/hostinger/n8n/secret.env.example clusters/hostinger/n8n/secret.env
   nano clusters/hostinger/n8n/secret.env
   ```
   El archivo `secret.env` está ignorado por git. En producción usa herramientas como SOPS, SealedSecrets o External Secrets para gestionar secretos.
3. Ajusta `configmap.yaml` e `ingress.yaml` con el dominio final (`WEBHOOK_URL`, `N8N_HOST`, `n8n.example.com`).
4. Si usas Let’s Encrypt, crea el `Certificate` correspondiente (no incluido en este paquete).

## Aplicación

```bash
kubectl apply -k clusters/hostinger/n8n
```

Comprueba:

```bash
kubectl get pods -n n8n
kubectl get ing -n n8n
```

Cuando el Ingress esté activo, podrás acceder a `https://n8n.example.com`. Ajusta DNS para que apunte a la IP pública del controlador de Ingress.

## Migración

1. **Pausa** el n8n en Cloud Run (evita nuevos workflows).
2. Asegúrate de que la base de datos en Supabase está sincronizada y accesible.
3. **Importa workflows** al nuevo n8n usando la API (`N8N_API_KEY`) o subiendo archivos `.json`. Puedes crear un Job temporal que ejecute la importación.
4. Valida workflows críticos; cuando todo esté verificado, actualiza DNS para apuntar al nuevo Ingress.
5. Mantén Cloud Run apagado pero disponible unos días por contingencia, luego elimínalo.

## Próximos pasos

- Añadir NetworkPolicies para aislar el namespace `n8n`.
- Configurar HPA y PodDisruptionBudget.
- Integrar la carpeta con GitOps (Flux) si la vas a sincronizar automáticamente.
