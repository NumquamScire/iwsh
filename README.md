# iwsh (INTERACTIVE WEB SHELL)


##### *The goal of the project is to create a fully interactive shell based on a web server without the need for any additional network connections.*


I was inspired by a situation where I couldn't create any new connections except for web connections over the HTTP protocol.
After spending several days i didn't find works solution. First problem is was create established process, so project create independent process of http requests on server. 

This project communicate over named pipes that create in file system. Interactive shell using two pipes. First pipe for **stdin** default `/tmp/i` that web server write data to from user. Second pipe use for **stdout** and **stderr** defualt `/tmp/o` that web server read data from shell and return to user via Chunked Transfer Encoding that available in `HTTP/1.1`. Streaming data transfer from **stdout** and **stderr** helps reduce the number of requests. I recommend use direcotry `/dev/shm` instead of `/tmp` or other directory that do not leave any fingerprints on disk.

The project consists of two files: 1) client is written in bash by use **curl** for communication with web server. 2) page for web server for communicate with client and server-side shell.

**Curl** has some limitation for request chunked, so not easily create two-way streaming use curl. I believe that can be created by other client or even better use one page on server with javascript for create full interactive webshell in browser. I don't know very well JavaScript and all of web stack that spend time for create some of this. So I hope someone will be interested in continuing to help develop the project.

---

###### Available options in client:
1. Run command in not interactive shell (by default) 
	Example: `./client --url http://localhost/mypage.php` 
2. Run command in interactive shell without tty 
	Example: `./client --url http://localhost/mypage.php -i`
3. Run command in interactive shell with tty. For this option client has several predefined command for spawning pseudo tty: `--stty-python`, `--stty-expect`, `--stty-script`. You can use own command for spawning tty. You must provide the command as one argument, so please don't forget `\"` use: `--stty-custom "/custom/path/python2.7 -c \"import pty; pty.spawn('/bin/zsh')\""`
    Example: `./client --url http://localhost/mypage.php -i --stty-raw --stty-python --alias`

###### Stty options:
- By default client running in normal mode and read command line by line. In this mode client can't read special keys some of `ctrl+c`, `ctrl+d`, `ctrl+r`, `ctrl+l` and *etc*.
- When you want change **stty option** you don't need push `ctrl+z` after run command: `stty raw -echo; fg` Instead you must use client commands, because client use two different approach for reading input in different modes.
- If you want to run client in **raw mode** you must use: `--stty-raw` or if client running in **normal mode** you can use command to switch from **normal mode** to **raw mode** use: `%:stty_raw`
- When client running in **raw mode** you can switch to **normal mode** use the key combination: `ctrl+alt+s`. To exit the program in **raw mode**, use the key combination `ctrl+alt+q`.


###### Help menu:

- `-h`, `--help`: Display help menu
- `-u`, `--url`: The URL to the file: `--url http://localhost:8080/webshell.php`
- `-curl`, `--curl`: Script communicate with shell by curl. You can add arguments to curl, usage: `--curl '-X POST' -A 'My User-Agent 2.0'`
- `-i`, `--interactive`: Switch to interactive shell.
- `--stty-raw`: Switch stty to raw mode. Switch to normal mode: `ctrl+alt+s`. While normal mode run switch to raw mode write command: `%:stty_raw`
- `--stty-python`: Send command to run python tty mode: `python -c "import pty; pty.spawn('$shell')"`
- `--stty-expect`: Send interactive command to run expect tty mode: 0)`expect` 1)`spawn $shell` 2)`interact`
- `--stty-script`: Send command to run script tty mode: `script -qc /bin/bash /dev/null`
- `--stty-custom`: Send command to run custom tty mode: `--stty-custom "/custom/path/python2.7 -c \"import pty; pty.spawn('/bin/zsh')\""`
- `--alias`: Send command for setup alias and export TERM: `export TERM=xterm-256color; alias ls='ls --color'; alias ll='ls -lsaht --color'`
- `--alias-custom`: Send command to setup custom alias and other command: `--alias-custom "export TERM=screen-256color; alias ls='ls --color'; alias ll='ls -lsaht --color'"`
- `--shell`: Change from default `bash` to any shell for spawning interactive shell and stty: `--shell /usr/sbin/sh`
- `-ish`, `--init-shell`: Change default command for spawning interactive shell: `--init-shell "rm -f /tmp/i /tmp/o; mkfifo /tmp/i /tmp/o; bash -c 'exec 5<>/tmp/i; cat <&5| bash  2>/tmp/o >/tmp/o'"`
- `-fi`, `--fi`: Interactive shell works on named pipes, so change name of stdin pipe: `--fi /dev/shm/some_input_pipe`
- `-fo`, `--fo`: Interactive shell works on named pipes, so change name of stdout, stderr pipe: `--fo /dev/shm/some_output_pipe`
- `-d`, `--default`: Script by default works with no interactive webshell. So flags set default interacte option: `--interactive`, `--stty-raw`, `--stty-python`, `--alias`. If you want change some of option you need provide next option after default options. `-d --stty-script --shell /bin/bash`
- `--attach`: Join a detached running shell process. To join the right shell, you need to use the same pipes that the shell process uses: `--attach --fi /dev/shm/i --fo /dev/shm/o`

To exit in normal mode stty usage: `ctrl+c` or write: `%:exit`. To exit in raw mode stty usage: `ctrl+alt+q`

If you want **create several instance** of client with interactive shells you need use **different pipes** for everyone instance by use: `--fi` and `--fo`
Don't forget that sever-side process will running even client is close. So if you don't want leaving running process on server-side and leaving any files, You have to manually kill process and remove files. 

---

**Acknowledgments:**
A heartfelt thank you! Your support has been invaluable.

**Special Thanks To:**
1. [@justOleh](https://github.com/justOleh)

---

If you'd like to show your appreciation, you can buy me a cup of coffee:

**Bitcoin Wallet:**
[bc1qtnz9s7l35aaappzrdsjdjxpze04ld0x5umk7yh](bitcoin:bc1qtnz9s7l35aaappzrdsjdjxpze04ld0x5umk7yh?message=Buy%20me%20a%20cup%20of%20coffe)

---

For any inquiries or just to say hello, my contact information is below. Feel free to reach out:

**Contact:**
- **Email:** [numquam_scire@proton.me](mailto:numquam_scire@proton.me)
- **XMPP Protocol:** [death_bee@xmpp.is](xmpp:death_bee@xmpp.is)


