This page described how to setup and configure a development workflow for building [Yesod](http://yesodweb.com) based applications (but also any other haskell development) using the [Stack](http://haskellstack.org) build system, with all compilation and execution running on a [Docker](http://docker.com) instance that isolates the compilation/execution of your system from the peculiarities of your host operating system dependencies. It also explains how to configure the [Emacs](http://www.gnu.org/s/emacs/) to use [Intero](http://commercialhaskell.github.io/intero/), which is the best out-of-the-box solution for emacs based Haskell development using Emacs, bar none. 

Let's first briefly explain what each component is and what each does for us. If you don't want to use each when I'm done, I've not done my job.

* [Stack](http://haskellstack.org) is a build system for haskell. It is cross platform, so providing a single and simple elegant method for haskell development on any OS. It takes care of installing necessary haskell backends for you, installing all packages your project needs dynamically (say goodbye to dependency hell), it builds, tests and benchmarks your project.Think of it as a replacement to cabal and more. Use it for all your Haskell work.

* [Emacs](http://www.gnu.org/s/emacs/) is one of the longest serving text editors out there, but as Emacs users know, it is better to think of it as a programmable programming environment. Have a look at the [Emacs Rock's](http://emacsrocks.com) series to get a feel for the productivity power efficient and experienced Emacs use can deliver. There are other choices, such as [vim](http://www.vim.org) and [atom](http://atom.io) and so forth. Check them out, but Emacs stands head and shoulders above them all for a great many professional developers.

* [Intero](http://commercialhaskell.github.io/intero/) is a complete interactive development system for haskell developers using emacs. It provides on-the-fly type checking, inline text completion, definition jumping, and a whole host of other features beautifully and professionally crafted. The experience of most haskell developers who try it is one of pleasant surprise: everything works out of the box. It is 'opinionated' in that it makes design decisions that constrain choices (such as requiring Stack - no bad thing) but the consensus broadly is that anything the [CommericalHaskell](https://github.com/commercialhaskell) team opine is worth taking seriously (and Stack is one of theirs also). 

* [Docker](http://docker.com) is a software containerisation platform, which makes it possible to wrap your software and development tools with one of a range of flavours of lightweight VMs encompassing operating system and toolset environments, irrespective of what host OS you use. What this gives you is consistency and independence, allowing you to pick stable development environments to host your toolsets. What sounds like an unnecessary layer in fact greatly simplifies software development. Check out this [blog post](http://www.ybrikman.com/writing/2015/05/19/docker-osx-dev/) for more details. We will use Docker to host our Haskell build and execute toolchain, so that irrespective of what host OS we are working from, our development work will in some sense be performed on the chosen Docker instance. 

* [Yesod](http://yesodweb.com) is a Haskell web framework for development of type-safe, RESTful web applications. There are other frameworks for building web applications, but Yesod is substantial, mature, and well documented (there is a good book by the key project author). A good post considering the question why you should use it is to be found [here](http://www.yesodweb.com/page/about).

In summary, we will create and manage Yesod projects using Stack, write them in Emacs configured to give us a good IDE like experience, and compile them and run them on a containerised virtual machine light that replicates our deployment environment and simplifies deployment greatly. Getting all this to work can be a little tricky however. So what follows is a step by step repeatable workflow, beginning with how to install the software and following with the detail of flags and settings to use to make this toolchain work well together. 

# Install The Software #
Install each component in turn. I will provide references to cross-platform install links as I go, but will assume Mac OS X as the installation platform for the text.

Note that you do not need to have installed haskell before you start. 

## Install homebrew (On Mac) ##
[Homebrew](http://brew.sh) is a package manager for Mac OS X. You probably already have it. If you don't, [get it](http://brew.sh) as you will need it to install most other packages on Mac OS X. For other operating systems, research an appropriate package manager. Many of the installation links provided below will provide these details. 

## Install Stack ##

Details [here](https://docs.haskellstack.org/en/stable/install_and_upgrade/#mac-os-x), but for Mac its as simple as:
```
#!bash

brew install haskell-stack
```
  
## Install Emacs and Intero ##
There are many flavours of emacs, so it might be worth researching what version you want to use, but for vannilla experience, I like [railwaycat's port](https://github.com/railwaycat/homebrew-emacsmacport), which handles some details oft he Mac OS X operating system environment better. Install this as follows:

```
#!bash

$ brew tap railwaycat/emacsmacport
$ brew install emacs-mac
```
You can also `brew install emacs` to get the standard emacs implementation. For installing emacs on other platforms, see [here](https://www.gnu.org/software/emacs/manual/html_node/efaq/Installing-Emacs.html).

Once you have installed Emacs there are a multitude of ways to customise it, with thousands of packages to choose from. We will skip all this fun for the present and consider only the configuration to enable Intero.

You will need to create or open a file called ~/.emacs.d/init.el. This is the file that Emacs uses to configure on load. To install Intero we need the following code:


```
#!elisp

;; If you don't have MELPA in your package archives:
(require 'package)
(add-to-list
  'package-archives
  '("melpa" . "http://melpa.org/packages/") t)
(package-initialize)
(package-refresh-contents)

;; Install Intero
(package-install 'intero)
(add-hook 'haskell-mode-hook 'intero-mode)
```

You will come across other code that achieves the same thing using different Emacs package managers etc. but this is sufficient. On the first occasion that you open a haskell file, Emacs will automatically download (you will need internet access) Intero and install it. Intero will itself install software, including Haskell backends. All this can take some time, so do not be concerned if the opening of a file in Emacs is slow on the first occasion. If you prefer, you can run M-x package-install from the emacs command line instead. Subsequently, every time you open a Haskell file for the first time in an Emacs session, Intero will boot up and this may cause a momentary pause. Once running, there will be no further delay when opening other Haskell files. Intero is fast and elegant. 

## Install Docker ##
Docker install instructions are to be found [here](https://docs.docker.com/engine/installation/). For Mac OS X, visit [this page](https://docs.docker.com/docker-for-mac/) and work your way through the full 'Getting Started' section. It should take no more than ten minutes and you will learn all you need to know for our purposes.

## Install Yesod Command Line Tools ##
The Yesod framework is just a project dependency as far as your haskell development is concerned, so you do not need to explicitly install the framework - it will be installed as needed when you use stack to build your project, as with any other project dependency. 

But Yesod comes with a set of command line tools that do need to be installed to support Yesod development, and this is how (using stack):

```
#!bash

stack build yesod-bin cabal-install --install-ghc
```

If you do this within a Stack project, then the project config will be used - you are essentially building the tools in the context of your project. If you run this command outside a stack project, then you global Stack config will be used. Do not worry about this for the moment. Just note that if you ever need to install Yesod command line tools that seem to be missing, this is how, and you run that command at the prompt where the problem was noted. We will include this step in the development workflow by default below, so there should be no need to run this command outside of that workflow.

Note that this command will take a few minutes on a fresh install - it is downloading and occasionally building haskell code, including dependencies (at time of writing, 104 steps). 

# Yesod Project Workflow #
So now we have the tools installed, we come to the workflow for creating and configuring a Yesod Haskell project, compiling and executing it and interacting with its web pages, and performing software development. 

## Create an initial Yesod project ##
Stack is your friend:

```
#!bash

stack new my-project yesod-sqlite && cd my-project
```

This command uses stack to create a skeleton project called `my-project` in a subdirectory of the same name. Obviously, you can call the project whatever you like. That project is configured to use Yesod with an SQLite database backend by declaring `yesod-sqlite` as the *template* to use. Stack uses a template system with a repository of open source templates that let you to create all kinds of projects with all kinds of configurations. `yseod-sqlite` is an example, and its generally a good starting point, supporting a baseline Yesod web application with sqlite database support. Consult the [Stack template repository](https://github.com/commercialhaskell/stack-templates) or run `stack templates` for more details of alternative templates, or write your own. 

## Enable Docker as the build and execution platform ##
The good news is that Stack has Docker support out-of-the-box, and it is a relatively simple fix to enable it for your project. Open stack.yaml and add the following configuration to the file. 

```
#!yaml

docker:
   enable: true
```

There are various guides online that you may come accross that detail the creation of a file called `DockeFile` to manage your docker instance. You don't need to do this any more, because Stack takes care of everything. Details on Stack/Docker integration are available [here](https://docs.haskellstack.org/en/stable/docker_integration/). 

**Windows Users:** Note that Stack/Docker integration presently does not work for Windows - if that's you then for the moment at least you will have to manage Docker instance configuration and execution. See [this blog](https://ilikewhenit.works/blog/1) will help. You will end up doing more manual configuration and running commands like `sudo docker build -t yourname/yesod ./` to build your software instead of ...

**All Users:** I have noticed that Docker can be a little temperamental. If a command does not execute properly, try again, perhaps restarting Docker. All following commands can be interrupted and restarted, so don't worry about breaking anything. If a step seems not to be progressing, give it a little time, but if needs be, kill it and rerun. If this does not work, dig into Docker documentation and/or support. 

## Compile your project ##
Assuming that Stack/Docker integration is supported:

Next run `stack setup`. In you forget to do this, and carry on to try to build your project, Stack will stop and remind you. 

We are now ready to build our project for the first time:

```
#!bash

stack build
```
The first build will take quite some time - perhaps 20 minutes or so. Go take a break. Appreciate that a tool stack performing these task automatically means a developer not having to do so, taking even longer. Stack will use precompiled libraries if they exist on your machine, downloading and building them if the particular library version required is not already cached.The stack build system is very robust, so the chances of this process failing before it reaches...ahem...your own code is very low - do not feel the need to monitor the build.

## Test your Project ##
You are obviously going to run the test suite yes? :)

```

stack test
```

## Execute your project and use ##
Use the following command line to execute your Yesod Project.

```
#!bash

stack --docker-run-args='--net=bridge --publish=3000:3000' exec -- yesod devel
```
There is a little bit going on here. 

First, the basic call is to `stack exec` passing `yesod devel` as the task to be executed. This launches your web app using the developer web server from the Yesod Command Line Toolset. You do not generally run your web app directly when developing. If you had built an ordinary Haskell application, you would run `stack exec yourProjectName` instead, as described in the standard Stack documentation. 

The argument `--docker-run-args='--net=bridge --publish=3000:3000'` is necessary to ensure that the launched web app is reachable from your host operating system (ie. your desktop browser). Recall that your web app is now executing in a VM lite, and so we need to make that accessible. If your application (Yesod based or not) has a network endpoint, then you will need an equivalent argument passed to Docker to expose that end point. Without such an argument, your application will execute, presuming it compiles, but will not be reachable from your desktop or any other machine. 

![Alt Text](http://g.gravizo.com/g?%20@startuml;%20node%20%22Desktop%22%20{;%20[Browser]%20-%20Port;%20node%20%22Docker%22%20{;%20Port%20-%20[Yesod%20devel];%20[Yesod%20devel]%20-%20[Second%20Component];%20}%20;%20};%20@enduml;)


We can now use our running application. Open a web browser and point it to `http://localhost:3000` which is the default link that `yesod devel` exposes your application on. 

You should now see a Default site home page with some test functionality. If you do, you are done. 


## Develop your Project ##
With the previous steps completed successfully, you can now develop without further consideration for the toolchain setup. As is normal with Yesod development, if you change Project files, `yesod devel` should notice these changes and prompt a recompile and launch of your project. 

If you close down your executing project, to restart it you will need to use the same launch command as before:

```
#!bash

stack --docker-run-args='--net=bridge --publish=3000:3000' exec -- yesod devel
```

It is probably worth creating an alias for this for future use:


```
#!bash

alias docker-yesod-dev="stack --docker-run-args='--net=bridge --publish=3000:3000' exec -- yesod devel"

```
whereupon you can simply call `docker-yesod-dev` from the command line to launch your project in development mode. If you modify code and then restart `yesod devel`, it will notice that the compiled application is out of date and recompile before launching. Most Yesod developers simply leave `yesod devel` running.
