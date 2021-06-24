<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset="UTF-8" />
<title>Orwell</title>
<link rel="StyleSheet" href="../style.css" type="text/css" media="screen" />
</head>
<body>
<h1>Orwell</h1>
<p>
This is a Mac OS X wrapper for VNC port forwarding through an SSH tunnel.
The wrapper is a minimalistic app written in AppleScript that invokes the
appropriate Unix shell commands. The Mac user doubleclicks "Orwell.app" to
establish a tunnel to a pre-defined host, and then a remote admin can
get access to the user's screen by connecting a VNC client to a port on
said host. Since the tunnel connection is initiated from the Mac user,
silly firewalls and NAT routers are bypassed as long as the outgoing
SSH connection can be established.
</p>

<p>
The AppleScript code, in some parts almost nauseating in its COBOL-wannabe syntax, looks like this:
</p>

<p>
<pre>
do shell script "cat ~/.orwellprefs"
set {hostname, sshport, remoteuser, vncport} to words of the result
set sshopts to "-N -o IdentityFile=%d/.ssh/id_orwell -o ServerAliveInterval=120 -R " & vncport & ":127.0.0.1:5900"
do shell script "ssh " & sshopts & " -p " & sshport & " " & remoteuser & "@" & hostname ¬
	& " >/dev/null 2>&1 & echo $!"
set pid to the result
if (pid > 0) then
	display alert "Remote screen session enabled." & return & ¬
		"Press Quit button to terminate." buttons "Quit"
	do shell script "kill " & pid
else
	display alert "An error occurred." & return & ¬
		"Could not start remote screen session." buttons "Quit"
end if

</pre>
</p>

<p>
The corresponding Mac OS X app can be downloaded <a href="Orwell.app.zip">here</a>.
</p>

<p>
After the initial install, no administration is required on the client side.
Your friendly remote admin will take care of everything.
Just doubleclick "Orwell.app" and smile blissfully...
</p>

<h3>Installation instructions</h3>

<p>
On the client machine (Macintosh), do the following:
</p>

<ol>
  <li>Create the client's SSH key for Orwell:
    <pre>ssh-keygen -N "" -C "Charlie Client" -t rsa -f ~/.ssh/id_orwell</pre>
  </li>

  <li>Create the configuration file <code>~/.orwellprefs</code> with the following contents:
    <pre>&lt;hostname&gt; &lt;sshport&gt; &lt;username&gt; &lt;vncport&gt;</pre>
    Substitute as follows:
    <p>
    <ul>
      <li><code>&lt;hostname&gt;</code> is the target host, e.g. <code>vnchost.example.com</code></li>
      <li><code>&lt;sshport&gt;</code> is the SSH port, e.g. <code>22</code></li>
      <li><code>&lt;username&gt;</code> is the target login, e.g. <code>vncuser</code></li>
      <li><code>&lt;vncport&gt;</code> is the remote-forwarded VNC port, e.g. <code>5942</code></li>
    </ul>
    </p>
    <p>
      Note: don't use hostnames or usernames that contain hyphens (-) or digits(0-9),
      since this will break the script's simple-minded configuration file parser.
      Underscore (_) can be used.
    </p>
  </li>

  <li>Download the app from the download link above.</li>

</ol>

<p>
On the target host (the other end of the tunnel), do the following:
</p>

<ol>
  <li>Create a new user (e.g. <code>vncuser</code>) on the target host. Login shell should be <code>/bin/false</code>.</li>

  <li>Copy <code>~/.ssh/id_orwell.pub</code> from the client machine
      and append its contents to <code>~/.ssh/authorized_keys</code>
      in the home directory of the target host user.</li>

  <li>Optionally change the <code>GatewayPorts</code> setting to <code>yes</code>
      in <code>/etc/ssh/sshd_config</code>. This allows other machines on the
      network to access the forwarded VNC port. Don't forget to HUP sshd after
      modifying the config file.</li>

</ol>

Go back to the client machine and do:

<ol>
  <li>Install the target host's public SSH key in <code>~/.ssh/known_hosts</code>.
      The easiest way to do this is by simply connecting with <code>ssh</code> to the
      host and then answer "yes" to the "Are you sure?" question. If you are paranoid
      you can then check the RSA fingerprint with
      <code>ssh-keygen -l -f /etc/ssh/ssh_host_rsa_key.pub</code>
      on the target host.</li>
  <li>Verify that it works by double-clicking <code>Orwell.app</code> on the client machine,
      and then connect a VNC viewer to e.g. <code>vnchost.example.com:42</code>.
      Note: The client must of course have "Remote Desktop" enabled in its sharing preferences.
  </li>
</ol>

</body>
</html>
