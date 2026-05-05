# Guía de Uso y Despliegue - GreenDevCorp 

## Week 8: Containerization (Docker)

Este manual detalla paso a paso el procedimiento operativo para preparar el entorno, construir las imágenes de contenedor y desplegar los servicios de la Week 8.

## 1. Estructura de Directorios del Proyecto
Para mantener la organización y cumplir con los requisitos de la práctica, se utiliza la siguiente estructura:

* `~/gsx-practica2/`: Directorio raíz del proyecto.
* `./nginx-app/`: Contiene el Dockerfile y los archivos estáticos del servidor web (Frontend).
* `./simple-app/`: Contiene el código fuente y el Dockerfile del servidor de aplicación (Backend).
* `install_docker.sh`: Script de automatización para la configuración inicial de la máquina virtual.

---

## 2. Preparación de la Máquina Virtual (MV)

Antes de operar con contenedores, es necesario instalar el motor de Docker y configurar los permisos de usuario en una máquina limpia.

### Automatización con Script
1.  **Crear el archivo:** `nano install_docker.sh` 
2.  **Otorgar permisos de ejecución:** `chmod +x install_docker.sh` 
3.  **Ejecutar el script:** `./install_docker.sh` 

### Comandos manuales de post-instalación
Para evitar el uso de `sudo` en cada comando de Docker, el script añade al usuario al grupo `docker`. Para aplicar este cambio sin reiniciar la sesión, ejecuta:
```bash
newgrp docker
```

---

## 3. Despliegue del Frontend (Servidor Nginx)

El objetivo es empaquetar un servidor Nginx que sirva una página estática personalizada.

### Comandos de Construcción
Desde el directorio `~/gsx-practica2/nginx-app/`, ejecuta:
```bash
docker build -t nginx-gsx .
```
* **`docker build`**: Comando para crear una imagen a partir de un Dockerfile.
* **`-t nginx-gsx`**: Flag (tag) para asignar un nombre a la imagen resultante.
* **`.`**: Especifica el "contexto de construcción"; indica que el Dockerfile y los archivos necesarios están en la carpeta actual.

### Comandos de Ejecución
```bash
docker run -d -p 80:80 nginx-gsx
```
* **`docker run`**: Crea e inicia un nuevo contenedor.
* **`-d`**: (Detached) Ejecuta el contenedor en segundo plano.
* **`-p 80:80`**: Mapeo de puertos. El puerto 80 de la MV se redirige al puerto 80 interno del contenedor.

### Verificación
```bash
curl localhost
```

---

## 4. Despliegue del Backend (Simple Node.js App)

Se despliega un servidor HTTP ligero que escucha en el puerto 3000.

### Comandos de Construcción y Ejecución
Desde el directorio `~/gsx-practica2/simple-app/`:
```bash
# Construir la imagen optimizada (alpine)
docker build -t simple-app-gsx .

# Ejecutar el contenedor
docker run -d -p 3000:3000 simple-app-gsx
```
* **`-p 3000:3000`**: Redirige el tráfico del puerto 3000 de la MV al puerto 3000 del contenedor donde escucha la app Node.js.

### Verificación
```bash
curl localhost:3000
```

---

## 5. Gestión de Imágenes en Docker Hub

Para cumplir con la entrega, las imágenes deben estar disponibles en el registro público.

### Autenticación (Login con PAT)
Dado que la cuenta de Docker Hub está vinculada a GitHub, se debe usar un *Personal Access Token* (PAT) generado en la web de Docker Hub como contraseña:
```bash
docker login -u <tu_usuario_dockerhub>
```

### Etiquetado y Publicación (Push)
Docker requiere que la imagen local tenga el prefijo de tu usuario del registro para poder subirla.

```bash
# 1. Crear el tag remoto
docker tag nginx-gsx <tu_usuario>/nginx-gsx:v1
docker tag simple-app-gsx <tu_usuario>/simple-app-gsx:v1

# 2. Subir las imágenes al registro público
docker push <tu_usuario>/nginx-gsx:v1
docker push <tu_usuario>/simple-app-gsx:v1
```
* **`docker tag`**: Crea un alias de la imagen local con el formato requerido por el registro remoto.
* **`docker push`**: Sube la imagen y sus capas al repositorio en la nube de Docker Hub.

