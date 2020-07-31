#!/bin/bash
set -euxo pipefail
rm /etc/ssh/ssh_host_*key*
ssh-keygen -v -A
