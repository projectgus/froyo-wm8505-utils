#!/bin/sh

if [ "$#" -ne 3 ]; then
	 echo "WM8505 Android firmware image build  helper"
	 echo
	 echo "Makes sd card image of an Android WM8505 install via loopback"
	 echo
	 echo "If you just want to put the firmware directly on an already-formatted"
	 echo "SD card, use build_sd_boot instead."
	 echo
	 echo "You will need to run this script as root, or with sudo."
	 echo
	 echo "Usage: $0 <Path to AOSP Root> <Path to write out images> <tablet>"
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
OUTDIR=$2
TABLET=$3
SIZE=1800

IMG=$TMPDIR/froyo-sdcard-$TABLET.img

rm -rf $TMPDIR

set -e

mkdir -p $FATDIR
mkdir -p $ROOTDIR
mkdir -p $MOUNTFAT
mkdir -p $MOUNTROOT

$SCRIPTDIR/build_sd_boot.sh $AOSPDIR $FATDIR $ROOTDIR $TABLET

mkdir -p $OUTDIR


echo "Building sparse disk image..."
set +e
dd if=/dev/zero of=$IMG bs=1M skip=$SIZE count=0
set -e


echo "Partitioning..."
sfdisk -uM $IMG <<EOF
,150,6
,128,82
,,83
EOF

kpartx -a $IMG


# assuming no other loopback devices, so /dev/mapper/loop0pX
LOOP=/dev/mapper/loop0

mkfs.vfat -F16 -n "froyo-fat" ${LOOP}p1
mkswap ${LOOP}p2
mkfs.ext2 -L "froyo-root" ${LOOP}p3

echo "Copying files & making tarballs..."

mount ${LOOP}p1 $MOUNTFAT
mount ${LOOP}p3 $MOUNTROOT
cp -r $FATDIR/* $MOUNTFAT
cp -a $ROOTDIR/* $MOUNTROOT
cd $SCRIPTDIR
umount ${LOOP}p1
umount ${LOOP}p3

kpartx -d $IMG

echo "Making tarballs..."

cd $FATDIR
tar zvcf "$OUTDIR/fatpart-$TABLET.tgz" .
cd $ROOTDIR
tar zvcf "$OUTDIR/extpart-$TABLET.tgz" .

echo "Compressing raw images..."
cd `dirname $IMG`
zip -r "$OUTDIR/froyo-sdcard-$TABLET.zip" `basename $IMG`
gzip $IMG
mv $IMG.gz $OUTDIR

echo "Done, cleaning up..."
cd $SCRIPTDIR
rm -rf $TMPDIR


