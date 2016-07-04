#!/bin/sh

set -u

failed=
add_failed(){
    if [ -z "$failed" ]; then
        failed="$1"
    else
        failed="$failed $1"
    fi
}
exit_failed(){
    if [ -n "$failed" ]; then
        echo "the following programs are not installed properly:" >&2
        echo " $failed" >&2
        echo "I can't proceed :(" >&2
        exit 4
    fi
}

set +e
for prog in bash cp curl cygpath diff git grep gzip m4 make mount mv patch rsync tar timeout xz ; do
    if ! "$prog" --version >/dev/null 2>&1 ; then
        add_failed "$prog"
    fi
done

if ! unzip -h >/dev/null 2>&1 ; then
    add_failed "unzip"
fi

if ! dash -ec '/bin/true' >/dev/null 2>&1 ; then
    add_failed "dash"
fi
if ! /usr/bin/timeout -s SIGTERM -k 1s 30.0s curl --insecure --retry 2 --head "https://github.com" >/dev/null 2>&1 ; then
    add_failed "curl"
fi
exit_failed

tdir="$(mktemp -d)"
if [ -z "$tdir" ] || [ ! -d "$tdir" ]; then
    add_failed "mktemp"
    exit_failed
fi
tdir="$(readlink -f "$tdir")"
if [ -z "$tdir" ] || [ ! -d "$tdir" ]; then
    add_failed "readlink"
    exit_failed
fi

tdirclean(){
    rm -rf "$tdir"
}
trap tdirclean EXIT

set -e
cd "$tdir"
echo "test" >test
if ! tar -cf- test 2>/dev/null | xz >/dev/null 2>&1 ; then
    add_failed "tar / xz"
    exit_failed
fi
rm test

git_repo='github.com/fdopen/opam-repository-mingw.git'
git_test='github.com/fdopen/installer-test-repo.git'
mirror=
for proto in 'https://' 'git://' 'http://' ; do
    if /usr/bin/timeout -s SIGTERM -k 1s 30.0s git clone -q "${proto}${git_test}" >/dev/null 2>&1; then
        mirror="${proto}${git_repo}"
        break
    fi
    rm -rf installer-*  >/dev/null 2>&1 || true
done
if [ -z "$mirror" ]; then
    add_failed "git"
    exit_failed
fi
if [ ! -f "installer-test-repo/README.md" ]; then
    add_failed "git"
    exit_failed
fi

if [ "$proto" != 'https://' ]; then
    echo "warning: git doesn't seem to support https" >&2
    echo "$proto will be used instead" >&2
    echo "There is probably something wrong with your cygwin installation" >&2
fi

cd

set -e
echo "Please don't close this window until the repository is initialized"
/usr/local/bin/opam init -y mingw "$mirror" --comp 4.02.3+mingw64c --switch 4.02.3+mingw64c
/usr/local/bin/opam config setup -a

if [ "$0" = "/tmp/OCaml32/ocaml32.sh" ]; then
    rm -rf "/tmp/OCaml32" >/dev/null 2>&1 || true
fi

set +e
name="$(cygpath -m / | sed -r 's|^.*/([^/]+)$|\1|')"
if [ -z "$name" ]; then
    case "4.02.3+mingw64c" in
        *mingw32*)
            name="OCaml32" ;;
        *)
            name="OCaml64" ;;
    esac
else
    case "$name" in
        *[Oo][Pp][Aa][Mm]*) o=1 ;;
        *[Oo][Cc][Aa][Mm][Ll]*) o=1 ;;
        *[Cc][Yy][Gg][Ww]*) o=1 ;;
        *) name="${name} OCaml32" ;;
    esac
fi
# shortcut creation will fail in case of unicode chars ...
mkshortcut -D -n "$name" /bin/mintty.exe -a '-' >/dev/null 2>&1 || true

echo "Ok! OCaml installation is finished!"
exit 0
