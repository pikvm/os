#!/bin/bash

CURDIR=$(dirname $(readlink -f $0))
TESTDIR=$CURDIR/tests.d

TITLE="Testing wizard"

(
	echo "** Starting testing sequence"
	echo

	Xdialog --title="$TITLE" --msgbox "Hello! This wizard will guide you through the testing proccess.\nClick OK to proceed" 0x0

	if [ -d $TESTDIR ] ; then
		for f in $TESTDIR/* ; do
			[ -f "$f" ] || continue
			[ -x "$f" ] || { echo "** File $f is not executable. Skipped."; continue; }
			echo "** Launching test script $f"
			$f || {
				RET=$?
				echo
				echo "!! Testing sequence has been failed by $f test script with exit code $RET"
				Xdialog --title="$TITLE" --msgbox "!!! Test sequence FAILED !!!\nPlease mark this board for further invistigation!" 0x0
				exit $RET
			}
			echo
		done
		unset f
	fi

	echo "** Testing sequence successful"
	Xdialog --title="$TITLE" --msgbox "Test successful! Thank you!" 0x0
) 2>&1 | tee /tmp/test.log

# hang
while [ 1 -eq 1 ]; do
	sleep 1
done
