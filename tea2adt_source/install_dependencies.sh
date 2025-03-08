#!/bin/bash
set -e
set -x
set -o pipefail
# read tmp path
TMP_PATH=$(head -n 1 cfg/tmp_path)
# read relevant configuration
TEXT_TO_SPEECH=$(head -n 1 cfg/text_to_speech)
TERMINAL=$(head -n 1 cfg/terminal)
# install
sudo $(which apt) update
sudo $(which apt) install minimodem
sudo $(which apt) install gpg
sudo $(which apt) install bc
# install terminal
# TODO: we may combine e.g. cool-retro-term with tmux, automate installation also in this case (?)
if [[ ${TERMINAL} =~ "gnome-terminal" ]]; then
  sudo $(which apt) install gnome-terminal
elif [[ ${TERMINAL} =~ "tmux" ]]; then
  sudo $(which apt) install tmux
elif [[ ${TERMINAL} =~ "cool-retro-term" ]]; then
  sudo $(which apt) install cool-retro-term  
fi
# install TTS tool
if [[ ${TEXT_TO_SPEECH} =~ "festival" ]]; then
  sudo $(which apt) install festival
elif [[ ${TEXT_TO_SPEECH} =~ "espeak" ]]; then
  sudo $(which apt) install espeak
fi
# ---------------------------------------
# NOTE: install the following if required
# sudo $(which apt) install pulseaudio
# sudo $(which apt) install gnupg
