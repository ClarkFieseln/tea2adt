#!/bin/bash

# read tmp path
TMP_PATH=$(head -n 1 cfg/tmp_path)

# read configuration from files copied in tmp path
BAUD=$(head -n 1 ${HOME}${TMP_PATH}/cfg/baud)
SYNCBYTE=$(head -n 1 ${HOME}${TMP_PATH}/cfg/syncbyte)
CONFIDENCE=$(head -n 1 ${HOME}${TMP_PATH}/cfg/confidence)
LIMIT=$(head -n 1 ${HOME}${TMP_PATH}/cfg/limit)

# RX
source rx.src
