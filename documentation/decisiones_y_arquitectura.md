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

---

## Week 10: Orquestación para Producción (Kubernetes)

### El Problema (Contexto)
Aunque Docker Compose es una herramienta excelente para el desarrollo local y pruebas, carece de las características necesarias para un entorno de producción real: no tiene auto-recuperación avanzada (self-healing), no distribuye la carga entre múltiples máquinas físicas y no escala horizontalmente de forma nativa. Necesitábamos una plataforma robusta que garantizara alta disponibilidad y resiliencia para los servicios de GreenDevCorp.

### La Solución
Para solucionar esto, hemos migrado la infraestructura a Kubernetes (utilizando Minikube para emular un clúster en el entorno local). Kubernetes actúa como un "director de orquesta" automatizado que supervisa la salud de los contenedores, los escala según la demanda y los reinicia instantáneamente en caso de fallo.

### Decisiones de Diseño por Componente (Manifiestos)

Hemos adoptado un enfoque declarativo, definiendo el estado deseado de nuestra infraestructura a través de manifiestos YAML:

#### 1. Frontend (Nginx) - Despliegue sin estado (Stateless)
* **Controlador:** `Deployment`.
* **Justificación:** Nginx no guarda datos persistentes. El uso de un Deployment permite escalar el número de réplicas fácilmente y garantiza que si un Pod falla, el *ReplicaSet* levante uno nuevo inmediatamente.
* **Exposición (Service):** Se ha utilizado un servicio de tipo `NodePort` para exponer el servidor web hacia el exterior del clúster (Puerto 30080), permitiendo el acceso de los usuarios finales.

#### 2. Backend (Node.js) - Despliegue con estado (Stateful)
* **Controlador:** `StatefulSet`.
* **Justificación:** A diferencia del frontend, el backend maneja datos que deben persistir (Requisito Avanzado). Un `StatefulSet` garantiza el orden de despliegue, proporciona una identidad de red estable (resolución DNS consistente) y asegura que cada réplica mantenga su propio almacenamiento persistente.
* **Exposición (Service):** Se ha configurado un servicio de tipo `ClusterIP`, manteniéndolo accesible únicamente de forma interna para el Nginx, garantizando así la seguridad de la arquitectura.

#### 3. Gestión de la Configuración
* **Controlador:** `ConfigMap`.
* **Justificación:** Siguiendo las mejores prácticas, hemos desacoplado la configuración del código creando un `ConfigMap` (`backend-config`). Esto nos permite inyectar variables de entorno (como el puerto o el modo de producción) directamente a los Pods sin tener que reconstruir las imágenes de Docker.

### Estabilidad y Robustez (Nivel Intermedio)

Para evitar que un contenedor defectuoso comprometa todo el nodo o que los usuarios reciban errores durante los arranques, se han implementado políticas estrictas en los manifiestos:
* **Límites de Recursos (Requests/Limits):** Se han definido `requests` (recursos mínimos garantizados) de 64Mi de RAM y 250m de CPU, y `limits` (recursos máximos permitidos) de 128Mi y 500m. Esto evita el efecto "vecino ruidoso" (noisy neighbor), impidiendo que un solo pod consuma toda la memoria del servidor físico y provoque la caída en cascada de otros servicios.
* **Health Probes (Sondas de salud):** 
  * *Liveness Probe:* Comprueba constantemente si la aplicación está "viva". Si el servidor Node.js se bloquea internamente, Kubernetes lo detectará y reiniciará automáticamente el pod.
  * *Readiness Probe:* Comprueba si la aplicación está lista para recibir tráfico. El balanceador de carga interno no enviará peticiones a un pod hasta que esta prueba sea exitosa, evitando la pérdida de paquetes durante los arranques.

### Persistencia de Datos (Nivel Avanzado)

