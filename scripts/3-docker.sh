apt-get update
apt-get upgrade
export http_proxy=http://www-proxy.scss.tcd.ie:8080
export https_proxy=http://www-proxy.scss.tcd.ie:8080
wget -qO- https://get.docker.com/ | sh
mkdir /etc/systemd/system/docker.service.d
cat > /etc/systemd/system/docker.service.d/http-proxy.conf << EOM
[Service]
Environment="HTTP_PROXY=http://www-proxy.scss.tcd.ie:8080"
EOM
apt-get install sudo
sudo systemctl daemon-reload
sudo systemctl show --property Environment docker
sudo systemctl restart docker
docker run hello-world
