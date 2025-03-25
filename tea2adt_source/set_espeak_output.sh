# from todo.txt:
# --------------
# - fix audio input/output interfaces as configured
#   - TTS and STT audio interfaces could be set once for the App at system level instead of setting them with each call
#
# Reference implementation for TTS with espeak (not working with festival!):
# --------------------------------------------------------------------------
# create tmux session for espeak
# important: espeak will from now on always have the same sink-input which can be redirected once!
#            (this is not the case if we use festival)
tmux new-session -d -s session_tts "cat | espeak"
# need to output tts once in order to get the sink-input
# this will be output in the current/default system audio output
tmux send-keys -t session_tts "Espeak started with the default audio output." Enter
# give time to speak the start message
sleep 3
# get sink-input
while true; do
    SINK_INPUT=$(pacmd list-sink-inputs | awk '/index:/{idx=$2} /application.process.binary = "espeak"/{print idx; exit}')
    if [ -n "$SINK_INPUT" ]; then
        break
    fi
    sleep 1
done
echo "SINK_INPUT = ${SINK_INPUT}"
# set configured sink for this specific sink-input
# pactl move-sink-input ${SINK_INPUT} ${INTERFACE_INDEX_TTS_OUT}
pactl move-sink-input ${SINK_INPUT} 16 # 16) 4)
# give time to switch
sleep 1
# test new setting, that is, output to new audio interface
tmux send-keys -t session_tts "Hello, this is a test with the new audio output." Enter
# give time to output last message
sleep 3
# kill tmux session
tmux kill-session -t session_tts
