#!/system/bin/sh

# This is custom WM8505 boot-time init stuff
# in here, not init.rc, to make things easier to follow
#
# (most is copied from WMT's init.rc, though)

echo "Powering up Wifi"
echo out > /sys/class/gpio/gpio2/direction
echo 1 > /sys/class/gpio/gpio2/value

# *** chmod some nodes

nodes=( /sys/class/leds/lcd-backlight/brightness
	 /proc/boot-splash
	 /proc/lcd-bltlevel
	 /dev/wmt_vibrate
	 /sys/class/timed_output/vibrator/enable
	 /dev/mbdev
	 /dev/graphics/fb1
	 /system/etc/Wireless/RT2870STA/RT2870STA.dat
	 /system/etc/Wireless/RT2870STA/RT2870STA.tmp
)
for node in ${nodes[@]}; do
	 chmod 0777 $node
done

# *** insert some modules

cd /lib/modules/auto
insmod wm9715-api.ko
insmod usbnet.ko
for mod in *.ko; do
	 # don't think order matters from here on in
	 insmod $mod
done
#	insmod g_file_storage.ko  removable=1 stall=0  file=/dev/block/mmcblk0


# *** calibrate the touchscreen
/system/bin/touchpad_init

# *** install busybox if it hasn't been installed
if ! [ -e /data/busybox/sh ]; then
  cd /data/busybox/
  ./busybox --install
fi

# *** enable swap
swapon /dev/block/mmcblk0p3
# (slatedroid guys seem to think these are good swappiness levels, so we'll do them too!)
echo 15 > /proc/sys/vm/swappiness 
sysctl -w vm.swappiness=40

