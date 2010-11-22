#!/bin/sh

TARGET=/media/froyo_root

if ! mount | grep -q $TARGET; then
  echo "Target $TARGET not mounted"
  exit 1
fi

set -e

make -j8
cd out/target/product/generic/

sudo rsync -a root/* $TARGET
sudo rsync -a system data $TARGET
cd -
sudo rsync -a overlay/* $TARGET
sync

echo "Done"
