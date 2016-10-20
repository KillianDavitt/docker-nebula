echo "Configuring node $1 as swarm member."

if [ "$#" -ne 3 ] ; then
  echo "Usage: $0 MACHINE_NAME ca.pem ca-priv-key.pem" >&2
  echo "    Configures the machine for TLS access as member of the swarm." >&2
  exit 1
fi

openssl genrsa -out $1-priv-key.pem 2048
openssl req -subj "/CN=swarm" -new -key $1-priv-key.pem -out $1.csr
openssl x509 -req -days 1825 -in $1.csr -CA $2 -CAkey $3 -CAcreateserial -out $1-cert.pem -extensions v3_req -extfile /usr/lib/ssl/openssl.cnf
docker-machine ssh $1 "sudo mkdir -p /var/lib/boot2docker/swarm-certs"
cat $2 | docker-machine ssh X "sudo sh -c \"cat - > /var/lib/boot2docker/swarm-certs/ca.pem\""
cat $1-cert.pem | docker-machine ssh $1 "sudo sh -c \"cat - > /var/lib/boot2docker/swarm-certs/cert.pem\""
cat $1-priv-key.pem | docker-machine ssh $1 "sudo sh -c \"cat - > /var/lib/boot2docker/swarm-certs/key.pem\""
rm $1-priv-key.pem       # these files no longer needed locally
rm $1-cert.pem
rm $1.csr
echo "Configuration complete."
