#!/bin/bash          

# message types
###############
: '
    [init]
    [init_ack_chat]
    [init_ack_shell]
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
ARMOR=$(head -n 1 ${HOME}${TMP_PATH}/cfg/armor) # "--armor" # ""
BAUD=$(head -n 1 ${HOME}${TMP_PATH}/cfg/baud) # 12000 # 240 # 1200 # 2400 # 12000
SYNCBYTE=$(head -n 1 ${HOME}${TMP_PATH}/cfg/syncbyte)
KEEPALIVE_TIME_SEC=$(head -n 1 ${HOME}${TMP_PATH}/cfg/keepalive_time_sec) # 1.0 # 0.25 # 0.0 or 0 to deactivate
# convert KEEPALIVE_TIME_SEC to ms:
KEEPALIVE_TIME_MS=$(echo ${KEEPALIVE_TIME_SEC}*1000 | bc)
# and now remove decimal values:
KEEPALIVE_TIME_MS=${KEEPALIVE_TIME_MS%.*}
RETRANSMISSION_TIMEOUT_SEC=$(head -n 1 ${HOME}${TMP_PATH}/cfg/retransmission_timeout_sec)
# convert RETRANSMISSION_TIMEOUT_SEC to ms:
RETRANSMISSION_TIMEOUT_MS=$(echo ${RETRANSMISSION_TIMEOUT_SEC}*1000 | bc)
# and now remove decimal values:
RETRANSMISSION_TIMEOUT_MS=${RETRANSMISSION_TIMEOUT_MS%.*}
TIMEOUT_POLL_SEC=$(head -n 1 ${HOME}${TMP_PATH}/cfg/timeout_poll_sec)
MAX_RETRANSMISSIONS=$(head -n 1 ${HOME}${TMP_PATH}/cfg/max_retransmissions)
REDUNDANT_TRANSMISSIONS=$(head -n 1 ${HOME}${TMP_PATH}/cfg/redundant_transmissions)
SHOW_TX_PROMPT=$(head -n 1 ${HOME}${TMP_PATH}/cfg/show_tx_prompt)
NEED_ACK=$(head -n 1 ${HOME}${TMP_PATH}/cfg/need_ack)
VERBOSE=$(head -n 1 ${HOME}${TMP_PATH}/cfg/verbose)
SPLIT_TX_LINES=$(head -n 1 ${HOME}${TMP_PATH}/cfg/split_tx_lines)
HALF_DUPLEX=$(head -n 1 ${HOME}${TMP_PATH}/cfg/half_duplex)
# uncomment if set-source-volume is used i.o. set-source-mute in files tx.src and restore_mic.sh
# VOLUME_MICROPHONE=$(head -n 1 ${HOME}${TMP_PATH}/cfg/volume_microphone)
MSGFILE="${HOME}${TMP_PATH}/tmp/msgtx.gpg"
TMPFILE="${HOME}${TMP_PATH}/tmp/out.txt"
echo "baud = $BAUD"
echo "half_duplex = $HALF_DUPLEX"
echo "need_ack = $NEED_ACK"
echo "start_msg = $START_MSG"
echo "end_msg = $END_MSG"
echo "preamble = $PREAMBLE"
echo "trailer = $TRAILER"
echo "cipher_algo = $CIPHER_ALGO"
echo "armor = $ARMOR"
echo "syncbyte = $SYNCBYTE"
echo "keepalive_time_sec = $KEEPALIVE_TIME_SEC"
echo "(keepalive_time_ms = $KEEPALIVE_TIME_MS)"
echo "retransmission_timeout_sec = $RETRANSMISSION_TIMEOUT_SEC"
echo "(retransmission_timeout_ms = $RETRANSMISSION_TIMEOUT_MS)"
echo "timeout_poll_sec = $TIMEOUT_POLL_SEC"
echo "max_retransmissions = $MAX_RETRANSMISSIONS"
echo "redundant_transmissions = $REDUNDANT_TRANSMISSIONS"
echo "send_delay_sec = $SEND_DELAY_SEC"
echo "show_tx_prompt = $SHOW_TX_PROMPT"
echo "verbose = $VERBOSE"
echo "split_tx_lines = $SPLIT_TX_LINES"

# state
#######
# seq_rx and sec_tx initialized after the session initialization
SEQ_TX_FILE="${HOME}${TMP_PATH}/state/seq_tx"
SEQ_TX_ACKED_FILE="${HOME}${TMP_PATH}/state/seq_tx_acked"
SEQ_RX_FILE="${HOME}${TMP_PATH}/state/seq_rx"
SESSION_ESTABLISHED_FILE="${HOME}${TMP_PATH}/state/session_established"
TRANSMITTER_STARTED_FILE="${HOME}${TMP_PATH}/state/transmitter_started"
INVALID_SEQ_NR=200
SESSION_ESTABLISHED="false" # $(head -n 1 "${SESSION_ESTABLISHED_FILE}")

