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

badge() {
	local TEXT

	TEXT="${*}"
	TEXT="$(sed -e "s/%u/$(whoami)/g" <<<"${TEXT}")"
	TEXT="$(sed -e "s/%h/$(sys_hostname)/g" <<<"${TEXT}")"

	printf "\e]1337;SetBadgeFormat=%s\a" "$(base64 <<<"${TEXT}")"
}

badge "%h"
unset -f sys_hostname
