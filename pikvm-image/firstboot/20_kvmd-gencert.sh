#!/bin/bash
set -euxo pipefail
rm /etc/kvmd/nginx/ssl/*
kvmd-gencert --do-the-thing
