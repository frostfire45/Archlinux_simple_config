# Archlinux_simple_config
Used to get a Archlinux inustance up and running for a VM with 50 GiB 

run to update all packages
pacman -Sy

Initial Startup requires you to ensure that glib.so > 2.33-5
To find the version

pacman -Ss glib | grep installed
To install
pacman -S glibc <2.33-5>

Install git
pacman -S git


Then run git clone on this repo
