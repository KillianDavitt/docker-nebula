#7 Docker Swarm#

Docker swarm is a clustering technology for docker that turns a pool of docker hosts (by which in our context, we mean SCSSNebula virtual machines running the docker service) into a single virtual docker host. You can direct your docker client to communicate with a swarm such that containers you request to be run may be run on any of the docker hosts within the pool of hosts managed by the swarm. This makes is relatively easy to deploy and manage highly scalable network applications. If one needs more container instances, one simply runs them and docker swarm will take care of where best to run them. If our pool of docker hosts become overloaded, we can simply add new hosts to the swarm.This architectural model is the basis of most real-world scalable service deployments today: behind some well known service endpoint, often accessible via a web browser, sits a dynamic group of tens, hundreds or even thousands of collaborating nodes. 

## 7.1 Creating a Swarm cluster ##

To proceed you must have created a set of nodes in the SCSSNebula cloud, and configured your machine set to use TLS as described in the Master-Worker sequence above, or by having created all nodes using `docker-machine`. In the following text, we will presume that one of the machines is designated as the swarm master, another machine will act a secondary master and provide something called a _discovery backend_ service, and all other machines will be workers in the swarm. Whenever we refer to a client machine, this means a machine with docker installed from which the _docker client_ is used to invoke commands on a the swarm, possibly hosted on a remote machine in the SCSSNebula, but not necessarily so. 


1. Create a discovery backend.

    To begin the swarm configuration for your machine set, we first create a _discovery backend_ which is a service that lets swarm members find each other. Login to your registry host (this will be a lightly loaded host suitable to also act as a discovery backend) or create a node for the purpose. We shall refer to this node in the following text as the `registry`. Create the discovery backend as follows:

        $ docker run -d --restart=always -p 8500:8500 --name=consul progrium/consul -server -bootstrap
        Unable to find image 'progrium/consul:latest' locally
        latest: Pulling from progrium/consul
        c862d82a67a2: Pull complete 
                    ...
        5d1cefca2a28: Pull complete 
        Digest: sha256:8cc8023462905929df9a79ff67ee435a36848ce7a10f18d6d0faba9306b97274
        Status: Downloaded newer image for progrium/consul:latest
        d71dfcd5f349d4404d1996aedddc38147c2c4fd2a929242f8c247cd22bfa4a4c

    Run the command `docker ps` to verify that the discovery backend is running. 

2. Create and distribute TLS keys

    To secure the swarm, we need to generate a set of TLS key pairs for the managers and swam nodes. These will be used for the swarm only, by the swarm software containers, and are not to be confused with TLS configuration you may have performed to secure docker client to engine communication. 

        As we probably want to perform this across a set of nodes, for simplicity, the following script collects all relevant operations for node configuration, such that executing `configure-b2d-swarm NODENAME ca.pem ca-priv-key.pem` will configure the node NODENAME:

    ```bash
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
    ```

    If you have followed the steps outlined, you now have compatible certificates installed on all machines, with the certificate authority that generated these certificates trusted by all machines. We are now ready to run the swam software on our nodes, using these certificates to secure host-to-host communication.

