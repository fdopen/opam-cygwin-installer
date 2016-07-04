#!/bin/sh

set -eu

#if [ -f /etc/passwd ]; then
#    echo "/etc/passwd already exists! I will not overwrite it" >&2
#    exit 0
#fi
LC_ALL=en_US.UTF-8
LANG=en_US.UTF-8
LANGUAGE=en_US.UTF-8
export LC_ALL LANG LANGUAGE

mcheck(){
    if [ -z "$1" ]; then
        echo "$2" >&2
        exit 1
    fi
}
dir="$(dirname "$0")"
mcheck "$dir" "invalid dir"
dir="$(readlink -f "$dir")"
mcheck "$dir" "invalid dir"

cd "$dir"
rm -f passwd
./mmkpasswd.exe
if [ -f passwd ]; then
    /usr/bin/install -m 0644 passwd /etc/passwd
fi
exit 0
