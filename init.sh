#!/bin/sh
#purpose:
#

set -eo pipefail

CUR_PATH=$(dirname $(readlink -f $0))
OR_INSTALL_PATH="/usr/local/openresty"

if [ ! -d "${CUR_PATH}/logs" ]; then
	mkdir -p "${CUR_PATH}/logs"
fi