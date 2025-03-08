#!/bin/bash
# configuration
###############
  # read tmp path
TMP_PATH=$(head -n 1 cfg/tmp_path)
TEXT_TO_SPEECH=$(head -n 1 ${HOME}${TMP_PATH}/cfg/text_to_speech)
TTS_OUT_FILE="${HOME}${TMP_PATH}/state/tts_out"
if [ "${TEXT_TO_SPEECH}" != "" ] ; then
    # TODO: loop and sleep (=poll) while TTS_OUT == true?
    # set flag
    echo "true" > ${TTS_OUT_FILE}
    # SPEAK_SINK_INDEX
    INTERFACE_INDEX_TTS_OUT=$(head -n 1 ${HOME}${TMP_PATH}/cfg/interface_index_tts_out)
    # argument
    TEXT="$1"
    if [[ ${TEXT_TO_SPEECH} =~ "festival" ]]; then
      WAIT_START_TTS_SEC=0.3
    elif [[ ${TEXT_TO_SPEECH} =~ "espeak" ]]; then
      WAIT_START_TTS_SEC=0.75
    fi
    # text-to-speech:
    $(echo ${TEXT} | ${TEXT_TO_SPEECH}) &
    # NOTE: this is now handled in caller mmrx.py
    # text with pauses requires call to move-sink-input every time!?
    # otherwise we will output to the interface where DATA is being transmitted and thus create disturbances!
    # markers found up to now:
    #          "? "
    #          "! "
    #          "... "
    #          ": "
    sleep ${WAIT_START_TTS_SEC}
    if [[ ${TEXT_TO_SPEECH} =~ "festival" ]]; then
      SINK_INPUT=$(pacmd list-sink-inputs | awk '/index:/{idx=$2} /application.process.binary = "aplay"/{print idx; exit}')
    elif [[ ${TEXT_TO_SPEECH} =~ "espeak" ]]; then
      SINK_INPUT=$(pacmd list-sink-inputs | awk '/index:/{idx=$2} /application.process.binary = "espeak"/{print idx; exit}')
      # SINK_INPUT=$(pacmd list-sink-inputs | awk '/index:/{idx=$2} /application.name = "eSpeak"/{print idx; exit}')
    fi
    # change output interface for text-to-speech
    $(pactl move-sink-input ${SINK_INPUT} ${INTERFACE_INDEX_TTS_OUT})
    # clear flag
    echo "false" > ${TTS_OUT_FILE}
fi
