#!/bin/bash

#Storing a set of commands under the variable 'installnipe' to run installation steps for Nipe, if it is not present in the system.
function installnipe()
{
	git clone https://github.com/htrgouvea/nipe && cd nipe
	sudo apt-get -y install cpanminus
	cpanm --installdeps .
	sudo cpan install Switch JSON LWP::UserAgent Config::Simple
	sudo perl nipe.pl install
}

#This is the IP of the remote server(Ubuntu), edit it to match the IP of the remote server user is connecting to.
HOST=192.168.139.129

#This is to ensure the host machine is up to date to receive the installations if needed.
echo "Ensuring system is up to date, this may take some time, please wait."
sudo apt-get update > /dev/null 2>&1
sudp apt-get upgrade -y > /dev/null 2>&1
sudo apt-get dist-upgrade -y > /dev/null 2>&1

#To check if the required applications to run the script exists, and install them if not.
echo "Checking if required applications are installed, please wait."

echo''

#Storing required applications to run the script into an array so that a for loop will run through each iterations"
array=('sshpass' 'tor' 'geoip-bin')

#To check if the package of the application exists on the machine, determining if they are installed. 3seconds pause before running the loop again.
for app in "${array[@]}"
do
	if [ "$(dpkg -s $app 2>/dev/null | grep 'Status: install ok installed')" ]
	then
		echo "$app is already installed."
	else
		echo "$app required, installing $app, please wait."
		sudo apt-get install -y $app > /dev/null 2>&1
		echo "$app installed."
	fi
	echo''
	sleep 3
done

#As nipe is not a package, script has to check for its directory's existence.
if [ -d nipe ]
then
	echo "Nipe is already installed."
else
	echo "Nipe required, installing Nipe, please wait."
	installnipe > /dev/null 2>&1
	echo "Nipe installed."
fi

echo''
sleep 10

#Script needs to cd into nipe in order for the nipe.pl script to run.
cd nipe
sudo perl nipe.pl start

#To check for a successful connection. Script will abort if connection fails.
anon=$(sudo perl nipe.pl status | grep true | awk '{print $3}' | wc -m)

if [ $anon -eq 5 ]
then
	echo "You are anonymous! Connecting to remote server."
else 
	echo "You are not anonymous! Exiting the script."
	exit
fi
sleep 3

echo''

#To check the IP and its location once there is an anonymous connection.
anonIP=$(sudo perl nipe.pl status | grep Ip | awk '{print $3}')
anonctry=$(geoiplookup $anonIP | awk -F: '{print $2}')

echo "Your Spoofed IP address is: $anonIP, and it's country is: $anonctry."
sleep 3

echo''

#To get an input from the user to be scanned.
echo "Enter a Domain/IP to scan:"
read input
sleep 3

echo''

#Information retrival from the remote server(Ubuntu) via sshpass. 
sptime=$(sshpass -p tc ssh -oStrictHostKeyChecking=no tc@$HOST uptime -p)
spif=$(sshpass -p tc ssh -oStrictHostKeyChecking=no tc@$HOST "curl ifconfig.me")
spctry=$(geoiplookup $spif | awk -F: '{print $2}')

echo "Details of remote server:"
echo "Uptime:" $sptime
sleep 3

echo''

echo "IP address:" $spif
sleep 3

echo''

echo "Country:" $spctry
sleep 3

echo''

#Performing scan with the input given by the user, with the results saved into a text file on the remote server(Ubuntu).
echo "Scanning given Domain/IP Address on the remote server."
sshpass -p tc ssh -oStrictHostKeyChecking=no tc@$HOST "whois $input > whois.txt"
echo "Scan completed, results saved on remote server."
#Log file created to capture whenever user conduct a scan.
date=$(date)
echo "$date [-] whois data collected for: $input" >> /var/log/NR.log
sleep 3

echo''

#Performing ftp to retrieve the saved file back into user's machine.
echo "Retrieving results from remote server."

USER=tc
PASSWORD=tc

ftp -inv $HOST > /dev/null 2>&1 <<EOF
user $USER $PASSWORD
cd /home/tc
get whois.txt
EOF

echo "Script has ended, exiting now, good bye."
exec bash