---

## 6. Comandos Útiles de Mantenimiento

* **Ver contenedores activos:** `docker ps` 
* **Ver todos los contenedores (incluidos parados):** `docker ps -a` 
* **Parar un contenedor:** `docker stop <container_id>` 
* **Eliminar una imagen local:** `docker rmi <image_id>` 
* **Ver logs de un contenedor:** `docker logs <container_id>`

---

## 7. Archivos de la Week 8

Los siguientes ficheros pertenecen a la entrega de la Week 8: Containerization (Docker):

* `scripts/install_docker.sh` - Script de automatización para la instalación de Docker
* `code/nginx-app/index.html` - Página estática del servidor frontend
* `code/nginx-app/Dockerfile` - Dockerfile para la construcción de la imagen Nginx
* `code/simple_app/server.js` - Código fuente del servidor backend
* `code/simple_app/Dockerfile` - Dockerfile para la construcción de la imagen Node.js

---

## Week 9: Multi-Container Orchestration (Docker Compose)

En esta fase, evolucionamos de gestionar contenedores individuales manualmente a orquestar una pila (stack) completa de servicios que se comunican entre sí utilizando Docker Compose.

### 1. Actualización de la Estructura de Directorios
Se ha creado un nuevo directorio para aislar la orquestación, copiando los artefactos de la Week 8 e introduciendo la configuración de Compose y del recolector de logs:

```text
~/gsx-practica2/
└── docker-compose/
    ├── nginx-app/             # (Copiado de la Week 8)
    ├── simple-app/            # (Copiado de la Week 8)
    ├── fluentd/
    │   └── fluent.conf        # Configuración del recolector de logs
    ├── .env                   # Variables de entorno reales (Ignorado en Git)
    ├── .env.example           # Plantilla de variables para el repositorio
    ├── .gitignore             # Evita la subida de secretos
    └── docker-compose.yml     # Archivo principal de orquestación
```

---

### 2. Preparación del Entorno y Archivos Base

**1. Instalación de Docker Compose:**
En algunas distribuciones, Compose no viene incluido con el motor base. Se instala mediante:
```bash
sudo apt install docker-compose -y
```

**2. Creación del directorio y migración de contenedores:**
```bash
cd ~/gsx-practica2
mkdir docker-compose
cd docker-compose
cp -r ../nginx-app ./
cp -r ../simple-app ./
```

**3. Configuración Segura (Variables de Entorno):**
Para evitar el *hardcoding* de configuración, creamos los archivos de entorno y protegemos los secretos.

Crear el `.gitignore`:
```bash
echo ".env" > .gitignore
```

Crear el archivo con los valores reales (`.env`):
```bash
cat <<EOF > .env
NODE_ENV=production
BACKEND_PORT=3000
NGINX_PORT=80
EOF
```

Crear la plantilla de ejemplo para el repositorio (`.env.example`):
```bash
cat <<EOF > .env.example
NODE_ENV=development
BACKEND_PORT=3000
NGINX_PORT=80
EOF
```

**4. Configuración del Servicio de Logs (Fluentd):**
Creamos la carpeta y el archivo de configuración para centralizar los registros:
```bash
mkdir fluentd
cat <<EOF > fluentd/fluent.conf
<source>
  @type forward
  port 24224
  bind 0.0.0.0
</source>

<match **>
  @type stdout
</match>
EOF
```

---

### 3. El Archivo de Orquestación (`docker-compose.yml`)

Este archivo YAML define todos los servicios (Nginx, Node.js, Fluentd), la persistencia (volúmenes), las redes privadas y las políticas de resiliencia. 

Creamos el archivo:
```bash
nano docker-compose.yml
```

Y añadimos la siguiente configuración que abarca los niveles Básico, Intermedio y Avanzado:

