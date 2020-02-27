#!/bin/sh
#purpose:
#

source "./init.sh"

"${OR_INSTALL_PATH}/bin/openresty" -p "${CUR_PATH}" -c "${CUR_PATH}/conf/nginx.conf"