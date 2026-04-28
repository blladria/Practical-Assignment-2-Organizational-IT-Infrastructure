## Week 8: Containerization (Docker)

### El Problema (Contexto)
La infraestructura inicial sufría de entornos inconsistentes (el clásico problema de "funciona en mi portátil, ¿por qué no en producción?") y dependía de despliegues manuales propensos a errores.

### La Solución
Para solucionar esto, hemos implementado la contenedorización con Docker. Esto nos permite empaquetar las aplicaciones y sus dependencias en contenedores que se ejecutan de manera idéntica en cualquier máquina, estableciendo un estándar de despliegue consistente para el equipo.

### Decisiones de Diseño por Componente

#### 1. Servidor Web Frontend (Nginx)
* **Imagen Base:** `nginx:latest`.
* **Justificación:** Se ha elegido la imagen oficial de Nginx por ser el estándar de la industria. Utilizar la versión `latest` nos proporciona la configuración por defecto más reciente, ideal para servir contenido estático de forma inmediata.
* **Dependencias:** Ninguna externa. El contenedor inyecta un archivo de configuración personalizado `index.html` copiándolo directamente en la ruta por defecto `/usr/share/nginx/html/` durante la construcción.

#### 2. Aplicación Backend Simple (Node.js)
* **Imagen Base:** `node:18-alpine`.
* **Justificación:** En lugar de usar una imagen completa basada en Ubuntu o Debian, hemos optado por la variante `alpine`. Esta decisión se basa en las mejores prácticas de Docker para mantener imágenes pequeñas. Alpine Linux reduce drásticamente el tamaño final, acelera los despliegues y minimiza la superficie de ataque por motivos de seguridad.
* **Dependencias:** La aplicación es un servidor HTTP básico diseñado para responder a peticiones simples. Está escrita usando el módulo nativo de Node.js, por lo que carece de dependencias externas (no requiere instalación de paquetes adicionales ni gestores como npm en esta fase).

### Distribución de Artefactos (Docker Hub)
Para facilitar la colaboración y asegurar que cualquier nuevo miembro del equipo pueda empezar a trabajar sin configurar su entorno local, las imágenes han sido construidas y subidas (pushed) a un registro público en Docker Hub. Esto centraliza nuestras versiones y garantiza su disponibilidad para los futuros despliegues en producción.

---

## Archivos de la Week 8

Los siguientes ficheros pertenecen a la entrega de la Week 8: Containerization (Docker):

* `scripts/install_docker.sh` - Script de automatización para la instalación de Docker
* `code/nginx-app/index.html` - Página estática del servidor frontend
* `code/nginx-app/Dockerfile` - Dockerfile para la construcción de la imagen Nginx
* `code/simple_app/server.js` - Código fuente del servidor backend
* `code/simple_app/Dockerfile` - Dockerfile para la construcción de la imagen Node.js