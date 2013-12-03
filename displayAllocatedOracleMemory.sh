#!/bin/bash

# 2013-12-03, Remi Bergsma
# Script to display current allocated memory to Oracle databases

# Function to get assigned Oracle mem
function get_oracle_mem() {

	# Pickup and validate parameter
	TYPE=$1
	if [ "$TYPE" != "pga" ] && [ "$TYPE" != "sga" ]; then
		echo "0"
		exit 1	
	fi

	# Do not continue if no oratab is found
	if [ ! -f /etc/oratab ]; then
		echo "0"
		exit 1
	fi
	
	# Do the real work here
	result=$(cat /etc/oratab | awk -F ':' {' print $2 "/dbs/spfile" $1 ".ora"'} |\
		grep -v '#' |\
		xargs strings -a 2>/dev/null |\
		grep target |\
		grep -iE "\*.${TYPE}" |\
		cut -d= -f2 |\
		sed -e 's/G/*1024*1024*1024/gi' |\
		sed -e 's/M/*1024*1024/gi' |\
		paste -s -d+ |\
		awk {'print "scale=2; (" $1 ")/1024/1024/1024"'} |\
		bc)

	# Display result so it can be put in a var when the function is called
	echo $result
}

# Calculate vars
MEM_DB_PGA=$(get_oracle_mem "pga")
MEM_DB_SGA=$(get_oracle_mem "sga")
MEM_OS=$(echo "scale=2; $(free -m | grep Mem | awk {'print $2'})/1024"|bc)
MEM_DB=$(echo "scale=2; $MEM_DB_SGA+$MEM_DB_PGA"|bc)
MEM_AVAIL=$(echo "scale=2; $MEM_OS-$MEM_DB"|bc)

# Display results
echo
echo "Available memory in OS: $MEM_OS GiB"
echo "Currently allocated memory to Oracle databases:"
echo "  SGA: $MEM_DB_SGA GiB "
echo "  PGA: $MEM_DB_PGA GiB"
echo "Total allocated: $MEM_DB GiB"
echo "Total available: $MEM_AVAIL GiB"
echo
