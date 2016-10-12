# 4 Running containers on Docker hosts#

We next move to consideration of how to run docker containers on sets of docker hosts that we create on the SCSSNebula cloud. We can always login to a node and execute `docker run` commands at the command line, but frankly this is a tedious option. Docker has been built around a client/server model. The docker command line tool in fact communicates with the Docker daemon service over a network socket. This means that we can use the docker client with remote docker daemons if we wish. However, to do so requires the service and docker client to be appropriately configured to use a form of authentication called TLS certification. 

If you created your nodes using `docker-machine` then this is handled for you and you have little to do but learn how to use `docker-machine` in conjunction with your docker client. If you choose to create your docker hosts using one of the various UIs, then you must configure TLS yourself.We discuss each process in turn.

## 4.1 Running containers on docker hosts, the docker-machine way###
In the previous section, we ran a container on a new docker host provisioned via `docker-machine` by logging into the host and running a container using `docker run` on the command line. However, because we used `docker-machine` to create the node there is a far more efficient elegant way to manage container execution on all docker hosts we create, all from the command line of the `docker-machine` node.

Log out of your virtual machine and login to your docker-machine node. perform the following command, which lists the available docker hosts you have created. A sample output follows:

    $  docker-machine ls
    NAME       ACTIVE   DRIVER       STATE     URL                     SWARM   DOCKER    ERRORS
    test     -        opennebula   Running   tcp://10.63.0.28:2376           v1.10.2   

This shows a single docker host, named test. `docker-machine` keeps track of all docker hosts you create on the cloud, making it very easy to interact with them via the local `docker` client. Now lets first use `docker-machine` to initialise the necessary environment variables to point the local `docker` tool to that host and invoke a container on that node. 

*GOTCHA: Note that when accessing a remote docker engine with your docker client, you can get an error that reports that your docker client version is out of step with your docker engine version. This can be resolved by setting the environment variable `DOCKER_API_VERSION` on the client machine, with the value of the reported server engine version number. Provided the client is at least as up to date as the server, this will work. If the client is out of date, upgrade your installation.*

*GOTCHA 2: make sure that you do not have `HTTP_PROXY` environment variable set when running this command, as it will pick it up if set and attempt to access the target docker server via the configured proxy.*

    $  eval $(docker-machine env test)     # points docker tool to docker host 'test'
    $  export DOCKER_API_VERSION=1.22      # if running a docker command returns an API error
    $  docker ps -a
    CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS                     PORTS               NAMES
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
    $ docker ps -a
    CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS                     PORTS               NAMES
    7fa3e8fa9e64        hello-world         "/hello"            2 minutes ago       Exited (0) 2 minutes ago                       hopeful_chandrasekhar

In summary, if you use `docker-machine` to create your docker hosts on the SCSSNebula cloud, then you can control them relatively easily from your `docker-machine` host.
        
## 4.2 Running containers on docker hosts, without docker-machine ##

By default, the Docker daemon does not support authentication/authorisation for its API, which makes it problematic to expose a Docker host's API to the network and deploy container across a set of distributed docker hosts. To solve this, Docker supports TLS certificates to provide proof of identity, thus allowing you to make the docker service network accessible without giving over root user or docker user credentials. It also provides for encryption of all traffic between servers and authenticated clients. 

In this section we explain a process for configuring a set of docker hosts to support host to host network authentication, essentially mimicking the processes that `docker-machine` otherwise performs for us. If you have chosen to create your docker hosts individually without using `docker-machine` then you must follow these steps to enable remote access to docker hosts by the docker client. You must also maintain your own lists of relevant machine details as you must configure the `docker` client via environment variables to target any particular machine. So, if you plan to create and manage multiple docker hosts, `docker-machine` is the recommended tool to use. If you have relatively few machines to manage, then the following explains how to proceed.

### 4.2.1 Creating a Certificate Authority ###

The following steps demonstrate how to enable a Docker installation to operate using TLS certificates. These instructions presume you have a set of nodes that you want to enable communication between. Unless noted otherwise, we presume that you are logged in to an SCSSNebula node that we refer to as the _master_ node. The master node is presumed to have docker installed, and as we proceed, this node will become the key administrative node for a set of docker enabled virtual machines. Create or select a node to act as your master node and login now.