Los contenedores son efímeros. Para garantizar que los datos del backend sobrevivan a la destrucción, escalado o reinicio de los pods:
* **PersistentVolumeClaim (PVC):** Dentro del `StatefulSet` del backend, hemos definido un `volumeClaimTemplates` que solicita 1Gi de almacenamiento con modo de acceso `ReadWriteOnce`.
* **Cómo funciona:** Kubernetes aprovisiona dinámicamente un volumen real (PersistentVolume) en el disco subyacente y lo "ata" a un pod específico. Si el pod `backend-0` es eliminado, Kubernetes lo levanta de nuevo y vuelve a montar exactamente el mismo volumen físico en el directorio `/data`, garantizando que la información se conserve intacta.

### Archivos de la Week 10

Los siguientes ficheros se han creado y pertenecen a la entrega de la Week 10: Orquestación para Producción (Kubernetes):

* `kubernetes/configmap.yaml` - Manifiesto (ConfigMap) que define las variables de entorno globales (`NODE_ENV`, `PORT`) para desacoplarlas de las imágenes.
* `kubernetes/nginx.yaml` - Manifiesto del Frontend que incluye el controlador `Deployment` (con *probes* y límites de recursos) y el `Service` de tipo NodePort para habilitar el acceso externo.
* `kubernetes/backend.yaml` - Manifiesto del Backend que incluye el controlador `StatefulSet` (con la petición de volumen persistente dinámico o PVC) y el `Service` de tipo ClusterIP para la comunicación interna segura.

---

## Week 11: Infraestructura como Código (IaC) y CI/CD (Core)

### El Problema (Contexto)
Aunque Kubernetes aporta resiliencia, aplicar manifiestos manualmente mediante comandos kubectl no es escalable ni permite llevar un registro de cambios. Además, construir y subir imágenes de Docker desde el entorno local genera inconsistencias. Necesitábamos automatizar el ciclo de vida de la infraestructura y el despliegue.

### La Solución
Hemos implementado Terraform como herramienta de Infraestructura como Código (IaC) para gestionar los recursos del clúster de forma declarativa. Complementariamente, hemos configurado un pipeline de Integración Continua (CI) con GitHub Actions que automatiza la construcción y el almacenamiento de imágenes en Docker Hub.

### Decisiones de Diseño por Componente

#### 1. Gestión de Infraestructura (Terraform)
* **Control del Estado:** Se ha migrado la configuración de Kubernetes a archivos .tf, permitiendo que Terraform gestione el ciclo de vida de los Pods y Servicios.
* **Desacoplamiento mediante Variables:** Se utiliza un archivo terraform.tfvars para definir los tags de las imágenes. Esto permite actualizar la versión de la aplicación sin modificar el código base de la infraestructura.
* **Automatización de Red:** Terraform gestiona la creación de servicios NodePort para el frontend y ClusterIP para el backend, asegurando que la conectividad sea reproducible.

#### 2. Automatización de Imágenes (GitHub Actions)
* **Pipeline de CI:** Al realizar un git push, el flujo de trabajo construye automáticamente las imágenes de Nginx y Node.js.
* **Etiquetado Inmutable:** Cada imagen se etiqueta con el SHA del commit de GitHub (un identificador único de 40 caracteres). Esto garantiza que siempre sepamos exactamente qué versión del código está ejecutándose en el clúster.
* **Registro Centralizado:** Las imágenes se suben automáticamente a Docker Hub, sirviendo como repositorio central de artefactos para el despliegue.

### Archivos de la Week 11

Los siguientes ficheros pertenecen a la entrega de la Week 11: Automatización y Despliegue (Core):

* `.github/workflows/ci.yml` - Pipeline de GitHub Actions para build y push automático.
* `terraform/main.tf` - Configuración del proveedor de Kubernetes.
* `terraform/nginx.tf` - Definición del Deployment y Service del Frontend.
* `terraform/backend.tf` - Definición del StatefulSet y Service del Backend.
* `terraform/variables.tf` - Declaración de variables de configuración.
* `terraform/terraform.tfvars` - Valores de las variables (tags de imágenes y usuario de Docker Hub).

---

## Week 11: Múltiples Entornos y Workspaces (Nivel Intermedio)

### El Problema (Contexto)
En un ciclo de desarrollo profesional, el código no pasa directamente del ordenador del desarrollador a producción. Necesitábamos una forma de desplegar la infraestructura en diferentes entornos (como Desarrollo y Pre-producción/Staging) usando exactamente el mismo código base, pero sin que los recursos de un entorno sobrescribieran o destruyeran los del otro al desplegarse en el mismo clúster.

