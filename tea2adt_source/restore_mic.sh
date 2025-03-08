#!/bin/bash
TMP_PATH=$(head -n 1 cfg/tmp_path)
VOLUME_MICROPHONE=$(head -n 1 ${HOME}${TMP_PATH}/cfg/volume_microphone)
default_source_index=$(pacmd list-sources | grep "* index: " | grep -o '...$')
if [ "${default_source_index:0:1}" == ":" ] ; then
     default_source_index=$(pacmd list-sources | grep "* index: " | grep -o '..$')
fi
pacmd set-source-mute ${default_source_index} 0
# pactl -- set-source-volume ${default_source_index} ${VOLUME_MICROPHONE}
