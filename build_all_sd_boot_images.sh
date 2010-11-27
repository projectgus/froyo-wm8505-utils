#!/bin/sh
for tablet in m001 m003; do
  "`dirname $0`/build_sd_boot_images.sh" $* $tablet
done