1. Create client certificates

    First we create the client certificates and use a Docker volume binding to put them into the `~/.docker` directory. To do this we will use a docker based _Self Signed SSL Certificate Generator_ that will act as an internal CA (certificate authority) for us. Note that if you have access to an existing certificate authority, then you can use it to generate certificates, and in all other respects follow along with the process.  _Note that in a production system, the certificate authority should probably not be a publicly accessible server._

    At the command prompt on your master node, type the following

        $ mkdir $(pwd)/.docker
        $ docker run --rm -v $(pwd)/.docker:/certs paulczar/omgwtfssl
        ----------------------------
        | OMGWTFSSL Cert Generator |
        ----------------------------

        --> Certificate Authority
        ====> Using existing CA Key ca-key.pem
        ====> Using existing CA Certificate ca.pem
        ====> Generating new config file openssl.cnf
        ====> Generating new SSL KEY key.pem
        Generating RSA private key, 2048 bit long modulus
        .............+++
        ..........+++
        e is 65537 (0x10001)
        ====> Generating new SSL CSR key.csr
        ====> Generating new SSL CERT cert.pem
        Signature ok
        subject=/CN=example.com
        Getting CA Private Key

    Move the Certs and change ownership of the `~/.docker` directory.

        $ sudo cp ~/.docker/ca.pem /etc/docker/ssl/ca.pem    # the certificate authority pem file
        $ chown -R $USER ~/.docker

2. Create server certificates

    Now that we have the docker client TLS certificates created and installed, we can create the certificates for the docker server, using the same CA `pem` file. We do this in the following command with a volume binding to `/etc/docker/ssl`, which we run on the master node. Modify the SSL_IP value to include the full list of IP addresses that you will want to be able to access the Docker server (replacing `a.b.c.d` below with a comma separated list of IP addresses, with no whitespace interjected):

        $ docker run --rm -v /etc/docker/ssl:/server -v $(pwd)/.docker:/certs -e SSL_IP=127.0.0.1,a.b.c.d -e SSL_DNS=docker.local -e SSL_KEY=/server/key.pem  -e SSL_CERT=/server/cert.pem paulczar/omgwtfssl
        ----------------------------
        | OMGWTFSSL Cert Generator |
        ----------------------------

        --> Certificate Authority
        ====> Using existing CA Key ca-key.pem
        ====> Using existing CA Certificate ca.pem
        ====> Generating new config file openssl.cnf
        ====> Generating new SSL KEY /server/key.pem
        Generating RSA private key, 2048 bit long modulus
        .................................+++
        ..................+++
        e is 65537 (0x10001)
        ====> Generating new SSL CSR key.csr
        ====> Generating new SSL CERT /server/cert.pem
        Signature ok
        subject=/CN=example.com
        Getting CA Private Key

3. Use the TLS certificates with Docker

    Open or create the file  `/etc/default/docker` and add the following:

        DOCKER_OPTS="-H=0.0.0.0:2376 -H unix:///var/run/docker.sock --tlsverify --tlscacert=/etc/docker/ssl/ca.pem --tlscert=/etc/docker/ssl/cert.pem --tlskey=/etc/docker/ssl/key.pem"

    Now restart docker with 

        $ /etc/init.d/docker restart

    That script calls `/etc/default/docker` and thus starts docker with TLS enabled. The server is now expecting TLS requests over port 2367. If we wanted, we could force even local docker clients to use TLS by removing the second `-H unix:///var/run/docker.sock` configuration. 

    Test that your docker client on the master machine _cannot_ yet access there server via TLS (as we have not yet configured it) as follows:

        $ docker -H tcp://127.0.0.1:2376 info
        Get http://127.0.0.1:2376/v1.21/containers/json: malformed HTTP response "\x15\x03\x01\x00\x02\x02".
        * Are you trying to connect to a TLS-enabled daemon without TLS?

    Now set the following environment variables to configure the docker client to use TLS:

        $ export DOCKER_HOST=tcp://127.0.0.1:2376
        $ export DOCKER_TLS_VERIFY=1
        $ export DOCKER_CERT_PATH=~/.docker

    and test the TLS connection with

        $ docker info
        Containers: 6
         Running: 0
         Paused: 0
         Stopped: 6
        Images: 2
        Server Version: 1.12.0
        Storage Driver: aufs
         Root Dir: /var/lib/docker/aufs
         Backing Filesystem: extfs
               ...

    Note that if you want to make this configuration the default, you will need to set the environment variables in a file such as `~/.bashrc`. 

