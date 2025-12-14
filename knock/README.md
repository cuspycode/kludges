# knock

Inspired by the concept of port-knocking. A special ssh login runs a small perl script that opens a hole in the firewall of the Linux host for a few minutes, to allow remote login via a specific port that was temporarily exposed. This is sometimes useful for ports that are tunnelled from other hosts where the security policies may be different from the ones on the main host.

How to install:

