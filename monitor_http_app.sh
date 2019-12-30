#!/bin/bash

# Vars
seconds=3

# TESTTIME=`date "+%H:%M:%S"`

auto_init() {
    run_test
}

# Takes two arguments:
#     ${1}: Message as string to log as an event in journald
#     ${2}: Priority of the message as string, options: info, warning and emerg
log_event() {
    echo "$1" | systemd-cat -t "monitor_script" -p "${2}"
}

curl_endpoint() {
    unset response
    response=$(curl -s -o /dev/null -w "%{http_code}" ${SITE})
    echo ${response}
}

run_test() {
    curl_endpoint
    try=0
    while [ "${response}" != "200" ]
    do
        log_event "Something is wrong. Retrying in ${seconds} seconds..." "warning"
        sleep ${seconds}
        curl_endpoint
        ((try++))
        if [[ ${try} > 1 ]];
        then
            # sudo systemctl restart openvpn
            log_event "OpenVPN service has been restarted" "emerg"
            exit 1
        fi
    done
}

echoHelp () {
less << EOF1
Usage:
	./monitor_http_app.sh [-h] [-s http://host:port/endpoint]
OPTIONS:
	-h	Show this message
	-s	site URL to test
	-n	app name
	
EOF1
}

while getopts ":hs:" OPTION
do
	case $OPTION in
		h) echoHelp; exit 1;;
		s) SITE="$OPTARG";;
		?) echo "Invalid option or empty value: -$OPTARG"; exit 1;;
	esac
done

auto_init
