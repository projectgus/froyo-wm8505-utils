#!/system/bin/sh

if [ -f /.driver/g_file_storage.ko ] ; then
    if [ -f /busybox/sbin/losetup ] ; then
        echo "Find /busybox/sbin/losetup"
        mkdir /.vfat_dir
        mount -t yaffs2 /dev/block/mtdblock12 /.vfat_dir
        if [ $? -ne 0 ] ; then
            echo "Fail to mount /dev/block/mtdblock12 to /.vfat_dir"
            exit 0
        fi
        if [ -f /.vfat_dir/vfat.bin ] ; then
            /busybox/sbin/losetup /dev/block/loop0 /.vfat_dir/vfat.bin
            if [ $? -eq 0 ] ; then
                echo "losetup successful"
                insmod /.driver/g_file_storage.ko file=/dev/block/loop0,/dev/block/mmcblk0 removable=1 stall=0
                if [ $? -eq 0 ] ; then
                    echo "insmod g_file_storage.ko file=/dev/block/loop0,/dev/block/mmcblk0 successful"
                    mkdir /LocalDisk
                    /system/bin/mount -o dirsync,nosuid,nodev,noexec,utf8,uid=1000,gid=1015,fmask=702,dmask=702,shortname=mixed -t vfat /dev/block/loop0  /LocalDisk
                    if [ $? -eq 0 ] ; then
                        echo "mount -t vfat /dev/block/loop0 to /LocalDisk successful"
                    else
                        echo "fail to mount /dev/block/loop0 to /LocalDisk"
                    fi
                else
                    echo "Fail to insmod g_file_storage.ko file=/dev/block/loop0,/dev/block/mmcblk0"
                fi
            else
                echo "Fail to losetup /dev/block/loop0 /.vfat_dir/vfat.bin"
            fi
        else
            echo "Not find /.vfat_dir/vfat.bin"
            insmod /.driver/g_file_storage.ko  file=/dev/block/mmcblk0 removable=1 stall=0
            if [ $? -eq 0 ] ; then                                                
                echo "insmod g_file_storage.ko file=/dev/block/mmcblk0 successful"   
            else                                                        
                echo "Fail to insmod g_file_storage.ko file=/dev/block/mmcblk0"     
            fi
            umount /.vfat_dir
            mkdir /LocalDisk
            mount -t yaffs2  /dev/block/mtdblock12 /LocalDisk
            if [ $? -eq 0 ] ; then
                echo "mount -t yaffs2 /dev/block/mtdblock12 to /LocalDisk successful"
            else
                echo "fail to mount /dev/block/mtdblock12 to /LocalDisk" 
            fi
        fi
    else
        echo "Not find /busybox/sbin/losetup"
        insmod /.driver/g_file_storage.ko  file=/dev/block/mmcblk0 removable=1 stall=0
        if [ $? -eq 0 ] ; then                                                
            echo "insmod g_file_storage.ko file=/dev/block/mmcblk0 successful"      
        else                                                        
            echo "Fail to insmod g_file_storage.ko file=/dev/block/mmcblk0" 
        fi
        mkdir /LocalDisk
        mount -t yaffs2  /dev/block/mtdblock12 /LocalDisk
        if [ $? -eq 0 ] ; then
            echo "mount -t yaffs2 /dev/block/mtdblock12 to /LocalDisk successful"
        else
            echo "fail to mount /dev/block/mtdblock12 to /LocalDisk"
        fi
    fi
else
    mkdir /LocalDisk
    mount -t yaffs2  /dev/block/mtdblock12 /LocalDisk
    if [ $? -eq 0 ] ; then
        echo "mount -t yaffs2 /dev/block/mtdblock12 to /LocalDisk successful" 
    else
        echo "fail to mount /dev/block/mtdblock12 to /LocalDisk"
    fi
fi
