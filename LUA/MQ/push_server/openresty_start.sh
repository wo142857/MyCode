#!/bin/bash

cmd_nginx="/opt/openresty/nginx/sbin/nginx"

case ${1} in
    start)
        $cmd_nginx -p . -c conf/nginx.conf
        ;;
    stop)
        $cmd_nginx -p . -s stop
        ;;
    reload)
        $cmd_nginx -p . -s reload
        ;;
    *) 
        echo ${1}
        echo "`basename ${0}`:usage: [start] | [stop] | [reload]"
        ;;
esac

