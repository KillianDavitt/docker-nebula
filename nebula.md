## Section 3 - Setting up Docker on SCSSNebula #
Next we move on to configuring servers to deploy your projects.

This section explains how to configure virtual machines running docker, which we will refer to as _docker hosts_, on the SCSSNebula OpenNebula installation. It will explain how to provision two kinds of nodes into SCSSNebula: a fairly standard _Debian_ based linux virtual machine, and a [boot2docker](https://github.com/boot2docker/boot2docker) virtual machine, this being a lightweight linux distribution specifically designed to run Docker containers. 

Debian machines are easier to setup, but boot_2_docker machines are much more scaleable and less resource demanding.

# Create a _Debian_ SCSSNebula docker host ##

First, we create a template of an image so that it will be easy for us to reuse the configuration.

OpenNebula UI is: [here](https://scssnebulaselfservice.scss.tcd.ie) for staff and students

The UI can't be accessed outside of college.

### Create a virtual machine using the newer UI ###

1. Open the [user interface](https://scssnebulaselfservice.scss.tcd.ie).

2. Click on the *Images* sub-menu option (found in the *Virtual Resources* menu), select the `[VM] DebianJessie [Research Ver 1.1]` image, and click the `clone` button. In the revealed pane, give the new image a name. We will use this image for the creation of our first virtual machine, but we will need to configure some files in it, so lets start by building a virtual machine from this image. The image is large so the clone creation will take some time. Next, select the clone you have created from the *Images* list, mark the clone as persistent by selecting the `make persistent` in the revealed panel (select the edit icon and change the value).

3. Next, we must create a Template. Select the *Templates* sub-menu in the *Virtual Resources* menu create a new template. The template system is complex but we will perform a minimal configuration. 
 
    1. On the storage tab, select your cloned image as Disk 0. 

        _Note that you can add multiple disks to a template. However, the image we have cloned is large enough for normal use and so we will not add a second disk._ 

    2. On the Network tab, select the `ResearchNet [routed]` network.

    3. On the Context tab, ensure `Add Network Contextualization` checkbox is selected.

    4. That is sufficient configuration. Create the template. 

4. Now we have a template, we will create a virtual machine. Select the *Virtual Machines* sub-menu option under the *Virtual Resources* menu. Create a new instance and in the dialog box, name it and select the template you just created. Click click `Create`. Again, because the boot2docker image has been designed to be very small, the virtual machine should be created very quickly, and you should not have to wait for its creation to complete. 

5. Your virtual machine should now be created. Try to login with `ssh root@a.b.c.d`, with the appropriate ip address obviously. The ip address of your SCSSNebula nodes are listed on the Compute page. If you used the aforementioned image to create your machine, then the password will be `scssnebula`. Login and change this password immediately by running the `passwd` command. If you used some other image, consult the provider. 


### Install Docker ###
We will now install various Docker tools to our new node.

First, lets make sure the node is up to date:

```bash
apt-get update
apt-get upgrade
apt-get install wget
```

Now, we'll set the tcd proxy settings
```bash
echo "export http_proxy='http://www-proxy.scss.tcd.ie:8080'" >> ~/.bashrc
echo "export https_proxy='https://www-proxy.scss.tcd.ie:8080'" >> ~/.bashrc
```

Now we can install docker...

```bash
wget -qO- https://get.docker.com/ | sh
```

Lets test docker is working.
```bash
docker version
```
You should get some lovely version info.

Docker is installed. However, we do not have Docker configured to access Docker hub, the remote source of docker containers. Let's test the docker installation by running a simple container, expecting the command to not list the following successful output (if it does, you are all set): 

1. First, create a systemd drop-in directory for the docker service:

    mkdir /etc/systemd/system/docker.service.d

2. Now create a file called `/etc/systemd/system/docker.service.d/http-proxy.conf` that adds the HTTP_PROXY environment variable:

        [Service]
        Environment="HTTP_PROXY=http://www-proxy.scss.tcd.ie:8080/"

    If you have internal Docker registries that you need to contact without proxying you can specify them via the `NO_PROXY` environment variable:

        Environment="HTTP_PROXY=http://www-proxy.scss.tcd.ie:8080/"
        Environment="NO_PROXY=localhost,127.0.0.0/8,docker-registry.somecorporation.com"

3. Flush changes:
    ```bash
    sudo systemctl daemon-reload
    ```
4. Verify that the configuration has been loaded:

    ```bash
    sudo systemctl show --property Environment docker
    ```
    Environment=HTTP_PROXY=http://www-proxy.tcd.ie:8080/

5. Restart Docker:
    ```bash
     sudo systemctl restart docker
    ```
Now try rerunning `docker run hello-world` and if everything works, you will see some success messages. 


```bash
docker run hello-world
```
Docker will download the latest image of 'hello-world' for you and run it.

###  Final configuration and baking###

This is probably a good time to enable [[ssh passwordless access]] access to your node, so that you do not need to keep using the username/password combination to login to your new node. 

Your virtual machine is now well configured to act as a docker virtual machine and run docker containers in the SCSSNebula cloud. To avoid having to repeat these steps in the future, it is sensible to now bake the virtual machine image for use as a base image for new virtual machines. To do this, perform the following:


1. Shutdown the virtual machine from the command line prompt as follows:
    ```bash
    poweroff
    ```
2. Delete the virtual machine. Note that in deleting the virtual machine the disk image was associated with, you have not deleted the disk image. 

3. Make the disk image that was associated with the now deleted virtual machine _non-persistent_ via the appropriate user interface option (you will have previously made the image persistent). 

You can now create new virtual machines based on this saved, configured image by using is as the base image in the UI based virtual machine creation processes described above. 

_Note however, that for each new docker host you wish to create, you will need to clone your base image, make the clone persistent, and build the new machine using the cloned image. This is so that each docker host can store containers persistently. This is a somewhat cumbersome if you need to create many docker hosts, resulting in a proliferation of disk images, one for each host, and so we next provide a process for creating docker hosts using a single non-volatile image called `boot2docker`_

## 3.2 Create a _boot2docker_ SCSSNebula docker host ##
We are now going to create and configure an OpenNebula [boot2docker](https://github.com/boot2docker/boot2docker) virtual machine that we will use to run docker containers in the SCSSNebula cloud. 

*boot2docker* is a very lightweight OS image designed to act as a docker host. It runs almost entriely in ram. Note that this means that we *can not* modify and save the boot2docker image as we did with our Debian based process above - most changes we make will be lost on reboot. To configure a boot2docker virtual machine _persistently_ to work correctly in the SCSSNebula, we must restrict out modifications to particular configuration and script files located in file system directories stored and mounted from the secondary disk. 

Our process will be to first create a new boot2docker based virtual machine using a UI, and then login and add configuration details to that machine. Note that this means that each boot2docker machine we create must be individually configured. This is a significant manual overhead, and so after we have explained the necessary configuration, we will discuss how to automate this configuration step so that we can more easily create and configure sets of virtual machines.

We can create boot2docker virtual machines using either a UI based process along the lines discussed above, or by using a command line tool called `docker-machine`. Because *boot2docker* must be configured to use a secondary disk for persistent data storage, you *can not* use the old UI, which does not support such configuration, but must instead use the newer UI available to SCSSNebula users [here](http://scssnebulateaching2.scss.tcd.ie:9869/). We discuss the creation process using each method in turn, before turning to persisting configuration specific to the SCSSNebula cloud.

### Create virtual machine using the newer UI ###

1. Open the [user interface](https://scssnebulaselfservice.scss.tcd.ie).

2. Click on the *Images* sub-menu option (found in the *Virtual Resources* menu), and look for an `[VM] boot2docker` image.If there is no such image, you will need to install the `boot2docker` image into the SCSSNebula as follows:

    1. Open the Marketplace and search for `boot2docker` and select it. Check the information, which should describe an image built to support _OpenNebula Contextualization_. Import this image, giving it a name such as `[VM] boot2docker`.

    2. Click the *Image* sub-menu again and find your `[VM] boot2docker` image.

3. Next, we must create a Template. Select the *Templates* sub-menu in the *Virtual Resources* menu create a new template. The template system is complex but we will perform a minimal configuration. 
 
    1. On the storage tab, select your boot2docker as Disk 0. 

    Add a second volatile disk at this point, of a reasonable size to store containers. The boot2docker image is configured to expect a volatile second disk for storing containers and that will be mounted into the file system directory structure.

    2. On the Network tab, select the `ResearchNet [routed]` network.

    3. On the Context tab, ensure `Add Network Contextualization` checkbox is selected.

    4. That is sufficient configuration. Create the template. 

4. Now we have a template, we will create a virtual machine. Select the *Virtual Machines* sub-menu option under the *Virtual Resources* menu. Create a new instance and in the dialog box, name it and select the template you just created. Click click `Create`. Again, because the boot2docker image has been designed to be very small, the virtual machine should be created very quickly, and you should not have to wait long for its creation to complete. 

5. Your virtual machine should now be running. Try to login with `ssh docker@a.b.c.d`, with the appropriate ip address obviously. The ip address of your SCSSNebula nodes are listed on the Compute page. If you used the aforementioned image to create your machine, the login password the `docker` account will be `tcuser`. 

### Create virtual machine using docker-machine ###
`docker-machine` is a client side tool that provides a simple command line interface that supports the creation of Docker virtual machines (known in the jargon as 'provisioning') and the management of groups of Docker machines. It is very easy to use, arguably easier to use that the SCSSnebula UI process described above, but it must be installed before use. 

In the following, we explain how to install `docker-machine`, and then describe how to create a standalone virtual machine using the tool. You can install `docker-machine` on any machine you like, including your laptop, provided that the machine has direct network access the the SCSSNebula cloud. 

You can test access to the SCSSNebula system by performing the following commands on the install machine:
```bash
$ apt-get install curl   # if necessary
$ curl http://scssnebulamgr.scss.tcd.ie:2633/RPC2
<HTML><HEAD><TITLE>Error 405</TITLE></HEAD><BODY><H1>Error 405</H1><P>POST is the only HTTP me...
```
If you see that output, then you are all set to proceed.

`docker-machine` supports the creation of Docker machines on a number of cloud platforms. There is an OpenNebula plugin that makes it possible to use `docker-machine` with OpenNebula clouds, such as SCSSNebula. We will install both `docker-machine` and the plugin, assuming our target machine is an SCSSNebula node based on Debian. Consult [documentation](https://docs.docker.com/machine/install-machine/) for details on how to install on other platforms.  

#### Install Docker-machine ####
Note that all the following presumes that you have network access on the install machine. Note also that if you installed Docker on a Mac or a Windows machine using the recommended methods, then you will already have docker-machine installed: proceed to the section on installation of the *docker-machine-opennebula plugin*.For the remainder of this section we will presume that the target machine is a standard DebianJessie instance in the SCSSNebula cloud, built using the process described above.

To install docker-machine, proceed as follows:

1. Download Docker-machine and extract it to your PATH:

    ```bash
     curl -L https://github.com/docker/machine/releases/download/v0.7.0/docker-machine-`uname -s`-` uname -m` > ~/docker-machine
         
     # Make it exectuable 
     chmod +x ~/docker-machine

     # Move it to your PATH
     mv ~/docker-machine /usr/local/bin/docker-machine 
    ```

2. Check the installation by displaying the Machine version:
    ```bash
    docker-machine version
    ```
3. Retrieve the shell completion scripts repository from GitHub, and follow the simple instructions at the top of each script to install them. Once installed, you can delete the repository.
    
    ```bash
    git clone https://github.com/docker/machine/tree/master/contrib/completion/bash
    ```
    
    Add the following to your `~/.bashrc` file:
    
    ```bash
    echo "PS1='[\u@\h \W$(__docker_machine_ps1)]\$ '" >> ~/.bashrc
    ```

####Install the docker-machine-opennebula plugin ####

1. To install the docker-machine-opennebula plugin, you are first going to need to install the programming language [Go](http://www.golang.org/), and [GoDep](https://github.com/tools/godep). Do that as follows:

    ```bash
    wget https://storage.googleapis.com/golang/go1.6.3.linux-amd64.tar.gz
     tar -C /usr/local -xzf go1.6.3.linux-amd64.tar.gz
    ```

2. Add the following to `/etc/profile` so that go is available to all users. 

    export PATH=$PATH:/usr/local/go/bin
  

3. Next, setup a workspace for Go. 

        mkdir ~/gowork
   
4. Add the following to your `~/.bashrc`:

        export GOPATH=$HOME/gowork

5. Also add the following to your PATH (via, for example, `~/.bashrc`):

        export PATH=$PATH:$GOPATH/bin


    We will need this when we use docker with the OpenNebula plugin.

6. Test your Go installation by adding a file `$GOPATH/src/github.com/[your Github username]/hello/hello.go` (you will need to make the directory structure) with the following contents:
    ```go
        package main

        import "fmt"

        func main() {
            fmt.Printf("hello, world\n")
        }
    ```
    and execute the following command (don't forget that the environment variables we added above must be active in your shell):

        $ go install github.com/[your Github username]/hello
        $ $GOPATH/bin/hello
        hello, world

    If you see `hello, world` as above, then you have Go installed. 

7. Execute the following command to install GoDep:

        $ go get github.com/tools/godep

8. Install `bzr`, which is a tool that _go_ sometimes uses:

        $ apt-get install bzr 

9. Next install the `docker-machine-plugin`:

        $ go get github.com/OpenNebula/docker-machine-opennebula
        $ cd $GOPATH/src/github.com/OpenNebula/docker-machine-opennebula
        $ make build

    After the build is complete, `bin/docker-machine-driver-opennebula` binary will be created and it must be included in $PATH variable. We will put it in the standard Go path by executing:

        $ make install

10. Configure the opennebula plugin.

    We must now set two environment variables needed by the opennebula plugin. At the command line, execute the following, where `username:password` is replaced with your SCSSNebula username and password. Be sure to adjust the file permissions so that this file is only readable by you:

        $ mkdir ~/.one
        $ echo "username:password" > ~/.one/one_auth    # or vi if you prefer
        $ chmod 400 ~/.one/one_auth                     # only owner can read 


    Add the following to your shell configuration (and don't forget to reload):  

        export ONE_XMLRPC=http://scssnebulamgr.scss.tcd.ie:2633/RPC2
        export ONE_AUTH=~/.one/one_auth
    

Your `docker-machine` tool is now configured. We will use it in the next section to create a Docker host.

####Provision docker hosts with docker-machine####

We are now ready to create Docker hosts within the SCSSNebula cloud. Using `docker-machine` is very easy:


    $ docker-machine create --driver opennebula --opennebula-network-id $NETWORK_ID --opennebula-image-id $BOOT2DOCKER_IMG_ID --opennebula-b2d-size $DATA_SIZE_MB nodename

where `$BOOT2DOCKER_IMG_ID` is the numerical ID of the imported boot2docker image, `$DATA_SIZE_MB` is the size of the volatile disk in MB, and `$NETWORD_ID` is the ID of the research network for SCSSNebula. 
    
For example:

    $ docker-machine create --driver opennebula --opennebula-network-id 6 --opennebula-image-id 1155 --opennebula-b2d-size 1000 test
    Running pre-create checks...
    Creating machine...
    (test) Creating SSH key...
    (test) Starting  VM...
    (test) Waiting for SSH...
    Waiting for machine to be running, this may take a few minutes...
    Detecting operating system of created instance...
    Waiting for SSH to be available...
    Detecting the provisioner...
    Provisioning with boot2docker...
    Copying certs to the local machine directory...
    Copying certs to the remote machine...
    Setting Docker configuration on the remote daemon...
    Checking connection to Docker...
    Docker is up and running!
    To see how to connect your Docker Client to the Docker Engine running on this virtual machine, run: docker-machine env test
    $
    $ docker-machine ls
    NAME     ACTIVE   DRIVER       STATE     URL                     SWARM   DOCKER    ERRORS
    test     -        opennebula   Running   tcp://10.63.0.28:2376           v1.10.2   


If you have created a template previously via the new open nebula interface, then you can create a docker machine as follows (replacing `$TEMPLATE_ID` with the appropriate template ID in the UI):

    $ docker-machine create --driver opennebula --opennebula-template-id $TEMPLATE_ID nodename
 
Once your node is created, you can login to the node via ssh, or more conveniently use `docker-machine`:

````
$ docker-machine ssh test
                        ##         .
                  ## ## ##        ==
               ## ## ## ## ##    ===
           /"""""""""""""""""\___/ ===
      ~~~ {~~ ~~~~ ~~~ ~~~~ ~~~ ~ /  ===- ~~~
           \______ o           __/
             \    \         __/
              \____\_______/
 _                 _   ____     _            _
| |__   ___   ___ | |_|___ \ __| | ___   ___| | _____ _ __
| '_ \ / _ \ / _ \| __| __) / _` |/ _ \ / __| |/ / _ \ '__|
| |_) | (_) | (_) | |_ / __/ (_| | (_) | (__|   <  __/ |
|_.__/ \___/ \___/ \__|_____\__,_|\___/ \___|_|\_\___|_|
Boot2Docker version 1.10.2, build master : 611be10 - Tue Feb 23 00:06:40 UTC 2016
Docker version 1.10.2, build c3959b1
docker@testlast:~$ 
````

### 3.2.3 Configure Networking for your new boot2docker instance - the manual way###

When we created a Debian based virtual machine, the disk image used was already configured to operate correctly in the SCSSNebula cloud, and so the procedure was short. However, the default boot2docker image is not so configured, and so we need to configure the networking for this default boot2docker virtual machine. 

Recall that the boot2docker image is a non-persisting OS image that does not maintain changes we might make in general in the OS file system after reboot, and so cannot be used as the basis of a pre-configured base image as we did with the _Debian_ based process above. As a consequence, we must configure each boot2docker machine that we create _individually_ following boot, in order to persist the necessary changes in the secondary storage disk.  

We will first explain how to configure an individual boot2docker virtual machine, and subsequently provide a script that can be executed from a remote machine with `ssh` access to the virtual machine that will perform the described configuration. This will provide us overall with a very streamlines command line process for creating and configuring Docker hosts.

_Note that every command we specify below should be entered into the appropriate named file to ensure it will be run on boot. You can also try the commands live at the prompt to ensure that the resulting configuration operates correctly._
 On reboot, the command line configuration will be lost, but rebuilt on reboot from the persistent changes you made in each step below._

Begin by logging in to your boot2docker virtual machine. Type the following to confirm that the network needs configuration - you should see an error when you enter the following command.

    $ docker run hello-world

Assuming that command caused an error, we proceed as follows:

1. Ensure that the host is forwarding IP packets:

        $ sysctl net.ipv4.conf.all.forwarding
        net.ipv4.conf.all.forwarding = 1

    If the returned value is '0', then add the following command to `/var/lib/boot2docker/bootsync.sh`:

        $ sysctl net.ipv4.conf.all.forwarding=1

    If the command did not return the value '0', skip to step 2.

2. Set the Domain name service configuration by adding the following commands to `/var/lib/boot2docker/bootsync.sh`:

        echo "nameserver 134.226.56.13" >> /etc/resolv.conf
        echo "nameserver 134.226.32.58" >> /etc/resolv.conf

3. Configure proxy environment variables by adding the following lines to `/var/lib/boot2docker/profile`

        echo "export http_proxy=http://www-proxy.scss.tcd.ie:8080" >> /var/lib/boot2docker/profile
        echo "export https_proxy=http://www-proxy.scss.tcd.ie:8080" >> /var/lib/boot2docker/profile
        echo "export HTTPS_PROXY=http://www-proxy.scss.tcd.ie:8080" >> /var/lib/boot2docker/profile
        echo "export HTTP_PROXY=http://www-proxy.scss.tcd.ie:8080" >> /var/lib/boot2docker/profile

    It's probably no harm putting the same content into the docker user's shell file `~/.profile` (boot2docker does not include bash - the shell is the standard `sh`) by adding the following to `/var/lib/boot2docker/profile`.

        echo "export http_proxy=http://www-proxy.scss.tcd.ie:8080" >> /usr/docker/profile
        echo "export https_proxy=http://www-proxy.scss.tcd.ie:8080" >> /usr/docker/profile
        echo "export HTTPS_PROXY=http://www-proxy.scss.tcd.ie:8080" >> /usr/docker/profile
        echo "export HTTP_PROXY=http://www-proxy.scss.tcd.ie:8080" >> /usr/docker/profile

4. The following listing is a well configured routing table for a docker node in the SCSSNebula network. We need to make your routing information look the same. Type `route -n` on the command line and compare with the following:

        route -n
        Kernel IP routing table
        Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
        0.0.0.0         10.63.255.254   0.0.0.0         UG    0      0        0 eth0
        10.63.0.0       0.0.0.0         255.255.0.0     U     0      0        0 eth0
        127.0.0.1       0.0.0.0         255.255.255.255 UH    0      0        0 lo
        172.17.0.0      0.0.0.0         255.255.0.0     U     0      0        0 docker0

    The routing table on your node will most likely not match this, but instead will most likely look like this (or perhaps contain only the second two lines):

        route -n
        Kernel IP routing table
        Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
        0.0.0.0         10.63.0.1       0.0.0.0         UG    1      0        0 eth0
        10.63.0.0       0.0.0.0         255.255.255.0   U     0      0        0 eth0
        127.0.0.1       0.0.0.0         255.255.255.255 UH    0      0        0 lo
        172.17.0.0      0.0.0.0         255.255.0.0     U     0      0        0 docker0

    Add the following commands to `/var/lib/boot2docker/bootlocal.sh`, or appropriate similar commands if your initial routing config is somewhat different, to transform the routing table to the necessary configuration.:

        echo "bootsync.sh: sleeping a little bit so route config works..."
        sleep 15
        echo"...continuing"
        sudo route add -net 10.63.0.0 netmask 255.255.0.0 eth0
        sudo route del default eth0
        sudo route add default gw 10.63.255.254 eth0
        sudo route del -net 10.63.0.0 netmask 255.255.255.0 eth0

    These adjustments, if executed on the command line, have immediate effect. You can test the resulting routing with tools such as `ping` and `curl`. Note that the `sleep` command is not necessary for effecting routing changes on the command line, but is necessary for performance of the changes as boot-time, due to an issue with _Tiny Core Linux_, on whcih _boot2docker_ is based. 

5. If you have been following along performing these command at the command line, restart the Docker engine:

        $ sudo /etc/init.d/docker restart

    Now test your network with the following command (the expected output is listed following the command):

        $ docker run hello-world
        Unable to find image 'hello-world:latest' locally
        latest: Pulling from library/hello-world
        c04b14da8d14: Pull complete 
        Digest: sha256:0256e8a36e2070f7bf2d0b0763dbabdd67798512411de4cdcf9431a1feb60fd9
        Status: Downloaded newer image for hello-world:latest

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

6. If all has worked so far, it remains to test that your boot-time configuration performs the same configuration as you have entered at the command line. Restart the virtual machine to ensure the configuration is reinitialised, login again, and test the installation by attempting the following `docker run` command, or some other `docker run` command on a container you have not previously executed:

        $ docker run docker/whalesay cowsay boo
        Unable to find image 'docker/whalesay:latest' locally
        latest: Pulling from docker/whalesay
        e190868d63f8: Pull complete 
        909cd34c6fd7: Pull complete 
        0b9bfabab7c1: Pull complete 
        a3ed95caeb02: Pull complete 
        00bf65475aba: Pull complete 
        c57b6bcc83e3: Pull complete 
        8978f6879e2f: Pull complete 
        8eed3712d2cf: Pull complete 
        Digest: sha256:178598e51a26abbc958b8a2e48825c90bc22e641de3d31e18aaf55f3258ba93b
        Status: Downloaded newer image for docker/whalesay:latest
         _____ 
        < boo >
         ----- 
            \
             \
              \     
                            ##        .            
                      ## ## ##       ==            
                   ## ## ## ##      ===            
               /""""""""""""""""___/ ===        
          ~~~ {~~ ~~~~ ~~~ ~~~~ ~~ ~ /  ===- ~~~   
               \______ o          __/            
                \    \        __/             
                 \____\______/   


    Your network is now configured correctly, and persistently, and Docker is able to retrieve data from remote sites.      

### 3.2.4 Configure Networking for your new boot2docker instance - the automated way###
The disadvantage of the `docker-machine` process is that each docker host is created with a non-persistent boot2docker image and thus starts execution misconfigured for use on the SCSSNebula cloud. There are in fact advanced methods that support the building or fully configured bespoke boot2docker images, but these are beyond the scope of this guide. We have so far described a manual process for logging in to a new boot2docker host, and configuring some persistent files that will ensure that the host will be correctly configured on reboot. However, this is a tedious process, and we would prefer to avoid a manual configuration of each host we create. The following script can be executed from the master node where you run `docker-machine` immediately after creating the new docker host and will perform all the necessary configuration for you. It creates a set of files in persistent locations in the docker host's file system that are always executed on boot, and that perform the necessary configuration after the base boot2docker image has started. 

Here is the script. Save it to a file named `docker-configure` and put in your path. 

````
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
````

The node creation and configuration process thus is performed as follows:

````
    $ docker-machine create --driver opennebula --opennebula-network-id 6 --opennebula-image-id 1155 --opennebula-b2d-size 1000 test   # for example
        ...
    $ ./docker-configure test
    Configuring node test...
    Configuration files initialised. 
    Restarting machine to enable new configuration.
    Configuration process complete. Please wait for node to restart.
````

And so we end up finally with a node creation process that is relatively simple.


