# knock

Inspired by the concept of port-knocking. A special ssh login runs a small perl script that opens a hole in the firewall of the Linux host for a few minutes, to allow remote login via a specific port that was temporarily exposed. This is sometimes useful for ports that are tunnelled from other hosts where the security policies may be different from the ones on the main host.

## How to install

```bash
make
sudo make install
sudo useradd -c "Knock,,," -d /opt/knock -s /opt/knock/knock knock
sudo passwd knock
sudo touch /opt/knock/.hushlogin
```

The last command is optional, it just silences the standard login message for the `knock` user.

If you prefer to use public keys to access this service, just add them to `/opt/knock/.ssh/authorized_keys` after first creating `/opt/knock/.ssh` with the correct ownership and permissions.

Before you try it out, please follow the steps below to integrate this thing into your iptables firewall.

## Integration with iptables firewall

The basic assumption here is that the firewall initially allows traffic to TCP port 2222.

First inspect yout firewall rules to see if anything conflicts with this script's rules for port 2222:

```bash
sudo iptables -n -L
sudo ip6tables -n -L
```

If no conflicts were found, proceed by adding the `knock` rules:

```bash
/opt/knock/knock add
```
Note 1: You probably want to do this as an initialization every time you reboot. So put it in your `/etc/rc.local` or wherever you keep that kind of stuff. Also note that you can always do this manually before you set up tunnels for port 2222. Or if you forget that, the script will still work but it will print an error message the first time it runs.

Note 2: This is not an idempotent operation! If you repeat it, the rules will be added multiple times, which will require manual intervention to clean up.

## Examples

Here is a sample interaction with `knock` using the Termux app on a mobile phone:

```text
~ $ ssh knock@myhost.example.com
Enter passphrase for key '/data/data/com.termux/files/home/.ssh/id_rsa':
Who's there? Door will be closed in 300 seconds.
Connection to myhost.example.com closed.
~ $
```

Now you have 5 minutes to connect to port 2222 on `myhost.example.com` from any other device. Port 2222 does not even have to use the SSH protocol, it can be anything as long as it's TCP.
