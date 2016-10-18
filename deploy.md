# 5 Deploying your containers to Docker #

Now that we have a Docker based development workflow in place, and Docker hosts deployed in the SCSSNebula cloud, the final step is to automate the deployment of your docker containers to our cloud instances.

When you execute a command such as `docker run hello-world`, docker retrieves the container image from a docker registry, the default registry being _Docker Hub_. To deploy your projects as containers run in the same way, you must first create the image, register the image with a registry of your choice, and then execute the appropriate `docker run your-project-container` command to install and launch that container on the docker host.

You will recall that we added docker support to our Yesod projects by modifying the `stack.yaml` file. This caused our project to be built and executed within a docker container. To generate a Yesod docker container image that we can deploy to our docker hosts, add the following to your project's `stack.yaml` file.

    # Generate a Docker image
    image:
      container:
        # New image will be called registry-account-name/myapp - adjust as required for your registry (see step 3)
        name: your registry-account-name/myapp
        # Base it on the stack-run images
        base: fpco/stack-run
        # Include some config and static files in the image
        add:
          config: /app/config
          static: /app/static


With this in place, you can generate a container image by running `stack image container` on the command line in the project home directory. Once you have an image you can push it to a registry. There are two basic choices. You can push to _Docker Hub_ or a similar third party registry, or you can create your own registry. We examine each case in turn.


##Using DockerHub##

