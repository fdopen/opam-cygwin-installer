#!/bin/bash

set -eu

prefix=/usr/local

dir="$(dirname "$0")"
cd "$dir"
dir="$(readlink -f .)"
if [ -z "$dir" ]; then
    echo "can't find script folder" >&2
    exit 1
fi

if [ ! -x /usr/bin/cygcheck ] ; then
    echo "warning: your cygwin installation is probably corrupted" >&2
else
    xtmpf="$(mktemp)"
    trap "rm -f \"${xtmpf}\"" EXIT
    /usr/bin/cygcheck -dc >"${xtmpf}"
    for f in git unzip rsync patch diffutils make m4 ; do
        if ! /usr/bin/grep -q "^${f} " "$xtmpf" ; then
            echo "warning: ${f} not installed. opam will not work without it!" >&2
        fi
    done
    if ! /usr/bin/grep -q "^curl " "$xtmpf" ; then
        if ! /usr/bin/grep -q "^wget " "$xtmpf" ; then
            echo "warning: neither curl nor wget are installed!" >&2
            echo "install at least on of them" >&2
        fi
    fi
    if ! /usr/bin/grep -q "^mingw64-i686-gcc-core" "$xtmpf" ; then
        if ! /usr/bin/grep -q "^mingw64-x86_64-gcc-core " "$xtmpf" ; then
            echo "please install either mingw64-i686-gcc-core (32-bit) or mingw64-x86_64-gcc-core (64-bit)" >&2
            echo "you need a working C compiler to compile native ocaml programs" >&2
        fi
    fi
fi

/usr/bin/mkdir -p "${prefix}/bin" "${prefix}/include"  "${prefix}/etc" "${prefix}/lib/flexdll"

cd bin
/usr/bin/install -m 0755 aspcud.exe clasp.exe gringo.exe cudf2lp.exe opam.exe flexlink.exe "${prefix}/bin"
/usr/bin/install -m 0644 misc2012.lp specification.lp "${prefix}/bin"
cd ..
/usr/bin/install -m 0644 include/flexdll.h "${prefix}/include"
cd lib/flexdll
for f in * ; do
    if [ ! "$f" ]; then
        continue
    fi
    case "$f" in
        *mingw64test*)
            /usr/bin/install -m 0755 "${f}" "${prefix}/lib/flexdll/${f}"
            ;;
        *)
            /usr/bin/install -m 0644 "${f}" "${prefix}/lib/flexdll/${f}"
            ;;
    esac
done
