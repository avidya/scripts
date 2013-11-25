#!/bin/bash
SSH_HOME=$HOME/.ssh
SSHX_HOME=$HOME/.sshx
SSHX_REGISTRY=$SSHX_HOME/sites

mkdir $SSHX_HOME 2> /dev/null

function loadentry {
    echo Loading ssh logging info from history...
    grep -i -E "ssh\s+[a-zA-Z0-9_@]+[a-zA-Z0-9\.]+$" $HOME/.bash_history|awk '{print $2}'|sed -r 's/(.*)/\1 n/'|sed -r "s/^([a-zA-Z0-9\.]+\s+[yn])$/${USER}@\1/"|sort|uniq &>$SSHX_REGISTRY
}

function genkeys {
    [ -d $SSH_HOME ] || mkdir $SSH_HOME
    local idfile
    idfile=`ls $HOME/.ssh/*.pub 2> /dev/null | head -1`
    [ -z "$idfile" ] && ssh-keygen -q -t dsa -f "${SSH_HOME}/id_dsa" -N ""
}

function putkeys {
    cat `ls ~/.ssh/*.pub 2> /dev/null | head -1` | execput "$*"
}

function execput {
    ssh $1 'mkdir .ssh; chmod 700 .ssh; touch ~/.ssh/authorized_keys; chmod 600 ~/.ssh/authorized_keys; cat >> ~/.ssh/authorized_keys' 2> /dev/null
}

[ -f "$SSHX_REGISTRY" ] || touch "$SSHX_REGISTRY"

if (( $# == 0 )); then
# INTERACTIVE MODE
    #check status for loading history ssh logging info
    ln=`cat $SSHX_REGISTRY | grep -vE "^\s*$" |wc -l`
    [ $((ln)) == 0 ] && loadentry

    exec 3<&0
    exec 0<"$SSHX_REGISTRY"
    
    num=1
    while read -r line
    do
        FLAG=1
        echo -e "\t$num.) $line" | sed -r 's/(\w+@[a-zA-Z0-9_:\.]+)\[([0-9]+)\].*/\1:\2/' 
	let num++
    done

    exec 0<&3

    if [ "$FLAG" = "" ]; then
        echo "No registed sites info."
    else
        echo -n "Please select the sites number: "
        read SEL
        registry=`head -$SEL $SSHX_REGISTRY | tail -1`
        pat="^([a-zA-Z0-9_\.]+@[a-zA-Z0-9_:\.]+)\[([0-9]+)\]\s+([yn])$"
        if [[ $registry =~ $pat ]]; then
            h=${BASH_REMATCH[1]}
            p=${BASH_REMATCH[2]}
            m=${BASH_REMATCH[3]}
            if [ $m != "y" ]; then
                echo -n "Do you want to store your public key on remote machine? [y|n] "
                read ans
                if [ $ans == "y" ]; then
                    genkeys
		            putkeys "$h -p $p"
                    sed -ri "s/($h\[$p\]\s+)n$/\1y/g"  $SSHX_REGISTRY 
                fi
            fi
            ssh -X $h -p $p # enable X forwarding
        fi
    fi
else
# DIRECT MODE
    param=("$@")
    for ((i=0; i<$#; i++))
    do
        [ "x${param[$i]}" == "x-p" ] && port=${param[$((i+1))]}
    done

    [ "x$port" == "x" ] && port=22

    for p in $*; do
        [[ $p =~ ^([a-zA-Z0-9\._]+@)?([a-zA-Z0-9:\.]+)+$ ]] && host=$p
    done

    [[ ! $host =~ .+@.+ ]] && host="${USER}@${host}"

    line=`grep "$host\[$port\]" $SSHX_REGISTRY`
    if [ $? == 1 ]; then
        echo -n "Do you want to save this host to your bookmark? [y|n] "
        read ans1
        echo -n "Do you want to store your public key on remote machine? [y|n] "
        read ans2
        if [ "$ans2" == "y" ]; then
            genkeys
	    putkeys "$host -p $port"
        fi
        if [ "$ans1" == "y" ]; then
            echo "$host[$port] $ans2" >> "$SSHX_REGISTRY"
        fi
    else
        pat="^([a-zA-Z0-9_\.]+@[a-zA-Z0-9_:\.]+)\[([0-9]+)\]\s+([yn])$"
        if [[ $line =~ $pat ]]; then
            h=${BASH_REMATCH[1]}
            p=${BASH_REMATCH[2]}
            m=${BASH_REMATCH[3]}
            if [ $m != "y" ]; then
                echo -n "Do you want to store your public key on remote machine? [y|n] "
                read ans
                if [ $ans == "y" ]; then
                    genkeys
        		    putkeys "$h -p $p"
                    sed -ri "s/($h\[$p\]\s+)n$/\1y/g"  $SSHX_REGISTRY 
                fi
            fi
        fi
    fi
    ssh $@
fi
