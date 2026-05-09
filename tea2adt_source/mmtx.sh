#!/bin/bash          

# TODO: remove all variables and definitions which are not required

# message types
###############
: '
    [init]
    [init_ack_chat]
    [init_ack_shell]
    [init_ack_llm]
    [init_ack_file]
    [keepalive]
    <probe>
    <start_msg>
    <end_msg>   
                    <preamble> <seq_tx><seq_rx>[ack]                                       <trailer>
                    <preamble> <seq_tx><seq_rx>[data]<input_data>                          <trailer>
                    <preamble> <seq_tx><seq_rx>[file_name]<file_name>[file]<file_data>     <trailer>
                    <preamble> <seq_tx><seq_rx>[file_name]<file_name>[file_end]<file_data> <trailer>
                               \_______________ _________________________________________/
                                               V
                                           encrypted
'

# configuration
###############
# read tmp path
TMP_PATH=$(head -n 1 cfg/tmp_path)
END_MSG=$(head -n 1 ${HOME}${TMP_PATH}/cfg/end_msg)
START_MSG=$(head -n 1 ${HOME}${TMP_PATH}/cfg/start_msg)
TRAILER=$(head -n 1 ${HOME}${TMP_PATH}/cfg/trailer)
PREAMBLE=$(head -n 1 ${HOME}${TMP_PATH}/cfg/preamble)
CIPHER_ALGO=$(head -n 1 ${HOME}${TMP_PATH}/cfg/cipher_algo)
ARMOR=$(head -n 1 ${HOME}${TMP_PATH}/cfg/armor)
BAUD=$(head -n 1 ${HOME}${TMP_PATH}/cfg/baud)
SYNCBYTE=$(head -n 1 ${HOME}${TMP_PATH}/cfg/syncbyte)
KEEPALIVE_TIME_SEC=$(head -n 1 ${HOME}${TMP_PATH}/cfg/keepalive_time_sec)
SEND_DELAY_SEC=$(head -n 1 ${HOME}${TMP_PATH}/cfg/send_delay_sec)
# convert KEEPALIVE_TIME_SEC to ms:
KEEPALIVE_TIME_MS=$(printf '%s\n' ${KEEPALIVE_TIME_SEC}*1000 | bc)
# and now remove decimal values:
KEEPALIVE_TIME_MS=${KEEPALIVE_TIME_MS%.*}
RETRANSMISSION_TIMEOUT_SEC=$(head -n 1 ${HOME}${TMP_PATH}/cfg/retransmission_timeout_sec)
# convert RETRANSMISSION_TIMEOUT_SEC to ms:
RETRANSMISSION_TIMEOUT_MS=$(printf '%s\n' ${RETRANSMISSION_TIMEOUT_SEC}*1000 | bc)
# and now remove decimal values:
RETRANSMISSION_TIMEOUT_MS=${RETRANSMISSION_TIMEOUT_MS%.*}
TIMEOUT_POLL_SEC=$(head -n 1 ${HOME}${TMP_PATH}/cfg/timeout_poll_sec)
MAX_RETRANSMISSIONS=$(head -n 1 ${HOME}${TMP_PATH}/cfg/max_retransmissions)
REDUNDANT_TRANSMISSIONS=$(head -n 1 ${HOME}${TMP_PATH}/cfg/redundant_transmissions)
SHOW_TX_PROMPT=$(head -n 1 ${HOME}${TMP_PATH}/cfg/show_tx_prompt) # true
NEED_ACK=$(head -n 1 ${HOME}${TMP_PATH}/cfg/need_ack)
VERBOSE=$(head -n 1 ${HOME}${TMP_PATH}/cfg/verbose) # false
SPLIT_TX_LINES=$(head -n 1 ${HOME}${TMP_PATH}/cfg/split_tx_lines)
HALF_DUPLEX=$(head -n 1 ${HOME}${TMP_PATH}/cfg/half_duplex)
MSGFILE="${HOME}${TMP_PATH}/tmp/msgtx.gpg"
TMPFILE="${HOME}${TMP_PATH}/tmp/out.txt"
TMPFILE_BASE64_OUT="${HOME}${TMP_PATH}/tmp/out.64"
printf '%s\n' "baud = $BAUD"
printf '%s\n' "half_duplex = $HALF_DUPLEX"
printf '%s\n' "need_ack = $NEED_ACK"
printf '%s\n' "start_msg = $START_MSG"
printf '%s\n' "end_msg = $END_MSG"
printf '%s\n' "preamble = $PREAMBLE"
printf '%s\n' "trailer = $TRAILER"
printf '%s\n' "cipher_algo = $CIPHER_ALGO"
printf '%s\n' "armor = $ARMOR"
printf '%s\n' "syncbyte = $SYNCBYTE"
printf '%s\n' "keepalive_time_sec = $KEEPALIVE_TIME_SEC"
printf '%s\n' "(keepalive_time_ms = $KEEPALIVE_TIME_MS)"
printf '%s\n' "retransmission_timeout_sec = $RETRANSMISSION_TIMEOUT_SEC"
printf '%s\n' "(retransmission_timeout_ms = $RETRANSMISSION_TIMEOUT_MS)"
printf '%s\n' "timeout_poll_sec = $TIMEOUT_POLL_SEC"
printf '%s\n' "max_retransmissions = $MAX_RETRANSMISSIONS"
printf '%s\n' "redundant_transmissions = $REDUNDANT_TRANSMISSIONS"
printf '%s\n' "send_delay_sec = $SEND_DELAY_SEC"
printf '%s\n' "show_tx_prompt = $SHOW_TX_PROMPT"
printf '%s\n' "verbose = $VERBOSE"
printf '%s\n' "split_tx_lines = $SPLIT_TX_LINES"

