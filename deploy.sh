#!/bin/bash

set -o errexit

shopt -s nocasematch

## 
# deploy.sh - Mark Gerard - October 28, 2012
#
# Deploys a given war file to a local instance of tomcat. It is meant to lessen the keystrokes required to stop, undeploy a 
# tomcat application, deploy a new war file and start tomcat.
#
##

# Tomcat installation directory
TOMCATDIR="/usr/local/tomcat"

# Tomcat bin directory
TOMCATBINDIR=$TOMCATDIR/bin

# Tomcat web apps directory
TOMCATWEBAPPSDIR=$TOMCATDIR/webapps

# OpenXdata maven build directory
OXDWARDIR="$HOME/Dev/projects/openxdata/serverX/webapp/target"

# Does the actual moving of files and starting tomcat
function deploy {

	# wipe the logs
	if [[ $DELETELOGS = "true" ]]; then
		echo "Deleting Tomcat logs..."
		rm $TOMCATDIR/logs/*
	fi

	# undeploy existing war file
	echo "undeploying openxdata..."
	rm -rf $TOMCATWEBAPPSDIR/openxdata*

	# Deploy new war file
	echo "Deploying new web app"
	cp -vf $OXDWARDIR/openxda*.war $TOMCATWEBAPPSDIR/openxdata.war

	# start tomcat
	echo "Starting tomcat"
	sh $TOMCATBINDIR/startup.sh
}

# Notify completion status
function completed {

	# Check if tomcat restart successfully
	local RESULT=$(netstat -na | grep 8080 | grep -v grep | awk '{print $7}' | wc -l)
	if [[ "$RESULT" != 0 ]]; then
		echo "Deployment completed successfully"
	elif [[ "$RESULT" == 0 ]]; then
		echo "Something went wickedly wrong with the deployment."
		exit -1
	fi
}

while getopts "d:h" optname 
	do
		case "$optname" in
		"d")
		# Pass true to wipe tomcat logs
		DELETELOGS=$OPTARG
		;;
		"h")
			echo "Usage: Should run as root user"
			echo "deploy.sh [-d ] [-h ]"
			exit 0
			;;
		"?")
        	exit 1
        	;;
      	":")
        	echo "No argument value for option $OPTARG"
        	;;
      *)
      # Should not occur
        echo "I support Mitt Romney?!"
        ;;
    esac
done

# Tomcat status
STAT=$(netstat -na | grep 8080 | grep -v grep | awk '/LISTEN/ {print $6}')

if [[ "$STAT" == "LISTEN" ]]; then

	echo "Tomcat running on default port."

	UNAME=$(whoami)

	# Get PID of tomcat process
	PID=$(ps -u $UNAME | grep -i tomcat | grep -v grep | awk '{print $2}')

	# Kill the tomcat process
	echo "Killing Tomcat Process:" $PID
	kill -term $PID

	# Deploy
	deploy

	# Complete
	completed

elif [[ -z "$STAT" ]]; then

	# Just deploy the file and start tomcat
	echo "Tomcat not running. Proceeding to deploy"

	# Deploy
	deploy

	# Complete
	completed
fi

exit