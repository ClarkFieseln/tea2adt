#!/bin/bash
set -e
set -x
set -o pipefail
# read tmp path
TMP_PATH=$(head -n 1 cfg/tmp_path)
# read relevant configuration
TEXT_TO_SPEECH=$(head -n 1 cfg/text_to_speech)
TERMINAL=$(head -n 1 cfg/terminal)
LLM_CMD=$(head -n 1 cfg/llm_cmd)
# install on Termux
if [ -n "$TERMUX_VERSION" ] || [[ "$PREFIX" == *"com.termux"* ]]; then
    pkg update
    # pkg upgrade
    pkg install termux-api
    pkg install alsa-utils
    pkg install python-pip
    if [[ ${TEXT_TO_SPEECH} =~ "espeak" ]]; then
      pkg install espeak  # it is usually not possible to use additional audio interfaces in Termux (?)
    fi
    if [[ ${LLM_CMD} =~ "tgpt" ]]; then
        pkg install tgpt
    fi
    pkg install sox
    pkg install minimodem
    pkg install gnupg
    pkg install tmux
    pkg install bc
    pkg install pulseaudio
# install on Linux
else
    sudo $(which apt) update
    sudo $(which apt) install minimodem
    sudo $(which apt) install gpg
    sudo $(which apt) install bc
    sudo $(which apt) install tmux
    sudo $(which apt) install sox libsox-fmt-mp3
    # install terminal
    # TODO: we may combine e.g. cool-retro-term with tmux, automate installation also in this case (?)
    if [[ ${TERMINAL} =~ "gnome-terminal" ]]; then
      sudo $(which apt) install gnome-terminal
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
fi