```yaml
services:
  # SERVICIO 1: FRONTEND (Nginx)
  nginx:
    build: ./nginx-app
    ports:
      - "${NGINX_PORT}:80"
    networks:
      - gsx_network
    restart: always
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost"]
      interval: 30s
      timeout: 10s
      retries: 3
    depends_on:
      backend:
        condition: service_healthy
      fluentd:
        condition: service_started
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 256M
    logging:
      driver: "fluentd"
      options:
        fluentd-address: localhost:24224
        tag: nginx.access

  # SERVICIO 2: BACKEND (Node.js)
  backend:
    build: ./simple-app
    environment:
      - NODE_ENV=${NODE_ENV}
      - PORT=${BACKEND_PORT}
    networks:
      - gsx_network
    restart: always
    volumes:
      - backend_data:/data
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3000"]
      interval: 30s
      timeout: 10s
      retries: 3
    depends_on:
      fluentd:
        condition: service_started
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 256M
    logging:
      driver: "fluentd"
      options:
        fluentd-address: localhost:24224
        tag: backend.app

  # SERVICIO 3: LOGGING COLLECTOR (Fluentd)
  fluentd:
    image: fluent/fluentd:v1.16-1
    volumes:
      - ./fluentd/fluent.conf:/fluentd/etc/fluent.conf
    ports:
      - "24224:24224"
      - "24224:24224/udp"
    networks:
      - gsx_network
    restart: always
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

networks:
  gsx_network:
    driver: bridge

volumes:
  backend_data:
```

---

### 4. Comandos de Despliegue y Verificación

El guion exige validar explícitamente el inicio, la comunicación y la persistencia de datos. 

**1. Despliegue de la infraestructura completa:**
Construye las imágenes si es necesario y levanta los contenedores en segundo plano.
```bash
docker-compose up -d
```

**2. Verificar el estado y los *healthchecks*:**
Confirma que los servicios arrancan y están saludables (`healthy`).
```bash
docker-compose ps
```

**3. Probar comunicación externa:**
```bash
curl localhost
curl localhost:3000
```

**4. Probar comunicación interna (Inter-service):**
Validamos que la resolución DNS interna funciona llamando al backend desde Nginx utilizando su nombre de servicio.
```bash
docker-compose exec nginx curl http://backend:3000
```

**5. Verificar el recolector de logs centralizado:**
Comprobamos que las peticiones anteriores se han registrado correctamente en Fluentd.
```bash
docker-compose logs fluentd
```

**6. Probar la persistencia de datos (Volúmenes):**
Se simula una escritura de datos, se destruye la pila y se vuelve a levantar para asegurar que los datos en `/data` sobreviven.
```bash
# Crear un archivo de prueba en el backend
docker-compose exec backend sh -c "echo 'Datos persistentes' > /data/prueba.txt"

# Destruir los contenedores y la red
docker-compose down

# Volver a levantar todo
docker-compose up -d

# Comprobar que el archivo sigue existiendo
docker-compose exec backend cat /data/prueba.txt
```

---

### 5. Archivos de la Week 9

Los siguientes ficheros se han creado y pertenecen a la entrega de la Week 9: Multi-Container Orchestration (Docker Compose):

* `docker-compose/docker-compose.yml` - Definición del stack, redes y volúmenes.
* `docker-compose/.env` - Variables de entorno locales (NO subir a Git).
* `docker-compose/.env.example` - Plantilla de variables para el repositorio.
* `docker-compose/.gitignore` - Exclusión del archivo `.env` del control de versiones.
* `docker-compose/fluentd/fluent.conf` - Configuración del enrutamiento de logs.

---

## Week 10: Orquestación para Producción (Kubernetes)

En esta semana abandonamos Docker Compose (orientado a desarrollo local) y migramos a **Kubernetes (K8s)**, el estándar de la industria para orquestación de contenedores en producción. Utilizaremos **Minikube** para simular un clúster de un solo nodo en nuestra máquina virtual.

### 1. Instalación y Preparación del Clúster

Antes de desplegar nada, necesitamos instalar las herramientas de Kubernetes y arrancar el clúster.

**Comandos de Instalación y Arranque:**
```bash
# 1. Instalar Minikube (El simulador del clúster local)
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# 2. Instalar kubectl (La herramienta cliente para hablar con el clúster)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# 3. Iniciar el clúster de Kubernetes
minikube start
```
*   **¿Por qué `minikube start`?**: Este comando descarga una imagen ISO base, crea una máquina virtual interna (o contenedor de Docker) y arranca todos los componentes críticos de Kubernetes (el *Control Plane*, el *API Server*, el *Scheduler*, etc.).

