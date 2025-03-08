#!/bin/bash
# TODO: check that we only kill the processes that we want (e.g. improve grep)
{ # try

    for pid in $(ps -ef | grep "sh ./tea2adt -" | awk '{print $2}'); 
    do
        kill -9 $pid; 
    done
} || { # catch
    # save log for exception
    :
}
{ # try

    for pid in $(ps -ef | grep mmrx.py | awk '{print $2}'); 
    do
        kill -9 $pid; 
    done
} || { # catch
    # save log for exception
    :
}
exit 0