### La Solución y Decisiones de Diseño
Para resolver este reto, hemos implementado el aislamiento de entornos utilizando una combinación de Namespaces de Kubernetes y Workspaces de Terraform.

* **Namespaces Dinámicos:** Hemos modificado todos los recursos en nuestros archivos .tf (main.tf) para que el atributo namespace no sea estático, sino que se inyecte a través de una variable (var.namespace). Además, Terraform se encarga de crear el namespace automáticamente si no existe.

* **Archivos de Variables Independientes:** Hemos separado la configuración creando archivos específicos por entorno:
  * **dev.tfvars:** Configurado para usar el puerto externo 30080 y levantar 1 sola réplica de Nginx (ahorrando recursos durante el desarrollo).
  * **staging.tfvars:** Configurado para usar el puerto externo 30081 (evitando colisiones de puertos) y levantar 2 réplicas de Nginx, simulando un entorno más robusto y cercano a producción.

* **Aislamiento del Estado (Workspaces):** El mayor desafío de Terraform es que, por defecto, utiliza un único archivo de estado (terraform.tfstate). Si se aplica una configuración diferente, Terraform destruye lo anterior. Para permitir la convivencia de los entornos, hemos utilizado el comando `terraform workspace`. Esto crea "burbujas" o estados paralelos independientes para dev y staging, permitiendo que ambos ecosistemas operen simultáneamente en el mismo clúster de Minikube sin interferir entre sí.

* **Trazabilidad de Entornos:** Se ha configurado el ConfigMap del backend para que la variable NODE_ENV cambie dinámicamente dependiendo del entorno desplegado, permitiendo a la aplicación saber en qué contexto se está ejecutando.

### Archivos de la Week 11

Los siguientes ficheros pertenecen a la entrega de la Week 11: Automatización, Despliegue (Core) y Múltiples Entornos (Intermediate):

* `.github/workflows/ci.yml` - Pipeline de GitHub Actions para build y push automático.
* `terraform/main.tf` - Configuración del proveedor, recursos de Kubernetes y namespaces automáticos.
* `terraform/outputs.tf` - Archivo para mostrar los puertos asignados y el entorno activo tras cada despliegue.
* `terraform/variables.tf` - Declaración de variables de configuración (incluyendo namespaces, réplicas y puertos dinámicos).
* `terraform/dev.tfvars` - Valores y configuración específica para el entorno de Desarrollo.
* `terraform/staging.tfvars` - Valores y configuración específica para el entorno de Pre-producción (Staging).

---

### CI/CD de Grado Empresarial y Seguridad (Nivel Avanzado)

#### El Problema (Contexto)
Un pipeline básico que simplemente construye y sube imágenes es insuficiente para un entorno de producción real. Carece de validaciones de seguridad, es lento si reconstruye capas sin cambios, y no proporciona garantías de trazabilidad (qué contiene la imagen) ni estrategias claras de recuperación ante desastres (rollback).

#### La Solución y Decisiones de Diseño
Hemos evolucionado nuestro flujo de GitHub Actions para convertirlo en un pipeline robusto, seguro y eficiente, cumpliendo con los estándares de DevOps modernos:

* **Escaneo de Seguridad Integrado (Trivy):** Se ha añadido la herramienta *AquaSecurity Trivy* como paso en la integración continua. 
  * **Decisión:** El pipeline está configurado para analizar vulnerabilidades de severidad `HIGH` o `CRITICAL`. Aunque en un entorno estrictamente bloqueante esto detendría el paso a producción (`exit-code: 1`), se ha validado su funcionamiento detectando vulnerabilidades de fábrica en la imagen base de Alpine, documentando el hallazgo y permitiendo el flujo para la generación posterior de artefactos.
* **Transparencia en la Cadena de Suministro (SBOM):** Utilizamos *Anchore SBOM Action* para generar automáticamente un *Software Bill of Materials* (Lista de materiales de software) en formato JSON para cada imagen. 
  * **Decisión:** Estos archivos se generan y se suben como artefactos descargables en la propia ejecución del workflow en GitHub, siendo vitales para futuras auditorías de seguridad y *compliance*.
