# Intro
This page described how to setup and configure a development workflow for building [Yesod](http://yesodweb.com) based applications (but also any other haskell development) using the [Stack](http://haskellstack.org) build system, with all compilation and execution running on a [Docker](http://docker.com) instance that isolates the compilation/execution of your system from the peculiarities of your host operating system dependencies. 

* [Stack](http://haskellstack.org) is a build system for haskell. It takes care of installing necessary haskell backends for you, installing all packages your project needs dynamically (say goodbye to dependency hell), it builds, tests and benchmarks your project.Think of it as a replacement to cabal and more.

<iframe width="560" height="315" src="https://www.youtube.com/embed/sRonIB8ZStw" frameborder="0" allowfullscreen></iframe>

* [The Stack Mega tutorial](https://www.youtube.com/watch?v=sRonIB8ZStw)

* [Docker](http://docker.com) is a software containerisation platform allowing you to pick stable development environments to host your toolsets. What sounds like an unnecessary layer in fact greatly simplifies software development. [why docker blog post](http://www.ybrikman.com/writing/2015/05/19/docker-osx-dev/). We will use Docker to host our Haskell build.

<iframe width="560" height="315" src="https://www.youtube.com/embed/aLipr7tTuA4" frameborder="0" allowfullscreen></iframe>

* [Yesod](http://yesodweb.com) is a Haskell web framework. It's the most mature haskell web framework.


![](docker.png)

* To get into nebula we need to go through macneill

* Your haskell code should be pushed to docker hub and then can be pulled onto many hosts at once

