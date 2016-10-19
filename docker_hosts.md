# 4 Running containers on Docker hosts with docker-machine#

We next move to consideration of how to run docker containers on sets of docker hosts that we create on the SCSSNebula cloud. We can always login to a node and execute `docker run` commands at the command line, but frankly this is a tedious option. Docker has been built around a client/server model. The docker command line tool in fact communicates with the Docker daemon service over a network socket. This means that we can use the docker client with remote docker daemons if we wish. However, to do so requires the service and docker client to be appropriately configured to use a form of authentication called TLS certification. 

If you created your nodes using `docker-machine` then this is handled for you and you have little to do but learn how to use `docker-machine` in conjunction with your docker client. If you choose to create your docker hosts using one of the various UIs, then you must configure TLS yourself.We discuss each process in turn.

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



