#!/bin/sh

# CONSTANTS
EXIT_FAILURE=1
EXIT_SUCCESS=0
SCRIPT_NAME=$0
PATH_TO_CONFIG=~/.ovpncfg
PATH_TO_DATA=~/.ovpndat

# GLOBAL VARIABLES
SERVER_NAME=""
USER=""
IP=""
PATH_TO_SERVER_SCRIPT=""

# Server management
add_server() {
	_NAME="$1"
	_IP="$2"
	_USER="$3"
	_PATH_TO_SCRIPT="$4"

	check_server_config "$@"
	resolve_data_file	

	printf "%-31s %-31s %-15s %s\n" "$_NAME" "$_USER" "$_IP" "$_PATH_TO_SCRIPT" >> $PATH_TO_DATA
}

resolve_data_file() {	
	if [ ! -s $PATH_TO_DATA ]; then
		touch $PATH_TO_DATA
		printf "%-31s %-31s %-15s %s\n" "SERVER_NAME" "USER" "IPv4_ADDRESS" "PATH_TO_SCRIPT" >> $PATH_TO_DATA
	fi	
}

resolve_config_file() {	
	if [ ! -s $PATH_TO_CONFIG ]; then
		touch $PATH_TO_CONFIG
		echo "SERVER_NAME" >> $PATH_TO_CONFIG
		echo "USER" >> $PATH_TO_CONFIG
		echo "IPv4_ADDRESS" >> $PATH_TO_CONFIG
		echo "PATH_TO_SCRIPT" >> $PATH_TO_CONFIG
	fi	
}

check_server_config() {		
	#TODO: add constraints
	if [ -z $_NAME ]; then
		echo "ERROR: invalid name for server configuration"
		exit $EXIT_FAILURE	
	elif [ -z $_IP ]; then
		echo "ERROR: invalid ip address for server configuration"
		exit $EXIT_FAILURE
	elif [ -z $_USER ]; then
		echo "ERROR: invalid username for server configuration"
		exit $EXIT_FAILURE
	elif [ -z $_PATH_TO_SCRIPT ]; then
		echo "ERROR: invalid path to script for server configuration"
		exit $EXIT_FAILURE
	fi
}

remove_server() {
	_NAME="$1"
	_USER="$2"	

	if [ -z $_NAME ] || [ -z $_USER ]; then
		echo "ERROR: provide correct server's name and its user!"
		exit EXIT_FAILURE
	fi
	
	awk -v server_name=$_NAME -v user=$_USER '
	{
		if ($1 == server_name && $2 == user) {
			next
		} else {
			print $0
		}
	}
	' $PATH_TO_DATA > /tmp/.ovpndat
	mv /tmp/.ovpndat $PATH_TO_DATA
}

switch_server() {
	_NAME="$1"
	_USER="$2"

	if [ -z $_NAME ] || [ -z $_USER ]; then
		echo "ERROR: provide correct server's name and its user!"
		exit EXIT_FAILURE
	fi

	resolve_data_file
	CONFIG="$(awk -v user=$_USER -v srvname=$_NAME '$1 == srvname && $2 == user' $PATH_TO_DATA)"
	if [ -z "$CONFIG" ]; then
		echo "ERROR: there is no such server."
	else
		resolve_config_file
		_IP="$(echo "$CONFIG" | awk '{ print $3 }')"
		_PATH_TO_SCRIPT="$(echo "$CONFIG" | awk '{ print $4 }')"
		awk -v srvname=$_NAME -v username=$_USER -v ip=$_IP -v path_to_script=$_PATH_TO_SCRIPT '
			{
				if ($1 == "SERVER_NAME") {
					printf "SERVER_NAME %s\n", srvname		
				} else if ($1 == "USER") {
					printf "USER %s\n", username
				} else if ($1 == "IPv4_ADDRESS") {
					printf "IPv4_ADDRESS %s\n", ip
				} else if ($1 == "PATH_TO_SCRIPT") {
					printf "PATH_TO_SCRIPT %s\n", path_to_script	
				} else {
					next
				}
			}
		' $PATH_TO_CONFIG > /tmp/.ovpncfg
		mv /tmp/.ovpncfg $PATH_TO_CONFIG
	fi
}

get_credentials() {
	resolve_config_file

	SERVER_NAME="$(awk '$1 == "SERVER_NAME" { print $2; exit }' $PATH_TO_CONFIG)"
	IP="$(awk '$1 == "IPv4_ADDRESS" { print $2; exit }' $PATH_TO_CONFIG)"
	USER="$(awk '$1 == "USER" { print $2; exit }' $PATH_TO_CONFIG)"
	PATH_TO_SERVER_SCRIPT="$(awk '$1 == "PATH_TO_SCRIPT" { print $2; exit }' $PATH_TO_CONFIG)"

	if [ -z $SERVER_NAME ] || [ -z $IP ] || [ -z $USER ] || [ -z PATH_TO_SERVER_SCRIPT ]; then
		echo "ERROR: You have the wrong credentials configured.\nCheck your config file via '$PATH_TO_SCRIPT config' command"
		exit $EXIT_FAILURE
	fi
}

# Commands for executing on the server
list() {
	get_credentials
	ssh $USER@$IP " \
		$PATH_TO_SERVER_SCRIPT client list" 
}


add_user() {
	get_credentials
	_NAME="$1"	

	if [ -z $_NAME ]; then
		echo "Please provide the user's name as an argument"
	else
		ssh $USER@$IP " \
			$PATH_TO_SERVER_SCRIPT client add $_NAME &>/dev/null && \ 
			cat $NAME.ovpn" > $NAME.ovpn 
	fi
}

revoke_user() {
	_NAME="$1"
	get_credentials

	if [ -z $_NAME ]; then
		echo "Please provide the user's name as an argument"
	else
		ssh $USER@$IP " \
			$PATH_TO_SERVER_SCRIPT client revoke $_NAME" 
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

show_credentials() {
	resolve_config_file
	echo "Your credentials configuration:"
	cat $PATH_TO_CONFIG
}

list_servers() {
	resolve_data_file
	cat $PATH_TO_DATA
}

main() {
	CMD="$1"	
	shift
	ARGS="$@"
	case $CMD in 
		credentials)
			show_credentials ;;
		list)
			list_users $ARGS ;;
		add)
			add_user $ARGS ;;
		revoke) 
			revoke_user $ARGS ;;
		list-servers)
			list_servers ;;
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
