sys_hostname() {
	local HOSTNAME_SYS MATCH

	HOSTNAME_SYS="$(hostname -f 2>/dev/null || (echo "$(hostname 2>/dev/null) $(domainname 2>/dev/null) $(dnsdomainname 2>/dev/null)"))"
	HOSTNAME_SYS="$(sed -e 's/(none)//' -e 's/ *$//g' -e 's/  */./g' <<<"${HOSTNAME_SYS}")"

	if [ -n "${JWALTER_HOSTNAME_DIVISORS}" ]; then
		MATCH="$(grep -Eo "\.($(sed -e 's/\([^a-zA-Z0-9_]\)/\\\1/g' -e 's/  */|/' <<<"${JWALTER_HOSTNAME_DIVISORS}"))\." <<<"${HOSTNAME_SYS}" | sed -e 's/^\./\\./g')"
		if [ -n "${MATCH}" ]; then
			echo -n "$(sed -e "s/${MATCH}.*$//" <<< "${HOSTNAME_SYS}")"
			return
		fi
	fi

	if [ -n "${JWALTER_HOSTNAME_PARTS}" ] && [ "${JWALTER_HOSTNAME_PARTS}" != "0" ]; then
		if [ "$(sed -e 's/\./ /g' <<<"${HOSTNAME_SYS}" | wc -w | awk '{print $1}')" -gt "${JWALTER_HOSTNAME_PARTS}" ]; then
			echo -n "$(cut -d . "-f1-${JWALTER_HOSTNAME_PARTS}" <<<"${HOSTNAME_SYS}")"
			return
		fi
	fi

	echo -n "${HOSTNAME_SYS}"
}

# ==============================================================================

__JWALTER_PLUGIN_ITERM2_CURSOR="1"
cursor() {
	local CURSOR

	case "${1}" in
		--last)
			CURSOR="${__JWALTER_PLUGIN_ITERM2_CURSOR}"
			;;
		0|block)
			CURSOR="0"
			;;
		1|bar)
			CURSOR="1"
			;;
		2|underline)
			CURSOR="2"
			;;
		*)
			echo "Error: Unknown cursor" 1>&2
			return 1
			;;
	esac

	__JWALTER_PLUGIN_ITERM2_CURSOR="${CURSOR}"
	echo -ne "\e]1337;CursorShape=${CURSOR}\a"
}

__JWALTER_PLUGIN_ITERM2_BADGE=""
badge() {
	local TEXT

	TEXT="${*}"
	if [ "${TEXT}" = "--last" ]; then
		TEXT="${__JWALTER_PLUGIN_ITERM2_BADGE}"
	elif [ "${TEXT}" = "--reset" ]; then
		TEXT=""
	fi

	TEXT="$(sed -e "s/%u/$(whoami)/g" <<<"${TEXT}")"
	TEXT="$(sed -e "s/%h/$(sys_hostname)/g" <<<"${TEXT}")"

	__JWALTER_PLUGIN_ITERM2_BADGE="${TEXT}"
	printf "\e]1337;SetBadgeFormat=%s\a" "$(base64 <<<"${TEXT}")"
}

stealfocus() {
	echo -ne "\e]1337;StealFocus\a"
}

clearsb() {
	echo -ne "\e]1337;ClearScrollback\a"
}

tabbg() {
	local RED GREEN BLUE

	RED="${1}"
	GREEN="${2}"
	BLUE="${3}"

	if [ "${RED}" = "--reset" ] && [ -z "${GREEN}" ] && [ -z "${BLUE}" ]; then
		echo -ne "\e]6;1;bg;*;default\a"
		return 0
	fi

	if ! grep -qE '^(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[0-9][0-9]?) (25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[0-9][0-9]?) (25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[0-9][0-9]?)$' <<<"${RED} ${GREEN} ${BLUE}"; then
		echo "Error: Three integers (0-255) are required" 1>&2
		return 1
	fi

	echo -ne "\e]6;1;bg;red;brightness;${RED}\a\e]6;1;bg;green;brightness;${GREEN}\a\e]6;1;bg;blue;brightness;${BLUE}\a"
}

# ==============================================================================

if [ "$(uname -s)" != "Darwin" ]; then
	badge "%h"
fi
unset -f sys_hostname