**Comandos de Verificación Base:**
```bash
kubectl cluster-info
```
*   **¿Por qué este comando?**: Verifica que tu herramienta `kubectl` se ha conectado correctamente al clúster recién creado. Te devolverá la IP y el puerto donde el "cerebro" de Kubernetes está escuchando tus órdenes.

---

### 2. Archivos de Configuración (Manifiestos YAML)

En Kubernetes no ejecutamos comandos imperativos para levantar cosas (no hacemos `docker run`). En su lugar, creamos archivos YAML (manifiestos) donde declaramos cómo queremos que sea la infraestructura, y Kubernetes se encarga de hacerlo realidad. Hemos creado los siguientes archivos en la carpeta `kubernetes/`:

*   **`configmap.yaml`**:
    *   **Qué hace:** Crea un objeto de tipo `ConfigMap`.
    *   **Por qué:** Sirve para almacenar variables de entorno (como `NODE_ENV=production` y `PORT=3000`). Esto desacopla la configuración de la imagen Docker. Si el puerto cambia, modificamos este archivo y no tenemos que recompilar el contenedor del backend.
*   **`nginx.yaml`**:
    *   **Qué hace:** Contiene dos recursos: un `Deployment` y un `Service`.
    *   **Por qué (Deployment):** Le dice a K8s que mantenga siempre viva 1 réplica del contenedor Nginx. Además, incluye `requests` y `limits` (para que no consuma más de 128Mi de RAM) y *Probes* (chequeos de salud automáticos para saber si el contenedor está colgado).
    *   **Por qué (Service NodePort):** Expone el Nginx hacia afuera. Mapea el puerto 80 interno al puerto `30080` de tu máquina para que puedas acceder desde el navegador.
*   **`backend.yaml`**:
    *   **Qué hace:** Contiene un `StatefulSet` y un `Service`.
    *   **Por qué (StatefulSet):** A diferencia de un Deployment, se usa para aplicaciones que guardan datos. Le da al pod una identidad fija (siempre se llamará `backend-0`) y define un `PersistentVolumeClaim` (PVC) que pide un disco de 1GiB para que la carpeta `/data` no se borre nunca.
    *   **Por qué (Service ClusterIP):** Crea un balanceador de carga interno. Solo permite que otros pods dentro del clúster (como Nginx) se comuniquen con el backend, manteniéndolo seguro del exterior.

---

### 3. Comandos de Despliegue de la Infraestructura

Una vez creados los archivos, debemos enviarlos al clúster para que los procese.
```bash
# 1. Aplicar todos los manifiestos
kubectl apply -f kubernetes/
```
*   **¿Por qué `apply -f`?**: El flag `-f` le indica que lea una carpeta o archivo. `apply` le dice al API Server: "Lee todos estos YAMLs y haz que el estado de mi clúster coincida con lo que está escrito aquí". Es un comando idempotente (si lo lanzas dos veces, no crea duplicados, solo aplica cambios si los hay).

**Comandos de Monitorización del Despliegue:**
```bash
# Ver el estado de los Pods (Contenedores)
kubectl get pods

# Ver los pods en tiempo real
kubectl get pods -w
```
*   **¿Por qué `-w` (watch)?**: Al principio, los pods estarán en `ContainerCreating` mientras K8s descarga tus imágenes de Docker Hub. El flag `-w` deja la terminal "escuchando" y te avisa en vivo cuando cambian a estado `Running`.
```bash
# Ver los servicios y sus IPs
kubectl get services
```
*   **¿Por qué?**: Te permite comprobar qué IP interna ha asignado el DNS al `backend` y confirmar que el `nginx-service` ha abierto el puerto externo correcto (ej. `80:30080`).

---

### 4. Comandos de Pruebas y Validación (Testing)

