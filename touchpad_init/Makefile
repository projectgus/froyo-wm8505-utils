# export/set CROSS_COMPILE from your shell/cmdline if you want something else
CROSS_COMPILE=arm-linux-gnueabi-

touchpad_init: touchpad_init.c
	$(CROSS_COMPILE)gcc -Wall -std=c99 -static -o touchpad_init touchpad_init.c
