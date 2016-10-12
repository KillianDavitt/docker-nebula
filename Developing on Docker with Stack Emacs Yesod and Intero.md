This page described how to setup and configure a development workflow for building [Yesod](http://yesodweb.com) based applications (but also any other haskell development) using the [Stack](http://haskellstack.org) build system, with all compilation and execution running on a [Docker](http://docker.com) instance that isolates the compilation/execution of your system from the peculiarities of your host operating system dependencies. It also explains how to configure the [Emacs](http://www.gnu.org/s/emacs/) to use [Intero](http://commercialhaskell.github.io/intero/), which is the best out-of-the-box solution for emacs based Haskell development using Emacs, bar none. 

Let's first briefly explain what each component is and what each does for us. If you don't want to use each when I'm done, I've not done my job.

* [Stack](http://haskellstack.org) is a build system for haskell. It is cross platform, so providing a single and simple elegant method for haskell development on any OS. It takes care of installing necessary haskell backends for you, installing all packages your project needs dynamically (say goodbye to dependency hell), it builds, tests and benchmarks your project.Think of it as a replacement to cabal and more. Use it for all your Haskell work.


* [Docker](http://docker.com) is a software containerisation platform, which makes it possible to wrap your software and development tools with one of a range of flavours of lightweight VMs encompassing operating system and toolset environments, irrespective of what host OS you use. What this gives you is consistency and independence, allowing you to pick stable development environments to host your toolsets. What sounds like an unnecessary layer in fact greatly simplifies software development. Check out this [blog post](http://www.ybrikman.com/writing/2015/05/19/docker-osx-dev/) for more details. We will use Docker to host our Haskell build and execute toolchain, so that irrespective of what host OS we are working from, our development work will in some sense be performed on the chosen Docker instance. 

* [Yesod](http://yesodweb.com) is a Haskell web framework for development of type-safe, RESTful web applications. There are other frameworks for building web applications, but Yesod is substantial, mature, and well documented (there is a good book by the key project author). A good post considering the question why you should use it is to be found [here](http://www.yesodweb.com/page/about).

In summary, we will create and manage Yesod projects using Stack, edit them using Emacs configured to give us a good IDE like experience, and compile them and run them on a containerised virtual machine light that replicates our deployment environment and simplifies deployment greatly. Getting all this to work can be a little tricky however. So what follows is a step by step repeatable workflow, beginning with how to install the software and following with the detail of flag, settings and procedures to follow to make this toolchain work well together. 

# 1. Install The Software #
Install each component in turn. We will provide references to cross-platform install links as we go, but will assume Mac OS X as the installation platform for the text. Note that you do not need to have installed haskell before you start. We assume only a default OS implementation.

## 1.1 Install homebrew (On Mac) ##
[Homebrew](http://brew.sh) is a package manager for Mac OS X widely used for managing the installation of open source software. You probably already have it. If you don't, [get it](http://brew.sh) as you will need it to install most other packages on Mac OS X. For other operating systems, research an appropriate package manager. Many of the installation links provided below will provide these details. 

## 1.2 Install Stack ##

Details [here](https://docs.haskellstack.org/en/stable/install_and_upgrade/#mac-os-x), but for Mac its as simple as:
```
#!bash

$ brew install haskell-stack
```
  
## 1.4 Install Docker ##
Docker install instructions are to be found [here](https://docs.docker.com/engine/installation/). For Mac OS X, visit [this page](https://docs.docker.com/docker-for-mac/) and work your way through the full 'Getting Started' section. It should take no more than ten minutes and you will learn all you need to know for our purposes.

To test if docker is working on your machine, run the following on the command line, which if successful will return status information regarding the docker server:

    $ docker info

**Note for Mac OS X Sierra Users:** I have noticed that Docker can be a little temperamental. If a command does not execute properly, try again, perhaps restarting Docker. All following commands can be interrupted and restarted, so don't worry about breaking anything. If a step seems not to be progressing, give it a little time, but if needs be, kill it and rerun. If this does not work, dig into Docker documentation and/or support. To test if Docker is operating correctly, call `docker info`, which should return immediately with status information. 

## 1.5 Install Yesod Command Line Tools ##
The Yesod framework is just a project dependency as far as your haskell development is concerned, so you do not need to explicitly install the framework - it will be installed as needed when you use stack to build your project, as with any other project dependency. 

But Yesod comes with a set of command line tools that do need to be installed to support Yesod development, and this is how (using stack):

```
#!bash

$ stack build yesod-bin cabal-install --install-ghc
```

If you do this within a Stack project, then the project config will be used - you are essentially building the tools in the context of your project. If you run this command outside a stack project, then you global Stack config will be used. Do not worry about this for the moment. Just note that if you ever need to install Yesod command line tools that seem to be missing, this is how, and you run that command at the prompt where the problem was noted. We will include this step in the development workflow by default below, so there should be no need to run this command outside of that workflow.

Note that this command will take a few minutes on a fresh install - it is downloading and occasionally building haskell code, including dependencies (at time of writing, 104 steps). 

# 2. Yesod Project Workflow #
So now we have the tools installed, we come to the workflow for creating and configuring a Yesod Haskell project, compiling and executing it and interacting with its web pages, and performing software development. 

## 2.1 Create an initial Yesod project ##
Stack is your friend:

```
#!bash

$ stack new my-project yesod-sqlite && cd my-project
```

This command uses stack to create a skeleton project called `my-project` in a subdirectory of the same name. Obviously, you can call the project whatever you like. That project is configured to use Yesod with an SQLite database backend by declaring `yesod-sqlite` as the *template* to use. Stack uses a template system with a repository of open source templates that let you to create all kinds of projects with all kinds of configurations. `yseod-sqlite` is an example, and its generally a good starting point, supporting a baseline Yesod web application with sqlite database support. Consult the [Stack template repository](https://github.com/commercialhaskell/stack-templates) or run `stack templates` for more details of alternative templates, or write your own. 

Of course, you don't necessarily want to create a Yesod based project and the stack template system can be used to create all kinds of project types. For example, if you wanted to build a REST based web service, then [Servant](http://haskell-servant.readthedocs.io/en/stable/) is a good choice:

```
#!bash
$ stack new my-project servant && cd my-project
```

## 2.2 Enable Docker as the build and execution platform ##
The good news is that Stack has Docker support out-of-the-box, and it is a relatively simple fix to enable it for your project. Open stack.yaml and add the following configuration to the file. 

```
#!yaml

docker:
   enable: true
```

There are various guides online that you may come accross that detail an alternative process based on the creation of a file called `DockerFile` to manage your docker instance build process. You don't need to do this any more, because Stack takes care of everything. Details on Stack/Docker integration are available [here](https://docs.haskellstack.org/en/stable/docker_integration/). 

**Windows Users:** Note that Stack/Docker integration presently does not work for Windows - if that's you then for the moment at least you will have to manage Docker instance configuration and execution via the `Dockerfile` method. [This blog](https://ilikewhenit.works/blog/1) will help. You will end up doing more manual configuration and running commands like `sudo docker build -t yourname/yesod ./` to build your software instead of simply running stack to compile and execute, but the development process is broadly similar once you have setup. 

## 2.3 Compile your project ##
Assuming that Stack/Docker integration is supported:

Now lets be sure the Yesod command line tools are built:

```
#!bash

$ stack build yesod-bin cabal-install --install-ghc
```

Next run `stack setup`. In you forget to do this, and carry on to try to build your project, Stack will stop and remind you. 

We are now ready to build our project for the first time:

```
#!bash

$ stack build
```
The first build will take quite some time - perhaps 20 minutes or so. Go take a break. Appreciate that a tool stack performing these task automatically means a developer not having to do so, taking even longer. Stack will use precompiled libraries if they exist on your machine, downloading and building them if the particular library version required is not already cached.The stack build system is very robust, so the chances of this process failing before it reaches...ahem...your own code is very low - do not entertain the need to monitor the build.

## 2.4 Test your Project ##
You are obviously going to run the test suite yes? :)

```

$ stack test
```

## 2.5 Execute your project and use ##
Use the following command line to execute your Yesod Project.

```
#!bash

$ stack --docker-run-args='--net=bridge --publish=3000:3000' exec -- yesod devel
```
There is a little bit going on here. 

First, the basic call is to `stack exec` passing `yesod devel` as the task to be executed. This launches your web app using the developer web server from the Yesod Command Line Toolset. You do not generally run your web app directly when developing. If you had built an ordinary Haskell application, you would run `stack exec yourProjectName` instead, as described in the standard Stack documentation. 

The argument `--docker-run-args='--net=bridge --publish=3000:3000'` is necessary to ensure that the launched web app is reachable from your host operating system (ie. your desktop browser). Recall that your web app is now executing in a VM lite, and so we need to make that accessible. If your Yesod application has a network endpoint, then you will need an equivalent argument passed to Docker to expose that end point. Without such an argument, your application will execute, presuming it compiles, but will not be reachable from your desktop or any other machine. Note that Docker documentation suggests that this is not necessary, specifically *"stack containers use the host's network stack within the container by default, meaning a process running in the container can connect to services running on the host, and a server process run within the container can be accessed from the host without needing to explicitly publish its port,"* but this appears not to be the case for `yesod devel` applications.

![Alt Text](http://g.gravizo.com/g?%20@startuml;%20node%20%22Desktop%22%20{;%20[Browser]%20-%20Port;%20node%20%22Docker%22%20{;%20Port%20-%20[Yesod%20devel];%20[Yesod%20devel]%20-%20[Web%20Application];%20}%20;%20};%20@enduml;)

We can now use our running application. Open a web browser and point it to `http://localhost:3000` which is the default link that `yesod devel` exposes your application on. 

You should now see a Default site home page with some test functionality. If you do, you are essentially done. If you wish, you can shutdown the web application by typing `quit` into the command line.

When you launch your web application for the first time, you may notice a message in the execution trace as follows:

```
#!bash

Warning: The package list for 'hackage.haskell.org' does not exist. Run 'cabal update' to download it.
```

You can resolve this by executing the following:

```
#!bash

$ stack exec -- cabal update
```
This is another "will take some time" command. However, I have noticed it fail with an "out of memory" error sometimes so you will need to keep an eye on it. If it fails, just rerun till it completes. You could resolve this by adjusting the parameters of the default virtual machine, but its probably not worth it. 

## 2.6 Develop your Project ##
With the previous steps completed successfully, you can now develop without further consideration for the toolchain setup. As is normal with Yesod development, if you change project files, `yesod devel` should notice these changes and prompt a recompile and relaunch of your web application. 

If you close down your executing web application, to restart it you will need to use the same launch command as before:

```
#!bash

$ stack --docker-run-args='--net=bridge --publish=3000:3000' exec -- yesod devel
```

It is probably worth creating an alias for this for future use, adding something like the following to your shells configuration file (such as `~/.bashrc`):

```
#!bash

alias docker-yesod-dev="stack --docker-run-args='--net=bridge --publish=3000:3000' exec -- yesod devel"

```
whereupon you can simply call `docker-yesod-dev` from the command line to launch your project in development mode.Put this alias in your shell configuration (for example, if you use base, add it to `~/.bashrc`.

If you modify code while `yesod devel` is not running, and then start `yesod devel`, it will notice that the compiled application is out of date and recompile before launching. Most Yesod developers simply leave `yesod devel` running, allowing it to rebuild and relaunch their web application as they work.


# 3 Setting up Docker on SCSSNebula #
Next we move on to configuring servers to deploy your projects.

This section explains how to configure virtual machines running docker, which we will refer to as _docker hosts_, on the SCSSNebula OpenNebula installation. You do not need to do this to perform development using Haskell and Docker as described above, but if you want to deploy your containers, you will need somewhere to deploy them, and this guide solves this. It will explain how to provision two kinds of nodes into SCSSNebula: a fairly standard _Debian_ based linux virtual machine, and a [boot2docker](https://github.com/boot2docker/boot2docker) virtual machine, this being a lightweight linux distribution specifically designed to run Docker containers. 

Each provisioning method has advantages and disadvantages. The _Debian_ based solution is simple and great for one-off docker host creation, whereas the _boot2docker_ method is more scaleable, making the creation and management of sets of nodes easier, but involving an additional tool called `docker-machine`. We explain each setup in turn. Note that these instructions are for the creation of virtual machines of the SCSS OpenNebula installation, and thus include configuration details specific to that cloud, and omit configuration details not necessary for that cloud. 


## 3.1 Create a _Debian_ SCSSNebula docker host ##


We will now explain how to provision a node in the SCSSNebula, fully configured to act as a docker host. We must provision a node using one of the UI's provided by SCSSNebula, using a disk image supplied, and then install docker on this node. Once you have a suitably configured virtual machine, the disk image associated with it can be used as a basis for new virtual machines so that you do not have to repeat this configuration. We conclude this section by explaining how to save the disk image for future use. 

Note that you can achieve this via the updated UI available to SCSSNebula users available [here](https://scssnebulaselfservice.scss.tcd.ie) for staff and students, or via the older interfaces available for [staff](http://scssnebularesearch.scss.tcd.ie:4567/ui) only. Note that you may not have access to all interfaces. The steps for each are different: we include both methods next before proceeding to installation of _Docker_. 

Note also that you will most likely not be able to access these UIs from outside the college networks. 

### 3.1.1 Create a virtual machine using the newer UI ###

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


### 3.1.3 Install Docker ###
We will now install various Docker tools to our new node.

First, lets make sure the node is up to date:

````
#!bash
$ apt-get update
$ apt-get upgrade
````

Out node is now up to date. There are various ways to install Docker onto your new Debian node, but this seem to be the most straightforward:

```
#!bash

$ wget -qO- https://get.docker.com/ | sh
```

This should kick off a long installation process. If it doesn't, then you will probably need `http_proxy` and `https_proxy`set correctly. Check in your environment (run `env` from the command line), and set them both to `http://www-proxy.scss.tcd.ie:8080` they are not set. Note also that you will need `wget` to run that command, which may require you to perform `sudo apt-get wget` on the command line to install it. 

Once the installation is finished, test the docker installation by running:

```
#!bash
$ docker version
Client:
 Version:      1.12.1
 API version:  1.24
 Go version:   go1.6.3
 Git commit:   23cf638
 Built:        Thu Aug 18 05:02:53 2016
 OS/Arch:      linux/amd64

Server:
 Version:      1.12.1
 API version:  1.24
 Go version:   go1.6.3
 Git commit:   23cf638
 Built:        Thu Aug 18 05:02:53 2016
 OS/Arch:      linux/amd64
```

Docker is installed. However, we do not have Docker configured to access Docker hub, the remote source of docker containers. Let's test the docker installation by running a simple container, expecting the command to not list the following successful output (if it does, you are all set): 

1. First, create a systemd drop-in directory for the docker service:

    mkdir /etc/systemd/system/docker.service.d

2. Now create a file called `/etc/systemd/system/docker.service.d/http-proxy.conf` that adds the HTTP_PROXY environment variable:

        [Service]
        Environment="HTTP_PROXY=http://proxy.example.com:80/"

    If you have internal Docker registries that you need to contact without proxying you can specify them via the `NO_PROXY` environment variable:

        Environment="HTTP_PROXY=http://proxy.example.com:80/"
        Environment="NO_PROXY=localhost,127.0.0.0/8,docker-registry.somecorporation.com"

3. Flush changes:

    $ sudo systemctl daemon-reload

4. Verify that the configuration has been loaded:

    $ sudo systemctl show --property Environment docker
    Environment=HTTP_PROXY=http://proxy.example.com:80/

5. Restart Docker:

    $ sudo systemctl restart docker

Now try rerunning `docker run hello-world` and if everything works, you will see the output as listed above. 


```
#!bash
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
```

If you get that working, Docker is now running on your node. However, if the `docker run` command did not succeed, you most likely have a network configuration problem. It may be worth your while reviewing the network configuration steps described in the section below on creating a _boot2docker_ based host, to see if you can diagnose and correct the problem. 

### 3.1.3 Final configuration and baking###

This is probably a good time to enable [[ssh passwordless access]] access to your node, so that you do not need to keep using the username/password combination to login to your new node. 

Your virtual machine is now well configured to act as a docker virtual machine and run docker containers in the SCSSNebula cloud. To avoid having to repeat these steps in the future, it is sensible to now bake the virtual machine image for use as a base image for new virtual machines. To do this, perform the following:

1. Install any further software you wish all nodes to have installed. Note that services such as databases are usually installed on docker hosts within dedicated containers, and so in general you should not install such software into the base image. 

2. Shutdown the virtual machine from the command line prompt as follows:

        $ poweroff

3. Delete the virtual machine. Note that in deleting the virtual machine the disk image was associated with, you have not deleted the disk image. 

4. Make the disk image that was associated with the now deleted virtual machine _non-persistent_ via the appropriate user interface option (you will have previously made the image persistent). 

You can now create new virtual machines based on this saved, configured image by using is as the base image in the UI based virtual machine creation processes described above. 

_Note however, that for each new docker host you wish to create, you will need to clone your base image, make the clone persistent, and build the new machine using the cloned image. This is so that each docker host can store containers persistently. This is a somewhat cumbersome if you need to create many docker hosts, resulting in a proliferation of disk images, one for each host, and so we next provide a process for creating docker hosts using a single non-volatile image called `boot2docker`_

## 3.2 Create a _boot2docker_ SCSSNebula docker host ##
We are now going to create and configure an OpenNebula [boot2docker](https://github.com/boot2docker/boot2docker) virtual machine that we will use to run docker containers in the SCSSNebula cloud. 

*boot2docker* is a very lightweight OS image designed to act as a docker host, that is based on [Tiny Core Linux](http://tinycorelinux.net/) that runs entirely in RAM, keeping volatile data in a secondary data disk mounted into the OS file system. Note that this means that we *can not* modify and save the boot2docker image as we did with our Debian based process above - most changes we make will be lost on reboot. To configure a boot2docker virtual machine _persistently_ to work correctly in the SCSSNebula, we must restrict out modifications to particular configuration and script files located in file system directories stored and mounted from the secondary disk. 

Our process will be to first create a new boot2docker based virtual machine using a UI, and then login and add configuration details to that machine. Note that this means that each boot2docker machine we create must be individually configured. This is a significant manual overhead, and so after we have explained the necessary configuration, we will discuss how to automate this configuration step so that we can more easily create and configure sets of virtual machines.

We can create boot2docker virtual machines using either a UI based process along the lines discussed above, or by using a command line tool called `docker-machine`. Because *boot2docker* must be configured to use a secondary disk for persistent data storage, you *can not* use the old UI, which does not support such configuration, but must instead use the newer UI available to SCSSNebula users [here](http://scssnebulateaching2.scss.tcd.ie:9869/). We discuss the creation process using each method in turn, before turning to persisting configuration specific to the SCSSNebula cloud.

### 3.2.1 Create virtual machine using the newer UI ###

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

### 3.2.2 Create virtual machine using docker-machine ###
`docker-machine` is a client side tool that provides a simple command line interface that supports the creation of Docker virtual machines (known in the jargon as 'provisioning') and the management of groups of Docker machines. It is very easy to use, arguably easier to use that the SCSSnebula UI process described above, but it must be installed before use. 

In the following, we explain how to install `docker-machine`, and then describe how to create a standalone virtual machine using the tool. You can install `docker-machine` on any machine you like, including your laptop, provided that the machine has direct network access the the SCSSNebula cloud. 

You can test access to the SCSSNebula system by performing the following commands on the install machine:

    $ apt-get install curl   # if necessary
    $ curl http://scssnebulamgr.scss.tcd.ie:2633/RPC2
    <HTML><HEAD><TITLE>Error 405</TITLE></HEAD><BODY><H1>Error 405</H1><P>POST is the only HTTP me...

If you see that output, then you are all set to proceed.

`docker-machine` supports the creation of Docker machines on a number of cloud platforms. There is an OpenNebula plugin that makes it possible to use `docker-machine` with OpenNebula clouds, such as SCSSNebula. We will install both `docker-machine` and the plugin, assuming our target machine is an SCSSNebula node based on Debian. Consult [documentation](https://docs.docker.com/machine/install-machine/) for details on how to install on other platforms.  

#### Install Docker-machine ####
Note that all the following presumes that you have network access on the install machine. Note also that if you installed Docker on a Mac or a Windows machine using the recommended methods, then you will already have docker-machine installed: proceed to the section on installation of the *docker-machine-opennebula plugin*.For the remainder of this section we will presume that the target machine is a standard DebianJessie instance in the SCSSNebula cloud, built using the process described above.

To install docker-machine, proceed as follows:

1. If necessary install the `curl`:  

        $ apt-get install curl 

2. Download Docker-machine and extract it to your PATH:


        $ curl -L https://github.com/docker/machine/releases/download/v0.7.0/docker-machine-`uname -s`-` uname -m` >          /usr/local/bin/docker-machine && chmod +x /usr/local/bin/docker-machine
  

    That command puts docker-machine in `/usr/local/bin`.

3. Check the installation by displaying the Machine version:

        $ docker-machine version
        docker-machine version 0.7.0, build 61388e9

4. Retrieve the shell completion scripts repository from GitHub, and follow the simple instructions at the top of each script to install them. Once installed, you can delete the repository.

        git clone https://github.com/docker/machine/tree/master/contrib/completion/bash

    Add the following to your `~/.bashrc` file:

        PS1='[\u@\h \W$(__docker_machine_ps1)]\$ '
        

####Install the docker-machine-opennebula plugin ####

1. To install the `docker-machine-opennebula plugin, you are first going to need to install the programming language [Go](http://www.golang.org/), and [GoDep](https://github.com/tools/godep). Do that as follows:


        $ wget https://storage.googleapis.com/golang/go1.6.3.linux-amd64.tar.gz
        $ tar -C /usr/local -xzf go1.6.3.linux-amd64.tar.gz


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

        package main

        import "fmt"

        func main() {
            fmt.Printf("hello, world\n")
        }

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

    We can get docker to run container from our registry as follows (replacing `a.b.c.d` as usual):

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

#7 Docker Swarm#

Docker swarm is a clustering technology for docker that turns a pool of docker hosts (by which in our context, we mean SCSSNebula virtual machines running the docker service) into a single virtual docker host. You can direct your docker client to communicate with a swarm such that containers you request to be run may be run on any of the docker hosts within the pool of hosts managed by the swarm. This makes is relatively easy to deploy and manage highly scalable network applications. If one needs more container instances, one simply runs them and docker swarm will take care of where best to run them. If our pool of docker hosts become overloaded, we can simply add new hosts to the swarm.This architectural model is the basis of most real-world scalable service deployments today: behind some well known service endpoint, often accessible via a web browser, sits a dynamic group of tens, hundreds or even thousands of collaborating nodes. 

## 7.1 Creating a Swarm cluster ##

To proceed you must have created a set of nodes in the SCSSNebula cloud, and configured your machine set to use TLS as described in the Master-Worker sequence above, or by having created all nodes using `docker-machine`. In the following text, we will presume that one of the machines is designated as the swarm master, another machine will act a secondary master and provide something called a _discovery backend_ service, and all other machines will be workers in the swarm. Whenever we refer to a client machine, this means a machine with docker installed from which the _docker client_ is used to invoke commands on a the swarm, possibly hosted on a remote machine in the SCSSNebula, but not necessarily so. 


1. Create a discovery backend.

    FINISH: not all that happy about this discovery backend - also need to secure.

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

    Login to your master node, create a directory `swarm` somewhere persistent in your file system and and execute the following to create a private key for our new CA.

        $ mkdir -p /etc/docker/ssl/swarm         # this is where i will put all the certs for swarm
        $ cd /etc/docker/ssl/swarm
        $ openssl genrsa -out ca-priv-key.pem 2048
        Generating RSA private key, 2048 bit long modulus
        ........................................+++
        ...+++
        e is 65537 (0x10001)

    Next create a public key called ca.pem for the CA (You can ignore the optional details for the key generation):

        $ openssl req -config /usr/lib/ssl/openssl.cnf -new -key ca-priv-key.pem -x509 -days 1825 -out ca.pem
        You are about to be asked to enter information that will be incorporated
        into your certificate request.
        What you are about to enter is what is called a Distinguished Name or a DN.
        There are quite a few fields but you can leave some blank
        For some fields there will be a default value,
        If you enter '.', the field will be left blank.
        -----
        Country Name (2 letter code) [AU]:IE
                   ...
        $ ls
        ca.pem	ca-priv-key.pem  

    We now have a configured CA server with a public and private key pair. We are ready to use these to create keys for our swarm managers, nodes and remote docker engine clients. The process is the same for each kind of node. For each node `NODENAME`, perform the following (replacing NODENAME with a name for the node in question, being sure not to reuse a name if you are creating keys for more than one node):

        
        $ openssl genrsa -out NODENAME-priv-key.pem 2048
        Generating RSA private key, 2048 bit long modulus
        ............................................................+++
        ........+++
        e is 65537 (0x10001)
        $ openssl req -subj "/CN=swarm" -new -key NODENAME-priv-key.pem -out NODENAME.csr
        $ openssl x509 -req -days 1825 -in NODENAME.csr -CA ca.pem -CAkey ca-priv-key.pem -CAcreateserial -out NODENAME-cert.pem -extensions v3_req -extfile /usr/lib/ssl/openssl.cnf
        Signature ok
        subject=/CN=swarm
        Getting CA Private Key
        $ ls
        ca.pem	ca-priv-key.pem  ca.srl  NODENAME-cert.pem  NODENAME.csr  NODENAME-priv-key.pem
    
    When you are finished, your directory will include two files, named in form of `NODENAME-cert.pem` and `NODENAME-priv-key.pem` for each node you intend to configure. Next, we install these certificates to the nodes. 

    1. If your nodes are _boot2docker_ based, then perform the following, to copy these files and the file `ca.pem` to the appropriate location on the remote host:

            $ docker-machine ssh NODENAME "sudo mkdir -p /var/lib/boot2docker/swarm-certs"
            $ cat ca.pem | docker-machine ssh NODENAME "sudo sh -c \"cat - > /var/lib/boot2docker/swarm-certs/ca.pem\""
            $ cat NODENAME-cert.pem | docker-machine ssh NODENAME "sudo sh -c \"cat - > /var/lib/boot2docker/swarm-certs/swarm.pem\""
            $ cat NODENAME-priv-key.pem | docker-machine ssh NODENAME "sudo sh -c \"cat - > /var/lib/boot2docker/swarm-certs/key.pem\""

        Once these commands are complete, you can delete all files on the local machine with names of the form `NODENAME-cert.pem` , `NODENAME.csr` and `NODENAME-priv-key.pem`.

        As we probably want to perform this across a set of nodes, for simplicity, the following script collects all relevant operations for node configuration, such that executing `configure-b2d-swarm NODENAME ca.pem ca-priv-key.pem` will configure the node NODENAME:

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

    2. If your nodes are not _boot2docker_ based (for example, perhaps your docker client machine) then ensure that each of the files `ca.pem`, `NODENAME-cert.pem` and `NODENAME-priv-key.pem` are copied to an appropriate location on the remote host. The `ca.pem` certificate must be added to the set of trusted certificates. The other two will be used to configure access to the Docker swarm. For example:

        FINISH

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


# 8 Thanks#
Thanks to Prof. Stefan Weber, who helped resolve the many networking issues that arose. Thanks also to the system administration team behind help@scss.tcd.ie for all their help. Thanks finally to the folks at docker.com and the various internet bloggers who share their personal experience using technology like Docker, too many to mention but all invaluable. 