Go to [Docker Hub](http://dockerhub.com) and create an account, or alternatively go to some other Docker compatible registry service and create an account. 

With an account created, you can now push that image to a docker registry using standard docker commands. Note that you can name your image as you like, so long as the name matches the appropriate pattern for your registry. So, for _Docker Hub_, the name should match the pattern `registry-account-name/image-name`.

    $ docker push registry-account-name/myapp  # modify push parameter as approptiate

To run the image on a docker host, login to the host of initialise your docker client with environment variables appropriately, and type:

    $ docker run registry-account-name/myapp

That is all there is to it if you are happy to use _Docker Hub_, or an equivalent registry service. 

##Running your own registry##

If you want instead to use your own registry server, you can do so via a docker registry container that can be run on a local docker host. This is a good option for keeping uploads and downloads to a minimum and for controlling who can access your containers (At time of writing, _Docker Hub_ provides unlimited storage for public containers, but requires a paying subscription to maintain more than one private container). 

To install a registry server, choose a docker host to be your registry. Be sure to provision a reasonably sized disk - this registry must hold container images. We will use this machine to launch the docker registry as a container, but before we do so, we must configure how registry clients will access the registry remotely.


1. Authorising remote access to the registry

    First, we will deal with remote access to the registry, so that the docker daemon running on other virtual machines can access our registry. We will refer to these docker daemons as _clients_ in the following. There are two methods of access: the choices being either secured via TLS certification, or unsecured. We consider each in turn, noting that unsecured access is a quick fix and should _never_ be used in production systems. 

    1. To configure for secure TLS access, you need to copy the appropriate registry certificate from the registry host to the client and place in the correct location. 

        If we created docker hosts with `docker-machine`, then that tool created a certificate authority for TLS authentication between the docker host and the docker-machine node, and copied the necessary keys and certificates into the directory `~/.docker/machine/machines/MACHINE_NAME` on the `docker-machine` node. We will use these certificates to configure our new registry. _Note that in a production environment, we should create a new registry certificate specific to the registry service, rather than reuse the certificates held by docker-machine for docker client communication. We are reusing the certificates held by docker-machine as a short-cut._

        For a _boot2docker_ based host, execute the following commands, replacing CLIENT_NAME and REGISTRY_NAME appropriately. These commands copy the certificate authority `ca.pem` associated with the registry machine to the client machine and places it in a persisting directory so that the certificate weill be incorporated intot he _boot2docker_ nodes configuration at boot-time:

            $ docker-machine ssh CLIENT_NAME "sudo mkdir -p /var/lib/boot2docker/certs"
            $ cat ~/.docker/machine/machines/REGISTRY_NAME/ca.pem | docker-machine ssh CLIENT_NAME "sudo sh -c \"cat - > /var/lib/boot2docker/certs/registry.pem\""
            $ docker-machine restart CLIENT_NAME

        As you will need to perform this configuration for every docker host that you wish to provide secure client access to, it is probably worth saving the following script as `docker-configure-registry`:

            echo "Configuring node $1 for TLS access to registry $2"

            if [ "$#" -ne 2 ] ; then
              echo "Usage: $0 REGISTRY_NAME MACHINE_NAME" >&2
              echo "    Configures the machine with TLS access to the given registry." >&2
              exit 1
            fi

            docker-machine ssh $2 "sudo mkdir -p /var/lib/boot2docker/certs"
            cat ~/.docker/machine/machines/$1/ca.pem | docker-machine ssh $2 "sudo sh -c \"cat - >> /var/lib/boot2docker/certs/registry.pem\" && sudo reboot"
            echo "Configuration complete."

         For a _non_boot2docker_ host, execute the following script on your `docker-machine` node, replacing CLIENT_NAME and REGISTRY_NAME appropriately. These commands copy the `ca.pem` certificate authority file from the registry machine to the client machine, storing it in the appropriate place in the standard `/etc/docker/certs.d` directory as `ca.crt`:

            $ docker-machine ssh REGISTRY_NAME 'cat ~/.docker/ca.pem' | docker-machine ssh CLIENT_NAME "sudo mkdir -p /etc/docker/certs.d/$(docker-machine ip REGISTRY_NAME) && sudo sh -c \"cat - >> /etc/docker/certs.d/$(docker-machine ip REGISTRY_NAME)/ca.crt\""

        As you will need to perform this configuration for every docker host you wish to provide secure access, it is probably worth saving the following script as `docker-configure-registry`, or else integrating the commands below into your `docker-configure` script:

            echo "Configuring node $1 for TLS access to registry $2"

            if [ "$#" -ne 2 ] ; then
              echo "Usage: $0 REGISTRY_NAME MACHINE_NAME" >&2
              echo "    Configures the machine with TLS access to the given registry." >&2
              exit 1
            fi

            docker-machine ssh $2 'cat ~/.docker/ca.pem' | docker-machine ssh $1 "sudo mkdir -p /etc/docker/certs.d/$(docker-machine ip $2) && sudo sh -c \"cat - >> /etc/docker/certs.d/$(docker-machine ip $2)/ca.crt\""
            echo "Configuration complete"

        This completes the configuration step for a docker host, assuming you created the host and registry host using `docker-machine`. 

        If you created the various hosts individually, then you will need to configure TLS authentication manually. You must create a certificate authority, and then create and distribute the appropriate certificate files to both the registry host and the client docker hosts. Consult the sections entitled _4.2 - Creating a Certificate Authority_ and _4.2.2 - Remote access via TLS_ for guidance and seek broadly to mimic the process described in this section. 

        FINISH: decide on whether to include more detailed instructions here on how to create TLS certification from scratch.

    
    2. To configure for insecure access, on each client set the `--insecure-registry=a.b.c.d:5000` option as a starting option on the client docker engine, replacing `a.b.c.d` with the registry's IP address, by one of the following methods:

        1. If your docker host is a _boot2docker_ based host, then add the following to the end of `/var/lib/boot2docker/profile`:
            EXTRA_ARGS="$EXTRA_ARGS --insecure-registry=a.b.c.d:5000"

        2. Otherwise add the following to the file (create if necessary) `/etc/default/docker` 

            DOCKER_OPTS="$DOCKER_OPTS --insecure-registry=a.b.c.d:5000"


2. Installing a registry

    Now that we have decided on and configured an access model, we must run the registry container. We will use a standard container provided by Docker from _Docker Hub_.

    1. Launch as a secure registry.

        Assuming that your registry node was created using `docker-machine`, begin by copying the necessary certificates from the `docker-machine` host to the registry host, placing them in a directory `/var/lib/boot2docker/registry-certs. 

        Note that we are in effect reusing the registry certificates established for docker-machine/registry-host communication for registry-client-registry communication. If you choose instead to create a fresh certificate pair, for example, if your nodes were not created using `docker-machine` or if you have decided to establish a more production quality deployment, then you would instead copy those certificate, key and CA files to the registry host in the following instructions, rather than reuse the existing certificate files:

            $ docker-machine ssh REGISTRY_MACHINE "sudo mkdir -p /var/lib/boot2docker/registry-certs"
            $ cat ~/.docker/machine/machines/REGISTRY_MACHINE/server.pem | docker-machine ssh REGISTRY_MACHINE "sudo sh -c \"cat - > /var/lib/boot2docker/registry-certs/registry.pem\""
            $ cat ~/.docker/machine/machines/REGISTRY_MACHINEy/server-key.pem | docker-machine ssh REGISTRY_MACHINE "sudo sh -c \"cat - > /var/lib/boot2docker/registry-certs/registry-key.pem\""
            $ cat ~/.docker/machine/machines/REGISTRY_MACHINE/ca.pem | docker-machine ssh REGISTRY_MACHINE "sudo sh -c \"cat - > /var/lib/boot2docker/registry-certs/ca.pem\""

        With the certificates installed on the registry host, next login and start the registry container, configuring it to use the TLS files we just copied to that node:

            $ docker-machine ssh REGISTRY_MACHINE
            $ docker run -d -p 443:5000 --restart=always --name registry -v /var/lib/boot2docker/registry-certs:/certs -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/registry.pem -e REGISTRY_HTTP_TLS_KEY=/certs/registry-key.pem -v /var/lib/boot2docker/registry-data:/var/lib/registry -e REGISTRY_HTTP_TLS_CLIENTCAS_0=/certs/ca.pem registry:2

        Logout of the registry server, returning back to the `docker-machine`. Next execute the following to test the registry:

            $ curl --cacert ~/.docker/machine/machines/REGISTRY_MACHINE/ca.pem https://$(docker-machine ip REGISTRY_MACHINE)/v2/
            {}$                # if you see this output then TLS authentication is working.

        If you are not using `docker-machine` then login to any machine on which you store a copy of the `ca.pem` file associated with the certificate authority that generated the registry certificates, and perform the same text. 


        You have now a 'secure' registry running, but note that this security is restricted to the client being able to validate the identity of the registry. It does not prevent registry clients who do not care about this identity validation from accessing the registry. To see this login a node that you have not configured and attempt the following:

            $ docker run a.b.c.d/hello-world
            Unable to find image 'a.b.c.d/hello-world:latest' locally
            docker: Error response from daemon: unable to ping registry endpoint https://10.63.0.90/v0/
            v2 ping attempt failed with error: Get https://10.63.0.90/v2/: x509: certificate signed by unknown authority
             v1 ping attempt failed with error: Get https://10.63.0.90/v1/_ping: x509: certificate signed by unknown authority.
            See 'docker run --help'.

        The docker client is complaining that the remote registry is not TLS authenticated. However, consider the following curl command, invoked with parameters that ignore certification issues and that retrieves the catalog of images stored by the registry:

            $ curl --insecure -X GET https://a.b.c.d:443/v2/_catalog
            {"repositories":["hello-world"]}

        Thus TLS authentication guarantees identity, but does not restrict registry access. To restrict access, we must add further account configuration to the registry, requiring registry clients to login with an appropriate username/password, or else configure _Docker Token Authentication_. Here is an example of how to do this, first creating a username password combination and then starting the registry to use the password file and require authenticated access. Perform the following on the registry machine (this assuming a boot2docker node - adjust as necessary for other configurations):

            $ mkdir -p /var/lib/boot2docker/registry-auth
            $ docker run --entrypoint htpasswd registry:2 -Bbn testuser testpassword > /var/lib/boot2docker/registry-auth/htpasswd

        Stop and remove your registry from the earlier steps and rerun as follows:

            $ docker stop registry
            $ docker rm registry         # will not delete the associated registry data
            $ docker run -d -p 443:5000 --restart=always --name registry -v /var/lib/boot2docker/registry-certs:/certs -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/registry.pem -e REGISTRY_HTTP_TLS_KEY=/certs/registry-key.pem -v /var/lib/boot2docker/registry-data:/var/lib/registry -e REGISTRY_HTTP_TLS_CLIENTCAS_0=/certs/ca.pem  -v /var/lib/boot2docker/registry-auth:/auth -e "REGISTRY_AUTH=htpasswd" -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm"  -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd registry:2

        The only change is that we have added `-e` configuration options detailing the authenticated access. Now logout of the registry, login to a client node which is configured to use TLS, and perform the following to demonstrate authenticated access:

            $ docker login a.b.c.d              # note that we have not yet logged in so this should fail
            Username: testuser
            Password: 
            Email: accountname@tcd.ie
            Error response from daemon: invalid registry endpoint https://a.b.c.d0/v0/: unable to ping registry endpoint https://a.b.c.d/v0/
            v2 ping attempt failed with error: Get https://a.b.c.d/v2/: Service Unavailable
             v1 ping attempt failed with error: Get https://a.b.c.d/v1/_ping: Service Unavailable. If this private registry supports only HTTP or HTTPS with an unknown CA certificate, please add `--insecure-registry a.b.c.d` to the daemon's arguments. In the case of HTTPS, if you have access to the registry's CA certificate, no need for the flag; simply place the CA certificate at /etc/docker/certs.d/a.b.c.d/ca.crt
            $
            $ docker login a.b.c.d               # now we login
            Username: testuser
            Password: 
            Email: accountname@tcd.ie
            WARNING: login credentials saved in /home/docker/.docker/config.json
            Login Succeeded
            $
            $ docker pull a.b.c.d/hello-world    # this pull attempt should succeed as we are now loged in
            Using default tag: latest
            latest: Pulling from hello-world
            Digest: sha256:0256e8a36e2070f7bf2d0b0763dbabdd67798512411de4cdcf9431a1feb60fd9
            Status: Image is up to date for 10.63.0.90/hello-world:latest

        We now have a secure registry deployed, with access restriction based on username/password combinations. To add additional username/password combinations, perform the following command on the registry machine:

            $ docker-machine ssh REGISTRY_MACHINE
            $ docker run --entrypoint htpasswd registry:2 -Bbn testuser testpassword > /var/lib/boot2docker/registry-auth/htpasswd
            $ docker restart registry

        _Note that if you  create bespoke TLS certification for your registry, then there are ways to configure certificate generation such that access can be further constrained, for example, to sets of client IP addresses. One can also use services such as LDAP and oAuth authentication processes. These methods are beyond the scope of this guide._

    2. Launch as an insecure registry.

        To launch for insecure access, create the registry without the `-e REGISTRY_HTTP_TLS_CLIENTCAS_0=/certs/ca.pem` option:

            $ docker-machine ssh devnostics-registry
            $ docker run -d -p 443:5000 --restart=always --name registry -v /var/lib/boot2docker/registry-certs:/certs -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/registry.pem -e REGISTRY_HTTP_TLS_KEY=/certs/registry-key.pem -v /var/lib/boot2docker/registry-data:/var/lib/registry registry:2

        Logout of the registry server, returning back to the `docker-machine`. Next execute the following to test the registry:

            $ curl http://$(docker-machine ip devnostics-registry)/v2/

        Note that you should never use an insecure registry in a production system.
      
    Your registry is now correctly configured. Note that we have described a configuration for a local repository that is fairly basic. For production, consult [appropriate documentation](https://docs.docker.com/registry/).

3. Using the registry

    Once your registry is up and running, you use it from any authorised node, by pushing and pulling images to and from it. For example, in the following, we obtain a copy of `hello-world` container from docker hub, tag it and push it to our registry. Note that to access our own registry, we prefix the Ip address of the registry host (replacing `a.b.c.d` with an appropriate Ip address):

        $ docker pull hello-world && docker tag hello-world a.b.c.d/hello-world
        $ docker push a.b.c.d/hello-world
        The push refers to a repository [a.b.c.d/hello-world]
        a02596fdd012: Pushed 
        latest: digest: sha256:a18ed77532f6d6781500db650194e0f9396ba5f05f8b50d4046b294ae5f83aa4 size: 524

    With `hello-world` installed in our registry, we can now pull a copy from the registry:

        $ docker pull a.b.c.d/hello-world
        Using default tag: latest
        latest: Pulling from hello-world
        Digest: sha256:a18ed77532f6d6781500db650194e0f9396ba5f05f8b50d4046b294ae5f83aa4 
        Status: Image is up to date for a.b.c.d/hello-world:latest

    We  can get docker to run container from our registry as follows (replacing `a.b.c.d` as usual):

        $ docker run a.b.c.d/hello-world
        Unable to find image 'a.b.c.d/hello-world:latest' locally
        latest: Pulling from hello-world
        c04b14da8d14: Pull complete 
        Digest: sha256:0256e8a36e2070f7bf2d0b0763dbabdd67798512411de4cdcf9431a1feb60fd9
        Status: Downloaded newer image for 10.63.0.90/hello-world:latest

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

    If your local registry does not have the container that you wish to run, you will get an error like so:

        $  docker run a.b.c.d/ubuntu
        Unable to find image 'a.b.c.d/ubuntu:latest' locally
        Pulling repository a.b.c.d/ubuntu
        docker: Error: image ubuntu not found.
        See 'docker run --help'.


