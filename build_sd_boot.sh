#!/bin/sh

if [ "$#" -ne 4 ]; then
	 echo "WM8505 Android firmware build & install helper"
	 echo "Builds an AOSP firmware, adds files in overlay/ to the filesystem"
	 echo "image, and installs it all to boot from an SD card."
	 echo
	 echo "(Requires sudo, will prompt you for a sudo password.)"
	 echo
	 echo "Usage: $0 <Path to AOSP Root> <Path to FAT partition> <Path to ext2 partition> <tablet>"
	 echo
	 echo "Supported tablets are m001, m003 (m002 same as m001?), maybe others?"
	 exit 1
fi

SCRIPTDIR=`dirname $(readlink -f $0)`
AOSP="$1"
FATPART="$2"
EXTPART="$3"
TABLET="$4"

if ! [ -d $AOSP ]; then
	 echo "Android root directory not found : $AOSP"
	 exit 1
fi
if ! [ -d $FATPART ]; then
	 echo "FAT directory/mount point not found : $FATPART"
	 exit 1
fi
if ! [ -d $EXTPART ]; then
	 echo "ext2 directory/mount point not found : $EXTPART"
	 exit 1
fi

AOSP=`cd $AOSP; pwd`
FATPART=`cd $FATPART; pwd`
EXTPART=`cd $EXTPART; pwd`

set -e

cd $AOSP
#make -j8

# copy AOSP build output
cd out/target/product/generic/ # todo: support different product names/debug
echo "Syncing AOSP output..."
sudo rsync -a root/* $EXTPART
sudo rsync -a system data $EXTPART


# build touchpad_init

cd $SCRIPTDIR/touchpad_init
make
sudo cp touchpad_init $EXTPART/system/bin/


# scriptcmd
cd $SCRIPTDIR
mkdir -p $FATPART/script/
mkimage -A arm -O linux -T script -C none -a 1 -e 0 -n "script image" -d script/cmd $FATPART/script/scriptcmd

# copy overlay & script files
echo "Syncing overlay..."
cd $SCRIPTDIR
sudo rsync -a overlay/* $EXTPART
if [ -e overlay_$TABLET ]; then
  sudo rsync -a overlay_$TABLET/* $EXTPART
fi
sudo rsync -a script $FATPART
if [ -e script_$TABLET ]; then
  sudo rsync -a script_$TABLET/* $EXTPART
fi
sync

echo "Done"
