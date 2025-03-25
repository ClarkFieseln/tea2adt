#!/bin/bash
TMP_PATH=$(head -n 1 cfg/tmp_path)
INTERFACE_INDEX_MINIMODEM_IN=$(head -n 1 ${HOME}${TMP_PATH}/cfg/interface_index_minimodem_in)
if [ "${INTERFACE_INDEX_MINIMODEM_IN}" == "" ] ; then
    default_source_index=$(pacmd list-sources | grep "* index: " | grep -o '...$')
    if [ "${default_source_index:0:1}" == ":" ] ; then
         default_source_index=$(pacmd list-sources | grep "* index: " | grep -o '..$')
    fi
    pacmd set-source-mute ${default_source_index} 1
else
    pacmd set-source-mute ${INTERFACE_INDEX_MINIMODEM_IN} 1
fi
