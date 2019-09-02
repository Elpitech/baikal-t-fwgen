#!/bin/sh
# vi: set ts=4 sw=4 cindent :
#
# $Id$
#
# Copyright (C) 2019, T-Platforms JSC (fancer.lancer@gmail.com)

FWGEN_IAM="$(basename "$0")"
FWGEN_ROOT_PATH="$(dirname "$(readlink -f "$0")")"
FWGEN_LIB_PATH="${FWGEN_ROOT_PATH}/lib"
FWGEN_FW_PATH="${FWGEN_ROOT_PATH}/fw"
FWGEN_FW_LIST=""
FWGEN_FW_NAME=""
FWGEN_TMP_NAME="/tmp/fwgen.XXXXXX"

FWGEN_SUCCESS="0"
FWGEN_ERROR="1"

if ! source "${FWGEN_LIB_PATH}/functions.sh"; then
	error "Couldn't source helper functions"
	exit "$FWGEN_ERROR"
fi

fwgen_get_fw_list() {
	local _list _f

	_list="$(cd "$FWGEN_FW_PATH" && echo *)" || return $FWGEN_ERROR

	for _f in $_list; do
		printf "${_f%.*} "
	done
}

fwgen_usage() {
	printf " Usage: ${FWGEN_IAM} -f <firmware> [options]

 Create microchip usb26x USB-hub firmware in accordance with the passed
 firmware script name.

 -h, --help            - Display this help.
 -f, --firmware <name> - Firmware name (mandatory).
 -o, --output   <name> - Name of the output file (stdout by default).
 -l, --layout          - Print a firmware layout instead of the binary data.

 Available firmware:
  $(fwgen_get_fw_list)

 Depends on: sed
"
}

fwgen_parse_args() {
	local _opts

	_opts=$(getopt -o "hf:o:l" --long "help,firmware:,output:,layout" -q -n "$FWGEN_IAM" -- "$@")
	if [ $? -ne 0 ]; then
		error "Can't parse arguments"
		exit $FWGEN_ERROR
	fi

	eval set -- "$_opts"
	while true; do
		# uncomment the next line to see how shift is working
		# echo "\$1:\"$1\" \$2:\"$2\""
		case "$1" in
		'-f'|'--firmware')
			FWGEN_FW_NAME="$2"
			shift 2
			;;
		'-o'|'--output')
			FWGEN_FILE_NAME="$2"
			shift 2
			;;
		'-l'|'--layout')
			FWGEN_CMD_INFO=1
			shift
			;;
		'-h'|'--help')
			fwgen_usage
			exit $FWGEN_SUCCESS
			;;
		'--')
			shift
			break
			;;
		*)
			error "Invalid argument '$1'"
			fwgen_usage
			exit $FWGEN_ERROR
			;;
		esac
	done

	if [ -z "$FWGEN_FW_NAME" ]; then
		error "Firmware name isn't specified"
		fwgen_usage
		exit $FWGEN_ERROR
	fi
}

function fwgen_init_env() {
	# Alas in order to support all three types of files (stdout, eeprom, file)
	# we have no way but to create a temporary file, send data there first, then
	# dump it into the target file.
	FWGEN_TMP_NAME=$(mktemp -q $FWGEN_TMP_NAME)
	if [ $? -ne 0 ]; then
		error "Couldn't create a temporary file"
		exit $FWGEN_ERROR
	fi

	trap "$fwgen_clean_env" EXIT
	if [ $? -ne 0 ]; then
		error "Couldn't setup an EXIT trap"
		exit $FWGEN_ERROR
	fi

	trap 'exit $?' HUP QUIT ABRT PIPE INT TERM
	if [ $? -ne 0 ]; then
		error "Couldn't setup 'exit \$?' wrapper"
		exit $FWGEN_ERROR
	fi

	set -e
}

function fwgen_run_fw_script() {
	local _outfile="$FWGEN_FILE_NAME"

	FWGEN_FILE_NAME="$FWGEN_TMP_NAME"
	. "${FWGEN_FW_PATH}/${FWGEN_FW_NAME}.sh"
	cat "$FWGEN_TMP_NAME" > "$_outfile"
}

function fwgen_clean_env() {
	set +e

	rm -f $FWGEN_TMP_NAME >/dev/null 2>&1

	trap - EXIT HUP QUIT ABRT PIPE INT TERM
}

function main() {
	fwgen_parse_args "$@"

	fwgen_init_env

	fwgen_run_fw_script

	fwgen_clean_env

	exit $FWGEN_SUCCESS
}

main "$@"