* **Optimización de Rendimiento (Caché de Docker Buildx):** Se ha habilitado la caché mediante GitHub Actions (`type=gha`).
  * **Decisión:** Esto permite al motor de Docker reutilizar las capas compiladas en ejecuciones anteriores, reduciendo drásticamente los tiempos de *build* y ahorrando recursos de cómputo.
* **Estrategia de Etiquetado (Release/Tag Strategy):** Hemos mejorado la gestión de versiones en nuestro registro.
  * **Decisión:** Cada imagen validada y subida a Docker Hub recibe dos etiquetas simultáneas:
    1. El **SHA del commit** de GitHub (`${{ github.sha }}`): Garantiza la inmutabilidad y la trazabilidad exacta de la infraestructura (sabemos qué línea exacta de código generó esa imagen).
    2. La etiqueta **`stable`**: Sirve como puntero móvil ("latest" controlado) hacia la última versión que superó las pruebas de forma exitosa.
* **Estrategia de Rollback (Recuperación ante Desastres):** En caso de que un despliegue provoque fallos en el clúster (por ejemplo, al cambiar de imagen o escalar incorrectamente), hemos definido y testeado un procedimiento de marcha atrás instantánea.
  * **Decisión:** Aprovechamos el historial de despliegues (`ReplicaSets`) nativo de Kubernetes. Utilizando el comando `kubectl rollout undo`, podemos revertir el clúster al estado funcional inmediatamente anterior en cuestión de segundos, garantizando la continuidad del servicio mientras se investiga el fallo en el código.

---

## Week 12: Network Architecture & Security (Core)

### 1. Diagrama de Arquitectura de Red (Segmentación)

El siguiente diagrama ilustra la separación lógica de nuestra infraestructura, aislando los entornos y delimitando la DMZ de las bases de datos internas mediante NetworkPolicies.

```text
                           [ Internet ]                        [ External Partners ]
                                 |                                 (10.0.10.0/24)
                                 | (Puertos 80/443)                      |
                                 v                                       v (VPN/API)
=========================================================================================
[ DMZ Segment (Expuesto) ]

         +-----------------+   +-----------------+   +-----------------+
         | Frontend Dev    |   | Frontend Stg    |   | Frontend Prod   |
         | (10.0.1.0/24)   |   | (10.0.2.0/24)   |   | (10.0.3.0/24)   |
         +-----------------+   +-----------------+   +-----------------+
                  |                     |                     |
      (Permitido) |         (Permitido) |         (Permitido) |
                  v                     v                     v
=========================================================================================
[ Internal Segment (Protegido) ]

         +-----------------+   +-----------------+   +-----------------+
         | Backend Dev     |   | Backend Stg     |   | Backend Prod    | <---- [ APIs ]
         | (10.0.1.0/24)   |   | (10.0.2.0/24)   |   | (10.0.3.0/24)   |
         +-----------------+   +-----------------+   +-----------------+
                  |                     |                     |
                  +---X (Bloqueado) X---+---X (Bloqueado) X---+
                            (Cross-Environment Denied)        | (Permitido)
                                                              v
=========================================================================================
[ Database Segment (Altamente Restringido) ]
                                                              
                                                       [( Database Prod )]
                                                       [( 10.0.3.0/24   )]
```
### 2. Planificación de Direccionamiento IP (IP Addressing Plan)
Para la organización GreenDevCorp, hemos reservado un bloque CIDR amplio (10.0.0.0/16), lo que nos proporciona 65,536 direcciones IP privadas. Este bloque se ha subdividido en subredes /24 para facilitar el enrutamiento, aislar dominios de broadcast y aplicar listas de control de acceso (ACLs) perimetrales.

**Organización global:** 10.0.0.0/16

**Subdivisiones:**

