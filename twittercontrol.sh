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

# TO DO: Add trap around processing command queue

# Initialize settings
# To Do: Load from twittercontrol.rc
config () {
	DEVICE=Zombie1
	TWITTER_FEED=_dotRoot
	TWITTER_POST=$TWITTER_FEED
	CMD_FILE=$DIR/twitter_cmd.rc
}

# Error Handling
# In future all calls to function thow()
# will sent and error type and have standardized error output with corriponding errorlevels
throw () {
	echo -e "$*" >&2
	echo
	exit 1
}

# Check depenancies and finds path of script
preload () {
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
}

usage() {
	case "$1" in
		-a | -e | -d)
			errmsg="$1 requires an argument."
			throw $errmsg
			;;
		-h | --help)
			echo "Usage: $0 [-l] [-a command] [-r command] [-x] [-h]"
			echo
			echo "Switches:"
			echo -e "  l\tList stored commands"
			echo -e "  a\tAdd command"
			echo -e "  r\tRemove command"
			echo -e "  x\tManual parsing then execution"
			echo -e "  h\tDisplays this help message"
			echo
			echo -e "  d\tDelete command (alias for -r)"
			echo
			echo -e "Description:\tTakes commands via Twitter. For automatic polling"
			echo -e "\t\tsetting a cron job is suggested."
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

# Returns hash of command salted with device name
hash_cmd() {
	# SHA1 hash of command + device name; then cut just the hash from the sha1sum output
	cmd_sha1=$(printf '%s' "${DEVICE}${@}" | sha1sum | cut -f1 -d' ')
	echo "$cmd_sha1"
}

# Searches for command via the hash
# Returns command if found and enabled, 0 if disabled
find_cmd() {
	awk -v hash=$@ '
		BEGIN {
			FS="\t"
		} $2 ~ hash {
			if ($1 == "1")
				print $3
			else
				print 0
		}' "$CMD_FILE"
}

add_cmd () {
	local hashed=$(hash_cmd $@)
	[ "$(find_cmd $hashed)" ] && throw "Command already in command table (or possible hash collision)." || echo -e "1\t${hashed}\t$@" >> $CMD_FILE
	echo Added: $@
}

exe () {
	#Pulls last tweet and pipes json data to be converted to csv and stored in file
	#Head to deal with issue that can not pull single tweet. Unknown why.
	$DIR/tcli.sh -c statuses_get -n $TWITTER_FEED -s 2 | $DIR/jsonv.sh id,text | head -n 1 > $DIR/tweet_new.csv

	#Verify new tweet
	if [ -r $DIR/tweet.csv ]; then
		if [ "$(cut -d "," -f 1 $DIR/tweet.csv)" -lt "$(cut -d "," -f 1 $DIR/tweet_new.csv)" ]; then
			mv -f $DIR/tweet_new.csv $DIR/tweet.csv
		else
			echo "No new tweets."
			exit 0
		fi
	else
		mv -f $DIR/tweet_new.csv $DIR/tweet.csv
	fi

	local tweet=$(cut -d "," -f 2 $DIR/tweet.csv)
	local result=$(find_cmd ${tweet:1:-1})
	if ((test -n "$result") && (test "$result" != 0 )) ; then
		$result
	else
		echo "Nothing to execute."
		exit 0
	fi
}

parse_options() {
	no_param=1
	while getopts :la:r:d:t:xh: opt; do
		unset -v no_param
		case $opt in
		l)
			cat $CMD_FILE | less; exit 0
			;;
		a)
			add_cmd $OPTARG
			;;
		d|r)
			echo "remove command $OPTARG"
			;;
		t)
			echo "toggle $OPTARG"
			;;
		x)
			exe
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
preload
config

# check if command repository exsist, if not create it.
[ -r "$CMD_FILE" ] || echo -e "Enabled\tSHA1\t\t\t\t\t\tCommand" > $CMD_FILE || throw "Can not access $CMD_FILE"

parse_options "$@"
