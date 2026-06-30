# Caso Práctico 2 - Automatización de despliegues en entornos Cloud

Repositorio del Caso Práctico 2 de la asignatura **DevOps & Cloud**.

El objetivo del proyecto es desplegar de forma automatizada una infraestructura en Microsoft Azure utilizando Terraform y Ansible.

El despliegue incluye:

- Un Azure Container Registry privado.
- Una máquina virtual Linux con una aplicación web ejecutándose en Podman.
- Un clúster AKS gestionado por Azure.
- Una aplicación distinta desplegada en Kubernetes con almacenamiento persistente.

Todo el despliegue se realiza desde un nodo de control Linux mediante el script `deploy.sh`.

---

## Arquitectura desplegada

El proyecto despliega los siguientes elementos principales:

1. **Azure Container Registry privado**

   Se utiliza para almacenar las imágenes de contenedor del proyecto:

   - `web-nginx:casopractico2`
   - `k8s-contador:casopractico2`

2. **Máquina virtual Linux en Azure**

   Máquina virtual donde se ejecuta una aplicación web con Podman.

3. **Aplicación web en Podman**

   Aplicación basada en Nginx, accesible por HTTPS, con certificado x.509 autofirmado y autenticación básica mediante `htpasswd`.

4. **Clúster AKS**

   Clúster Kubernetes gestionado por Azure, con un único nodo worker.

5. **Aplicación contador en Kubernetes**

   Aplicación Python/Flask distinta de la aplicación web de Podman. Usa almacenamiento persistente mediante un PVC para guardar el contador de visitas.

---

## Estructura del repositorio

```text
.
├── README.md
├── LICENSE
├── .gitignore
├── deploy.sh
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── acr.tf
│   ├── network.tf
│   ├── vm.tf
│   └── aks.tf
├── ansible/
│   ├── group_vars/
│   │   └── all/
│   │       └── main.yml
│   ├── inventory.ini.example
│   ├── playbook_prepare_vm_podman.yml
│   ├── playbook_deploy_web_podman.yml
│   └── playbook_deploy_k8s.yml
├── images/
│   ├── web-nginx/
│   │   ├── Dockerfile
│   │   ├── default.conf
│   │   ├── index.html
│   │   ├── auth/
│   │   └── certs/
│   └── k8s-contador/
│       ├── Dockerfile
│       ├── app.py
│       └── requirements.txt
└── kubernetes/
    └── pruebas/
        └── pod-prueba-acr.yaml
```

---

## Herramientas utilizadas

- Terraform
- Ansible
- Podman
- Azure CLI
- kubectl
- Python 3
- Azure Container Registry
- Azure Virtual Machine
- Azure Kubernetes Service

---

## Requisitos previos

El despliegue debe ejecutarse desde un nodo de control Linux con las siguientes herramientas instaladas:

```bash
az --version
terraform version
ansible --version
podman --version
kubectl version --client
python3 --version
```

También es necesario haber iniciado sesión en Azure:

```bash
az login
```

Y tener seleccionada la suscripción correcta:

```bash
az account show
```

---

## Despliegue completo

Dar permisos de ejecución al script:

```bash
chmod +x deploy.sh
```

Ejecutar el despliegue completo:

```bash
./deploy.sh
```

El script realiza las siguientes acciones:

1. Inicializa Terraform.
2. Crea o actualiza la infraestructura en Azure.
3. Obtiene los outputs de Terraform.
4. Construye la imagen web Nginx.
5. Sube la imagen web al ACR.
6. Genera dinámicamente el inventario de Ansible para la VM.
7. Configura la VM e instala Podman.
8. Despliega la aplicación web Nginx como servicio systemd.
9. Obtiene las credenciales del clúster AKS.
10. Construye la imagen de la aplicación contador.
11. Sube la imagen contador al ACR.
12. Prepara un entorno virtual Python para los módulos Kubernetes de Ansible.
13. Despliega la aplicación contador en AKS con Ansible.
14. Muestra las URLs finales de acceso.

---

## Aplicación web en Podman

La aplicación web desplegada en la VM utiliza:

- Nginx.
- Certificado x.509 autofirmado.
- Autenticación básica con `htpasswd`.
- Imagen privada descargada desde ACR.
- Servicio systemd para que el contenedor se mantenga activo.

La URL se muestra al final de la ejecución de `deploy.sh`.

Credenciales de laboratorio:

```text
usuario: alumno
contraseña: unir2026
```

Comprobación manual:

```bash
curl -k -I https://<IP_PUBLICA_VM>
curl -k -u alumno:unir2026 https://<IP_PUBLICA_VM>
```

---

## Aplicación contador en AKS

La aplicación de Kubernetes es una aplicación Python/Flask que muestra un contador de visitas.

Características principales:

- Imagen distinta a la usada en Podman.
- Imagen almacenada en ACR con el tag `casopractico2`.
- Despliegue mediante Ansible y módulos nativos de Kubernetes.
- Service de tipo `LoadBalancer` para acceso desde Internet.
- PVC con `managed-csi` para almacenamiento persistente.
- Montaje del volumen persistente en `/data`.

Comandos útiles de comprobación:

```bash
kubectl get nodes
kubectl get pods -l app=contador -o wide
kubectl get pvc,pv
kubectl get service contador-service
kubectl logs -l app=contador --tail=50
```

Obtener la IP pública de la aplicación:

```bash
kubectl get service contador-service
```

Probar la aplicación:

```bash
APP_IP=$(kubectl get service contador-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl http://${APP_IP}
```

---

## Prueba de persistencia

Para comprobar que el contador no se pierde al recrear el pod:

```bash
APP_IP=$(kubectl get service contador-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

curl http://${APP_IP}
curl http://${APP_IP}

kubectl get pods -l app=contador
kubectl delete pod -l app=contador

kubectl get pods -l app=contador
curl http://${APP_IP}
```

Si el contador continúa aumentando después de borrar el pod, significa que el dato se mantiene en el volumen persistente y no dentro del contenedor.

---

## Limpieza de recursos

Para evitar consumo innecesario de crédito en Azure, se deben destruir los recursos cuando ya no sean necesarios:

```bash
export ARM_SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
terraform -chdir=terraform destroy -var="subscription_id=${ARM_SUBSCRIPTION_ID}"
```

Después de la destrucción, se recomienda comprobar en el portal de Azure que el grupo de recursos ha desaparecido.

---

## Archivos no versionados

Este repositorio no debe incluir archivos generados o sensibles como:

- `terraform.tfstate`
- `terraform.tfstate.backup`
- `.terraform/`
- `ansible/inventory.ini`
- entornos virtuales Python
- claves privadas SSH

Estos archivos están excluidos mediante `.gitignore`.

---

## Notas de seguridad

Las credenciales de la autenticación básica y el certificado autofirmado incluidos en la imagen web se utilizan únicamente con fines académicos y de laboratorio.

En un entorno real se recomienda gestionar secretos y certificados mediante mecanismos más seguros, como Azure Key Vault, Ansible Vault, secretos de Kubernetes o certificados emitidos por una autoridad certificadora válida.

---

## Licencia

Este proyecto se distribuye bajo licencia MIT. Consultar el archivo `LICENSE` para más información.