# state
#######
# seq_rx and sec_tx initialized after the session initialization
SEQ_TX_FILE="${HOME}${TMP_PATH}/state/seq_tx"
SEQ_TX_ACKED_FILE="${HOME}${TMP_PATH}/state/seq_tx_acked"
SEQ_RX_FILE="${HOME}${TMP_PATH}/state/seq_rx"
SESSION_ESTABLISHED_FILE="${HOME}${TMP_PATH}/state/session_established"
TRANSMITTER_STARTED_FILE="${HOME}${TMP_PATH}/state/transmitter_started"
TX_SENDING_FILE_FILE="${HOME}${TMP_PATH}/state/tx_sending_file"
INVALID_SEQ_NR=200
SESSION_ESTABLISHED="false" # $(head -n 1 "${SESSION_ESTABLISHED_FILE}")

# pipe file out
###############
PIPE_FILE_OUT="${HOME}${TMP_PATH}/tmp/pipe_file_out"

# initialize state: transmitter not yet started
printf '%s\n' "false" > ${TRANSMITTER_STARTED_FILE}
printf '%s\n' "false" > ${SESSION_ESTABLISHED_FILE}
printf '%s\n' "false" > ${TX_SENDING_FILE_FILE}
printf '%s\n' "0" > ${SEQ_TX_FILE}
printf '%s\n' "0" > ${SEQ_RX_FILE}
printf '%s\n' "200" > ${SEQ_TX_ACKED_FILE}

# banner
########
printf '%s\n' "*************************************"
printf '%s\n' "*** tea2adt transmitter, input from:"
printf '%s\n' "*** ${PIPE_FILE_OUT}"
printf '%s\n' "*************************************"

# the first argument is the password
####################################
PASSWORD="$1"
shift 1

# store new state: transmitter started
printf '%s\n' "true" > ${TRANSMITTER_STARTED_FILE}
printf '%s\n' "true" > ${TX_SENDING_FILE_FILE}

