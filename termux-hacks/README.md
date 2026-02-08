# Termux hacks

Termux is not only a great terminal emulator for Android, it is
also an entire ecosystem for Linux command-line programs, with its
own package repository, similar to mainstream Linux distributions.

If you are impatient, skip directly to the hacks:
- [startssh](#startssh)
- [hello](#shortcutshello)
- [timed-flashlight](#shortcutstimed-flashlight)
- [tea-timer](#shortcutstea-timer)
- [goodnight](#shortcutsgoodnight)
- [perltest](#shortcutsperltest)
- [push-photos](#shortcutspush-photos)
- [hulog](#shortcutshulog)

If you aren't impatient, keep reading instead.

When I write this in December 2025, you should install Termux from
F-Droid, *not* the version from Google Play. Lots of stuff didn't
work when I tried the Google Play version. This might change in the
future of course.

The version I am using when writing this is Termux `0.118.3`
from F-Droid.

## A few prerequisites

- First, it is a good idea to set up an SSH service, so you can
  login remotely to your Android device. There are multiple guides
  on the Internet on how to do this. Personally I like to run it as
  a foreground process in a Termux session. See my [startssh](#startssh)
  script for a way to do this in the same command that starts `ssh-agent`.
  Also see my [notes on running rsync](#rsync-is-your-friend).
- Termux will be killed after a while by the operating system unless you
  protect it by running `termux-wake-lock` after you start the app.
  And for some platforms (notably Samsung) you also need to disable
  Battery Optimization (set it to "Unrestricted") for the Termux app,
  and add it to the list of "Never sleeping apps".

For using Termux Widgets you also need to do:
- Install the app "Termux:Widgets", and then install "Termux:API".
- Add the permission "Appear on top" to the Termux:Widget app.
- The Termux app (or the Termux API app?) needs to be in the
  foreground for some of the API features to work.
- For some of my hacks, you will also need the "jq" program for
  parsing JSON (i.e. the latest fad in the endless progression
  of s-expression wannabes). This is easily done by running the
  command `pkg install jq`.

Note: the above worked for me, running Android 16. Other devices and
systems may work differently.
<br />

## Some other tips for using Termux

- Get rid of the colors! They are just irritating.
  See the section on [disabling Termux colors](#disable-termux-colors)
  for details.

- If you use Emacs, it is very convenient to use "Tramp mode" to edit
  files on your target device. Just set up an SSH server on the device
  and add the SSH key of your development computer to it. Then you don't have
  to install Emacs on your mobile phone (unless you want to of course).

## Rsync is your friend

Fetch photos and backup other things by connecting from another machine
via `rsync`. For example, the following command on your computer will
fetch photos from your Termux device:

```text
rsync -e "ssh -p 60022" -av 192.0.2.3:storage/dcim/Camera/ ~/Pictures/phone/
```

Adapt the above command to your particular circumstances:
- `60022` is the SSH port on the Termux device.
- `192.0.2.3` is the IP address of the Termux device.
- `~/Pictures/phone` is the destination folder on your computer.

And as always with `rsync`, the trailing slashes are important.
They determine whether the intended object is a directory or
the contents of a directory.

## .profile

The file is named `dot.profile` in this Git repository. Rename it to
`.profile` to use it or combine it with your own Termux shell initialization
stuff. The only content in mine is this:

```text
export SSH_AUTH_SOCK=$HOME/.ssh-agent-socket
```

This makes the SSH-agent socket name available to all scripts or interactive
shells that run later. The socket does not have to exist beforehand.
The command below will create it, if necessary.

## startssh

For various reasons I start SSH manually from an interactive Termux session.
I start it with the command `./startssh` and leave it to run `sshd` in the
foreground, until I stop it with ^C. The content of `startssh` looks like
this:

```text
#!/data/data/com.termux/files/usr/bin/sh

SOCKET=/data/data/com.termux/files/home/.ssh-agent-socket
rm -f "$SOCKET"
ssh-agent -a "$SOCKET" sh -c "ssh-add; sshd -D"
```

The last command in the script accomplishes three things:
* Start `ssh-agent`
* Run `ssh-add` to provide `ssh-agent` with the default key. This is for
convenience, so that subsequent ssh commands can be done without requiring
the passphrase. This is optional however; you can just press RETURN here
(which provides a wrong passphrase) and run `ssh-add` later if you want.
* Start `sshd` with the option `-D` to make it run in the foreground.
Then if you need to, you can revisit this Termux session later and terminate
it with ^C.

Note: The listening port can't be the default 22 unless you run the daemon
as root. I recommend setting a non-privileged port number in
`../usr/etc/ssh/sshd_config` rather than specifying it in the script,
in case you wish to try out other ways of starting `sshd`.

## Disable Termux colors

Work in progress. Set white for `color2` which is used in the prompt,
and also for `color8` to `color15`. This eliminates most of the headaches
caused by colored text. My basic goal here is to make all text to be white
on a black background. No more dark blue text on a black background, or
yellow text on a white background, or any similar abominations.
See the contents of this file:

[.termux/colors.properties](dot.termux/colors.properties)

## Termux Widget apps (.shortcuts)

The files under `dot.shortcuts` should be placed under `.shortcuts`
in your Termux home directory.

### .shortcuts/hello

Displays "Hello, World!" as a toast on the main screen.

### .shortcuts/timed-flashlight

A very straigt-forward script that turns on the flashlight after a
few seconds delay, and then turns it back off after another delay.
The commands in the script are:

```text
sleep 5
termux-torch on
sleep 45
termux-torch off

```
Just edit the `sleep` commands to customize the script for your own needs.

### .shortcuts/tea-timer

A simple timer that sleeps for 3 minutes and then says
"Your tea is ready" via the text-to-speech feature.

For a more sophisticated timer, see [Egg Timer](../egg-timer/)
which has a slightly different purpose and works in pure shell
with no Termux dependencies.

### .shortcuts/goodnight

This is something I use to turn off the screen of my main desktop computer.
This computer is located right next to my bedroom, so the glare from the
screen is sometimes visible after I go to bed. 

### .shortcuts/perltest

Sample test script written in Perl. Demonstrates file locking using
the UNIX "flock" primitive.
<br />Install perl first via `pkg install perl`.

### .shortcuts/push-photos

Sends newly taken photos to a designated host. This is different and
complementary to the remote-initiated rsync method described
above in the section [Rsync is your friend](#rsync-is-your-friend).

With `push-photos` you can quickly upload your latest photos to a
predefined host. This can come in handy if you unexpectedly become
a witness to criminal activity, like for example police brutality,
or any other situation where you need to upload your latest photos
quickly before your evidence-containing phone gets destroyed or
confiscated.

### .shortcuts/hulog

The name "hulog" is an abbreviation for "Human Log". The original
intention for this script was to log timestamps together with some
predefined user-selected keywords in a log file, at the press of
a button.
It has evolved slightly, and it can now also take (very short)
voice notes, do ambient light readings (in terms of Lux measurements),
and log the current GPS location.

This script could easily grow into a "kitchen sink" script that collects
and logs any data you can imagine. In that case it should probably
be changed to use some kind of plugin architecture, or be turned into
a regular app, but for now it's still just a small bash script that fits
on a single page when printed.

I have considered adding features that involve the detection of
movement, i.e. by using the accelerometer, or detecting a change
of Wifi connection, and similar things. But those things would require
having a background process that monitors the accelerometer (or whatever)
and then detects a sudden change. I don't think Termux is suitable for
that type of application however, but I may be wrong about that.

Some notes:
- GPS data is logged to a separate file (`gps-hulog.json`) together
with a timestamp. The timestamp is identical to the timestamp logged
in the main logfile `hulog.txt`, so it can be used as a foreign key
in a relational-logic sense.
- Speech recognition may or may not work without Internet connectivity.
It does work on my device, which I think is quite fascinating, and a
tribute to how capable modern mobile phones are. It only seems to work
in English however, but not in my native language.
- No data is exported from the mobile phone, except when the user chooses
to do so (see [Rsync is your friend](#rsync-is-your-friend) above).

To view the log files, you will have to copy them to a regular computer
(see [Rsync is your friend](#rsync-is-your-friend) for details).
If you want to view them directly on your mobile phone,
I recommend the app "Text Viewer" (by Panagola Private Limited).
Or alternatively you can use a file manager (for example "My Files"
by Google) to invoke an app of your choice to open it. For example,
"Notepad Free" (by atomczak), which I currently use for note-taking.