- **10.0.1.0/24** -> Development (Dev): 254 IPs usables. Aloja los pods efímeros, servicios y recursos de pruebas de los desarrolladores.
- **10.0.2.0/24** -> Staging (Pre-producción): 254 IPs usables. Entorno clonado de producción para pruebas de integración finales.
- **10.0.3.0/24** -> Production (Prod): 254 IPs usables. Aloja el tráfico real de usuarios. Separarlo evita que un error en el código de desarrollo consuma IPs o sature la red de producción.
- **10.0.10.0/24** -> External Partners: 254 IPs usables. Subred dedicada a conexiones VPN o integraciones API de terceros.

**Justificación de la subdivisión:** Un bloque /24 (256 direcciones, 254 asignables) es el tamaño ideal para entornos de contenedores pequeños/medianos por nodo. Permite escalar hasta más de 200 pods por entorno sin desperdiciar masivamente el bloque principal /16. Si un entorno necesitara más escala en el futuro, se le asignaría un bloque /23.

### 3. Fronteras de Seguridad (Security Boundaries)
Para garantizar el principio de privilegio mínimo (Zero Trust), se ha configurado la red del clúster bajo las siguientes directivas:

#### ¿Qué tráfico está permitido?
- El tráfico de Internet solo puede alcanzar la capa de presentación (DMZ) donde reside el Frontend (Nginx).
- El Frontend tiene permisos estrictos para comunicarse por el puerto 3000 con el Backend dentro de su mismo entorno.

#### ¿Qué tráfico está bloqueado y por qué?
- **Acceso directo al Backend/DB:** Bloqueado desde el exterior. El backend y la base de datos no tienen IPs públicas ni servicios NodePort. Esto evita ataques directos de explotación de vulnerabilidades.
- **Tráfico Cross-Environment (Cross-Namespace):** Bloqueado. Un pod comprometido en la red de Desarrollo (10.0.1.0/24) no puede escanear ni conectarse a un pod en Producción (10.0.3.0/24). Esto contiene las brechas de seguridad (blast radius).

#### ¿Cómo prevenimos desconfiguraciones accidentales?
- **Utilizando Infraestructura como Código (Terraform):** Las políticas de red están declaradas en el código (network-policies.tf); nadie aplica reglas manualmente en el servidor.
- **Implementando una directiva Default-Deny:** La primera regla de red deniega todo el tráfico entrante al namespace. Luego, se abren explícitamente solo los puertos necesarios (Frontend -> Backend). Si a alguien se le olvida proteger un nuevo microservicio, nacerá totalmente aislado y sin red por defecto.

---

## Week 12: Core Services & Identity Management Research

### 1. Core Network Services

#### 1.1. DNS (Domain Name System)
**¿Qué es y qué problema resuelve?**
DNS es un sistema de nomenclatura jerárquico y descentralizado. Su propósito principal es traducir (resolver) nombres de dominio legibles por humanos (ej. `www.greendevcorp.com`) en direcciones IP numéricas (ej. `192.168.1.50`) que las máquinas utilizan para comunicarse. Resuelve el problema de tener que memorizar direcciones IP y permite que las IPs cambien por debajo sin afectar el nombre con el que se accede al servicio.

**¿Por qué una organización necesita DNS?**
Una empresa lo necesita tanto a nivel externo (para que sus clientes encuentren su web o sus APIs) como a nivel interno. En la red interna, el DNS permite que los servicios se descubran entre sí (Service Discovery), algo vital en Kubernetes (donde los Pods cambian de IP constantemente) y en sistemas como Active Directory.

**¿Cómo funciona (Alto nivel)?**
Cuando un usuario teclea una URL, su ordenador consulta a un servidor DNS local (Resolver). Si este no tiene la respuesta en caché, consulta a la raíz de internet (Root Servers), luego a los servidores de dominio de nivel superior (TLD, ej. `.com`), y finalmente al servidor autoritativo que tiene el registro exacto de la IP. Una vez obtenida, se la devuelve al usuario y la guarda en caché.