# transmit init message and wait until init_ack
###############################################
if [ "${SESSION_ESTABLISHED}" == false ] ; then
    printf '%s\n' "Trying to establish session..."
    if [ "${VERBOSE}" == true ] ; then
        printf '%s\n' "> [init]"
    fi    
    # send start_msgs?
    if [ "${START_MSG}" != "" ] ; then
        printf '%s\n' "${START_MSG}" | source tx.src
    fi
    # send [init]
    printf '%s\n' "[init]" | source tx.src
    # send end_msg?
    if [ "${END_MSG}" != "" ] ; then
        printf '%s\n' "${END_MSG}" | source tx.src
    fi    
    # poll timeout to send [init]
    start_poll_ms=$(date +%s%3N)
    # wait [init_ack_*] by polling state/session_established
    while sleep $TIMEOUT_POLL_SEC
    do
        # poll state
        SESSION_ESTABLISHED=$(head -n 1 "${SESSION_ESTABLISHED_FILE}")
        now_ms=$(date +%s%3N)
        elapsed_time_ms=$((now_ms-start_poll_ms))
        # send [init] ?
        if [ "${SESSION_ESTABLISHED}" == true ] ; then
      	    printf '%s\n' "Session established!"
            break
        elif [[ ${elapsed_time_ms} -gt ${RETRANSMISSION_TIMEOUT_MS} ]] ; then   
            if [ "${VERBOSE}" == true ] ; then
                printf '%s\n' "> [init]"
            fi
            # send start_msg?
            if [ "${START_MSG}" != "" ] ; then
                printf '%s\n' "${START_MSG}" | source tx.src
            fi
            # send [init]
            printf '%s\n' "[init]" | source tx.src
            # send end_msg?
            if [ "${END_MSG}" != "" ] ; then
                printf '%s\n' "${END_MSG}" | source tx.src
            fi
            start_poll_ms=$(date +%s%3N)
        fi
    done 
else
    printf '%s\n' "Session already established!"
fi

# further states
################
printf '%s\n' "false" > ${TX_SENDING_FILE_FILE}
# to show the correct initial values on the prompt
SEQ_TX=$(head -n 1 ${SEQ_TX_FILE})
SEQ_TX_ACKED=$(head -n 1 ${SEQ_TX_ACKED_FILE})
SEQ_RX_NEW=$(head -n 1 ${SEQ_RX_FILE})            
if [[ ${SEQ_RX_NEW} != ${INVALID_SEQ_NR} ]] ; then
    # clean state
    printf '%s\n' ${INVALID_SEQ_NR} > ${SEQ_RX_FILE}
    SEQ_RX=${SEQ_RX_NEW}
else
    SEQ_RX=0 # default is different to 1 which is the first value to be received
fi
seq_tx=$((SEQ_TX+33))
seq_rx=$((SEQ_RX+33))
seq_tx_ascii=$(printf "\x$(printf %x $seq_tx)")
seq_rx_ascii=$(printf "\x$(printf %x $seq_rx)")

# banner 2
##########
if [ "${SHOW_TX_PROMPT}" == true ] ; then
    printf '%s\n' "You can now transfer files in a separate terminal, e.g. with:"
    printf '%s\n' "echo \"<absolute_path>/file\" > ${PIPE_FILE_OUT}"
fi

