Forked from: https://bitbucket.org/esjmb/teaching/wiki/Developing_on_Docker_with_Stack_Emacs_Yesod_and_Intero
Created by Prof. Stephen Barrett

This page described how to setup and configure a development workflow for building [Yesod](http://yesodweb.com) based applications (but also any other haskell development) using the [Stack](http://haskellstack.org) build system, with all compilation and execution running on a [Docker](http://docker.com) instance that isolates the compilation/execution of your system from the peculiarities of your host operating system dependencies. It also explains how to configure the [Emacs](http://www.gnu.org/s/emacs/) to use [Intero](http://commercialhaskell.github.io/intero/), which is the best out-of-the-box solution for emacs based Haskell development using Emacs, bar none. 

Let's first briefly explain what each component is and what each does for us. If you don't want to use each when I'm done, I've not done my job.

* [Stack](http://haskellstack.org) is a build system for haskell. It is cross platform, so providing a single and simple elegant method for haskell development on any OS. It takes care of installing necessary haskell backends for you, installing all packages your project needs dynamically (say goodbye to dependency hell), it builds, tests and benchmarks your project.Think of it as a replacement to cabal and more. Use it for all your Haskell work.


* [Docker](http://docker.com) is a software containerisation platform, which makes it possible to wrap your software and development tools with one of a range of flavours of lightweight VMs encompassing operating system and toolset environments, irrespective of what host OS you use. What this gives you is consistency and independence, allowing you to pick stable development environments to host your toolsets. What sounds like an unnecessary layer in fact greatly simplifies software development. Check out this [blog post](http://www.ybrikman.com/writing/2015/05/19/docker-osx-dev/) for more details. We will use Docker to host our Haskell build and execute toolchain, so that irrespective of what host OS we are working from, our development work will in some sense be performed on the chosen Docker instance. 

* [Yesod](http://yesodweb.com) is a Haskell web framework for development of type-safe, RESTful web applications. There are other frameworks for building web applications, but Yesod is substantial, mature, and well documented (there is a good book by the key project author). A good post considering the question why you should use it is to be found [here](http://www.yesodweb.com/page/about).

In summary, we will create and manage Yesod projects using Stack, edit them using Emacs configured to give us a good IDE like experience, and compile them and run them on a containerised virtual machine light that replicates our deployment environment and simplifies deployment greatly. Getting all this to work can be a little tricky however. So what follows is a step by step repeatable workflow, beginning with how to install the software and following with the detail of flag, settings and procedures to follow to make this toolchain work well together. 

* [1 Stack](stack.md)
* [2 Stack](yesod.md)
*
*
*
*



# 8 Thanks#
Thanks to Prof. Stefan Weber, who helped resolve the many networking issues that arose. Thanks also to the system administration team behind help@scss.tcd.ie for all their help. Thanks finally to the folks at docker.com and the various internet bloggers who share their personal experience using technology like Docker, too many to mention but all invaluable. 
