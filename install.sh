#!/bin/bash

alias=r1

. /srv/http/bash/addons.sh

sed -i '/^#IgnorePkg/ a\IgnorePkg   = raspberrypi-firmware raspberrypi-bootloader raspberrypi-bootloader-x' /etc/pacman.conf
pacman -Sy --noconfirm cifs-utils

installstart "$1"

getinstallzip

installfinish
