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

---

## Week 9: Multi-Container Orchestration (Docker Compose)

### El Problema (Contexto)
Las aplicaciones en el mundo real rara vez se ejecutan de forma aislada. Nuestro servidor Nginx y nuestra aplicación Node.js necesitan comunicarse entre sí, mantener datos persistentes cuando los contenedores se reinician y centralizar su configuración para arrancar rápidamente de forma conjunta. Ejecutarlos y conectarlos manualmente es tedioso y propenso a errores.

### Diagrama de Arquitectura
La infraestructura orquestada sigue la siguiente topología de red y comunicación:

```text
[Cliente Externo]
       │
       ▼ (Puerto 80)
┌───────────────┐         (gsx_network)          ┌──────────────────┐
│               │ ────── http://backend:3000 ──▶ │                  │
│  Frontend     │                                │  Backend         │
│  (Nginx)      │ ──┐                            │  (Node.js)       │
│               │   │                            │                  │
└───────────────┘   │                            └──────────────────┘
                    │                                     │      │
                    │                                     │      ▼
                    │       ┌───────────────────┐         │   [(Volumen)]
                    │       │                   │         │   backend_data
                    └─────▶ │  Logging          │ ◀───────┘   (/data)
           (Logs vía driver)│  (Fluentd)        │ (Logs vía driver)
                            │                   │
                            └───────────────────┘
```

### Explicación de los Servicios
1. **Frontend (Nginx):** Actúa como el punto de entrada principal (Service 1). Es necesario para servir el contenido estático y, en un futuro, actuar como proxy inverso para enrutar el tráfico externo.
2. **Backend (Node.js):** Contiene la lógica de la aplicación (Service 2). Es necesario para procesar las peticiones dinámicas internas.
3. **Logging Collector (Fluentd):** Servicio adicional implementado para cumplir con los requisitos avanzados de observabilidad. Centraliza los registros de Nginx y del Backend, evitando el fallo silencioso de los servicios y facilitando la depuración.

### Comunicación entre Servicios
En Docker Compose, los servicios se comunican a través de redes virtuales. Hemos creado una red personalizada (`gsx_network`) en lugar de usar la predeterminada. Dentro de esta red, Docker incluye un servidor DNS interno que permite a los contenedores encontrarse utilizando el nombre del servicio como si fuera un dominio. Por ejemplo, Nginx puede alcanzar al backend realizando peticiones a `http://backend:3000`.

### Persistencia de Datos (Volúmenes)
Los contenedores son efímeros por naturaleza; si se reinician o destruyen, todos los datos internos desaparecen. Para solucionar esto, utilizamos **Volúmenes**.
* **Implementación:** Hemos definido un volumen llamado `backend_data` mapeado al directorio `/data` dentro del contenedor del Backend.
* **Por qué y cuándo usarlos:** Garantizan que la información persista independientemente del ciclo de vida del contenedor. Se utilizan siempre que una aplicación maneje estados, bases de datos o archivos generados por los usuarios que no deban perderse tras un despliegue o caída.

### Gestión de la Configuración y Secretos
Las configuraciones no deben estar *hardcodeadas* (incrustadas de forma fija) dentro de las imágenes de Docker. 
* **Variables de entorno:** La configuración se inyecta en tiempo de ejecución utilizando el archivo `docker-compose.yml`, que a su vez lee los valores de un archivo local llamado `.env`.
* **Gestión de Secretos:** Para proteger contraseñas y claves de API, el archivo `.env` se añade al `.gitignore` para asegurar que nunca se suba al sistema de control de versiones (Git). Para el trabajo en equipo, se proporciona una plantilla llamada `.env.example` con valores de muestra.

### Conceptos Clave y Decisiones Finales

**¿Qué define `docker-compose.yml`?**
Es un archivo en formato YAML que define de forma declarativa una aplicación multicontenedor completa en un solo lugar. Describe los servicios que la componen, las redes que los conectan, los volúmenes para sus datos y las variables de entorno necesarias.

**Robustez del Sistema (Mejoras Intermedias/Avanzadas)**
Para evitar comportamientos erráticos, hemos añadido:
* `healthchecks`: Docker comprueba periódicamente si la aplicación está realmente respondiendo.
* `depends_on`: Fuerzan un orden de inicio estricto (Nginx no arranca hasta que el backend reporta estar "sano").
* **Límites de recursos y logs**: Se han establecido cuotas de CPU/Memoria y límites de tamaño (`max-size`) usando el driver `json-file` para evitar que un contenedor acapare recursos o llene el disco con logs.

**¿Cuándo usar Compose vs. Kubernetes?**
Docker Compose es ideal para entornos de desarrollo local y pruebas, ya que permite levantar rápidamente toda la pila tecnológica (stack) en una sola máquina sin complejidad. Sin embargo, está limitado para producción. Kubernetes se utiliza cuando el sistema necesita ejecutarse a gran escala, repartiendo la carga entre múltiples servidores, proporcionando recuperación automática ante fallos de hardware y realizando actualizaciones sin tiempo de inactividad (rolling updates).