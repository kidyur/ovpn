#!/bin/sh

# Make the .ovpn file with the name
# provided with first argument
ssh root@000.000.000.000   # Connect to server
PASSWORD 		   # Entry password
bash openvpn-install.sh    # Open `openvpn` service
2                          # Choose `remove client` option
$1.ovpn                    # Pass first argument as name for .ovpn file
exit                       # Break connection