2. Create swarm managers.

    In a production environment, you should create two swarm managers and configure them to work together to maintain the cluster. So lets do this. We will create a primary manager on the `docker-machine` node (note that this must be a node in the SCSSNebula cloud) and a secondary manager on the `registry` node (also an SCSSNebula node).

    Login to your `docker-machine` node (or select a docker host to act as swarm master manager) and perform the following:

        $ export IPADR=$(ifconfig eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
        # $ docker run -d --restart=always --name=swarm_mgr -p 4000:4000 swarm manage -H :4000 --replication --advertise $IPADR:4000 consul://$(docker-machine ip registry):8500

        $ docker run -d --restart=always --name=swarm_mgr -p 4000:4000 -v /var/lib/boot2docker/swarm-certs:/server:ro swarm manage --tlsverify --tlscacert=/server/ca.pem --tlscert=/server/cert.pem --tlskey=/server/key.pem --host=0.0.0.0:4000 --replication --advertise $IPADR:4000 consul://$(docker-machine ip registry):8500
            ....
        $ docker ps
        CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                              NAMES
        fb8feaa84042        swarm               "/swarm manage -H :40"   2 minutes ago      Up 2 minutes       2375/tcp, 0.0.0.0:4000->4000/tcp   swarm_mgr

    The first command retrieves the IP address of the machine and sets and environment variable which is then used in the command to create the swarm manager. Recall that our discovery service is running on the `registry` node, and this is why the ip of that node is used to configure the consul parameter. The `docker ps` command lists the running swarm manager process. 

    Next we will create a second swarm manager on the registry node (the same node that incidentally on which we have the discovery backend running). On the docker-machine node, execute the following:

        $ eval $(docker-machine env registry)
        # $ docker run -d --restart=always --name=swarm_bck_mgr -p 4000:4000 swarm manage -H :4000 --replication --advertise $(docker-machine ip registry):4000 consul://$(docker-machine ip registry):8500

        $ docker run -d --restart=always --name=swarm_bck_mgr -p 4000:4000 -v /var/lib/boot2docker/swarm-certs:/server:ro swarm manage --tlsverify --tlscacert=/server/ca.pem --tlscert=/server/cert.pem --tlskey=/server/key.pem --host=0.0.0.0:4000 --replication --advertise $(docker-machine ip registry):4000 consul://$(docker-machine ip registry):8500


        $ docker ps
        CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                                                                            NAMES
        6274fa6384a8        swarm               "/swarm manage -H :40"   1 seconds ago       Up 2 seconds        2375/tcp, 0.0.0.0:4000->4000/tcp                                                 swarm_bck_mgr
        d71dfcd5f349        progrium/consul     "/bin/start -server -"   35 minutes ago      Up 35 minutes       53/tcp, 53/udp, 8300-8302/tcp, 8400/tcp, 8301-8302/udp, 0.0.0.0:8500->8500/tcp   consul
        9ae624d42b58        registry:2          "/entrypoint.sh /etc/"   5 hours ago         Up 5 hours          0.0.0.0:443->5000/tcp                                                            registry


    We now have two managers and a discovery backend service running. Next, we will add our worker nodes to the swarm.

2. Join each docker worker machine to the swarm cluster by executing the following command, once for each worker machine, replacing _MACHINE_NAME_ with the docker-machine name of the relevant worker node. Note that these commands are run from the docker-machine node in each case. We use the `eval $(docker-machine env MACHINE_NAME)` command to configure our local docker engine client to communicate with the remote node's docker engine. Note that we configure each swarm member to use the swarm certificates we have deployed to the host. 

    _Be sure to specify TCP port 2376 and not 2375: we are using TLS based access. ???_

        $ eval $(docker-machine env MACHINE_NAME)
        $ docker run --restart=always -d -v /var/lib/boot2docker/swarm-certs:/server:ro swarm join --discovery-opt kv.cacertfile=/server/ca.pem --discovery-opt kv.certfile=/server/cert.pem --discovery-opt kv.keyfile=/server/key.pem --host=0.0.0.0:4000 --advertise=$(docker-machine ip MACHINE_NAME):4000 consul://$(docker-machine ip registry):8500
                    ...
        $ docker ps
        CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
        f58c9796faf2        swarm               "/swarm join --advert"   4 seconds ago       Up 5 seconds        2375/tcp            suspicious_noyce

    _Recall that this communication operates over a secure TLS channel and that the primary advantage of docker-machine to us here is to manage this aspect of client/server communication for us. If you have not used docker-machine to build your nodes, then you will have to manually configure your docker engine client, providing it with the appropriate TLS certificates and so forth, by manual environment variable setting. This is error prone. You could alternatively login to each node in turn and perform the `docker run` command locally using that node's docker engine client. However, generally we try to avoid having to manually login to machines to perform actions as this approach is hard automate in scripts: far better in general to manage your systems from a centralised point. Draw your own conclusions._
    
We now have a set of worker machines registered to a docker swarm.

## 7.2 Start and test the swarm manager ##
Start the swarm manager on your master machine with the following command to launch a new container with TLS enabled:

    $ docker run -d -p 3376:3376 -v /etc/docker/ssl:/server:ro swarm manage --tlsverify --tlscacert=/server/ca.pem --tlscert=/server/cert.pem --tlskey=/server/key.pem --host=0.0.0.0:3376 token://$TOKEN

The command above launches a new container based on the swarm image and it maps port 3376 on the server to port 3376 inside the container. This mapping ensures that Docker Engine commands sent to the host on port 3376 are passed on to port 3376 inside the container. The container runs the Swarm manage process with the --tlsverify, --tlscacert, --tlscert and --tlskey options specified. These options force TLS verification and specify the location of the Swarm manager’s TLS keys, which we point to those we previously created in `/etc/docker/ssl` for the docker service on the master (we are following a policy of having a single set of TLS keys for each virtual machine's docker service, and all containers running within it. We could instead choose to have unique TLS keys for each installed container, but that would be overkill here).

Next run `docker ps` to verify the swarm manager is running:

````bash
$ docker ps
CONTAINER ID   IMAGE               COMMAND                  CREATED          STATUS          PORTS                              NAMES
035dbf57b26e   swarm               "/swarm manage --tlsv"   7 seconds ago    Up 7 seconds    2375/tcp, 0.0.0.0:3376->3376/tcp   compassionate_lovelace
````

We now have a swarm cluster, configured to use TLS. Next, we will test the configuration. 

## 7.3 Test the swarm ##

Lets try to use our cluster. On the master, type the following:

````bash
$ docker -H tcp://127.0.0.1:3376 version
Client:
 Version:      1.9.1
 API version:  1.21
 Go version:   go1.4.2
 Git commit:   a34a1d5
 Built:        Fri Nov 20 13:12:04 UTC 2015
 OS/Arch:      linux/amd64

Server:
 Version:      swarm/1.0.1
 API version:  1.21
 Go version:   go1.5.2
 Git commit:   744e3a3
 Built:
 OS/Arch:      linux/amd64
````

Note the port number `3376`, which is the port number of the docker swarm container that we launched on the local docker engine. The local docker engine continues to accept connections on port `2376`. Do not confuse the two.

The output above shows the Server version as “swarm/1.0.1”. This means that the command was successfully issued against the Swarm manager. If instead, you get a response like:

````bash
$ docker -H tcp://127.0.0.1:3376 version
:
 Version:      1.9.1
 API version:  1.21
 Go version:   go1.4.2
 Git commit:   a34a1d5
 Built:        Fri Nov 20 13:12:04 UTC 2015
 OS/Arch:      linux/amd64
Get http://127.0.0.1:3376/v1.21/version: malformed HTTP response "\x15\x03\x01\x00\x02\x02".
* Are you trying to connect to a TLS-enabled daemon without TLS?
````

then you do not have TLS enabled for the master machine docker client. Perhaps you did not persist the DOCKER_TLS_VERIFY, DOCKER_CERT_PATH, and DOCKER_HOST environment variables from a previous step. Consult the documentation above regarding configuring TLS or try instead the following alternative command form, which provides values for these variables on the command line:

````bash
$ docker --tlsverify --tlscacert=~/.docker/ca.pem --tlscert=~/.docker/cert.pem --tlskey=~/.docker/key.pem -H tcp://127.0.0.1:3376 version
````

_Note that if you were to perform these commands on a TLS enabled client machine (your laptop perhaps), then you would replace `127.0.0.1` in the aforementioned commands with the IP address of the master machine. In general if DOCKER_HOST is set, then you do not need to include the `-H tcp://a.b.c.d:n` option (unless you wish to override the environment variable setting)._

## Deploy a container to the swarm ##

Now that we have a fully functional docker swarm, it remains to run some simple containers on the swarm and observe the load balancing of docker swarm in action. We will address all further commands to the master node's docker engine. You can achieve this by logging into this machine, or any other with TLS enabled network access to the master, and ensuring that the docker client is directed to communicate with the master's docker swarm manager, either by setting the environment variable DOCKER_HOST or setting a `-H` command line option as described above. In the following we will assume the DOCKER_HOST variable is set correctly.

*Note though, that we wish to communicate with the docker swarm on port `3376` and not the local docker engine on port `2376`.* 

Docker swarm has the same API as the normal docker engine, so we can run containers on the swarm in the same way that we run containers on the local docker engine:

    $ docker run hello-world
    Hello from Docker!
    This message shows that your installation appears to be working correctly.

    To generate this message, Docker took the following steps:
     1. The Docker client contacted the Docker daemon.
     2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
     3. The Docker daemon created a new container from that image which runs the
        executable that produces the output you are currently reading.
     4. The Docker daemon streamed that output to the Docker client, which sent it
        to your terminal.

     To try something more ambitious, you can run an Ubuntu container with:
      $ docker run -it ubuntu bash

     Share images, automate workflows, and more with a free Docker Hub account:
      https://hub.docker.com

     For more examples and ideas, visit:
      https://docs.docker.com/engine/userguide/

Now we will examine where this ran. run `docker ps -a` and you will see an output similar to this, which shows that hello-world was run on a specific node:

````bash
$ docker ps -a
CONTAINER ID        IMAGE                COMMAND                CREATED             STATUS                     PORTS                                     NAMES
54a8690043dd        hello-world:latest   "/hello"               22 seconds ago      Exited (0) 3 seconds ago                                             worker-1/modest_goodall     
78be991b58d1        swarm:latest         "/swarm join --addr    5 minutes ago       Up 4 minutes               2375/tcp                                  worker-2/swarm-agent        
da5127e4f0f9        swarm:latest         "/swarm join --addr    8 minutes ago       Up 8 minutes               2375/tcp                                  worker-1/swarm-agent                
45821ca5208e        swarm:latest         "/swarm manage --tls   18 minutes ago      Up 18 minutes              2375/tcp, 192.168.99.104:3376->3376/tcp   swarm-master/swarm-agent-master   

````
Notice the output, which is different from that generated when we run the command against the local docker engine. Here the listing includes information about execution over docker hosts in the pool. Try running a few more docker containers and observe the evolution of the container deployment.Notice also the swarm containers running on our nodes. We ran these up earlier in the process. 



