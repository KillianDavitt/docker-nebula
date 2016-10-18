echo "Configuring node $1..."

if [ "$#" -ne 1 ] ; then
  echo "Usage: $0 MACHINE_NAME" >&2
  exit 1
fi

docker-machine ssh $1 <<'ENDSSH'
sudo sh -c "echo \"sysctl net.ipv4.conf.all.forwarding=1\" >> /var/lib/boot2docker/bootlocal.sh"
sudo sh -c "echo \"echo 'nameserver 134.226.56.13' >> /etc/resolv.conf\" >> /var/lib/boot2docker/bootlocal.sh"
sudo sh -c "echo \"echo 'nameserver 134.226.32.58' >> /etc/resolv.conf\" >> /var/lib/boot2docker/bootlocal.sh"
sudo sh -c "echo \"export http_proxy=http://www-proxy.scss.tcd.ie:8080\" >> /var/lib/boot2docker/profile"
sudo sh -c "echo \"export https_proxy=http://www-proxy.scss.tcd.ie:8080\" >> /var/lib/boot2docker/profile"
sudo sh -c "echo \"export HTTPS_PROXY=http://www-proxy.scss.tcd.ie:8080\" >> /var/lib/boot2docker/profile"
sudo sh -c "echo \"export HTTP_PROXY=http://www-proxy.scss.tcd.ie:8080\" >> /var/lib/boot2docker/profile"
sudo sh -c "echo \"export http_proxy=http://www-proxy.scss.tcd.ie:8080\" >> /home/docker/profile"
sudo sh -c "echo \"export https_proxy=http://www-proxy.scss.tcd.ie:8080\" >> /home/docker/profile"
sudo sh -c "echo \"export HTTPS_PROXY=http://www-proxy.scss.tcd.ie:8080\" >> /home/docker/profile"
sudo sh -c "echo \"export HTTP_PROXY=http://www-proxy.scss.tcd.ie:8080\" >> /home/docker/profile"

sudo sh -c "echo \"echo 'bootsync.sh: sleeping a little bit so route config works...'\" >> /var/lib/boot2docker/bootlocal.sh"
sudo sh -c "echo \"sleep 15\" >> /var/lib/boot2docker/bootlocal.sh"
sudo sh -c "echo \"echo '...continuing'\" >> /var/lib/boot2docker/bootlocal.sh"
sudo sh -c "echo \"sudo route add -net 10.63.0.0 netmask 255.255.0.0 eth0\" >> /var/lib/boot2docker/bootlocal.sh"
sudo sh -c "echo \"sudo route del default eth0\" >> /var/lib/boot2docker/bootlocal.sh"
sudo sh -c "echo \"sudo route add default gw 10.63.255.254 eth0\" >> /var/lib/boot2docker/bootlocal.sh"
sudo sh -c "echo \"sudo route del -net 10.63.0.0 netmask 255.255.255.0 eth0\" >> /var/lib/boot2docker/bootlocal.sh"

# the next command disables the username/password combination for the docker account. 
# If you enable this, then you will only be able to access the machine using the command
#   'docker-machine ssh MACHINENAME'
# If you do not enable this command, then the username 'docker' and password 'tcuser' will 
# gain sudo enabled access to the machine. This is a security risk.

# sudo sh -c "echo \"sudo passwd -d docker\" >> /var/lib/boot2docker/bootlocal.sh"

echo "Configuration files initialised."
echo "Restarting machine to enable new configuration."
sudo reboot
ENDSSH
echo "Configuration process complete. Please wait for node to restart."