# initialize state: transmitter not yet started
echo "false" > ${TRANSMITTER_STARTED_FILE}
echo "false" > ${SESSION_ESTABLISHED_FILE}
echo "0" > ${SEQ_TX_FILE}
echo "0" > ${SEQ_RX_FILE}
echo "200" > ${SEQ_TX_ACKED_FILE}

# banner
########
echo "****************************"
echo "*** tea2adt transmitter ***"
echo "****************************"

# the first argument is the password
####################################
PASSWORD="$1"
shift 1

# store new state: transmitter started
echo "true" > ${TRANSMITTER_STARTED_FILE}

# transmit init message and wait until init_ack
###############################################
if [ "${SESSION_ESTABLISHED}" == false ] ; then
    echo "Trying to establish session..."
    if [ "${VERBOSE}" == true ] ; then
        echo "> [init]"
    fi    
    # send start_msgs?
    if [ "${START_MSG}" != "" ] ; then
        echo "${START_MSG}" | source tx.src
    fi
    # send [init]
    echo "[init]" | source tx.src
    # send end_msg?
    if [ "${END_MSG}" != "" ] ; then
        echo "${END_MSG}" | source tx.src
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
      	    echo "Session established!"
            break
        elif [[ ${elapsed_time_ms} -gt ${RETRANSMISSION_TIMEOUT_MS} ]] ; then   
            if [ "${VERBOSE}" == true ] ; then
                echo "> [init]"
            fi              
            # send start_msg?
            if [ "${START_MSG}" != "" ] ; then
                echo "${START_MSG}" | source tx.src
            fi
            # send [init]
            echo "[init]" | source tx.src
            # send end_msg?
            if [ "${END_MSG}" != "" ] ; then
                echo "${END_MSG}" | source tx.src
            fi 
            start_poll_ms=$(date +%s%3N)
        fi
    done 
else
    echo "Session already established!"
fi

# further states
################
# to show the correct initial values on the prompt
SEQ_TX=$(head -n 1 ${SEQ_TX_FILE})
SEQ_TX_ACKED=$(head -n 1 ${SEQ_TX_ACKED_FILE})
SEQ_RX_NEW=$(head -n 1 ${SEQ_RX_FILE})            
if [[ ${SEQ_RX_NEW} != ${INVALID_SEQ_NR} ]] ; then
    # clean state
    echo ${INVALID_SEQ_NR} > ${SEQ_RX_FILE}
    SEQ_RX=${SEQ_RX_NEW}
else
    SEQ_RX=0 # default is different to 1 which is the first value to be received
fi
seq_tx=$((SEQ_TX+33))
seq_rx=$((SEQ_RX+33))
seq_tx_ascii=$(printf "\x$(printf %x $seq_tx)") 
seq_rx_ascii=$(printf "\x$(printf %x $seq_rx)") 

