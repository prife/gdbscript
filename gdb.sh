#!/bin/bash

LOCAL_PATH=`pwd`

DEVICE=hammerhead
OBJDIR=$LOCAL_PATH/out/target/product/$DEVICE/symbols/system
PROG=$OBJDIR/bin/mediaserver
#PROG=$GECKO_OBJDIR/bin/app_process_gaia

ADB=adb
GDB=arm-linux-androideabi-gdb
#GDB=$LOCAL_PATH/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.6/bin/arm-linux-androideabi-gdb

GDBINIT=/tmp/cos.gdbinit.`whoami`

GDB_PORT=$((20000 + $(id -u) % 50000))

$ADB forward tcp:$GDB_PORT tcp:$GDB_PORT

if [ "$1" = "attach" ]; then
   # attach mode
   WRT_PID=$2
   if [ -z $WRT_PID ]; then
      echo Error: No PID to attach to. WRT not running?
      exit 1
   fi

   echo GDB_PORT = $GDB_PORT WRT_PID = $WRT_PID 
   $ADB shell gdbserver :$GDB_PORT --attach $WRT_PID &
else
   # find mode
   while [ -z $TARGET_PID ]
   do
   TARGET_PID=`xps $1`
   done

   arr=(${TARGET_PID// / })

   for i in ${arr[@]}
   do
      echo $i
   done
   WRT_PID=${arr[2]}
   $ADB shell gdbserver :$GDB_PORT --attach $WRT_PID &
fi

sleep 3
echo "set solib-absolute-prefix $OBJDIR/../" > $GDBINIT
echo "set solib-search-path $OBJDIR/lib" >> $GDBINIT
echo "target extended-remote :$GDB_PORT" >> $GDBINIT

echo $GDB -x $GDBINIT $PROG
$GDB -x $GDBINIT $PROG