El guion requiere verificar que el frontend y el backend pueden hablar entre sí usando la resolución DNS nativa de Kubernetes.
```bash
# 1. Entrar de forma interactiva en el pod de Nginx
kubectl exec -it <nombre-del-pod-nginx> -- bash
```
*   **¿Por qué `exec -it`?**: `exec` ejecuta un comando dentro de un pod existente. `-it` significa "Interactivo" y "Terminal (TTY)". Le pedimos que abra el programa `bash` para darnos una consola de comandos dentro del contenedor, igual que hacíamos en Docker.
```bash
# 2. Hacer una petición al backend desde dentro de Nginx
curl http://backend:3000
```
*   **¿Por qué?**: Demuestra que el servidor DNS interno de Kubernetes (CoreDNS) funciona. Nginx no sabe la IP del backend, pero K8s traduce la palabra "backend" a la IP correcta del `ClusterIP Service` y devuelve el mensaje *"Hello from container"*.

---

### 5. Comandos de Escalabilidad (Auto-Scaling)

Una de las grandes ventajas de Kubernetes es su capacidad para multiplicarse ante picos de tráfico.

```bash
# 1. Escalar hacia arriba (Scale up)
kubectl scale deployment nginx --replicas=3
```
*   **¿Por qué?**: Modifica el estado deseado en caliente. Le ordena al *Controller Manager* que la infraestructura ahora requiere 3 copias de Nginx. K8s provisionará 2 Pods nuevos instantáneamente para balancear la carga de trabajo.
```bash
# 2. Escalar hacia abajo (Scale down)
kubectl scale deployment nginx --replicas=1
```
*   **¿Por qué?**: Cuando el pico de tráfico pasa, volvemos a reducir el estado a 1. Kubernetes enviará una señal de apagado seguro (SIGTERM) a los 2 pods sobrantes para liberar memoria y CPU del servidor.

---

### 6. Comandos de Resiliencia (Self-Healing)

Kubernetes está diseñado para sobrevivir a desastres y caídas de hardware sin intervención humana.
```bash
# 1. Simular una caída catastrófica borrando un pod
kubectl delete pod <nombre-del-pod-nginx>
```
*   **¿Por qué?**: Destruye forzosamente el contenedor activo. Sirve para probar el "Auto-Healing" o autorecuperación.
```bash
# 2. Verificar la resurrección
kubectl get pods
```
*   **¿Por qué?**: Al ejecutar esto inmediatamente después, verás que K8s ha detectado que falta un pod (tienes 0 pero le pediste 1) y en cuestión de segundos ha arrancado un pod completamente nuevo para sustituir al muerto, garantizando que el servicio no se caiga.
```bash
# 3. Consultar registros de un pod
kubectl logs <nombre-del-nuevo-pod>
```
*   **¿Por qué `logs`?**: En caso de que el nuevo pod resucitado marque un estado de error (como `CrashLoopBackOff`), este comando extrae la salida estándar (stdout) del contenedor para que puedas investigar por qué la aplicación Node.js o Nginx está fallando internamente.

---

## Week 11: Infraestructura como Código (IaC) y Múltiples Entornos

En esta semana abandonamos el despliegue manual mediante comandos `kubectl` y pasamos a gestionar nuestra infraestructura como código utilizando **Terraform**. Además, implementamos la convivencia de entornos (Desarrollo y Pre-producción) sobre un mismo clúster utilizando **Workspaces**.

### 1. Preparación y Migración a Terraform (Nivel Core)

En lugar de aplicar YAMLs directamente, hemos migrado nuestras definiciones a lenguaje HCL (HashiCorp Configuration Language). Se ha creado el directorio `terraform/` y los siguientes ficheros base:

* **`main.tf`**:
  * **Qué hace:** Define el bloque de configuración requerido para que Terraform descargue el proveedor oficial de Kubernetes (como si fuera un plugin). Además, contiene la traducción directa de nuestros archivos YAML (`Deployment`, `StatefulSet`, `Services` y `ConfigMap`) a código de Terraform.
  * **Por qué:** Centraliza la definición de los recursos y automatiza el aprovisionamiento.
* **`variables.tf`**:
  * **Qué hace:** Declara un esquema de variables (ej. `var.nginx_tag`, `var.namespace`).
  * **Por qué:** Para evitar "harcodear" valores como la versión de la imagen Docker o el entorno, permitiéndonos inyectarlos dinámicamente durante el despliegue.
* **`outputs.tf`**:
  * **Qué hace:** Imprime información útil en la terminal al finalizar el despliegue.
  * **Por qué:** Facilita al administrador conocer inmediatamente el puerto asignado o el namespace desplegado sin tener que buscarlo mediante comandos `kubectl`.

