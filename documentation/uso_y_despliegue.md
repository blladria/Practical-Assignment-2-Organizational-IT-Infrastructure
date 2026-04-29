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