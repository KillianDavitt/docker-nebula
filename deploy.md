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

Login with your account 
    
    docker login

With an account created, you can now push that image to a docker registry using standard docker commands. Note that you can name your image as you like, so long as the name matches the appropriate pattern for your registry. So, for _Docker Hub_, the name should match the pattern `username/image-name`.


    docker push username/myapp  # modify push parameter as approptiate

To run the image on a docker host, login to the host of initialise your docker client with environment variables appropriately, and type:

    $ docker run registry-account-name/myapp

That is all there is to it if you are happy to use _Docker Hub_, or an equivalent registry service. 



