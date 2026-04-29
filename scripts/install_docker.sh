sudo apt update

sudo apt install docker.io -y
sudo apt install docker-compose -y

sudo systemctl start docker
sudo systemctl enable docker

sudo usermod -aG docker $USER