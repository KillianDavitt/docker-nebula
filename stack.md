# Section 1
Note that you do not need to have installed haskell before you start. We assume only a default OS implementation.


# Install Stack
## macOS
[Homebrew](http://brew.sh) is a package manager for macOS widely used for managing the installation of open source software. You probably already have it. If you don't, [get it](http://brew.sh) as you will need it to install most other packages on macOS. For other operating systems, research an appropriate package manager. Many of the installation links provided below will provide these details. 


Details [here](https://docs.haskellstack.org/en/stable/install_and_upgrade/#mac-os-x), but for macOS it's as simple as:
```bash
brew install haskell-stack
```

## Linux (Ubuntu/Debian)
```bash
sudo apt-get install stack
```
  
# Install Docker ##
Docker install instructions are to be found [here](https://docs.docker.com/engine/installation/). For macOS, visit [this page](https://docs.docker.com/docker-for-mac/) and work your way through the full 'Getting Started' section. It should take no more than ten minutes and you will learn all you need to know for our purposes.

To test if docker is working on your machine, run the following on the command line, which if successful will return status information regarding the docker server:
```bash
  docker info
```
**Note for macOS Sierra Users:** I have noticed that Docker can be a little temperamental. If a command does not execute properly, try again, perhaps restarting Docker. All following commands can be interrupted and restarted, so don't worry about breaking anything. If a step seems not to be progressing, give it a little time, but if needs be, kill it and rerun. If this does not work, dig into Docker documentation and/or support. To test if Docker is operating correctly, call `docker info`, which should return immediately with status information. 

# Install Yesod Command Line Tools (platform agnostic) ##
The Yesod framework is just a project dependency as far as your haskell development is concerned, so you do not need to explicitly install the framework - it will be installed as needed when you use stack to build your project, as with any other project dependency. 

But Yesod comes with a set of command line tools that do need to be installed to support Yesod development, and this is how (using stack):

```bash
stack build yesod-bin cabal-install --install-ghc
```

This command will take ages :(

If you do this within a Stack project, then the project config will be used - you are essentially building the tools in the context of your project. If you run this command outside a stack project, then you global Stack config will be used. Do not worry about this for the moment.



