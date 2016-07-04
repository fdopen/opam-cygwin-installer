#!/bin/sh

set -eu

OPAM32_URL='https://dl.dropboxusercontent.com/s/eo4igttab8ipyle/opam32.tar.xz'
OPAM64_URL='https://dl.dropboxusercontent.com/s/b2q2vjau7if1c1b/opam64.tar.xz'

STDUTILS_URL='https://bitbucket.org/lord_mulder/stdutils/downloads/StdUtils.2015-10-10.zip'
THEME_URL='http://nsis.sourceforge.net/mediawiki/images/5/5d/Orange-Full-MoNKi.zip'

dir="$(dirname "$0")"
dir="$(readlink -f "$dir")"
cd "$dir"

if [ ! -f opam32.tar.xz ] ; then
    wget "$OPAM32_URL" -O opam32.tar.xz
fi
if [ ! -d opam32 ]; then
    tar -xf opam32.tar.xz
fi

if [ ! -f opam64.tar.xz ] ; then
    wget "$OPAM64_URL" -O opam64.tar.xz
fi
if [ ! -d opam64 ]; then
    tar -xf opam64.tar.xz
fi

if [ ! -f StdUtils.zip ] ; then
    wget "$STDUTILS_URL" -O StdUtils.zip
fi
if [ ! -d StdUtils ]; then
    mkdir StdUtils
    cd StdUtils
    unzip ../StdUtils.zip
    cd ..
fi

if [ ! -f Orange-Full-MoNKi.zip ]; then
    wget "$THEME_URL" -O "Orange-Full-MoNKi.zip"
fi
if [ ! -d orange ]; then
    unzip Orange-Full-MoNKi.zip
    mv Orange-Full-MoNKi orange
fi

if [ ! -x mkpasswd/mmkpasswd.exe ]; then
    cd mkpasswd
    x=$(ocamlfind ocamlc -config | awk '/^architecture:/ { print $2; }')
    case "$x" in
        i[34567]86*)
            x=ok ;;
        *)
            echo "32-bit OCaml required" >&2
            exit 1
            ;;
    esac
    if ! ocamlfind query containers >/dev/null 2>&1 ; then
        echo "containers required"
    fi
    make clean
    make all
    make strip
    cd ..
fi

for x in 32 64 ; do
    cp -p mkpasswd/mmkpasswd.exe "OCaml${x}/mkpasswd"
    rm -rf "OCaml${x}/bin" "OCaml${x}/lib" "OCaml${x}/include"
    cp -a "opam${x}/bin" "opam${x}/lib" "opam${x}/include" "OCaml${x}"
done

makensis opam32
makensis opam64
