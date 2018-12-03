#!/usr/local/bin/bash

# DON'T EDIT
COMMAND_TEMPLATE="python2 run.py -u %s -n '%s' -a %s"

####### EDIT VARIABLES BELOW

# Edit device array below - be sure to change UUID, DEVICE NAME and ACCOUNT MANAGER FLAG only.  
# - ACCOUNT MANAGER FLAG is a switch to use account manager or not (true/false)
declare -A DEVICE_COMMANDS
DEVICE_COMMANDS=(
	["DEVICE NAME 1"]=$(printf "${COMMAND_TEMPLATE}" "UUID 1" "DEVICE NAME 1" "ACCOUNT MANAGER FLAG 1")
	["DEVICE NAME 2"]=$(printf "${COMMAND_TEMPLATE}" "UUID 2" "DEVICE NAME 2" "ACCOUNT MANAGER FLAG 2")
)

# Config options
TIMER=600					# number of seconds before terminating a tmux session and starting a new one
SLEEP=120					# number of seconds to wait before moving on to the next batch of instances
MAX_STARTING=2				# max number of instances to start concurrently

HOSTIP=						# ip of the RDM host database
PORT=						# port of the RDM host database
DBNAME=						# name of the RDM host database
DB_USER=					# user account of the RDM host database
PASSWORD=''					# password for the DB_USER account of the RDM host database

####### BEGIN SCRIPT

while True
do
	starting=0
	clear

	for i in "${!DEVICE_COMMANDS[@]}"
	do
		if (tmux ls | grep -q "$i") >/dev/null 2>/dev/null; then
			LAST_SEEN=$(echo $(MYSQL_PWD="${PASSWORD}" mysql -u ${DB_USER} -h ${HOSTIP} -P ${PORT} -e "select (UNIX_TIMESTAMP(NOW()) - last_seen) from device where uuid = '${i}'" ${DBNAME}))
			TRIMMED=$(echo ${LAST_SEEN} | awk {'print $4'})

			if [ "${TRIMMED:0}" -gt "${TIMER}" ] && [ "${TRIMMED:0}" -lt 1540000000 ]; then
				printf "[$(date '+%Y-%m-%d %H:%M:%S')] %s\n" "${i} hasn't been seen in over ${TIMER} second(s). Restarting..."
				((starting++))

				tmux kill-session -t "$i" >/dev/null 2>&1
				tmux new -d -s "$i" "${DEVICE_COMMANDS[$i]}";
			else
				printf "[$(date '+%Y-%m-%d %H:%M:%S')] %s\n" "${i} was seen ${TRIMMED} second(s) ago"
			fi
		else
			printf "[$(date '+%Y-%m-%d %H:%M:%S')] %s\n" "${i} session not found. Starting new session..."
			((starting++))
			tmux new -d -s "$i" "${DEVICE_COMMANDS[$i]}";
		fi
		
		if [ "${starting}" -eq "${MAX_STARTING}" ]; then
			remaining=${SLEEP}
			tput sc
			while [[ ${remaining} -gt 0 ]];
			do
				tput rc; tput el
				printf "[$(date '+%Y-%m-%d %H:%M:%S')] %s" "Waiting ${remaining} second(s) before continuing with the next batch of ${MAX_STARTING} instances..."
				sleep 1
				((remaining--))
			done
			tput rc; tput el;
			starting=0
		fi
	done

	remaining=${SLEEP}
	tput sc
	while [[ ${remaining} -gt 0 ]];
	do
		tput rc; tput el
		printf "[$(date '+%Y-%m-%d %H:%M:%S')] %s" "Waiting ${remaining} second(s) before beginning the next round..."
		sleep 1
		((remaining--))
	done
done

####### END SCRIPT