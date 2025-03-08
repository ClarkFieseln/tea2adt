#!/bin/bash
default_source_index=$(pacmd list-sources | grep "* index: " | grep -o '...$')
if [ "${default_source_index:0:1}" == ":" ] ; then
     default_source_index=$(pacmd list-sources | grep "* index: " | grep -o '..$')
fi
pacmd set-source-mute ${default_source_index} 1
# pactl -- set-source-volume ${default_source_index} "0%"
