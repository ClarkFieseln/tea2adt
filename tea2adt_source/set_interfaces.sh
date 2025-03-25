#!/bin/bash

TMP_PATH=$(head -n 1 cfg/tmp_path)
INTERFACE_INDEX_MINIMODEM_OUT=$(head -n 1 ${HOME}${TMP_PATH}/cfg/interface_index_minimodem_out)
INTERFACE_INDEX_MINIMODEM_IN=$(head -n 1 ${HOME}${TMP_PATH}/cfg/interface_index_minimodem_in)

set_interfaces()
{
    # speaker / sink (communication)
    if [ "${INTERFACE_INDEX_MINIMODEM_OUT}" != "" ] ; then
        # get sink-input
        while true; do
            SINK_INPUT=$(pacmd list-sink-inputs | awk '/index:/{idx=$2} /application.process.binary = "minimodem"/{print idx; exit}')
            if [ -n "$SINK_INPUT" ]; then
                break
            fi
            sleep 1
        done
        # set configured sink for this specific sink-input
        pactl move-sink-input ${SINK_INPUT} ${INTERFACE_INDEX_MINIMODEM_OUT}
        echo "set minimodem output with sink input ${SINK_INPUT} to interface index ${INTERFACE_INDEX_MINIMODEM_OUT}"
    fi
    # microphone / source (communication)
    if [ "${INTERFACE_INDEX_MINIMODEM_IN}" != "" ] ; then
        # get source-input
        while true; do
            SOURCE_OUTPUT=$(pacmd list-source-outputs | awk '/index:/{idx=$2} /application.process.binary = "minimodem"/{print idx; exit}')
            if [ -n "$SOURCE_OUTPUT" ]; then
                break
            fi
            sleep 1
        done
        # set configured source for this specific source-output
        pactl move-source-output ${SOURCE_OUTPUT} ${INTERFACE_INDEX_MINIMODEM_IN}
        echo "set minimodem input with source output ${SOURCE_OUTPUT} to interface index ${INTERFACE_INDEX_MINIMODEM_IN}"
    fi
}

set_interfaces