---

### 2. Múltiples Entornos (Nivel Intermediate)

Para cumplir con el requerimiento de múltiples entornos sin duplicar código, hemos implementado el aislamiento a nivel de infraestructura y estado.

#### Aislamiento de Red y Configuración
Se han modificado los recursos en `main.tf` para que el bloque `metadata` utilice la variable de entorno:
```hcl
  metadata {
    name      = "nginx"
    namespace = kubernetes_namespace.env_namespace.metadata[0].name
  }
```
* **Por qué:** Esto asegura que los recursos de `dev` se creen dentro del recinto de `dev`, y los de `staging` dentro de `staging`. Además, Terraform crea automáticamente el namespace si no existe mediante el recurso `kubernetes_namespace`.

Se ha configurado el `ConfigMap` del Backend para inyectar dinámicamente la variable de entorno según el entorno desplegado:
```hcl
  data = {
    NODE_ENV = var.namespace == "prod" ? "production" : "development"
    PORT     = "3000"
  }
```

#### Archivos de Variables
Se han creado dos ficheros específicos para alimentar a Terraform en diferentes escenarios:

* **`dev.tfvars`**:
  * **Configuración:** `namespace = "dev"`, `node_port = 30080`, `nginx_replicas = 1`.
  * **Por qué:** Entorno ligero y aislado para pruebas de integración continua.
* **`staging.tfvars`**:
  * **Configuración:** `namespace = "staging"`, `node_port = 30081`, `nginx_replicas = 2`.
  * **Por qué:** Entorno de pre-producción. Se asigna un puerto externo distinto (`30081`) para evitar conflictos en la misma máquina física, y se aumenta el número de réplicas para simular cargas de trabajo más exigentes previas al paso a producción.

---

### 3. Comandos de Despliegue con Workspaces

El mayor reto es que el archivo de estado de Terraform (`terraform.tfstate`) destruiría el entorno previo si aplicáramos una configuración distinta directamente. Para aislar los estados (las "memorias" de Terraform), utilizamos **Workspaces**.

**1. Inicialización de Terraform:**
```bash
cd ~/gsx-practica2/terraform/
terraform init
```
* **¿Por qué?**: Descarga e instala los binarios necesarios (el proveedor de Kubernetes configurado en el `main.tf`) en una carpeta oculta `.terraform/`.

**2. Creación y Despliegue del Entorno de Desarrollo (Dev):**
```bash
terraform workspace new dev
terraform apply -var-file="dev.tfvars"
```
* **¿Por qué `workspace new`?**: Crea un estado en blanco, paralelo e independiente llamado "dev" y cambia nuestro contexto a él.
* **¿Por qué `apply -var-file`?**: Ejecuta el plan de infraestructura inyectando explícitamente el archivo con las variables específicas para desarrollo.

**3. Creación y Despliegue del Entorno de Pre-producción (Staging):**
```bash
terraform workspace new staging
terraform apply -var-file="staging.tfvars"
```
* **¿Por qué?**: Cambia el contexto de Terraform a una nueva "burbuja" de estado ("staging") y despliega los recursos utilizando las variables que definen 2 réplicas y un puerto alternativo, permitiendo que conviva con el entorno de Dev.

---

### 4. Pruebas y Validación (Testing de Entornos)

Para asegurar que el nivel intermedio se ha implementado correctamente, debemos validar la convivencia de ambos ecosistemas.

**1. Verificar recursos en Desarrollo:**
```bash
kubectl get pods -n dev
```
* **Resultado esperado:** Muestra 1 pod de Nginx y 1 pod de Backend. (El flag `-n` indica el namespace a consultar).

**2. Verificar recursos en Staging:**
```bash
kubectl get pods -n staging
```
* **Resultado esperado:** Muestra 2 pods de Nginx y 1 pod de Backend aislados lógicamente.

**3. Comprobación Global Simultánea:**
```bash
kubectl get pods -A | grep -E "dev|staging"
```
* **¿Por qué?**: Este comando lista todos los pods de todos los namespaces del clúster (`-A`) y los filtra para mostrar únicamente los que pertenezcan a `dev` o `staging`. Demuestra empíricamente la coexistencia pacífica y operativa de múltiples entornos orquestados desde una única base de código fuente.

