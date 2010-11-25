#!/bin/sh

if [ "$#" -ne 4 ]; then
	 echo "WM8505 Android firmware image build  helper"
	 echo
	 echo "Makes an image on an sd card and then generates images from it"
	 echo "(I tried using just a disk image + loopback w/o a real SD but it's"
	 echo "a nightmare partitioning a loopback device!)"
	 echo
	 echo "If you just want to put the firmware directly on the SD card itself,"
	 echo "use build_sd_boot instead."
	 echo
	 echo "You will need to run this script as root, or with sudo"
	 echo
	 echo "Usage: $0 <Path to AOSP Root> <SD card device> <Path to write out images> <tablet>"
	 echo
	 echo "Supported tablets are m001, m003 (m002 same as m001?), maybe others?"
	 exit 1
fi

SCRIPTDIR=`dirname $(readlink -f $0)`
TMPDIR=/tmp/froyo-wm8505-temp
FATDIR=$TMPDIR/fat
ROOTDIR=$TMPDIR/root
MOUNTFAT=$TMPDIR/mount_fat
MOUNTROOT=$TMPDIR/mount_root

AOSPDIR=$1
SDDEV=$2
OUTDIR=$3
TABLET=$4

rm -rf $TMPDIR

if ! [ -b $SDDEV ]; then
	 echo "$SDDEV will need to be a block device"
	 exit 1
fi

set -e

mkdir -p $FATDIR
mkdir -p $ROOTDIR
mkdir -p $MOUNTFAT
mkdir -p $MOUNTROOT

$SCRIPTDIR/build_sd_boot.sh $AOSPDIR $FATDIR $ROOTDIR $TABLET


if mount | grep $SDDEV; then
	 echo "One or more partitions on $SDDEV are mounted. Unmounted first (note that the entire device will be erased"
	 rm -rf $TMPDIR
	 exit 1
fi

mkdir -p $OUTDIR


echo "Zeroing the SD card to get a clean image... this might take some time..."
set +e
dd if=/dev/zero of=$SDDEV bs=1M
set -e
echo "Done zeroing..."

fdisk $SDDEV <<EOF
o
w
EOF

sfdisk -uM $SDDEV <<EOF
,150,6
,128,82
,,83
EOF

mkfs.vfat -F16 -n "froyo-fat" "${SDDEV}1"
mkswap "${SDDEV}2"
mkfs.ext2 -L "froyo-root" "${SDDEV}3"

echo "Copying files & making tarballs..."

mount "${SDDEV}1" $MOUNTFAT
mount "${SDDEV}3" $MOUNTROOT
cp -r $FATDIR/* $MOUNTFAT
cp -a $ROOTDIR/* $MOUNTROOT
cd $SCRIPTDIR
umount "${SDDEV}1"
umount "${SDDEV}3"

echo "Making tarballs..."

cd $FATDIR
tar zvcf "$OUTDIR/fatpart-$TABLET.tgz" .
cd $ROOTDIR
tar zvcf "$OUTDIR/extpart-$TABLET.tgz" .


echo "Generating images (another slow one, hogs ram on tmpfs too!)..."
dd if=$SDDEV of=$TMPDIR/image-$TABLET.img bs=1M
cd $TMPDIR
zip -r "$OUTDIR/image-$TABLET.zip" image-$TABLET.img
gzip image-$TABLET.img
mv image-$TABLET.img.gz $OUTDIR

echo "Done, cleaning up..."
cd $SCRIPTDIR
rm -rf $TMPDIR


