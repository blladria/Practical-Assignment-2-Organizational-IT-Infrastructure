# Reflexión sobre el Despliegue y Orquestación de Infraestructura Cloud-Native

**Autores del Proyecto:** Daniel Molina Orive y Adrià Borrell Lloret

**Asignatura:** Gestión de Sistemas y Redes

**Fecha:** Mayo de 2026

### Introducción: La Evolución de GreenDevCorp

El viaje tecnológico de GreenDevCorp a lo largo de estas 13 semanas ha representado un cambio de paradigma fundamental en nuestra forma de entender la computación. Comenzamos empaquetando aplicaciones en contenedores Docker aislados para resolver inconsistencias de entorno y hemos culminado con una infraestructura orquestada, segura y totalmente reproducible mediante código. Como estudiantes de Ingeniería Informática, este proceso nos ha revelado que la infraestructura moderna es una arquitectura de software dinámica que requiere precisión y automatización.

### El Desafío Técnico: Redes y Convergencia

El aspecto más desafiante ha sido la gestión de la red y la seguridad en Kubernetes. A diferencia de Docker Compose, la introducción de **NetworkPolicies** y motores de red como **Calico** exige una comprensión profunda de las capas de aislamiento.

Durante el test de integración final, nos enfrentamos a una condición de carrera crítica: los pods de aplicación intentaban arrancar antes de que el motor de red Calico estuviera listo en los nodos. Gestionar esos errores iniciales de `FailedCreatePodSandBox` fue una lección valiosa sobre las dependencias de infraestructura y el orden de convergencia en sistemas distribuidos.

### La Sorpresa: El Clúster como Organismo Resiliente

Lo que más nos ha sorprendido es la capacidad de **autorrecuperación (Self-Healing)** de Kubernetes. Ver cómo el clúster gestionaba los reintentos de los pods automáticamente hasta que Calico estuvo operativo, sin intervención manual, demuestra la potencia de los sistemas declarativos. Esta resiliencia nativa asegura que el sistema siempre tienda al "estado deseado", minimizando el tiempo de inactividad por fallos temporales.

### Cambio de Visión: La Era de la Infraestructura como Código (IaC)

Nuestra visión de **DevOps** ha madurado al implementar Terraform. Hemos pasado de "instalar software" a "programar infraestructuras". La capacidad de ejecutar un `minikube delete` y reconstruir dos entornos completos (dev y staging) en menos de 10 minutos, con cuotas de recursos y reglas de seguridad aplicadas, demuestra que la **IaC** es la única forma viable de gestionar sistemas a gran escala de forma predecible.

### Mirando al Futuro: Seguridad y Escalabilidad

Si tuviéramos que empezar de nuevo, habríamos adoptado **Helm** desde el principio para gestionar los manifiestos, lo que habría hecho la configuración mucho más modular y fácil de versionar que el uso de recursos de Terraform puros.

De cara al futuro, este proyecto ha despertado nuestro interés por la **observabilidad avanzada** y la **seguridad de red**. Nos gustaría profundizar en la implementación de controladores de Ingress con terminación **TLS** para asegurar el tráfico externo y explorar herramientas como **Prometheus y Grafana** para obtener métricas de rendimiento en tiempo real. Además, nos interesa investigar sobre **GitOps** para automatizar completamente la reconciliación entre el repositorio y el estado real del clúster.

### Conclusión

Este proyecto ha sido una simulación fiel de los retos reales de producción. Hemos aprendido que la tecnología debe servir para construir sistemas predecibles, seguros y fáciles de operar. Nos sentimos preparados para defender esta arquitectura y para aplicar estos principios de diseño en cualquier entorno profesional de ingeniería de sistemas.
