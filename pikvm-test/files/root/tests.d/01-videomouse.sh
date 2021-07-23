#!/bin/bash

echo Trying to test video output and mouse functionality

Xdialog --title "Mouse and video testing" --default-no --yesno "Hello!\nIf you are able to see this message, please click YES button below" 0x0 || exit $?
