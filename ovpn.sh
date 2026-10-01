#!/bin/sh

#
# client chooses: 
# 	server  -> program gets data about server from config file
#	command -> program sends needed command 
#


EXIT_FAILURE=1
EXIT_SUCCESS=0
SCRIPT_NAME=$0
PATH_TO_CONFIG=~/.ovpncfg
PATH_TO_DATA=~/.ovpndat

# Server management
add_server() {
	NAME="$1"
	IP="$2"
	USER="$3"
	PATH_TO_SCRIPT="$4"

	check_server_config "$@"
	resolve_data_file	

	printf "%-31s %-31s %-15s %s\n" "$NAME" "$USER" "$IP" "$PATH_TO_SCRIPT" >> $PATH_TO_DATA
}

resolve_data_file() {	
	if [ ! -s $PATH_TO_DATA ]; then
		touch $PATH_TO_DATA
		printf "%-31s %-31s %-15s %s\n" / 
		       "SERVER_NAME" "USER_NAME" "IP_ADDRESS" "PATH_TO_SCRIPT" /
		       >> $PATH_TO_DATA
	fi	
}

resolve_config_file() {	
	if [ ! -s $PATH_TO_CONFIG ]; then
		touch $PATH_TO_CONFIG
		echo "SERVER" >> $PATH_TO_CONFIG
		echo "USER" >> $PATH_TO_CONFIG
	fi	
}

check_server_config() {		
	#TODO: add constraints
	if [ -z $NAME ]; then
		echo "ERROR: invalid name for server configuration"
		exit $EXIT_FAILURE	
	elif [ -z $IP ]; then
		echo "ERROR: invalid ip address for server configuration"
		exit $EXIT_FAILURE
	elif [ -z $USER ]; then
		echo "ERROR: invalid username for server configuration"
		exit $EXIT_FAILURE
	elif [ -z $PATH_TO_SCRIPT ]; then
		echo "ERROR: invalid path to script for server configuration"
		exit $EXIT_FAILURE
	fi
}

remove_server() {
	NAME="$1"
	USER="$2"	
}

switch_server() {
	NAME="$1"
	USER="$2"

	if [ -z $NAME ] || [ -z $USER ]; then
		echo "ERROR: provide correct server's name and its user!"	
	else
		resolve_data_file
		CONFIG="$(awk -v user="$USER" -v srvname="$NAME" '$1 == srvname && $2 == user' $PATH_TO_DATA)"
		if [ -z "$CONFIG" ]; then
			echo "ERROR: there is no such server."
		else
			resolve_config_file
			awk -v srvname=$NAME -v username=$USER '
				{
					if ($1 == "SERVER") {
						printf "SERVER %s\n", srvname		
					} else if ($1 == "USER") {
						printf "USER %s\n", username
					} else {
						print $0
					}
				}
			' $PATH_TO_CONFIG > /tmp/.ovpncfg
			mv /tmp/.ovpncfg $PATH_TO_CONFIG
		fi
	fi
}

get_server() {
	resolve_config_file
	awk '$1 == "SERVER" { print $2; exit }' $PATH_TO_CONFIG
}

get_user() {
	resolve_config_file
	awk '$1 == "USER" { print $2; exit }' $PATH_TO_CONFIG
}

# Commands for executing on the server
list() {
	ssh ${USER}@${IP} " \
		${SRV_SHELL} ${PATH_TO_SRV_SCRIPT} --listclients" 
}


add_user() {
	CFG_NAME=$2
	
	if [[ -z "${CFG_NAME}" ]]; then
		echo "Please provide the users name as an argument"
	elif [ $# -gt 2 ]; then
		echo "Too much arguments"
	else
		ssh ${USER}@${IP} " \
			${SHELL} ${PATH_TO_SERVER_SCRIPT} --addclient ${CFG_NAME} &>/dev/null && \ 
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
			bash ${SERVER_SCRIPT} --revokeclient ${CFG_NAME} -y && \
			rm ${CFG_NAME}.ovpn" 
	fi
}

help() {
	echo "
	USAGE: $ ./ovpn.sh CMD [ARGUMENTS]
	CMDS:
		--add [ARG1]    - adds a new vpn client with name=ARG1 and 
				  copies his .ovpn file to your local machine
		--list          - shows all active vpn clients
		--revoke [ARG1] - revokes client with name=ARG1"
}

error_msg() {	
	echo "Unknown command. Use '${SCRIPT_NAME} -h' to see the manual."
}

main() {
	CMD="$1"	
	shift
	ARGS="$@"
	case $CMD in 
		list)
			list_users $ARGS ;;
		add)
			add_user $ARGS ;;
		revoke) 
			revoke_user $ARGS ;;
		switch)
			switch_server $ARGS ;;
		add-server)
			add_server $ARGS ;;
		remove-server)
			remove_server $ARGS ;;
		-h|--help)
			help ;;
		*)
			error_msg ;;
	esac	
}

main $@
