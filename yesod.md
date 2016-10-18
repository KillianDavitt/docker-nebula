# Section 2 - Yesod 
So now we have the tools installed, we come to the workflow for creating and configuring a Yesod Haskell project, compiling and executing it and interacting with its web pages, and performing software development. 

## Create an initial Yesod project ##
Stack is your friend:

```bash
stack new my-project yesod-sqlite && cd my-project
```

This command uses stack to create a skeleton project called `my-project` in a subdirectory of the same name. Obviously, you can call the project whatever you like. That project is configured to use Yesod with an SQLite database backend by declaring `yesod-sqlite` as the *template* to use. Stack uses a template system with a repository of open source templates that let you to create all kinds of projects with all kinds of configurations. `yseod-sqlite` is an example, and its generally a good starting point, supporting a baseline Yesod web application with sqlite database support. Consult the [Stack template repository](https://github.com/commercialhaskell/stack-templates) or run `stack templates` for more details of alternative templates, or write your own. 

Of course, you don't necessarily want to create a Yesod based project and the stack template system can be used to create all kinds of project types. For example, if you wanted to build a REST based web service, then [Servant](http://haskell-servant.readthedocs.io/en/stable/) is a good choice:

```bash
stack new my-project servant && cd my-project
```

##  Enable Docker as the build and execution platform ##
The good news is that Stack has Docker support out-of-the-box, and it is a relatively simple fix to enable it for your project. Open stack.yaml and add the following configuration to the file. 

```yaml
docker:
   enable: true
```

There are various guides online that you may come accross that detail an alternative process based on the creation of a file called `DockerFile` to manage your docker instance build process. You don't need to do this any more, because Stack takes care of everything. Details on Stack/Docker integration are available [here](https://docs.haskellstack.org/en/stable/docker_integration/). 

**Windows Users:** Note that Stack/Docker integration presently does not work for Windows - if that's you then for the moment at least you will have to manage Docker instance configuration and execution via the `Dockerfile` method. [This blog](https://ilikewhenit.works/blog/1) will help. You will end up doing more manual configuration and running commands like `sudo docker build -t yourname/yesod ./` to build your software instead of simply running stack to compile and execute, but the development process is broadly similar once you have setup. 

## Compile your project ##
Assuming that Stack/Docker integration is supported:

Now lets be sure the Yesod command line tools are built:

```bash
stack build yesod-bin cabal-install --install-ghc
```

Next run `stack setup`. In you forget to do this, and carry on to try to build your project, Stack will stop and remind you. 

We are now ready to build our project for the first time:

```bash
stack build
```
The first build will take quite some time - perhaps 20 minutes or so. Go take a break. Appreciate that a tool stack performing these task automatically means a developer not having to do so, taking even longer. Stack will use precompiled libraries if they exist on your machine, downloading and building them if the particular library version required is not already cached.The stack build system is very robust, so the chances of this process failing before it reaches...ahem...your own code is very low - do not entertain the need to monitor the build.

## Test your Project ##
You are obviously going to run the test suite yes? :)

```bash
stack test
```

## 2.5 Execute your project and use ##
Use the following command line to execute your Yesod Project.

```bash
stack --docker-run-args='--net=bridge --publish=3000:3000' exec -- yesod devel
```
There is a little bit going on here. 

First, the basic call is to `stack exec` passing `yesod devel` as the task to be executed. This launches your web app using the developer web server from the Yesod Command Line Toolset. You do not generally run your web app directly when developing. If you had built an ordinary Haskell application, you would run `stack exec yourProjectName` instead, as described in the standard Stack documentation. 

The argument `--docker-run-args='--net=bridge --publish=3000:3000'` is necessary to ensure that the launched web app is reachable from your host operating system (ie. your desktop browser). Recall that your web app is now executing in a VM lite, and so we need to make that accessible. If your Yesod application has a network endpoint, then you will need an equivalent argument passed to Docker to expose that end point. Without such an argument, your application will execute, presuming it compiles, but will not be reachable from your desktop or any other machine. Note that Docker documentation suggests that this is not necessary, specifically *"stack containers use the host's network stack within the container by default, meaning a process running in the container can connect to services running on the host, and a server process run within the container can be accessed from the host without needing to explicitly publish its port,"* but this appears not to be the case for `yesod devel` applications.

![Alt Text](http://g.gravizo.com/g?%20@startuml;%20node%20%22Desktop%22%20{;%20[Browser]%20-%20Port;%20node%20%22Docker%22%20{;%20Port%20-%20[Yesod%20devel];%20[Yesod%20devel]%20-%20[Web%20Application];%20}%20;%20};%20@enduml;)

We can now use our running application. Open a web browser and point it to `http://localhost:3000` which is the default link that `yesod devel` exposes your application on. 

You should now see a Default site home page with some test functionality. If you do, you are essentially done. If you wish, you can shutdown the web application by typing `quit` into the command line.

When you launch your web application for the first time, you may notice a message in the execution trace as follows:

```bash
Warning: The package list for 'hackage.haskell.org' does not exist. Run 'cabal update' to download it.
```

You can resolve this by executing the following:

```bash
stack exec -- cabal update
```
This is another "will take some time" command. However, I have noticed it fail with an "out of memory" error sometimes so you will need to keep an eye on it. If it fails, just rerun till it completes. You could resolve this by adjusting the parameters of the default virtual machine, but its probably not worth it. 

## Develop your Project ##
With the previous steps completed successfully, you can now develop without further consideration for the toolchain setup. As is normal with Yesod development, if you change project files, `yesod devel` should notice these changes and prompt a recompile and relaunch of your web application. 

If you close down your executing web application, to restart it you will need to use the same launch command as before:

```bash
stack --docker-run-args='--net=bridge --publish=3000:3000' exec -- yesod devel
```

do this to add an alias to your bashrc so that you dont have to type it everytime
```bash
echo "alias docker-yesod-dev=\"stack --docker-run-args='--net=bridge --publish=3000:3000' exec -- yesod devel\"" >> ~/.bashrc
```

In future, type 'docker-yesod-dev'


If you modify code while `yesod devel` is not running, and then start `yesod devel`, it will notice that the compiled application is out of date and recompile before launching. Most Yesod developers simply leave `yesod devel` running, allowing it to rebuild and relaunch their web application as they work.



