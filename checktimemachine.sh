#!/bin/sh

### Settings
# FS is the name of the host one should mount from
FS=nas.example.com
# The name of the share
MPD=foobackup
# The name of the file which is the sparsebundle which is the real backup
SB=foo.example.com.sparsebundle


# No settings below

MP=/Volumes/$MPD

echo "Enter info for afp://${FS}/${MPD}"
read -p "Username: " USER
read -sp "Password: " PW; echo " "

if [ "x$USER" = "x" ]; then
    echo Username can not be empty
    exit 1
fi
if [ "x$PW" = "x" ]; then
    echo Password can not be empty
    exit 1
fi

if [ -e ${MP} ]; then
    echo $MP exists
    exit 1
fi

echo Creating mountpoint ${MP}
mkdir ${MP}
echo Mount file system afp://${FS}/${MPD}
mount_afp afp://${USER}:${PW}@${FS}/${MPD} ${MP}
echo Change file system flags on file system /Volumes/${MPD}/${SB}
chflags -R nouchg /Volumes/${MPD}/${SB}
echo Attach sparsebundle /Volumes/${MPD}/${SB}
FS=`hdiutil attach -nomount -noverify -noautofsck /Volumes/${MPD}/${SB} | grep Apple_HFS | awk '{ print $1 }'`
RFS=`echo $FS | sed 's/disk/rdisk/'`

echo Run fsck on sparsebundle
fsck_hfs -fy $RFS

cp /Volumes/${MPD}/${SB}/com.apple.TimeMachine.MachineID.plist /Volumes/${MPD}/${SB}/com.apple.TimeMachine.MachineID.plist.old
cat /Volumes/${MPD}/${SB}/com.apple.TimeMachine.MachineID.plist | sed 's/<integer>[12]<\/integer>/<integer>0<\/integer>/' | sed '/RecoveryBackupDeclinedDate/,/^/d' > /Volumes/${MPD}/${SB}/com.apple.TimeMachine.MachineID.plist.new
mv /Volumes/${MPD}/${SB}/com.apple.TimeMachine.MachineID.plist.new /Volumes/${MPD}/${SB}/com.apple.TimeMachine.MachineID.plist

DISK=`echo $FS | sed 's/\/dev\///' | sed 's/..$//'`
echo Detach $DISK
hdiutil detach ${DISK}

echo Unmount file system
diskutil unmount force $MP