Your docker service is now running with TLS enabled on port 2376 and is working, and the local docker client is now configured to use TLS to communicate with the service. 

###4.2.2  Remote access via TLS###

We will next configure a second _client_ machine to access the master machine's docker service over the network using TLS (in the following we will presume the client machine is another SCSSNebula node, but it could, for example, be your laptop). To access the docker service on the master, we must generate and deploy TLS certificates to the client machine, and configure the docker client on the client machine to use them:

1. Insure that the client machine can reach the master machine over the network. Login to the client machine and test its access this with a command such as `ping a.b.c.d`, where `a.b.c.d` is replaced with the ip address of the master machine. If the client machine does not have Docker installed, then install it as described above. 

2. Generate a new certificate for the client machine by executing the following on the _master_ machine:

        $ mkdir $(pwd)/docker-client
        $ docker run --rm -v $(pwd)/docker-client:/certs paulczar/omgwtfssl
        ----------------------------
        | OMGWTFSSL Cert Generator |
        ----------------------------

        --> Certificate Authority
        ====> Using existing CA Key ca-key.pem
        ====> Using existing CA Certificate ca.pem
        ====> Generating new config file openssl.cnf
        ====> Generating new SSL KEY key.pem
        Generating RSA private key, 2048 bit long modulus
        .............+++
        ..........+++
        e is 65537 (0x10001)
        ====> Generating new SSL CSR key.csr
        ====> Generating new SSL CERT cert.pem
        Signature ok
        subject=/CN=example.com
        Getting CA Private Key

    The directory `$(pwd)/docker-client` now has three certs, that you will need to transfer to the client machine (detailed in the next step):

        ca.pem          # The Certificate Authority's public key
        cert.pem        # A certificate signed by the CA. One half of the node's key pair.
        key.pem         # A private key signed by the CA. The other half of the node's key pair.

    We performed this action on the server machine because this is where we created the original certificate authority and server certificates via our command line docker certificate generation tool. The server certificates and the client machine certificates must be created by the same certificate authority for TLS access to be granted: _possession_ of appropriately signed client certificates gives access to the server.

3. copy the contents of `$(pwd)/docker-client` (specifically, `ca.pem`, `cert.pem` and `key.pem`) from the master machine to the user's `~/.docker` directory on the client machine, by executing the following commands (where `a.b.c.d` is replaced with the ip address of the client machine and _USER_ is replaced by the account name on the client machine):

        $ ssh USER@a.b.c.d mkdir -p .docker
        $ cat $(pwd)/docker-client/ca.pem | ssh USER@a.b.c.d 'cat >> .docker/ca.pem'
        $ cat $(pwd)/docker-client/cert.pem | ssh USER@a.b.c.d 'cat >> .docker/cert.pem'
        $ cat $(pwd)/docker-client/key.pem | ssh USER@a.b.c.d 'cat >> .docker/key.pem'

    If you have previously set up [[ssh passwordless access]] from the server machine to the client machine, then you will not have to enter a password to complete these commands. If you are prompted for a password, you must provide the password for the docker account on the _client_ machine.

    You can now delete the directory `$(pwd)/docker-client` on the server machine:

        $ rm -rf $(pwd)/docker-client

    _Note: Ideally, you should create a fresh set of client certificates for each machine that you wish to give client access to the server machine. This necessitates repeating the process described so far for each machine. A shortcut is to reuse the certificates generated in `$(pwd)/docker-client` by generating once and copying them to each client machine. *Do not* do this in anything other than a test/sandbox environment. Note also that if you are deploying to a production environment, then you should use a production quality certificate authority and process, rather than the method described here, and should consult appropriate documentation and understand TLS authentication in detail._

4. Login to the client machine, and set the following environment variables to configure the docker client to use TLS (performing this configuration in the appropriate shell configuration file such as `~/.bashrc` if you wish the configuration to persist, and replacing a.b.c.d with the IP address of the client machine):

        $ export DOCKER_HOST=tcp://a.b.c.d:2376
        $ export DOCKER_TLS_VERIFY=1
        $ export DOCKER_CERT_PATH=~/.docker

