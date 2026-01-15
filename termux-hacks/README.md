# Termux hacks

Termux is not only a great terminal emulator for Android, it is
also an entire ecosystem for Linux command-line programs, with its
own package repository, similar to mainstream Linux distributions.

As of 2025-12-20, you should install Termux from F-Droid,
*not* the version from Google Play. Lots of stuff didn't work
when I tried the Google Play version. This might change in the
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
- Termux will be killed by the operating system unless you protect it
  by running `termux-wake-lock` after you start the app. And for some
  platforms (notably Samsung) you also need to disable Battery Optimization
  (set it to "Unrestricted") for the Termux app, and add it to the list
  of "Never sleeping apps".

For using Termux Widgets you also need to do:
- Install the app "Termux:Widgets", and then install "Termux:API".
- Add the permission `Appear on top` to the Termux:Widget app.
- The Termux app (or the Termux API app?) needs to be in the
  foreground for some of the API features to work.
- For some of my hacks, you will also need the "jq" program for
  parsing JSON (i.e. the latest fad in the endless progression
  of s-expression wannabes). This is easily done by running the
  command `pkg install jq`.

## Some other tips for using Termux

- Get rid of the colors! They are just irritating.
  [Disable Termux colors](#disable-termux-colors)

- If you use Emacs, it is very convenient to use "Tramp mode" to edit
  files on your target device. Just set up an SSH server on the device
  and add the key of your development computer to it. Then you don't have
  to install Emacs on your mobile phone (unless you want to of course).

## Rsync is your friend

Fetch photos and backup other things by connecting from another machine
via `rsync` (fill in later).

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

Note: The listening port can't be the default 22 unless you run the daemon
as root. I recommend setting a non-privileged port number in
`../usr/etc/ssh/sshd_config` rather than specifying it in the script,
in case you wish to try out other ways of starting `sshd`.

## Disable Termux colors

Work in progress. Set white for `color2` which is used in the prompt,
and also for `color8` to `color15`. This eliminates most of the headaches
caused by colored text. (fill in later)

## Termux Widget apps (.shortcuts)

### .shortcuts/hello

Displays "Hello, World!" as a toast on the main screen.

### .shortcuts/goodnight

This is something I use to turn off the screen of my main desktop computer.
This computer is located right next to my bedroom, so the glare from the
screen is sometimes visible after I go to bed. 

### .shortcuts/tea-timer

### .shortcuts/push-photos

### .shortcuts/hulog

