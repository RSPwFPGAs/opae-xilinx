# First, install docker on Ubuntu.

>
>```bash
>    sudo apt update && sudo apt upgrade
>    sudo snap install docker --stable
>    sudo groupadd docker
>    sudo usermod -aG docker $USER


# Then, create a new docker image.

>
>```bash
>    source create_container.sh

## Inside the docker VM, download the OPAE source code(Drivers, SDK, Python bindings), and then build and install them.

>
>```bash
>    cd shared
>    source install_opae_src.sh

# Start the docker image, without recreating it.

>
>```bash
>    source start_container.sh

