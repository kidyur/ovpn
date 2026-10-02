# ovpn

A small POSIX shell wrapper for managing **OpenVPN servers, users, and local credentials** from the command line. It keeps a list of your servers, tracks which one is "active", and lets you run common OpenVPN operations (add/list/revoke users) over SSH without memorizing paths or logging in manually.

---

## Features

- **Server registry** — store multiple OpenVPN servers locally.
- **Switch servers** — change the "active" server with one command.
- **User management** — add, list, and revoke VPN users on the active server.
- **Config download** — `add-user` automatically pulls the generated `.ovpn` file into `~/Downloads`.
- **POSIX `sh`** — no bashisms, works on any POSIX-compliant shell.
- **Flat-file storage** — human-readable config/data files, easy to inspect.

---

## Requirements

- `awk`, `ssh`, `cat`, `mv`, `touch`
- An OpenVPN server running [`openvpn-install.sh`](https://github.com/angristan/openvpn-install)
- SSH access to that server (key-based)

---

## Files Used

| Path | Purpose |
|---|---|
| `~/.ovpncfg` | The **active** server's credentials (server's name, user, IP, script path). |
| `~/.ovpndat` | The **registry** of all known servers. |

Both are created automatically on first run. Do not edit them by hand!
If you did that, just remove them and setup your application again.

---

## Quick Start

```sh
# 1. Register a server you already have access to
ovpn add-server myvps 203.0.113.10 root /root/openvpn-install.sh

# 2. Make it the active server
ovpn switch-server myvps root

# 3. Create a VPN user and download their config
ovpn add-user alice
# → ~/Downloads/alice.ovpn

# 4. Later, revoke that user
ovpn revoke-user alice
```

---

## Commands

### Configuration

| Command | Alias | Description |
|---|---|---|
| `credentials` | `cs` | Show the current active server configuration. |

### Server Management

| Command | Alias | Description |
|---|---|---|
| `add-server <srv_name> <ip> <user> <path_to_script>` | `as` | Register a new server. |
| `list-servers` | `ls` | List all registered servers. |
| `remove-server <srv_name> <user>` | `rs` | Remove a server/user pair from the registry. |
| `switch-server <srv_name> <user>` | `ss` | Set the active server in `~/.ovpncfg`. |

### User Management (runs on the active server)

| Command | Alias | Description |
|---|---|---|
| `add-user <name>` | `au` | Create a user and download their `.ovpn` to `~/Downloads`. |
| `list-users` | `lu` | List all users on the active server. |
| `revoke-user <name>` | `ru` | Revoke a user's certificate and delete their config on the server. |

### Help

| Command | Description |
|---|---|
| `-h`, `--help` | Show the general help. |
| `<command> -h` | Show per-command help. |

---

## Usage Examples

### Register two servers

```sh
ovpn add-server frankfurt 198.51.100.5 root /root/openvpn-install.sh
ovpn add-server tokyo     203.0.113.20 admin /opt/openvpn/openvpn-install.sh
```

### See the registry

```sh
$ ovpn ls
SERVER_NAME                     USER                            IPv4_ADDRESS    PATH_TO_SCRIPT
frankfurt                       root                            198.51.100.5    /root/openvpn-install.sh
tokyo                           admin                           203.0.113.20    /opt/openvpn/openvpn-install.sh
```

### Switch active server and check it

```sh
ovpn switch-server tokyo admin
ovpn credentials
```

### Add a user to the active server

```sh
ovpn add-user bob
# → file written to ~/Downloads/bob.ovpn
```

### Revoke that user

```sh
ovpn revoke-user bob
```

---

## How It Works

- `~/.ovpndat` is a whitespace-aligned table of servers, written with `printf` and read back with `awk`.
- `~/.ovpncfg` holds the **currently selected** server's `SERVER_NAME`, `USER`, `IPv4_ADDRESS`, and `PATH_TO_SCRIPT`.
- Commands that talk to the server (`add-user`, `revoke-user`, `list-users`) first call `get_credentials` to load the active server, then run `ssh $USER@$IP "$PATH_TO_SERVER_SCRIPT client <op>"`.
- `add-user` streams the generated `.ovpn` over SSH and redirects it to `~/Downloads/<name>.ovpn`.

---

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| `ERROR: You have the wrong credentials configured.` | `~/.ovpncfg` is empty or missing fields — run `ovpn switch-server …` first. |
| `ERROR: there is no such server.` | The `<name, user>` pair isn't in `~/.ovpndat`. Check with `ovpn ls`. |
| SSH prompts for a password every time | Use SSH keys: `ssh-copy-id user@host`. |
| `add-user` produces an empty file | The remote `openvpn-install.sh` path is wrong, or the user already exists. Run `ovpn add-user <name> -h` and verify the remote path. |
| Config file has 0 bytes after switching | `~/.ovpncfg` was edited manually and lost its `KEY value` format. Re-run `ovpn switch-server`. |

---

## Security Notes

- `~/.ovpndat` and `~/.ovpncfg` may contain usernames and IPs — treat them as sensitive and keep `chmod 600` if desired.
- SSH is invoked **without** `-o StrictHostKeyChecking=no`; first connections will prompt you to accept the host key. That's intentional.
- The script runs the remote `openvpn-install.sh` as the SSH user — make sure that user has permission to manage OpenVPN client certificates.

---

## TODO

- `check_server_config` has a `#TODO: add constraints` — it only checks that fields are non-empty (no IP/name validation).

