#!/bin/bash
# TODO: check that we only kill the processes that we want (e.g. improve grep)
{ # try
    for pid in $(ps -ef | grep 'mmsessionout.sh' | awk '{print $2}'); 
    do
        kill -9 $pid; 
    done
} || { # catch
    # save log for exception
    :
}
# TODO: remove this code block, mmsessionout.sh seems to be working fine
: '
{ # try
    for pid in $(ps -ef | grep 'tmux new-session -d -s session_llm' | awk '{print $2}'); 
    do
        kill -9 $pid; 
    done
} || { # catch
    # save log for exception
    :
}
'
{ # try

    tmux kill-session -t session_llm
} || { # catch
    # save log for exception
    :
}
{ # try

    for pid in $(ps -ef | grep "./tea2adt -" | awk '{print $2}'); 
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
# TODO: need this?
: '
{ # try

    for pid in $(ps -ef | grep "ollama_llama_server --model" | awk '{print $2}'); 
    do
        kill -9 $pid; 
    done
} || { # catch
    # save log for exception
    :
}
'
exit 0
