#!/bin/bash

case ${1} in
    start)
        openresty -p . -c conf/nginx.conf
        ;;
    stop)
        openresty -p . -s stop
        ;;
    reload)
        openresty -p . -s reload
        ;;
    *) 
        echo ${1}
        echo "`basename ${0}`:usage: [start] | [stop] | [reload]"
        ;;
esac

