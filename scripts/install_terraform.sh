# 1. Instalar unzip
sudo apt-get install unzip -y

# 2. Descargar la última versión estable de Terraform
wget https://releases.hashicorp.com/terraform/1.9.0/terraform_1.9.0_linux_amd64.zip

# 3. Descomprimir el archivo
unzip terraform_1.9.0_linux_amd64.zip

# 4. Mover el programa a la carpeta del sistema donde Linux lee los comandos
sudo mv terraform /usr/local/bin/

# 5. Limpiar el archivo zip descargado
rm terraform_1.9.0_linux_amd64.zip