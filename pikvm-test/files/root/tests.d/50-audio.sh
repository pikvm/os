#!/bin/bash


TITLE="Audio test"

process() {
	for i in `seq $1`; do
		sleep 1
		echo .
	done
}

rm -f /tmp/test.wav
(
	process 5 &
	arecord -D hw:2,0 -d 5 -f dat /tmp/test.wav
) | Xdialog --title $TITLE --progress "Trying to record HDMI audio... Prepare your headset for the next step" 0x0 5

Xdialog --title $TITLE --msgbox "Now after clicking OK I will try to play recorded sound. Click OK when you are ready." 0x0
(
	process 5 &
	aplay -D hw:1,0 /tmp/test.wav
) | Xdialog --title $TITLE --progress "Playing recorded sound. Try to hear it." 0x0 5
Xdialog --default-no --yesno "Did you hear something?" 0x0 || exit $?
