#!/bin/sh

# Make the .ovpn file with the name
# provided with first argument
ssh root@000.000.000.000   # Connect to server	
PASSWORD		   # Entry password
bash openvpn-install.sh	   # Open `openvpn` service
1			   # Choose `create client` option
$1			   # Pass first argument as name for .ovpn file
exit		           # Break connection

# Download the .ovpn file
sftp root@000.000.000.000  # Connect to server
PASSWORD		   # Entry password
get $1.ovpn		   # Download file
exit			   # Break connection
