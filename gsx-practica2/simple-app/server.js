const http = require('http');

// Lee el puerto desde las variables de entorno, o usa el 3000 por defecto
const port = process.env.PORT || 3000;

const server = http.createServer((req, res) => {
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/plain');
  
  // Mensaje que devuelve el backend
  res.end('Hello from container\n');
});

server.listen(port, () => {
  console.log(`Backend server running on port ${port}`);
});
