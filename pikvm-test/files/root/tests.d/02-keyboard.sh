#!/bin/bash

TITLE="Keyboard"
TESTSTRING="This is the KEYBOARD test."

TEXT=`Xdialog --title $TITLE --inputbox "Please type the following text case sensitive:\n\n$TESTSTRING" 0x0 2>&1`
RET=$?
[ $? -ne 0 ] && exit $RET
[ x"$TEXT" = x"$TESTSTRING" ] || exit 2
