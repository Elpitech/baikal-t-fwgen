#!/bin/sh
# vi: set ts=4 sw=4 cindent :
#
# $Id$
#
# Copyright (C) 2019, T-Platforms JSC (fancer.lancer@gmail.com)

: ${FWGEN_CMD_INFO:="0"}
: ${FWGEN_FILE_NAME:="/proc/self/fd/1"}
: ${FWGEN_SUCCESS:="0"}
: ${FWGEN_ERROR:="1"}

FWGEN_CMD_INFO_FMT="0x%.4X - 0x%.4X %-15s %-7s: %-s"
FWGEN_POSITION="0"

#
# Print an error to the stderr
#
# $1 ... Error message
function error() {
	local _msg="$1"

	printf "Error: %s\n" "$_msg" >&2
}

#
# Print the passed binary data to the output file
#
# $1 ... Data chunk name
# $2 ... Data-string (hex/dec/oct bytes separated by spaces)
# $3 ... Field length (at least the passed data length)
function binary() {
	local _name="$1"
	local _data="$2"
	local _flen="$3"
	local _val _byte _dlen

	_flen="$(printf "%d" "$_flen")"
	_dlen=0
	for _val in $_data; do
		_byte=$(printf "%d" "$_val")
		if [ $_byte -lt 0 -o $_byte -gt 255 ]; then
			error "Invalid data $_name: $_val"
			return $FWGEN_ERROR
		fi
		_dlen=$((_dlen + 1))
	done

	if [ $_dlen -gt $_flen ]; then
		error "Data is too long for the field $_name"
		return $FWGEN_ERROR
	fi

	FWGEN_POSITION=$((FWGEN_POSITION + _flen))
	if [ $FWGEN_CMD_INFO -ne 0 ]; then
		printf "${FWGEN_CMD_INFO_FMT}\n" "$((FWGEN_POSITION - _flen))" \
			"$FWGEN_POSITION" "$_name" "binary" "$_data" >>"$FWGEN_FILE_NAME"
		return $FWGEN_SUCCESS
	fi

	for _val in $_data; do
		printf "$(printf "\\\x%x" "$_val")" >>"$FWGEN_FILE_NAME"
	done
	_byte=$((_flen - _dlen))
	while [ $_byte -gt 0 ]; do
		printf '\0' >>"$FWGEN_FILE_NAME"
		_byte=$((_byte - 1))
	done
}

#
# Print passed ASCII string
#
# $1 ... Data chunk name
# $2 ... ASCII string
# $3 ... Field length (at the length of the passed data)
function ascii() {
	local _name="$1"
	local _str="$2"
	local _flen="$3"
	local _dlen

	_flen="$(printf "%d" "$_flen")"
	_dlen="${#_str}"
	if [ $_dlen -gt $_flen ]; then
		error "String is too long for the field $_name"
		return $FWGEN_ERROR
	fi

	FWGEN_POSITION=$((FWGEN_POSITION + _flen))
	if [ $FWGEN_CMD_INFO -ne 0 ]; then
		printf "${FWGEN_CMD_INFO_FMT}\n" "$((FWGEN_POSITION - _flen))" \
			"$FWGEN_POSITION" "$_name" "ascii" "$_str" >>"$FWGEN_FILE_NAME"
		return $FWGEN_SUCCESS
	fi

	printf "$_str" >>"$FWGEN_FILE_NAME"
	_byte=$((_flen - _dlen))
	while [ $_byte -gt 0 ]; do
		printf '\0' >>"$FWGEN_FILE_NAME"
		_byte=$((_byte - 1))
	done
}

#
# Print passed string in utf16le
#
# $1 ... Data chunk name
# $2 ... ASCII string
# $3 ... Field length (at least twice the length of the passed data)
function utf16le() {
	local _name="$1"
	local _str="$2"
	local _flen="$3"
	local _rest _bin _dlen

	_flen="$(printf "%d" "$_flen")"
	_dlen="$((${#_str} * 2))"
	if [ $_dlen -gt $_flen ]; then
		error "String is too long for the field $_name"
		return $FWGEN_ERROR
	fi

	FWGEN_POSITION=$((FWGEN_POSITION + _flen))
	if [ $FWGEN_CMD_INFO -ne 0 ]; then
		printf "${FWGEN_CMD_INFO_FMT}\n" "$((FWGEN_POSITION - _flen))" \
			"$FWGEN_POSITION" "$_name" "utf16le" "$_str" >>"$FWGEN_FILE_NAME"
		return $FWGEN_SUCCESS
	fi

	while [ -n "$_str" ]; do
		_rest="${_str#?}"
		printf "${_str%"$_rest"}\0" >>"$FWGEN_FILE_NAME"
		_str="$_rest"
	done
	_byte=$((_flen - _dlen))
	while [ $_byte -gt 0 ]; do
		printf '\0' >>"$FWGEN_FILE_NAME"
		_byte=$((_byte - 1))
	done
}
