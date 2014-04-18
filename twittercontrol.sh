#!/bin/bash
#

#Set constants
TWITTER_ACCOUNT=_dotroot

throw () {
	echo -e "$*" >&2
	echo
	exit 1
}

usage() {
	case "$1" in
		-a | -e | -d)
			errmsg="$1 requires an argument."
			throw $errmsg
			;;
		-h | --help)
			echo "Usage: $0"
			echo
			exit 0
			;;
		
		*)
			errmsg=
			if ! [ $# -eq 0 ];
				then
				errmsg="Invalid argument: $1"
			else
				errmsg="Missing arguments."
			fi
			echo "Use --help for options."
			throw $errmsg
			;;
	esac
}

parse_options() {
	local no_param=1
	while getopts :gla:e:d:h: opt; do
		no_param=
		case $opt in
		g)
			echo "get"
			;;
		l)
			echo "list"
			;;
		a)
			echo "add $OPTARG"
			;;
		e)
			echo "enable $OPTARG"
			;;
		d)
			echo "disable $OPTARG"
			;;
		h | ?)
			usage $1;
			;;
		*)
			usage $1;
			;;
		esac
	done
	[ -n no_param ] && usage $1
}

###### MAIN ######
# Determine script location
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  TARGET="$(readlink "$SOURCE")"
  if [[ $SOURCE == /* ]]; then
    SOURCE="$TARGET"
  else
    DIR="$( dirname "$SOURCE" )"
    SOURCE="$DIR/$TARGET" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  fi
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# Check for all necessary files
files=( OAuth.sh TwitterOAuth.sh tcli.sh jsonv.sh json.awk )
errmsg=
for i in "${files[@]}"; do
	[ -s "$DIR/$i" ] && ([ -r "$DIR/$i" ] || errmsg="$errmsg Can not read $i") || errmsg="$errmsg $i not found."
done
[ -n "$errmsg" ] && throw $errmsg || files=

parse_options "$@"