# main loop
###########
while sleep 0
do  
    # show prompt
    #############
    if [ "${SHOW_TX_PROMPT}" == true ] ; then
      	if [ "${VERBOSE}" == true ] ; then
      	    # increment current seq_tx to show the value that will be sent
      	    tmp_tx=$(((SEQ_TX+1)%94))
      	    echo -n "> [${tmp_tx},${SEQ_RX}] "
      	else
      	    echo -n "> "
      	fi    
    fi
    
    # get user input (and send ACKs and [keepalive] in the background)
    ##################################################################
    # poll changes in seq_rx to send ACKs (=<seq_tx><seq_rx>[ack]),
    # poll timeout to send [keepalive]
    start_poll_ms=$(date +%s%3N)
    while :
    do    
        # user input (blocking call with timeout)
        #########################################
        read -t ${TIMEOUT_POLL_SEC} user_input <&1
        # calculate elapsed time
        now_ms=$(date +%s%3N)
        elapsed_time_ms=$((now_ms-start_poll_ms))
        
        # got user input?
        #################
        if [[ ${user_input} != "" ]] ; then                   
  	        break # process further below..
  	    fi
  	    
  	    # send ACK?
  	    ###########
        if [ "${NEED_ACK}" == "true" ] ; then
            SEQ_RX_NEW=$(head -n 1 ${SEQ_RX_FILE})            
            if [[ ${SEQ_RX} != ${INVALID_SEQ_NR} ]] && [[ ${SEQ_RX_NEW} != ${INVALID_SEQ_NR} ]] ; then
                # clean state
                echo ${INVALID_SEQ_NR} > ${SEQ_RX_FILE}
                # SEQ_RX to be acknowledged in ACK message
                SEQ_RX=${SEQ_RX_NEW}
                seq_rx=$((SEQ_RX+33))
                seq_rx_ascii=$(printf "\x$(printf %x $seq_rx)")
                SEQ_TX=$(head -n 1 ${SEQ_TX_FILE})
                seq_tx=$((SEQ_TX+33))
                seq_tx_ascii=$(printf "\x$(printf %x $seq_tx)") 
                # send ACK without data
                if [[ ${PREAMBLE} == "" && ${TRAILER} == "" ]] ; then
                    echo "${seq_tx_ascii}${seq_rx_ascii}[ack]" | source gpg.src
                else
                    echo -n ${PREAMBLE} > ${MSGFILE}
                    echo "${seq_tx_ascii}${seq_rx_ascii}[ack]" | source gpgappend.src
                    if [ "${TRAILER}" != "" ] ; then
                        echo ${TRAILER} >> ${MSGFILE}
                    fi
                fi
                # prepare message with encrypted data
                if [ "${VERBOSE}" == true ] ; then
                    echo "> ack[${SEQ_TX},${SEQ_RX}]"
                fi                 
                # send start_msg?
                if [ "${START_MSG}" != "" ] ; then
                    echo "${START_MSG}" | source tx.src
                fi
                # send ACK
                cat ${MSGFILE} | source tx.src
                # send end_msg?
                if [ "${END_MSG}" != "" ] ; then
                    echo "${END_MSG}" | source tx.src
                fi                
                start_poll_ms=$(date +%s%3N)                
  	        fi
  	    fi 	 
  	       
  	    # send keepalive message?
  	    #########################
  	    # TODO: add a random value to KEEPALIVE_TIME_SEC when checked against elapsed_time_ms in order to avoid collissions
        if [[ ${KEEPALIVE_TIME_SEC} != 0 && ${KEEPALIVE_TIME_SEC} != 0.0 ]] ; then             
            if [[ ${elapsed_time_ms} -gt ${KEEPALIVE_TIME_MS} ]] ; then                            
                if [ "${VERBOSE}" == true ] ; then
                    echo "> [keepalive]"
                fi       	        
      	        echo "[keepalive]" | source tx.src
      	        start_poll_ms=$(date +%s%3N)
  	        fi
  	    fi
    done
    
    # store user_input in temporary file
    #####################################
    echo "${user_input}" > ${TMPFILE}
    
    # split data
    ############
    if [ ${SPLIT_TX_LINES} -gt 0 ] ; then
        split -l ${SPLIT_TX_LINES} --numeric-suffixes ${TMPFILE} ${TMPFILE}"_split"
    else
        mv ${TMPFILE} ${TMPFILE}"_split00"
    fi
    
    # loop to send data-chunks
    ##########################
    for f in ${TMPFILE}"_split"*;
    do
        # update SEQ_TX
        ###############
        # we store the increased value later, after it was acknowledged
        SEQ_TX=$(((SEQ_TX+1)%94))
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
                echo ${INVALID_SEQ_NR} > ${SEQ_RX_FILE}
                # SEQ_RX to be acknowledged in data message
                SEQ_RX=${SEQ_RX_NEW}
                seq_rx=$((SEQ_RX+33))
                seq_rx_ascii=$(printf "\x$(printf %x $seq_rx)")
            fi
            if [[ ${PREAMBLE} == "" && ${TRAILER} == "" ]] ; then
                echo "${seq_tx_ascii}${seq_rx_ascii}[data]$(<${f} )" | source gpg.src
            else
                echo -n ${PREAMBLE} > ${MSGFILE}
                echo "${seq_tx_ascii}${seq_rx_ascii}[data]$(<${f} )" | source gpgappend.src
                if [ "${TRAILER}" != "" ] ; then
                    echo ${TRAILER} >> ${MSGFILE}
                fi
            fi
            
            # send message with encrypted data-chunk
            ########################################
            if [ "${VERBOSE}" == true ] ; then
                echo "> data[${SEQ_TX},${SEQ_RX}] try ${current_retransmissions}"
            fi             
            # send start_msg?
            if [ "${START_MSG}" != "" ] ; then
                echo "${START_MSG}" | source tx.src
            fi
            # send message
            cat ${MSGFILE} | source tx.src
            # send end_msg?
            if [ "${END_MSG}" != "" ] ; then
                echo "${END_MSG}" | source tx.src
            fi
            # send redundant messages
            for ((i=1; i<=${REDUNDANT_TRANSMISSIONS}; i++))
            do
                if [ "${VERBOSE}" == true ] ; then
                    echo ">> data[${SEQ_TX},${SEQ_RX}] transmitted redundant message times = ${i}"
                fi            
                # NOTE: no start_msg needed for redundant messages
                # send redundant message
                cat ${MSGFILE} | source tx.src
                # send end_msg?
                if [ "${END_MSG}" != "" ] ; then
                    echo "${END_MSG}" | source tx.src
                fi 
                            
            done          
            start_poll_ms=$(date +%s%3N)            
                    
            # loop to poll retransmission timeout
            #####################################
            # wait ACK by polling state/seq_tx_acked
            # in parallel check if need to send ACK to the other side
            while sleep $TIMEOUT_POLL_SEC
            do                        
                # received ACK?
                ###############
                SEQ_TX_ACKED=$(head -n 1 ${SEQ_TX_ACKED_FILE})
                now_ms=$(date +%s%3N)
                elapsed_time_ms=$((now_ms-start_poll_ms))                    
                if [ "${NEED_ACK}" == "false" ] || [[ ${SEQ_TX_ACKED} == ${SEQ_TX} ]] ; then
                    # store SEQ_TX after it was acknowledged
                    echo ${SEQ_TX} > ${SEQ_TX_FILE}
                    if [ "${VERBOSE}" == true ] && [[ ${SEQ_TX_ACKED} == ${SEQ_TX} ]]; then
                        total_elapsed_time_ms=$(echo ${current_retransmissions}*${RETRANSMISSION_TIMEOUT_MS}+${elapsed_time_ms} | bc)                      
                        echo "RECEIVED ACK after milliseconds = ${total_elapsed_time_ms}"
                    fi                        
                    rm ${f}
                    # signal to exit outer loop
                    current_retransmissions=-1
                    # send next chunk
                    break                                        
                # retransmit?
                #############
                # TODO: subtract TIMEOUT_POLL_SEC (in milliseconds) from RETRANSMISSION_TIMEOUT_MS
                #       in order to always retransmit "before" RETRANSMISSION_TIMEOUT_MS expires?
                elif [[ ${elapsed_time_ms} -gt ${RETRANSMISSION_TIMEOUT_MS} ]] ; then                    
                    # max. retransmission exceeded?
                    if [[ ${current_retransmissions} -gt ${MAX_RETRANSMISSIONS} ]] ; then
                        # we exit with an error message
                        echo "ERROR: maximum nr. of retransmissions (${MAX_RETRANSMISSIONS}) exceeded!"
                        sleep 5
                        # some error code between 1 and 255
                        exit 200
                        # TODO: check if we can continue here, but making sure that flags and counters remain consistent.
                        # signal to exit outer loop
                        # current_retransmissions=-1
                        # break
                    fi 
                    current_retransmissions=$((current_retransmissions+1))
                    # retransmit
                    break                       
                else
                    : # continue polling if ACK received                            
                fi      
                # send ACK?
          	    ###########
                if [ "${NEED_ACK}" == "true" ] ; then
                    SEQ_RX_NEW=$(head -n 1 ${SEQ_RX_FILE})            
                    if [[ ${SEQ_RX} != ${INVALID_SEQ_NR} ]] && [[ ${SEQ_RX_NEW} != ${INVALID_SEQ_NR} ]] ; then
                        # clean state
                        echo ${INVALID_SEQ_NR} > ${SEQ_RX_FILE}
                        # SEQ_RX to be acknowledged in ACK message
                        SEQ_RX=${SEQ_RX_NEW}
                        seq_rx=$((SEQ_RX+33))
                        seq_rx_ascii=$(printf "\x$(printf %x $seq_rx)")
                        # send ACK without data
                        if [[ ${PREAMBLE} == "" && ${TRAILER} == "" ]] ; then
                            echo "${seq_tx_ascii}${seq_rx_ascii}[ack]" | source gpg.src
                        else
                            echo -n ${PREAMBLE} > ${MSGFILE}
                            echo echo "${seq_tx_ascii}${seq_rx_ascii}[ack]" | source gpgappend.src
                            if [ "${TRAILER}" != "" ] ; then
                                echo ${TRAILER} >> ${MSGFILE}
                            fi
                        fi
                        # send message with encrypted data
                        if [ "${VERBOSE}" == true ] ; then
                            echo "> ack[${SEQ_TX},${SEQ_RX}]"
                        fi                        
                        # send start_msg?
                        if [ "${START_MSG}" != "" ] ; then
                            echo "${START_MSG}" | source tx.src
                        fi
                        # send ACK                      
                        cat ${MSGFILE} | source tx.src
                        # add end_msg?
                        if [ "${END_MSG}" != "" ] ; then
                            echo "${END_MSG}" | source tx.src
                        fi
          	        fi
          	    fi                        
            done # while poll ACK
        done # while retransmissions
    done # while TX data-chunks
done # main loop
