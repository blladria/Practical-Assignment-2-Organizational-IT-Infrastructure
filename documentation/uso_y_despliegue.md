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