5. test the TLS connection by logging into the client machine and then executing:

        $ docker info
        Containers: 6
         Running: 0
         Paused: 0
         Stopped: 6
        Images: 2
        Server Version: 1.12.0
        Storage Driver: aufs
         Root Dir: /var/lib/docker/aufs
         Backing Filesystem: extfs
               ...



Your client machine can now invoke docker on the docker server machine, as a remote docker client. Note that we did not configure the docker server running on the client machine to use TLS, as our focus here was configuring for access to the server machine so as to be able to launch containers on it.

### 4.2.3 Master node access to Worker Dockers###

Rather than give a remote client access to docker on the master machine as we have just done, you may wish to give an account on the master machine access to docker services running on a set of remote machines (which we will henceforth refer to as _workers_, building obviously towards a master-worker distributed architectural pattern in which we control execution of containers over a set of worker nodes from a central master node). 

To achieve this, we need to configure the docker servers on each worker machine to use a server certificate that has been signed by the same CA as our client certificates. For each remote worker you wish to gain TLS access to, perform the following.

_Note that if you are deploying to a production environment, then you should use a production quality certificate authority and process, rather than the method described here, and should consult appropriate documentation and understand TLS authentication in detail._

1. On the master machine, generate a certificate set for the each worker by executing the following (where _N_ is replaced with 1,2,3... for the set of workers you wish to configure, and _a.b.c.d_ is replaced with the master machine ip address):

        $ mkdir $(pwd)/docker-server-N       # we will put the certificates here
        $ docker run --rm -v $(pwd)/docker-server-N:/server -v $(pwd)/.docker:/certs -e SSL_IP=127.0.0.1,a.b.c.d -e SSL_DNS=docker.local -e SSL_KEY=/server/key.pem  -e SSL_CERT=/server/cert.pem paulczar/omgwtfssl
        ----------------------------
        | OMGWTFSSL Cert Generator |
        ----------------------------

        --> Certificate Authority
        ====> Using existing CA Key ca-key.pem
        ====> Using existing CA Certificate ca.pem
        ====> Generating new config file openssl.cnf
        ====> Generating new SSL KEY /server/key.pem
        Generating RSA private key, 2048 bit long modulus
        .................................+++
        ..................+++
        e is 65537 (0x10001)
        ====> Generating new SSL CSR key.csr
        ====> Generating new SSL CERT /server/cert.pem
        Signature ok
        subject=/CN=example.com
        Getting CA Private Key

2. For each worker machine, copy the certificates to the worker machine (in the following `a.b.c.d` represents the worker's ip address:

        $ ssh docker@a.b.c.d mkdir -p /etc/docker/ssl
        $ cat  $(pwd)/docker-server-N/ca.pem | ssh docker@a.b.c.d 'cat >>  /etc/docker/ssl/ca.pem'
        $ cat  $(pwd)/docker-server-N/cert.pem | ssh docker@a.b.c.d 'cat >> /etc/docker/ssl/cert.pem'
        $ cat  $(pwd)/docker-server-N/key.pem | ssh docker@a.b.c.d 'cat >>  /etc/docker/ssl/key.pem'

3. Login to each worker machine in turn, and configure each worker machine's Docker service to use TLS with the deployed certificates, by opening or creating the file  `/etc/default/docker` and adding the following:

        DOCKER_OPTS="-H=0.0.0.0:2376 -H unix:///var/run/docker.sock --tlsverify --tlscacert=/etc/docker/ssl/ca.pem --tlscert=/etc/docker/ssl/cert.pem --tlskey=/etc/docker/ssl/key.pem"

    The docker service must be restarted for this configuration to take effect:

        $ /etc/init.d/docker restart

If we complete the steps described above, our master machine will be able to invoke docker commands on any of our workers by performing the following (again where `a.b.c.d` is replaced with the ip address of the target worker machine):

    $ export DOCKER_HOST=tcp://a.b.c.d:2376
    $ export DOCKER_TLS_VERIFY=1
    $ export DOCKER_CERT_PATH=~/.docker
    $ docker info
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


This is useful, but as we have seen, Docker provides `docker-machine`, a more comprehensive and less cumbersome approach to managing the creation and configuration of docker hosts, and the execution of containers over sets of such hosts. 



