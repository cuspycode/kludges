# knock

Inspired by the concept of port-knocking. A special ssh login runs a small perl script that opens a hole in the firewall of the Linux host for a few minutes, to allow remote login via a specific port that was temporarily exposed. This is sometimes useful for ports that are tunnelled from other hosts where the security policies may be different from the ones on the main host.

How to install:

```bash
make
sudo make install
sudo useradd -c "Knock,,," -d /opt/knock -s /opt/knock/knock knock
sudo passwd knock
sudo touch /opt/knock/.hushlogin
```

The last command is optional, it just silences the standard login message for the `knock` user.

If you prefer to use public keys to access this service, just add them to `/opt/knock/.ssh/authorized_keys` after first creating `/opt/knock/.ssh` with the correct ownership and permissions.
