#!/bin/sh
#
# System backup transfer script to usbstick for OpenVario and XCSoar
#
# This backup script stores all XCSoar settings and relevant OpenVario settings
# like:
#   - brightness of the display
#   - rotation
#   - Touch screen calibration
#   - language settings
#   - dropbear settings
#   - SSH, variod and sensord status
#
# Backups are stored at USB stick at:
#   openvario/backup/"MAC address of eth0"/
# So you can store more than one backup on the same stick!
#
# 7lima & Blaubart, 2022-06-19
#
# This backup script stores all XCSoar settings and relevant OpenVario settings like:
#
# -brightness of the display
# -rotation
# -Touch screen calibration
# -language settings
# -dropbear settings
# -SSH, variod and sensord status
# 
# backups are stored at USB stick at:
# openvario/backup/"MAC address of eth0"/

So you can store more than one backup on the same stick!


# Path where the USB stick is mounted
USB_PATH=/usb/usbstick
# Backup path on the USB stick
BACKUP=openvario/backup
# MAC address of the Ethernet device eth0 to do a separate backup
MAC=`ip li|grep -A 1 eth0|tail -n 1|cut -d ' ' -f 6|sed -e s/:/-/g`

# Store SSH status 
if   /bin/systemctl --quiet is-enabled dropbear.socket
then	echo enabled
elif /bin/systemctl --quiet is-active  dropbear.socket
then	echo temporary
else	echo disabled  
fi > /home/root/ssh-status

# Store variod and sensord status
for DAEMON in variod sensord
do
	if /bin/systemctl --quiet is-enabled $DAEMON
	then echo  enabled
	else echo disabled  
	fi > /home/root/$DAEMON-status
done

# Copy brightness setting
cat /sys/class/backlight/lcd/brightness > /home/root/brightness

# Copy all directories and files from list to backup directory recursively
echo "
/etc/locale.conf
/etc/udev/rules.d/libinput-ts.rules
/etc/pointercal
/etc/dropbear
/etc/opkg
/home/root
/opt/conf
/var/lib/connman
/boot/config.uEnv
" |
if 
	echo ' Starting backup ...'
	echo ' Wait until "DONE !!" appears before you exit!'
	rsync --files-from - --archive --recursive --quiet --relative --mkpath \
	      --checksum --safe-links \
	      / "$USB_PATH/$BACKUP/$MAC"/
	RSYNC_EXIT=$?
# Sync the system buffer to be sure data is on disk
	sync
	test $RSYNC_EXIT -eq 0
then
	echo ' All files and some settings have been backed up.'
	echo ' DONE !!'
	exit 0
else 
	echo ' An error has occurred!'
	echo ' Copying using rsync issued error code' $RSYNC_EXIT
	echo ' DONE !!'
	exit $RSYNC_EXIT
fi
