#!/usr/bin/env bash

# Script maestro del caso práctico.
# Ejecuta el despliegue completo desde el nodo de control:
# 1. Crea o actualiza la infraestructura en Azure con Terraform.
# 2. Construye y sube las imágenes al Azure Container Registry.
# 3. Genera el inventario dinámico de Ansible para la VM.
# 4. Configura la VM e instala Podman.
# 5. Despliega la app Nginx en la VM como servicio systemd.
# 6. Configura el acceso a AKS.
# 7. Despliega la app contador en Kubernetes con almacenamiento persistente.


# Hace que el script falle si algo va mal
set -euo pipefail

# Se coloca en la raíz del proyecto
cd "$(dirname "$0")"

echo -e "\n Despliegue ACR + VM + Podman + Ansible"

# Obtiene la suscripción de Azure. Mira si ya existe la variable y si no, la obtiene automáticamente
echo -e "\n ==> Obteniendo suscripción de Azure"
export ARM_SUBSCRIPTION_ID="${ARM_SUBSCRIPTION_ID:-$(az account show --query id -o tsv)}"

# Ejecuta terraform. Con init inicializa Terraform. Con apply crea o actualiza la infra que se haya definido en los archivos *.tf
echo -e "\n ==> Aplicando infraestructura con terraform"
terraform -chdir=terraform init
terraform -chdir=terraform apply -var="subscription_id=${ARM_SUBSCRIPTION_ID}" -auto-approve


# Lee los outputs de Terraform. Estas variables evitan que tenga que estar tocando archivos por cada destroy y apply posterior que pueda hacer
echo -e "\n ==> Obteniendo outputs de terraform"
VM_IP=$(terraform -chdir=terraform output -raw vm_public_ip)
VM_USER=$(terraform -chdir=terraform output -raw vm_admin_username)
ACR_SERVER=$(terraform -chdir=terraform output -raw acr_login_server)
ACR_USER=$(terraform -chdir=terraform output -raw acr_admin_username)
ACR_PASS=$(terraform -chdir=terraform output -raw acr_admin_password)
RESOURCE_GROUP=$(terraform -chdir=terraform output -raw resource_group_name)
AKS_NAME=$(terraform -chdir=terraform output -raw aks_name)

# Muestro los datos obtenidos más importantes de los outputs
echo -e "\n ==> Datos obtenidos:"
echo "VM pública: ${VM_IP}"
echo "Usuario VM: ${VM_USER}"
echo "ACR: ${ACR_SERVER}"
echo "Resource Group: ${RESOURCE_GROUP}"
echo "AKS: ${AKS_NAME}"

# Con podman build construimos la imagen de nuestra web
echo -e "\n ==> Construyendo imagen web Nginx"
podman build --no-cache -t "${ACR_SERVER}/web-nginx:casopractico2" images/web-nginx
  
# Con podman login iniciamos sesión en el ACR desde el nodo de control
echo -e "\n ==> Iniciando sesión en ACR desde el nodo de control"
podman login "${ACR_SERVER}" -u "${ACR_USER}" -p "${ACR_PASS}"

# Y con podman push subimos la imagen ya construida al ACR
echo -e "\n ==> Subiendo imagen web Nginx al ACR"
podman push "${ACR_SERVER}/web-nginx:casopractico2"  
  
# Genero archivo de inventario de Ansible con la IP actual de este momento de la VM.
echo -e "\n ==> Generando inventario de Ansible"
cat > ansible/inventory.ini <<EOF
[vm_podman]
vm-cp2-cristina ansible_host=${VM_IP} ansible_user=${VM_USER}

