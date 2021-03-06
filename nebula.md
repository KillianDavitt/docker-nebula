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

    2. On the Network tab, select the `TeachingNET [routed]` network.

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

This is probably a good time to enable [[ssh passwordless access]] access to your node, so that you do not need to keep using the username/password combination to login to your new node. 

## 3.2 Create a _boot2docker_ SCSSNebula docker host ##
We are now going to create and configure an OpenNebula [boot2docker](https://github.com/boot2docker/boot2docker) virtual machine that we will use to run docker containers in the SCSSNebula cloud. 

*boot2docker* is a very lightweight OS image designed to act as a docker host. It runs almost entriely in ram. Note that this means that we *can not* modify and save the boot2docker image as we did with our Debian based process above - most changes we make will be lost on reboot. To configure a boot2docker virtual machine _persistently_ to work correctly in the SCSSNebula, we must restrict out modifications to particular configuration and script files located in file system directories stored and mounted from the secondary disk. 

Our process will be to first create a new boot2docker based virtual machine using a UI, and then login and add configuration details to that machine. Note that this means that each boot2docker machine we create must be individually configured. This is a significant manual overhead, and so after we have explained the necessary configuration, we will discuss how to automate this configuration step so that we can more easily create and configure sets of virtual machines.

We can create boot2docker virtual machines using either a UI based process along the lines discussed above, or by using a command line tool called `docker-machine`. Because *boot2docker* must be configured to use a secondary disk for persistent data storage, you *can not* use the old UI, which does not support such configuration, but must instead use the newer UI available to SCSSNebula users [here](http://scssnebulateaching2.scss.tcd.ie:9869/). We discuss the creation process using each method in turn, before turning to persisting configuration specific to the SCSSNebula cloud.

### Create virtual machine using the newer UI ###

1. Open the [user interface](https://scssnebulaselfservice.scss.tcd.ie).

2. Next, we must create a Template. Select the *Templates* sub-menu in the *Virtual Resources* menu create a new template. The template system is complex but we will perform a minimal configuration. 
 
    1. On the storage tab, select your boot2docker as Disk 0. 

    Add a second volatile disk at this point, of a reasonable size to store containers. The boot2docker image is configured to expect a volatile second disk for storing containers and that will be mounted into the file system directory structure.

    2. On the Network tab, select the `TeachingNet [routed]` network.

    3. On the Context tab, ensure `Add Network Contextualization` checkbox is selected.

    4. That is sufficient configuration. Create the template. 

3. Now we have a template, we will create a virtual machine. Select the *Virtual Machines* sub-menu option under the *Virtual Resources* menu. Create a new instance and in the dialog box, name it and select the template you just created. Click click `Create`. Again, because the boot2docker image has been designed to be very small, the virtual machine should be created very quickly, and you should not have to wait long for its creation to complete. 

4. Try to login with `ssh docker@a.b.c.d`, with the appropriate ip address. The ip address of your SCSSNebula nodes are listed on the webui. The password will be `tcuser`. 

#### Install Docker-machine ####
docker-machine basically allows us to create new nebula nodes without visiting the webui. It also simplifies the process by automatically setting up ssh keys for login.
We are installing docker-machine on our debian node.

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
   
4. Put another config in bashrc:

        echo "export GOPATH=$HOME/gowork" >> ~/.bashrc

5. Another config for the bashrc:

        echo "export PATH=$PATH:$GOPATH/bin" >> ~/.bashrc


    We will need this when we use docker with the OpenNebula plugin.

6. Test your Go installation by creating a file hello.go, put the following in it
    ```go
        package main

        import "fmt"

        func main() {
            fmt.Printf("hello, world\n")
        }
    ```
    and execute the following command:

        go run hello.go

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
Get your template id from the OpenNebula webui

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

### 3.2.4 Configure Networking for your new boot2docker instance - the automated way###
The disadvantage of the `docker-machine` process is that each docker host is created with a non-persistent boot2docker image and thus starts execution misconfigured for use on the SCSSNebula cloud. There are in fact advanced methods that support the building or fully configured bespoke boot2docker images, but these are beyond the scope of this guide. We have so far described a manual process for logging in to a new boot2docker host, and configuring some persistent files that will ensure that the host will be correctly configured on reboot. However, this is a tedious process, and we would prefer to avoid a manual configuration of each host we create. The following script can be executed from the master node where you run `docker-machine` immediately after creating the new docker host and will perform all the necessary configuration for you. It creates a set of files in persistent locations in the docker host's file system that are always executed on boot, and that perform the necessary configuration after the base boot2docker image has started. 

```bash
wget https://raw.githubusercontent.com/KillianDavitt/docker-nebula/master/scripts/docker-config.sh
```


The node creation and configuration process thus is performed as follows:

```
  docker-machine create --driver opennebula --opennebula-template-id $TEMPLATE_ID nodename
  ...
  ./docker-configure test
```

And so we end up finally with a node creation process that is relatively simple.