**Explicación para una persona no técnica:**
> Piensa en el DNS como si fuera la agenda de contactos de tu teléfono móvil. A las personas no se nos da bien memorizar decenas de números de teléfono de 9 cifras, así que guardamos un nombre como "Mamá" o "Taller". 
> Cuando quieres llamar, buscas el nombre y el teléfono marca el número por ti automáticamente. El DNS hace exactamente eso en Internet: tú escribes "google.com" (el nombre) y el DNS busca en su enorme libreta cuál es su "número de teléfono" (la dirección IP) para poder conectar tu ordenador con el de ellos.

#### 1.2. DHCP (Dynamic Host Configuration Protocol)
**¿Qué es y qué problema resuelve?**
DHCP es un protocolo de red cliente/servidor que asigna dinámicamente direcciones IP y otros parámetros de configuración de red (como la máscara de subred, la puerta de enlace y los servidores DNS) a cada dispositivo que se conecta a una red. Resuelve el problema de la configuración manual (IPs estáticas), previniendo conflictos de IP duplicadas y ahorrando incontables horas de administración.

**¿Por qué lo usaría una organización?**
Porque en una red moderna, los dispositivos entran y salen constantemente (portátiles, móviles, máquinas virtuales, pods). Asignar IPs manualmente sería un caos administrativo y propenso a errores humanos.

**¿Cómo funciona (Alto nivel)?**
Utiliza un proceso llamado DORA (Discover, Offer, Request, Acknowledge):
1. **D**iscover: El cliente entra a la red y grita "¿Hay algún servidor DHCP aquí?".
2. **O**ffer: El servidor DHCP responde "Sí, te ofrezco esta IP".
3. **R**equest: El cliente dice "Perfecto, me la quedo, regístrala".
4. **A**cknowledge: El servidor confirma "Hecho, es tuya por un tiempo determinado (Lease)".

**Explicación para una persona no técnica:**
> Imagina que llegas a un gran hotel. No puedes simplemente entrar y meterte en la habitación que más te guste, porque podrías meterte en la cama de otra persona (conflicto de IP). El DHCP es el recepcionista del hotel: cuando llegas a la puerta, le pides una habitación, y él revisa qué habitaciones están libres y te entrega la llave de una por el tiempo que dure tu estancia. Así se asegura de que todo el mundo tenga su propio espacio sin chocarse con los demás.

#### 1.3. NTP (Network Time Protocol)
**¿Qué es y por qué importa la sincronización?**
NTP es un protocolo diseñado para sincronizar los relojes de los ordenadores a través de una red de datos, con una precisión de milisegundos respecto al Tiempo Universal Coordinado (UTC). 

**Importancia para seguridad y operaciones:**
* **Seguridad (Criptografía):** Los certificados SSL/TLS y tokens de seguridad tienen fechas de caducidad y de inicio de validez estrictas. Si el reloj de un servidor está atrasado, rechazará conexiones válidas o aceptará certificados caducados. Protocolos de identidad como Kerberos fallan automáticamente si hay más de 5 minutos de diferencia entre el cliente y el servidor para evitar ataques de repetición (Replay Attacks).
* **Operaciones (Auditoría):** Si ocurre un ciberataque o un fallo en el sistema, los ingenieros miran los *logs* (registros). Si el Servidor A y el Servidor B tienen horas distintas, es imposible reconstruir la línea temporal para saber qué ocurrió primero.

**Explicación para una persona no técnica:**
> El NTP es como el director de una orquesta sinfónica. Si tienes 100 músicos (ordenadores), no importa lo buenos que sean; si cada uno empieza a tocar con un segundo de diferencia basándose en su propio reloj, el resultado será un ruido espantoso. El NTP se asegura de que todos los ordenadores del mundo miren al mismo reloj maestro y "tic-taqueen" exactamente en el mismo milisegundo. Esto es crítico porque si el banco registra que sacaste dinero a las 12:05, y el cajero automático dice que te lo dio a las 12:00, las cuentas de seguridad no cuadrarán y bloquearán la operación.

---

### 2. Identity Management

#### 2.1. Authentication vs. Authorization
**Authentication (Autenticación - *Identidad*):**
La autenticación responde a la pregunta **"¿Quién eres?"**. Es el proceso mediante el cual un sistema verifica que una persona o servicio es quien dice ser. Se logra comprobando factores como algo que el usuario sabe (una contraseña), algo que tiene (un teléfono para recibir un SMS o token) o algo que es (huella dactilar o FaceID).