[vm_podman:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=accept-new'
EOF

echo -e "\n ==> Inventario generado:"
cat ansible/inventory.ini

echo -e "\n ==> Eliminando posible clave SSH antigua de known_hosts para esta IP"
ssh-keygen -R "${VM_IP}" >/dev/null 2>&1 || true

echo -e "\n ==> Instalando colección de Ansible para Podman si no existe"
ansible-galaxy collection install containers.podman >/dev/null

echo -e "\n ==> Esperando a que la VM acepte conexiones SSH"
for intento in {1..30}; do
  if ansible vm_podman -i ansible/inventory.ini -m ping >/dev/null 2>&1; then
    echo "La VM responde correctamente por Ansible."
    break
  fi

  if [ "${intento}" -eq 30 ]; then
    echo "ERROR: La VM no responde por SSH después de varios intentos."
    exit 1
  fi

  echo "La VM todavía no está lista. Reintentando en 10 segundos... (${intento}/30)"
  sleep 10
done

echo -e "\n ==> Configurando la VM con Podman"
ansible-playbook -i ansible/inventory.ini ansible/playbook_prepare_vm_podman.yml

echo -e "\n ==> Desplegando aplicación web Nginx con Podman"
ansible-playbook -i ansible/inventory.ini ansible/playbook_deploy_web_podman.yml -e "acr_username=${ACR_USER}" -e "acr_password=${ACR_PASS}"

echo -e "\n ==> Configurando acceso kubectl al cluster AKS"
az aks get-credentials --resource-group "${RESOURCE_GROUP}" --name "${AKS_NAME}" --overwrite-existing

# El Service de tipo LoadBalancer necesita una IP pública para exponer la aplicación.
# En esta suscripción de Azure existe un límite de 3 IPs públicas por región.
# Como ya se han usado 3 IPs en swedencentral, Kubernetes no puede crear una cuarta IP
# y el Service se queda en estado EXTERNAL-IP <pending>.
# Para evitar ese problema, se reutiliza la IP pública que AKS ya tiene creada
# en su grupo de recursos gestionado. Ese grupo se llama normalmente:
# MC_<resource-group>_<aks-name>_<region>
# Terraform crea el AKS, pero Azure crea internamente este grupo gestionado.
# Por eso obtenemos el nombre mediante Azure CLI.

echo -e "\n ==> Obteniendo grupo de recursos gestionado de AKS"
AKS_NODE_RG=$(az aks show --resource-group "${RESOURCE_GROUP}" --name "${AKS_NAME}" --query nodeResourceGroup -o tsv)

# Dentro del grupo gestionado de AKS ya existe una IP pública asociada
# al Load Balancer del clúster. Se reutilizará para el Service contador.
echo -e "\n ==> Obteniendo IP pública existente del Load Balancer de AKS"
AKS_LB_PUBLIC_IP_NAME=$(az network public-ip list --resource-group "${AKS_NODE_RG}" --query "[0].name" -o tsv)
AKS_LB_PUBLIC_IP=$(az network public-ip show --resource-group "${AKS_NODE_RG}" --name "${AKS_LB_PUBLIC_IP_NAME}" --query ipAddress -o tsv)

echo "Resource Group gestionado de AKS: ${AKS_NODE_RG}"
echo "Nombre de la IP pública reutilizada: ${AKS_LB_PUBLIC_IP_NAME}"
echo "IP pública reutilizada: ${AKS_LB_PUBLIC_IP}"

echo -e "\n ==> Construyendo imagen de la aplicación contador para Kubernetes"
podman build --no-cache -t "${ACR_SERVER}/k8s-contador:casopractico2" images/k8s-contador

echo -e "\n ==> Subiendo imagen contador al ACR"
podman push "${ACR_SERVER}/k8s-contador:casopractico2"

echo -e "\n ==> Instalando colección de Ansible para Kubernetes si no existe"
ansible-galaxy collection install kubernetes.core >/dev/null

echo -e "\n ==> Preparando entorno Python para Ansible y Kubernetes"
python3 -m venv .venv-ansible
.venv-ansible/bin/python -m pip install --upgrade pip >/dev/null
.venv-ansible/bin/python -m pip install kubernetes >/dev/null

# Se despliega la aplicación contador en AKS usando Ansible.
# Además del ACR, se pasan dos variables relacionadas con la IP pública:
# - aks_node_resource_group:
#   grupo de recursos gestionado de AKS donde está el Load Balancer real.
# - aks_lb_public_ip_name:
#   nombre de la IP pública ya existente que se reutilizará en el Service.
# Estas variables permiten que el Service LoadBalancer no intente crear
# una nueva IP pública, evitando el error PublicIPCountLimitReached.
echo -e "\n ==> Desplegando aplicación contador en AKS con Ansible"
ansible-playbook ansible/playbook_deploy_k8s.yml -e "acr_login_server=${ACR_SERVER}" -e "aks_node_resource_group=${AKS_NODE_RG}" -e "aks_lb_public_ip_name=${AKS_LB_PUBLIC_IP_NAME}"

# Añado un bucle para esperar la IP del LoadBalancer y obtener la IP pública de la app contador
echo -e "\n ==> Esperando a que la aplicación contador tenga IP pública"
for intento in {1..30}; do
  K8S_APP_IP=$(kubectl get service contador-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)

  if [ -n "${K8S_APP_IP}" ]; then
    break
  fi

  echo "La IP pública del Service todavía no está disponible. Reintentando en 10 segundos... (${intento}/30)"
  sleep 10
done

if [ -z "${K8S_APP_IP:-}" ]; then
  echo "ERROR: El Service contador-service no obtuvo IP pública."
  kubectl get service contador-service
  exit 1
fi

echo -e "\n ==> Estado de la aplicación contador en AKS"
kubectl get pvc,pv
kubectl get pods -l app=contador -o wide
kubectl get service contador-service

# Ya tenemos configurada la VM y desplegada la web con Nginx gracias a Podman
echo -e "\n ==> Despliegue finalizado correctamente"

echo -e "\n URL de la aplicación web en la VM con Podman:"
echo "https://${VM_IP}"

echo -e "\n Credenciales del acceso web:"
echo "usuario: alumno"
echo "contraseña: unir2026"

echo -e "\n URL de la aplicación contador en AKS:"
echo "http://${K8S_APP_IP}"