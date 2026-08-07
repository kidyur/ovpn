# ovpn - get .ovpn files in a fast way
Simple cli tool to quickly and easily manage openVPN 
users on the server. It connects via SSH, can create
new user, revoke old one and list all the active users.
When you create new user, it will get USERNAME.ovpn
file for you from server to your local machine.

# Requires
* `Bash` both on the server and on the client
* `openvpn.sh` on the server (get here `https://github.com/hwdsl2/openvpn-install`)
* `ssh` on the client and `ssh-server` on the server

# Usage
* Change the USER and the IP variables in `ovpn.sh` with
your values.
## --add 
`ovpn.sh --add CLIENTNAME` 
It will create the client with corresponding name, .ovpn
files both on the server and on the client. The file will 
appear on clients machine, so you don't have to get it through
`sftp`
## --list
`ovpn.sh --list` 
It will list all the active vpn clients
## --revoke 
`ovpn.sh --revoke CLIENTNAME`
It will revoke one of the vpn clients. 