# main loop
###########
while sleep 0
do      
    # user input file (blocking call)
    #################################
    # note: timeout with option -t not working here
    #       we could try to pipe to a timeout instead
    #       but killing the pipeline may cause problems due to buffering
    #       So, in file-mode the ACKs are sent by the RX process
    read user_input_file <${PIPE_FILE_OUT}
     
    # clean up possible "split-cadavers" that may still exist after transmission errors
    # this way we can continue working in this session
    for f in ${TMPFILE}"_split"*;
    do
        if test -f "${f}"; then
            rm ${f}
        fi
    done
    
    # convert input file to base64 to avoid NUL bytes
    #################################################
    # note: Strings in bash can not contain a NUL byte, and that includes any output from a command substitution. 
    #       Bash variables can't contain a NUL byte either. 
    #       This can not be ignored or over-ridden (although it can be worked around in some commands, such as printf.
    #       https://unix.stackexchange.com/questions/683811/how-do-i-make-bash-not-drop-nul-bytes-on-input-from-command-substitution
    #       As we do not pipe the binary data "directly" to GPG, which uses the option --armor, it is not sufficient to overcome this problem.
    #       Therefore, in order to process NUL bytes correctly we convert the binary file to base64.
    base64 < ${user_input_file} > ${TMPFILE_BASE64_OUT}
    # here we would lose the NUL bytes if we didn't convert first to base64!
    user_input="$(cat ${TMPFILE_BASE64_OUT})"
    if [ "${VERBOSE}" == true ] ; then
        printf '%s\n' "user_input: ${user_input}"
    fi
    
    # show prompt
    #############
    if [ "${SHOW_TX_PROMPT}" == true ] ; then
      	if [ "${VERBOSE}" == true ] ; then
      	    # increment current seq_tx to show the value that will be sent
      	    tmp_tx=$(((SEQ_TX+1)%94))
      	    printf '%s\n' "> [${tmp_tx},${SEQ_RX}] "${user_input_file}
      	else
      	    printf '%s\n' "> "${user_input_file}
      	fi
    fi    
    
    # store user_input in temporary file
    ####################################
    printf '%s\n' "${user_input}" > ${TMPFILE}
    
    # split data
    ############
    if [ ${SPLIT_TX_LINES} -gt 0 ] ; then
        nr_splitted_files=$(split --verbose -l ${SPLIT_TX_LINES} --numeric-suffixes ${TMPFILE} ${TMPFILE}"_split" | wc -l)
    else
        mv ${TMPFILE} ${TMPFILE}"_split00"
        nr_splitted_files=1
    fi
    
    # file name
    file_name=$(basename -- "${user_input_file}")
    
    # set flag
    printf '%s\n' "true" > ${TX_SENDING_FILE_FILE}
    
    # loop to send data-chunks
    ##########################
    chunk_nr=0
    for f in ${TMPFILE}"_split"*;
    do
        # update SEQ_TX
        ###############
        # we store the increased value later, after it was acknowledged
        SEQ_TX=$(((SEQ_TX+1)%94))
        # update chunk-nr
        chunk_nr=$((chunk_nr+1))
        # prepare before send
        current_retransmissions=0
        seq_tx=$((SEQ_TX+33))      
        seq_tx_ascii=$(printf "\x$(printf %x $seq_tx)")   
                             
        # retransmission loop
        #####################
        # send message, wait ACK, and retransmit when needed up to max. retransmissions
        while [[ ${current_retransmissions} -ge 0 ]]
        do
            # prepare send
            ##############
            SEQ_RX_NEW=$(head -n 1 ${SEQ_RX_FILE})
            if [[ ${SEQ_RX} != ${INVALID_SEQ_NR} ]] && [[ ${SEQ_RX_NEW} != ${INVALID_SEQ_NR} ]] ; then
                # clean state and update variable
                printf '%s\n' ${INVALID_SEQ_NR} > ${SEQ_RX_FILE}
                # SEQ_RX to be acknowledged in data message
                SEQ_RX=${SEQ_RX_NEW}
                seq_rx=$((SEQ_RX+33))
                seq_rx_ascii=$(printf "\x$(printf %x $seq_rx)")
            fi
            # last chunk?
            if [[ ${chunk_nr} -eq ${nr_splitted_files} ]] ; then
                if [[ ${PREAMBLE} == "" && ${TRAILER} == "" ]] ; then
                    printf '%s\n' "${seq_tx_ascii}${seq_rx_ascii}[file_name]${file_name}[file_end]$(<${f} )" | source gpg.src
                else
                    printf '%s' ${PREAMBLE} > ${MSGFILE}
                    printf '%s\n' "${seq_tx_ascii}${seq_rx_ascii}[file_name]${file_name}[file_end]$(<${f} )" | source gpgappend.src
                    if [ "${TRAILER}" != "" ] ; then
                        printf '%s\n' ${TRAILER} >> ${MSGFILE}
                    fi
                fi
            else
                if [[ ${PREAMBLE} == "" && ${TRAILER} == "" ]] ; then
                    printf '%s\n' "${seq_tx_ascii}${seq_rx_ascii}[file_name]${file_name}[file]$(<${f} )" | source gpg.src
                else
                    printf '%s' ${PREAMBLE} > ${MSGFILE}
                    printf '%s\n' "${seq_tx_ascii}${seq_rx_ascii}[file_name]${file_name}[file]$(<${f} )" | source gpgappend.src
                    if [ "${TRAILER}" != "" ] ; then
                        printf '%s\n' ${TRAILER} >> ${MSGFILE}
                    fi
                fi
            fi

            # send message with encrypted data-chunk
            ########################################
            if [ "${VERBOSE}" == true ] ; then
                printf '%s\n' "> file[${SEQ_TX},${SEQ_RX}] chunk ${chunk_nr} from total ${nr_splitted_files}, try ${current_retransmissions}"
            fi
            # send start_msg?
            if [ "${START_MSG}" != "" ] ; then
                printf '%s\n' "${START_MSG}" | source tx.src
            fi
            # send message
            cat ${MSGFILE} | source tx.src
            # send end_msg?
            if [ "${END_MSG}" != "" ] ; then
                printf '%s\n' "${END_MSG}" | source tx.src
            fi
            # send redundant messages?
            for ((i=1; i<=${REDUNDANT_TRANSMISSIONS}; i++))
            do
                if [ "${VERBOSE}" == true ] ; then
                    printf '%s\n' ">> file[${SEQ_TX},${SEQ_RX}] chunk ${chunk_nr} from total ${nr_splitted_files}, transmitted redundant message times = ${i}"
                fi
                # NOTE: no start_msg needed for redundant messages
                # send redundant message
                cat ${MSGFILE} | source tx.src
                # add end_msg?
                if [ "${END_MSG}" != "" ] ; then
                    printf '%s\n' "${END_MSG}" | source tx.src
                fi
            done
            start_poll_ms=$(date +%s%3N)

            # loop to poll retransmission timeout
            #####################################
            # wait ACK by polling state/seq_tx_acked
            while sleep $TIMEOUT_POLL_SEC
            do
                # received ACK?
                ###############
                SEQ_TX_ACKED=$(head -n 1 ${SEQ_TX_ACKED_FILE})
                now_ms=$(date +%s%3N)
                elapsed_time_ms=$((now_ms-start_poll_ms))                    
                if [ "${NEED_ACK}" == "false" ] || [[ ${SEQ_TX_ACKED} == ${SEQ_TX} ]] ; then
                    # store SEQ_TX after it was acknowledged
                    printf '%s\n' ${SEQ_TX} > ${SEQ_TX_FILE}
                    if [ "${VERBOSE}" == true ] && [[ ${SEQ_TX_ACKED} == ${SEQ_TX} ]]; then
                        total_elapsed_time_ms=$(printf '%s\n' ${current_retransmissions}*${RETRANSMISSION_TIMEOUT_MS}+${elapsed_time_ms} | bc)
                        printf '%s\n' "RECEIVED ACK for ${SEQ_TX} after milliseconds = ${total_elapsed_time_ms}"
                    fi
                    rm ${f}
                    # signal to exit outer loop
                    current_retransmissions=-1
                    # show prompt
                    #############
                    if [ "${SHOW_TX_PROMPT}" == true ] ; then
                  	    printf '%s\n' ">     part ${chunk_nr} from ${nr_splitted_files} sent"
                    fi
                    # send next chunk
                    sleep ${SEND_DELAY_SEC}
                    break
                # retransmit?
                #############
                # TODO: subtract TIMEOUT_POLL_SEC (in milliseconds) from RETRANSMISSION_TIMEOUT_MS
                #       in order to always retransmit "before" RETRANSMISSION_TIMEOUT_MS expires?
                elif [[ ${elapsed_time_ms} -gt ${RETRANSMISSION_TIMEOUT_MS} ]] ; then                    
                    # max. retransmission exceeded?
                    if [[ ${current_retransmissions} -gt ${MAX_RETRANSMISSIONS} ]] ; then
                        # we exit with an error message
                        printf '%s\n' "ERROR: maximum nr. of retransmissions (${MAX_RETRANSMISSIONS}) exceeded!"
                        # TODO: put back exit 200 and remove break and flag reset
                        sleep 5
                        # some error code between 1 and 255
                        exit 200
                        # TODO: check if we can continue here, but making sure that flags and counters remain consistent.
                        # current_retransmissions=-1
                        # break
                    fi
                    current_retransmissions=$((current_retransmissions+1))
                    # retransmit
                    break
                else
                    : # continue
                fi # retransmit?
            done # while poll ACK
        done # while retransmissions
    done # while TX data-chunks

    # reset flag
    printf '%s\n' "false" > ${TX_SENDING_FILE_FILE}
done # main loop
