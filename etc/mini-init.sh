#!/bin/sh

 #   mini-init.sh -- main shell script, used by the pi2pwd project.
 #
 #   Copyright 2016 mincepi     mincepi at gmail.com
 #
 #   This program is free software: you can redistribute it and/or modify
 #   it under the terms of the GNU General Public License as published by
 #   the Free Software Foundation, either version 3 of the License, or
 #   (at your option) any later version.
 #
 #   This program is distributed in the hope that it will be useful,
 #   but WITHOUT ANY WARRANTY; without even the implied warranty of
 #   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 #   GNU General Public License for more details.
 #
 #   You should have received a copy of the GNU General Public License
 #   along with this program.  If not, see <http://www.gnu.org/licenses/>.

echo Processing mini-init.sh...

VERSION=`uname -r`
/bin/mount -t proc /proc /proc
/bin/mount -t sysfs /sys /sys
/sbin/insmod /lib/modules/$VERSION/kernel/drivers/usb/gadget/udc/udc-core.ko
/sbin/insmod /lib/modules/$VERSION/kernel/drivers/usb/dwc2/dwc2.ko
/sbin/insmod /lib/modules/$VERSION/kernel/drivers/usb/gadget/libcomposite.ko
/sbin/insmod /lib/modules/$VERSION/kernel/drivers/usb/gadget/function/usb_f_hid.ko
/sbin/insmod /lib/modules/$VERSION/kernel/drivers/usb/gadget/legacy/g_hid.ko

# wait for USB system to become stable
sleep 5
# run regular init if keyboard is plugged into USB jack
lsusb -v | grep Keyboard && exec /sbin/init
echo mini-init...
# turn off HDMI output to reduce current consumption
/opt/vc/bin/tvservice -o
IFS=''

# main loop
# NOTE: getleds only returns a value if there is a change in lock light state.
while true; do
    # wait until all lights are on
    while true; do
	LIGHTS=`/etc/getleds`
	if [ "$LIGHTS" = 7 ]; then break; fi
    done

    # print account ids one by one
    while true; do
	while true; do
	    read -r ID
	    read -r USER
	    read -r PASS
	    if [ -z "$ID" ]; then break; fi
	    echo "$ID" | /etc/hidgsend -i
	    # is there a change in the lights?
	    LIGHTS=`/etc/getleds`
	    if [ -n "$LIGHTS" ]; then
		echo "$ID" | /etc/hidgsend -d
		while true; do
		    case "$LIGHTS" in
			# is caps lock off?
			(5)	
			    echo "$USER" | /etc/hidgsend
			;;
			# is num lock off?
			(6)
			    echo "$PASS" | /etc/hidgsend -i
			;;
			# are both caps lock and num lock off?
			(4)
			    echo "$PASS" | /etc/hidgsend
			;;
			# is scroll lock off?
			(0 | 1 | 2 | 3 ) break 3;;
		    esac
		    LIGHTS=`/etc/getleds`
		done
	    fi
	    echo "$ID" | /etc/hidgsend -d
	done < /etc/data
    done
done
