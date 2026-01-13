# docker_pcl
build scripts for my custom docker image used to run PCL with an Nvidia GPU. OpenCV is also built here for computer vision tasks. 


## Using the code

### Build and Run the Docker Image
This installation was tested on Ubuntu 22 using Docker 20.10.18. To build, use the following commands in the root of the repository:
```
make build
make run
```
### The Arglist
Check `.arglist.default` if you want to see the key library versions in the build. 

Create a new `.arglist` to if you want to build the docker container with different library versions.