DOCKERIMAGE=ubuntu:16.04
SHAREDDIR=$PWD/shared
sudo docker rm opae_build
sudo docker run -it --privileged -v $SHAREDDIR:/shared -h opae_build --name opae_build $DOCKERIMAGE /bin/bash
