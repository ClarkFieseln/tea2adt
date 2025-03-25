#!/bin/bash
TMP_PATH=$(head -n 1 cfg/tmp_path)
TEXT_TO_SPEECH=$(head -n 1 ${HOME}${TMP_PATH}/cfg/text_to_speech)
TTS_OUT_FILE="${HOME}${TMP_PATH}/state/tts_out"
if [ "${TEXT_TO_SPEECH}" != "" ] ; then
    # TODO: loop and sleep (=poll) while TTS_OUT == true?
    # set flag
    echo "true" > ${TTS_OUT_FILE}
    # get sink index
    INTERFACE_INDEX_TTS_OUT=$(head -n 1 ${HOME}${TMP_PATH}/cfg/interface_index_tts_out)
    # argument
    TEXT="$1"
    # specific delay setting
    # TODO: replace with loop as commented further below
    if [[ ${TEXT_TO_SPEECH} =~ "festival" ]]; then
      WAIT_START_TTS_SEC=0.40  # 0.30
    elif [[ ${TEXT_TO_SPEECH} =~ "espeak" ]]; then
      WAIT_START_TTS_SEC=0.65  # 0.75
    fi
    # text-to-speech:
    $(echo ${TEXT} | ${TEXT_TO_SPEECH}) &
    # delay
    sleep ${WAIT_START_TTS_SEC}
    # get sink-input
    if [[ ${TEXT_TO_SPEECH} =~ "festival" ]]; then
      SINK_INPUT=$(pacmd list-sink-inputs | awk '/index:/{idx=$2} /application.process.binary = "aplay"/{print idx; exit}')
    elif [[ ${TEXT_TO_SPEECH} =~ "espeak" ]]; then
      SINK_INPUT=$(pacmd list-sink-inputs | awk '/index:/{idx=$2} /application.process.binary = "espeak"/{print idx; exit}')
      # SINK_INPUT=$(pacmd list-sink-inputs | awk '/index:/{idx=$2} /application.name = "eSpeak"/{print idx; exit}')
    fi
    # TODO: find out what is the problem with this loop which shall replace sleep ${WAIT_START_TTS_SEC}
    #       after some time we do find the sink-input but then the command pactl move-sink-input fails
    # while true; do    
    #     if [[ ${TEXT_TO_SPEECH} =~ "festival" ]]; then
    #       SINK_INPUT=$(pacmd list-sink-inputs | awk '/index:/{idx=$2} /application.process.binary = "aplay"/{print idx; exit}')
    #     elif [[ ${TEXT_TO_SPEECH} =~ "espeak" ]]; then
    #       SINK_INPUT=$(pacmd list-sink-inputs | awk '/index:/{idx=$2} /application.process.binary = "espeak"/{print idx; exit}')
    #       # SINK_INPUT=$(pacmd list-sink-inputs | awk '/index:/{idx=$2} /application.name = "eSpeak"/{print idx; exit}')
    #     fi
    #     if [ -n "${SINK_INPUT}" ]; then
    #         break
    #     fi
    #     sleep 0.01
    # done    
    # set output interface for text-to-speech
    $(pactl move-sink-input ${SINK_INPUT} ${INTERFACE_INDEX_TTS_OUT})
    # clear flag
    echo "false" > ${TTS_OUT_FILE}
fi
