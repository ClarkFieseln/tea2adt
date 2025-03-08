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
TMP_PATH=$(head -n 1 cfg/tmp_path)
END_MSG=$(head -n 1 ${HOME}${TMP_PATH}/cfg/end_msg)
START_MSG=$(head -n 1 ${HOME}${TMP_PATH}/cfg/start_msg)
TRAILER=$(head -n 1 ${HOME}${TMP_PATH}/cfg/trailer)
PREAMBLE=$(head -n 1 ${HOME}${TMP_PATH}/cfg/preamble)
CIPHER_ALGO=$(head -n 1 ${HOME}${TMP_PATH}/cfg/cipher_algo)
ARMOR=$(head -n 1 ${HOME}${TMP_PATH}/cfg/armor)
BAUD=$(head -n 1 ${HOME}${TMP_PATH}/cfg/baud)
SYNCBYTE=$(head -n 1 ${HOME}${TMP_PATH}/cfg/syncbyte)
NEED_ACK=$(head -n 1 ${HOME}${TMP_PATH}/cfg/need_ack)
VERBOSE=$(head -n 1 ${HOME}${TMP_PATH}/cfg/verbose)
HALF_DUPLEX=$(head -n 1 ${HOME}${TMP_PATH}/cfg/half_duplex)
# uncomment if set-source-volume is used i.o. set-source-mute in files tx.src and restore_mic.sh
# VOLUME_MICROPHONE=$(head -n 1 ${HOME}${TMP_PATH}/cfg/volume_microphone)
MSGFILE="${HOME}${TMP_PATH}/tmp/msgtx.gpg"
TMPFILE="${HOME}${TMP_PATH}/tmp/out.txt"
INVALID_SEQ_NR=200

# state
#######
SEQ_TX_FILE="${HOME}${TMP_PATH}/state/seq_tx"
SEQ_RX_FILE="${HOME}${TMP_PATH}/state/seq_rx"
SEQ_TX_ACKED_FILE="${HOME}${TMP_PATH}/state/seq_tx_acked"
SEQ_TX=$(head -n 1 ${SEQ_TX_FILE})
SEQ_TX_ACKED=$(head -n 1 ${SEQ_TX_ACKED_FILE})
SEQ_RX_NEW=$(head -n 1 ${SEQ_RX_FILE})            
if [[ ${SEQ_RX_NEW} != ${INVALID_SEQ_NR} ]] ; then
    # we don't clean state, that will be done in mmshellout.sh     
    SEQ_RX=${SEQ_RX_NEW}
else
    if [ "${VERBOSE}" == true ] ; then
        echo "WARNING: mmdata.sh called but SEQ_RX = INVALID_SEQ_NR. Defaulting to 0!"
    fi
    SEQ_RX=0 # default is different to 1 which is the first value to be received
fi
seq_tx=$((SEQ_TX+33))
seq_rx=$((SEQ_RX+33))
seq_tx_ascii=$(printf "\x$(printf %x $seq_tx)") 
seq_rx_ascii=$(printf "\x$(printf %x $seq_rx)") 

# the first argument is the password
PASSWORD="$1"
DATA="$2"
                                  
# send DATA
###########
if [ "${NEED_ACK}" == "true" ] ; then
    if [[ ${SEQ_RX} != ${INVALID_SEQ_NR} ]] && [[ ${SEQ_RX_NEW} != ${INVALID_SEQ_NR} ]] ; then
        # SEQ_RX to be acknowledged in data message
        # we don't clean state, that will be done in mmshellout.sh
        SEQ_RX=${SEQ_RX_NEW}
        seq_rx=$((SEQ_RX+33))
        seq_rx_ascii=$(printf "\x$(printf %x $seq_rx)")        
        # send DATA
        if [[ ${PREAMBLE} == "" && ${TRAILER} == "" ]] ; then
            echo "${seq_tx_ascii}${seq_rx_ascii}[data]${DATA}" | source gpg.src
        else
            echo -n ${PREAMBLE} > ${MSGFILE}
            echo "${seq_tx_ascii}${seq_rx_ascii}[data]${DATA}" | source gpgappend.src
            if [ "${TRAILER}" != "" ] ; then
                echo ${TRAILER} >> ${MSGFILE}
            fi
        fi
        if [ "${VERBOSE}" == true ] ; then
            echo "> data[${SEQ_TX},${SEQ_RX}]"
        fi
        # send start_msg?
        if [ "${START_MSG}" != "" ] ; then
            echo "${START_MSG}" | source tx.src
        fi        
        # send message with encrypted data
        cat ${MSGFILE} | source tx.src
        # add end_msg?
        if [ "${END_MSG}" != "" ] ; then
            echo "${END_MSG}" | source tx.src
        fi            
    else
        if [ "${VERBOSE}" == true ] ; then
            echo "FAILED to send: data[${SEQ_TX},${SEQ_RX},${SEQ_RX_NEW}]"
        fi            
    fi
fi                        
