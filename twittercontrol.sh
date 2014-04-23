#!/bin/bash
#
# ###### #
# file: twittercontrol.sh
# created by: Carlos Meza of digitalRoots
# description: Communicates with a device via twitter.
# utilizes (tools may be modify to fit the needs of twittercontrol.sh):
#	tcli.sh, TwitterOAuth.sh, OAuth.sh
# 		description: Communicates with Twitter
#		website: https://github.com/livibetter/bash-oauth
# 	jsonv.sh, json.awk
#		description: Parses json data from Twitter to csv
#		website: https://github.com/archan937/jsonv.sh
# ###### #

# Initialize settings
# To Do: Load from twittercontrol.rc
config () {
	DEVICE=Zombie1
	TWITTER_FEED=_dotroot
	TWITTER_POST=$TWITTER_FEED
	CMD_FILE=$DIR/twitter_cmd.rc
}

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
			echo "Usage: $0 -[larxh] (command)"
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

hash_cmd() {
	cmd_sha1=$(printf '%s' "$1" | sha1sum | cut -f1 -d' ')
	echo "$cmd_sha1"
}
find_cmd() {
	local i=0
	hashed_cmd=$(hash_cmd $1)
	#while read line; do
	#	if [ $i -gt 1 ]; then
	#		echo "Line ${i}: ${line}\n"
	#	fi
	#	i=$((i+1))
	#done < $CMD_FILE
	awk '
		BEGIN {
			FS="\n"
			RS="\t"
			OFS=", "
		}{
			print $2
		}' $CMD_FILE
		

	# if $(hash_cmd $1) is found in twitter_cmd.rc, return true
}

add_cmd () {
	echo -e $(find_cmd $1)
	#[ $(find_cmd) ] && echo "yes" || echo "no"
}

parse_options() {
	no_param=1
	while getopts :la:r:t:xh: opt; do
		unset -v no_param
		case $opt in
		l)
			cat $CMD_FILE | less; exit 0
			;;
		a)
			add_cmd $OPTARG
			;;
		r)
			echo "remove command $OPTARG"
			;;
		t)
			echo "toggle $OPTARG"
			;;
		x)
			echo "execute"
			;;

		h | ?)
			usage $1;
			;;
		*)
			usage $1;
			;;
		esac
	done
	[ -n "$no_param" ] && usage $1
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
    SOURCE="$DIR/$TARGET" # if $SOURCE was a relative symlink, resolve it relative to the path where the symlink
  fi
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# Check for all necessary files
files=( OAuth.sh TwitterOAuth.sh tcli.sh jsonv.sh json.awk )
errmsg=
for i in "${files[@]}"; do
	[ -s "$DIR/$i" ] && ([ -r "$DIR/$i" ] || errmsg="${errmsg}Can not read $i") || errmsg="${errmsg}$i not found."
done
[ -n "$errmsg" ] && throw ${errmsg}|| unset -v i

files=.tcli.rc
[ -s "$DIR/$files" ] && ([ -r "$DIR/$files" ] || errmsg="${errmsg}Can not read $files") || errmsg="${errmsg}$files not found."
if [ -z "$errmsg" ]; then
	. $DIR/$files
else
	$DIR/tcli.sh
	throw "$errmsg"
fi
# Check if tokens exsist, if not runs tcli.sh to authenticate oauth.
[ -n "$oauth_token" ] && [ -n "$oauth_token_secret" ] || $DIR/tcli.sh
unset -v files

config

[ -r "$CMD_FILE" ] || echo -e "Enabled\tSHA1\t\t\t\t\tCommand" > $CMD_FILE || throw "Can not access $CMD_FILE"

parse_options "$@"
