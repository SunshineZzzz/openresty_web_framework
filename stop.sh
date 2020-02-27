#!/bin/sh
#purpose:
#

set -eo pipefail

CUR_PATH=$(dirname $(readlink -f $0))
OR_INSTALL_PATH="/usr/local/openresty"

"${OR_INSTALL_PATH}/bin/openresty" -p "${CUR_PATH}" -c "${CUR_PATH}/conf/nginx.conf" -s stop