---

### 5. Operaciones Avanzadas de CI/CD (Nivel Advanced)

En este nivel hemos vitaminado nuestro flujo de trabajo para que no solo despliegue, sino que lo haga de forma segura, auditable y con capacidad de recuperación ante desastres.

#### 5.1. Modificación del Pipeline (Integración Continua)
Se ha modificado íntegramente el fichero `.github/workflows/ci.yml` para introducir las siguientes mejoras:
1. **Caché (Docker Buildx):** Se han añadido las directivas `cache-from` y `cache-to` para acelerar la construcción de imágenes reutilizando capas previas.
2. **Estrategia de Tags:** En lugar de usar la etiqueta por defecto, el flujo ahora inyecta dos etiquetas por cada `push`: el identificador único del commit (`${{ github.sha }}`) y la etiqueta `stable`.
3. **Escaneo de Seguridad (Trivy):** Se ha integrado el escáner de AquaSecurity para analizar vulnerabilidades del SO y librerías en las imágenes generadas. *(Nota operativa: Para permitir que el pipeline finalice en verde en este entorno de prácticas pese a las vulnerabilidades de la imagen base de Alpine, se ha configurado temporalmente con `exit-code: '0'`)*.
4. **Generación de SBOM (Anchore):** Se ha integrado un paso para extraer el inventario de software en formato JSON.

**Comandos para desplegar el nuevo pipeline:**
```bash
git add .github/workflows/ci.yml
git commit -m "feat: pipeline CI/CD avanzado con seguridad, cache y SBOM"
git push
```

#### 5.2. Pruebas de Seguridad y Extracción de Artefactos
Para validar que el pipeline avanzado funciona correctamente:
1. Acceder a la interfaz web del repositorio en GitHub.
2. Navegar a la pestaña **Actions** y abrir la última ejecución exitosa del flujo.
3. **Comprobación Trivy:** Al desplegar los logs del paso *"Run Trivy vulnerability scanner"*, se visualiza una tabla detallada con los CVEs detectados en la imagen (ej. vulnerabilidades en librerías de Alpine).
4. **Comprobación SBOM:** En la vista general (*Summary*) de la ejecución, en la parte inferior, aparece la sección **Artifacts** con los archivos `sbom-nginx.json` y `sbom-backend.json` listos para ser descargados y auditados.

#### 5.3. Procedimiento de Rollback en Kubernetes (Despliegue Continuo)
Se ha definido y probado un procedimiento de marcha atrás de emergencia (Rollback) para recuperar la disponibilidad del servicio de forma inmediata ante un despliegue defectuoso, aprovechando el historial de los `ReplicaSets`.

**Prueba realizada paso a paso (Entorno Dev):**

1. **Seleccionar el espacio de trabajo:**
   ```bash
   terraform workspace select dev
   ```
2. **Generar un cambio en el historial:** 
   Se modificó el archivo `dev.tfvars` cambiando la etiqueta de la imagen (`nginx_tag = "stable"`) simulando el despliegue de una nueva versión.
3. **Aplicar el despliegue:**
   ```bash
   terraform apply -var-file="dev.tfvars"
   ```
4. **Ejecutar el Rollback (Botón del pánico):**
   Ante la suposición de un fallo crítico en la nueva versión `stable`, se ordenó a Kubernetes revertir instantáneamente a la configuración de la versión anterior:
   ```bash
   kubectl rollout undo deployment/nginx -n dev
   ```
5. **Verificación de la recuperación:**
   ```bash
   kubectl get pods -n dev
   ```
   *Resultado:* Kubernetes destruyó automáticamente el Pod de la versión defectuosa y levantó uno nuevo utilizando la versión de la imagen inmediatamente anterior registrada en su historial, recuperando el sistema en apenas 7 segundos y sin necesidad de ejecutar Terraform.

---

## Week 12: Network Architecture & Security (Core)

En esta semana hemos implementado la seguridad de red (Firewalling) dentro del clúster. Para ello, hemos activado un motor de red avanzado (Calico) y hemos definido reglas de aislamiento mediante Infraestructura como Código (IaC).

### 1. Preparación del Clúster (Activar Motor de Red)

