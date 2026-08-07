#!/bin/bash


list() {
	ssh ${USER}@${IP} " \
		bash openvpn.sh --listclients" 
}

add_user() {
	CFG_NAME=$2
	
	if [[ -z "${CFG_NAME}" ]]; then
		echo "Please provide the users name as an argument"
	elif [ $# -gt 2 ]; then
		echo "Too much arguments"
	else
		ssh ${USER}@${IP} " \
			bash openvpn.sh --addclient ${CFG_NAME} &>/dev/null && \ 
			cat ${CFG_NAME}.ovpn" > ${CFG_NAME}.ovpn 
	fi
}

revoke_user() {
	CFG_NAME=$2

	if [[ -z "${CFG_NAME}" ]]; then
		echo "Please provide the users name as an argument"
	elif [ $# -gt 2 ]; then
		echo "Too much arguments"
	else
		ssh ${USER}@${IP} " \
			bash openvpn.sh --revokeclient ${CFG_NAME} -y && \
			rm ${CFG_NAME}.ovpn" 
	fi
}


COMMAND=$1
ARGS=$@
IP=192.168.0.0
USER=root


if [[ ${COMMAND} = "--list" ]]; then
	list
elif [[ ${COMMAND} = "--add" ]]; then
	add_user ${ARGS}
elif [[ ${COMMAND} = "--revoke" ]]; then
	revoke_user ${ARGS}
else	
	echo "	Command not found"
	echo "
	USAGE: $ ./ovpn.sh COMMAND [ARGUMENTS]
	COMMANDS:
		--add [ARG1]    - adds a new vpn client with name=ARG1 and 
			          copies his .ovpn file to your local machine
		--list          - shows all active vpn clients
		--revoke [ARG1] - revokes client with name=ARG1"
fi
