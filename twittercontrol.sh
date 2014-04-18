#!/bin/bash
#

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
