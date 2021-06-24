<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset="UTF-8" />
<title>Remote Removable Drive</title>
<link rel="StyleSheet" href="../style.css" type="text/css" media="screen" />
<style>
<!--
.api-list td { padding-left: 1em; }
.color1 { color: #909090; }
.color2 { color: #000000; }
-->
</style>
</head>
<body>
<h1><span class="color1"><span class="color2">Remote</span> Remo<span class="color2">vable</span> Drive</h1>
<p>
This is a simple Perl CGI script that lets a remote user mount and unmount
removable drives via a web page. This eliminates the need to interact with
a file server via command line or point-and-click console (either locally
or remote) in order to mount or unmount a removable drive.
</p>
<p>
The CGI script uses a
<a href="http://en.wikipedia.org/wiki/Representational_State_Transfer">REST</a>
API which is called by Javascript client code on the web page. This makes it very
easy to create other clients (e.g. scripts or GUI widgets) that use the same protocol.
</p>

<p>
The script is split into two parts, a frontend called <code>request.pl</code>
and a backend called <code>response.pl</code>. The backend is called from the
frontend via a setuid-root program named <code>setuid-wrapper</code>.
This allows the backend to perform the mount and umount commands with
superuser privileges.
</p>

<p>
The REST API looks like this:
</p>
<div style="margin-left: 1em">
<table class="api-list">
<tr>
  <td><code>/cgi-bin/removable/request.pl?op=mount&volid=Foo</code></td>
  <td>- Mounts the volume <code>Foo</code>.</td>
</tr>
<tr>
  <td><code>/cgi-bin/removable/request.pl?op=unmount&volid=Foo</code></td>
  <td>- Unmounts the volume <code>Foo</code>.</td>
</tr>
<tr>
  <td><code>/cgi-bin/removable/request.pl?op=list&volid=all</code></td>
  <td>- Lists (in XML) all mount points managed by the script.</td>
</tr>
<tr>
  <td><code>/cgi-bin/removable/request.pl?op=list&volid=mounted</code></td>
  <td>- Like above, but only lists currently mounted volumes.</td>
</tr>
<tr>
  <td><code>/cgi-bin/removable/request.pl?op=list&volid=unmounted</code></td>
  <td>- Like above, but only lists currently unmounted volumes.</td>
</tr>
</table>
</div>

<p>
Note: the list of unmounted volumes contains the names of volumes that are
attached but not mounted, so while the intersection of mounted and unmounted
volume names is empty by definition, their union is a subset of all mount-points.
</p>
<p>
The code can be downloaded
<a href="remotevable.tar.gz">here</a>.
A brief explanation about the contents:
</p>
<div style="margin-left: 1em">
<table class="api-list">
<tr>
  <td><code>Makefile</code></td>
  <td>- Compiles and installs.</td>
</tr>
<tr>
  <td><code>mount.html</code></td>
  <td>- Browser client with Javascript code, can be installed anywhere.</td>
</tr>
<tr>
  <td><code>request.pl</code></td>
  <td>- CGI script frontend part.</td>
</tr>
<tr>
  <td><code>response.pl</code></td>
  <td>- CGI script backend part (privileged).</td>
</tr>
<tr>
  <td><code>sample.htaccess</code></td>
  <td>- For the CGI scripts.</td>
</tr>
<tr>
  <td><code>setuid-wrapper.c</code></td>
  <td>- Source code for setuid-wrapper.</td>
</tr>
</table>
</div>

<p>
Installation:
</p>

<ol>
<li>If desired, edit <code>Makefile</code>, <code>setuid-wrapper.c</code>,
    <code>request.pl</code>, <code>response.pl</code> and <code>mount.html</code>
    in order to change the installation paths and mount-point root from the defaults.</li>
<li>Then do "<code>make</code>" to compile <code>setuid-wrapper</code> for
    your CPU architecture. This also copies the file <code>sample.htaccess</code>
    to <code>.htaccess</code> which will be the source for installation later.</li>
<li>Edit <code>.htaccess</code> to fit your requirements. This file handles access
    to the REST API scripts.</li>
<li>Do "<code>sudo make install</code>" to install the scripts.</li>
<li>Do "<code>sudo make install-web</code>" to install the client web page
    <code>mount.html</code> in the default location under the mount-points root.
    Alternatively you can install it manually wherever you like under the document
    root of the web server.</li>
</ol>

<p>
Read below for how to set up the rest of your system.
</p>

<h3>Prepare your file server</h3>
<p>
First create the root for the mount points:
<pre>
mkdir /removable
</pre>
</p>

<p>
Then create a mount point for each individual volume:
<pre>
mkdir /removable/My-1st-Volume
mkdir /removable/My-2nd-Volume
mkdir /removable/My-3rd-Volume
</pre>
(Repeat for as many volumes as desired)
</p>

<p>
Then connect the volume labels with the mount points by adding a
line to <code>/etc/fstab</code> for each volume:
<pre>
/dev/disk/by-label/My-1st-Volume /removable/My-1st-Volume auto noauto 0 0
/dev/disk/by-label/My-2nd-Volume /removable/My-2nd-Volume auto noauto 0 0
/dev/disk/by-label/My-3rd-Volume /removable/My-3rd-Volume auto noauto 0 0
</pre>
(Note: the volume labels and mount points must match, because I'm too lazy
to make my scripts parse fstab to figure out the connections)
</p>

<h3>Configure WebDAV sharing</h3>

<p>
This step is optional. You can use any file sharing protocol you want,
but WebDAV is very versatile. Be careful with NFS since you may need
to unexport the share before it is possible to unmount it. This requires
some extra hacking.
For WebDAV, enable the relevant Apache modules and add the following
configuration:
<pre>
DavLockDB "/srv/www/DavLocks/TestDavLockDB"
Alias /removable "/removable"
&lt;Directory "/removable"&gt;
    Dav On
    Options +Indexes
    IndexOptions FancyIndexing Charset=UTF-8
    Order Deny,Allow
    Deny from all
    Allow from 192.168.0.0/16
&lt;/Directory&gt;</pre>
</p>

<p>
(You can combine or replace this with password-based authorization if you like)
</p>

<hr />
</body>
</html>
