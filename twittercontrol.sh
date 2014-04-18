#!/bin/bash
#

#Check for all files
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

errmsg="not found."
files=( tclid.sh jsonv.sh )
for i in "${files[@]}"; do
	echo $DIR/$i
	[ -s "$DIR/$i" ] && (! [ -r "$DIR/$i" ] || echo "$i not found.") || echo "no"
done

#Set constants
TWITTER_ACCOUNT=_dotroot

throw () {
  echo "$*" >&2
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
	while getopts :gla:e:d:h: opt; do
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
echo "opt = $opt"
}

parse_options "$@"
