# Termux
Termux is a free and open-source terminal emulator for Android which supports most Linux commands.

Additional packages are available in a Debian-based package manager.


## Installation
On your Android smartphone you need to install Termux and Termux-API from these links:
```
  https://f-droid.org/en/packages/com.termux
  https://f-droid.org/en/packages/com.termux.api
```
I will describe some steps that worked for me while trying some things.

Not all these steps might be required in your case.

Once the Apps are installed give Termux (and Termux-API?) permission to access your microphone.

Install python with:
```
pkg install python-pip
```
Then follow the steps described under "Installation" on the main page.

After installation you need to create or modify the following files:

- .sound and .bashrc found in the home directory

- default.pa found in $PREFIX/etc/pulse

Here the corresponding contents to be added:
```
  # .sound
  pulseaudio --start --exit-idle-time=-1
  pacmd load-module module-sles-source
  pacmd load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1

  # .bashrc
  source /data/data/com.termux/files/home/.sound

  # default.pa
  load-module module-sles-source
  set-default-source OpenSL_ES_source
```
Now close and restart Termux.

## Configuration

Type:
```
  [pacmd list-sinks]
  [pacmd list-sources]
  [pactl get-default-source] # make sure your microphone/line-in/audio-input is selected
  tea2adt -d
  # copy the path shown in the previous step
  nano <copied_path>/cfg/terminal
  # the following shall be the first line in this file:
  tmux split-window -v   # type Ctrl-o + ENTER to save, Ctrl-x to leave nano
  # proceed as above to adapt other configuration files if required
```
## Use
Type:
```
  # prevent the Android device from entering deep sleep mode while using the Termux terminal emulator:
      termux-wake-lock
  # check audio connectivity and adjust volumes as required:
      tea2adt -p
      (Ctrl+C after test)
  # run tea2adt:
      tea2adt -c  # chat
  # or
      tea2adt -s  # shell-terminal
  # or
      tea2adt -f  # file-transfer
  # or
      tea2adt -l  # AI-prompt
  # Ctrl+C as many times as required to finish
```
The audio infrastructure connected to your offline smartphone may be e.g.:
- PSTN (Public Switched Telphone Network), just a landline telephone
- 'online' devices using a messenger like qTox which you may install in Linux with:
```
  sudo apt install qtox
```
- other smartphones making a call

In my particular case the following tea2adt settings worked very well:
- baud: 1200
- keep_time_sec: 0.0
- preamble, start_msg, end_msg: # all empty
- retransmission_timeout_sec: 5.0

## Tested features
The following features have not yet been fully tested in termux and may not work in this environment:
- text-to-speech
- remote AI prompt with 'tgpt'
  
## Hint
Although I no longer use it, I initially relied on the “EZ Booster” app on the smartphone running tea2adt via Termux to increase the speaker’s output volume.

If the volume is too low, there are also other apps available that can achieve a similar effect.
