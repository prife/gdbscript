#!/bin/bash

#########################################################
# If DEFAULT_GDB_UI == cgdb, pls install cgdb           #
# If DEFAULT_GDB_UI == emacs, pls install emacs         #
#                                                       #
# + install emacs                                       #
# apt-get install emacs                                 #
# + install cgdb                                        #
#########################################################

LOCAL_PATH=`pwd`

DEFAULT_GDB_UI=cgdb
DEVICE=hammerhead
OBJDIR=$LOCAL_PATH/out/target/product/$DEVICE/symbols/system
PROG=$OBJDIR/bin/mediaserver
#PROG=$OBJDIR/bin/app_process_gaia

ADB=adb
GDBPATH=arm-linux-androideabi-gdb
#GDBPATH=$LOCAL_PATH/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.6/bin/arm-linux-androideabi-gdb
GDB="cgdb -d $GDBPATH"

GDBINIT=/tmp/cos.gdbinit.`whoami`

GDB_PORT=$((20000 + $(id -u) % 50000))

$ADB forward tcp:$GDB_PORT tcp:$GDB_PORT

function kill_gdb() {
    gdbpid=`$ADB shell ps | grep gdbserver | tail -n 1 | awk '{print $2}'`
    if [ -z $gdbpid ]; then
      echo gdbserver is not running!
    else
        $ADB shell "kill -9 $gdbpid"
    fi
}

function get_app_pid() {
    targetpid=`$ADB shell ps|grep $1|tail -n 1|awk '{print $2}'`;
    echo $targetpid;
}

if [ "$1" = "attach" ]; then
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

if [[ $DEFAULT_GDB_UI == "cgdb" ]]; then
    echo $GDB -x $GDBINIT $PROG
    $GDB -x $GDBINIT $PROG
fi

if [[ $DEFAULT_GDB_UI == "emacs" ]]; then
    echo "cmd $0"
    tail -33 $0 > /tmp/gdb.el
    echo "emacs -l /tmp/gdb.el $GDBPATH -x $GDBINIT $PROG"
    emacs -l /tmp/gdb.el $GDBPATH -x $GDBINIT $PROG
fi

exit 0
#################### end here #################################

;;; package --- Summary
;;; Commentary:
;;; code:

;; (defconst gdbpath "/usr/bin/gdb"
;;   "set the gdb path")

;; We can't using with-output-to-string in emacs, because the implement
;; is diff than cl
(defun concatString (lst)
  "concatenates a list of strings"
  (if (listp lst)
      (let ((str ""))
        (dolist (item lst)
          (when (stringp item)
              (setq str (concat str item))
              (setq str (concat str " "))))
        str)))

(defun gdb-multiwindows-main ()
  "run gdb command with multiwindows show"
  (setq gdb-many-windows t)
  (let ((gdb-args "")
        (gdb-cmd ""))
    (setq gdb-cmd (car command-line-args-left))
    (setq command-line-args-left (cdr command-line-args-left))
    (if (>= emacs-major-version 24)
        (setq gdb-args " --i=mi ")
      (setq gdb-args " --annotate=3 "))
    ;;(message-box (concatString (cons gdb-cmd (cons gdb-args command-line-args-left))))
    (gdb (concatString (cons gdb-cmd (cons  gdb-args command-line-args-left))))))

(gdb-multiwindows-main)
