#!/bin/bash

LOCAL_PATH=`pwd`

DEVICE=hammerhead
OBJDIR=$LOCAL_PATH/out/target/product/$DEVICE/symbols/system
PROG=$OBJDIR/bin/mediaserver
#PROG=$OBJDIR/bin/app_process_gaia

ADB=adb
GDB=arm-linux-androideabi-gdb
PS=xps

#GDB=$LOCAL_PATH/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.6/bin/arm-linux-androideabi-gdb
GDBINIT=/tmp/cos.gdbinit.`whoami`

GDB_PORT=$((20000 + $(id -u) % 50000))

exist() {
    command -v $1 >/dev/null 2>&1 || { echo >&2 "$1 may be not installed. abort"; exit 1; }
}

exist $ADB
exist $GDB;
exist $PS;

usage() {
    echo "Pls help to add description"
}

function kill_gdb() {
    gdbpid=`$ADB shell ps | grep gdbserver | tail -n 1 | awk '{print $2}'`
    if [[ -z $gdbpid ]]; then
        echo gdbserver is not running!
    else
        $ADB shell "kill -9 $gdbpid"
    fi
}
function get_app_pid() {
    targetpid=`$ADB shell ps|grep $1|tail -n 1|awk '{print $2}'`;
    echo $targetpid;
}

if [[ $# -le 2 ]]; then
    usage
    exit 0
fi

$ADB forward tcp:$GDB_PORT tcp:$GDB_PORT

if [[ "$1" == "attach" ]]; then
    # attach mode
    kill_gdb
    WRT_PID=$(get_app_pid $2)
    echo GDB_PORT = $GDB_PORT WRT_PID = $WRT_PID
    if [ -z $WRT_PID ]; then
        echo Error: No PID to attach to. WRT not running?
        exit 1
    fi
    $ADB shell gdbserver :$GDB_PORT --attach $WRT_PID &
else
    # find mode
    while [[ -z $TARGET_PID ]]
    do
        TARGET_PID=`$PS $1`
    done
    arr=(${TARGET_PID// / })
    for i in "${arr[@]}"
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