**Authorization (Autorización - *Permisos*):**
La autorización responde a la pregunta **"¿Qué puedes hacer?"**. Ocurre *después* de la autenticación. Es el proceso de determinar si la identidad confirmada tiene los permisos o privilegios necesarios para acceder a un recurso específico, como leer un archivo, entrar a un servidor o modificar una base de datos. Se suele gestionar mediante control de acceso basado en roles (RBAC).

#### 2.2. Centralized Identity (Identidad Centralizada)
* **LDAP:** Es un protocolo abierto utilizado para interactuar con servicios de directorio (una base de datos optimizada para lecturas rápidas). Permite buscar información sobre usuarios, grupos y permisos en una red.
* **Active Directory (AD):** Es el servicio de directorio propietario de Microsoft. Actúa como el "cerebro" de una red empresarial, utilizando LDAP para consultas, Kerberos para autenticación y DNS para localizar recursos.
* **SSO (Single Sign-On):** Permite a un usuario iniciar sesión *una sola vez* con un solo usuario y contraseña, y obtener acceso a múltiples aplicaciones independientes de forma automática. Importa porque reduce la fatiga de contraseñas (evita que los empleados apunten contraseñas en post-its) y facilita dar de baja a un empleado en un solo clic.

**¿Qué problema resuelve la identidad centralizada?**
Elimina las cuentas "locales". Sin identidad centralizada, un empleado necesitaría una cuenta distinta creada manualmente en su PC, en el servidor de correo, en el software de RRHH y en la base de datos de código. La identidad centralizada proporciona una "Única Fuente de Verdad" (Single Source of Truth) para altas, bajas y permisos.

**Necesidades por tamaño de empresa:**
* **Empresa Pequeña (1-15 personas):** A menudo sobreviven con cuentas locales o gestionando la identidad a través de un servicio en la nube sencillo (como las cuentas de Google Workspace). No necesitan la complejidad de un AD on-premise.
* **Empresa Grande (100+ personas):** Es obligatoria una solución IAM (Identity and Access Management) robusta (como Active Directory o Entra ID) para cumplir con normativas de seguridad, auditorías y gestionar eficientemente el alto volumen de rotación de personal.

#### 2.3. Identity Strategy para GreenDevCorp
**Análisis y Recomendación:**
Dado que GreenDevCorp es una empresa en crecimiento con **20+ empleados** y que hace un uso intensivo de tecnologías modernas (Kubernetes, contenedores, nubes públicas), **la recomendación es adoptar un Identity Provider (IdP) basado en la nube (Cloud IAM)**, como *Microsoft Entra ID*, *Okta* o *Google Workspace Cloud Identity*, evitando montar un servidor tradicional de Active Directory local (On-Premise).

**Razonamiento:**
1. **Cero Mantenimiento de Infraestructura:** Con ~20 empleados, no hay justificación económica ni técnica para destinar a un ingeniero a mantener servidores físicos de Active Directory, parchearlos y hacerles copias de seguridad.
2. **Integración Moderna (SSO y MFA):** Las soluciones Cloud IAM incluyen Single Sign-On mediante protocolos modernos (OIDC, SAML), lo que permite a los desarrolladores hacer login único para acceder a GitHub, Kubernetes, VPNs y herramientas de CI/CD. Además, el Autenticador Multifactor (MFA) viene configurado por defecto.
3. **Trabajo Remoto:** No requiere que los empleados estén conectados a una red local o VPN tradicional simplemente para validar sus credenciales contra un controlador de dominio.

**Trade-offs (Compromisos):**
* **Dependencia (Vendor Lock-in):** La empresa pasará a depender económicamente de un proveedor en la nube y de suscripciones recurrentes (pago por usuario/mes).
* **Disponibilidad:** Si la conexión a Internet de la oficina falla (o el proveedor cloud sufre una caída), los empleados podrían experimentar problemas para autenticarse en servicios locales (aunque esto se mitiga con cachés de credenciales locales en los portátiles).