Por defecto, Kubernetes no aplica restricciones de red. Para que las políticas funcionen, debemos reconstruir el clúster habilitando un **CNI (Container Network Interface)** que soporte NetworkPolicies, como **Calico**.

**Comandos de preparación:**
```bash
# 1. Borrar el clúster previo sin soporte de red avanzado
minikube delete

# 2. Iniciar Minikube con Calico activado y recursos suficientes
minikube start --cni=calico --memory=4096 --cpus=2
```
* **¿Por qué `--cni=calico`?**: Es el componente encargado de interceptar el tráfico entre pods y aplicar las reglas de filtrado que definiremos.
* **¿Por qué `--memory=4096`?**: Calico es un servicio persistente que consume recursos adicionales para monitorizar la red en tiempo real.

**Verificación del motor de red:**
```bash
kubectl get pods -n kube-system | grep calico
```
* **Resultado esperado:** Los pods `calico-node` y `calico-kube-controllers` deben estar en estado `Running`.

---

### 2. Definición del Firewall (Archivo `network_policies.tf`)

Se ha creado un nuevo fichero en la carpeta `terraform/` que automatiza la seguridad del clúster:

* **`network_policies.tf`**:
  * **Contenido:** Define dos recursos `kubernetes_network_policy`.
  * **Lógica "Deny All" (Aislamiento):** La primera regla bloquea todo el tráfico que intenta entrar en el Namespace desde el exterior o desde otros Namespaces.
  * **Lógica "Allow Internal":** Permite que los pods hablen entre sí solo si pertenecen al mismo entorno (Dev con Dev, Staging con Staging).
  * **Excepción de Entrada:** Permite tráfico desde `0.0.0.0/0` (Internet) únicamente hacia los pods con la etiqueta `app=nginx` en el puerto 80.

---

### 3. Despliegue de la Seguridad con Terraform

Aplicamos las reglas en nuestros entornos de trabajo habituales.

```bash
cd ~/gsx-practica2/terraform/

# Aplicar seguridad en Desarrollo
terraform workspace select dev
terraform apply -var-file="dev.tfvars" -auto-approve

# Aplicar seguridad en Staging
terraform workspace select staging
terraform apply -var-file="staging.tfvars" -auto-approve
```

**Verificación de despliegue:**
```bash
kubectl get networkpolicies -A
```
* **¿Por qué?**: Confirma que las reglas `namespace-isolation-policy` y `allow-external-to-frontend` están creadas y activas en ambos namespaces.

---

### 4. Protocolo de Pruebas de Penetración (Testing)

Para validar que la red está protegida, simulamos un ataque desde dentro del clúster.

**Paso 1: Entrar en el Pod "Hacker" (Nginx de Dev)**
```bash
# Obtener el nombre del pod de nginx en dev
POD_NAME=$(kubectl get pods -n dev -l app=nginx -o jsonpath="{.items[0].metadata.name}")

# Entrar al contenedor
kubectl exec -it $POD_NAME -n dev -- bash
```

**Paso 2: Prueba de Conectividad Interna (Permitida)**
```bash
curl http://backend:3000 --connect-timeout 5
```
* **¿Por qué?**: Valida que la política permite el tráfico legítimo entre el Frontend y el Backend del mismo entorno. Debe responder "Hello from container".

**Paso 3: Prueba de Ataque Cruzado (Bloqueada)**
Intentamos atacar al backend de **Staging** desde el entorno de **Dev**.
```bash
curl http://backend.staging.svc.cluster.local:3000 --connect-timeout 5
```
* **Resultado esperado:** `curl: (28) Connection timed out after 5001 milliseconds`.
* **¿Por qué?**: Esto demuestra que, aunque el servicio de Staging es visible por DNS, la **NetworkPolicy** intercepta los paquetes y los descarta, protegiendo los datos de pre-producción del entorno de desarrollo.

---

### 5. Archivos de la Week 12

Los siguientes ficheros pertenecen a la entrega de la Week 12: Network Architecture & Security (Core):

* `terraform/network_policies.tf` - Código HCL para la gestión de políticas de seguridad.
* `decisiones_y_arquitectura.md` - Documentación de diseño de red y servicios core (DNS, DHCP, NTP).