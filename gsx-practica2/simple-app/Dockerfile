# Usar la variante ligera (alpine) de Node.js versión 18
FROM node:18-alpine

# Crear y definir el directorio de trabajo dentro del contenedor
WORKDIR /app

# Copiar el archivo del servidor
COPY server.js .

# Exponer el puerto donde escucha la app
EXPOSE 3000

# Comando para ejecutar la aplicación
CMD ["node", "server.js"]