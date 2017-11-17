#!/bin/bash
#
# This script aims to install yunohost v2 from git
#
# polytan02@mcgva.org
# 01/05/2015
#
# Mod by lordzurp, 09/2015
#


#################
#
# Config et check-list
#
#################

lang="fr"

# We make sure the user launch the script from the bundle, or at least one folder up
if [[ ! -e 1_base.sh ]];
	then if [[ -d Odin_webserver ]];
		then cd Odin_webserver || {
			echo -e >&2 "\n Le repertoire du bundle existe mais je ne peux pas cd dedans.\n"; exit 1;
		 }
		else echo -e "\n Veuillez rentrer dans le repertoire avant de lancer le script.\n"; exit 1;
		fi;
fi;

# We check that all necessary files are present
for i in couleurs.sh 1_trad_msg.sh 2_trad_msg.sh 3_trad_msg.sh 4_trad_msg.sh 5_trad_msg.sh 6_trad_msg.sh 7_trad_msg.sh 8_trad_msg.sh 9_trad_msg.sh;
do
	if ! [ -a "etc/$i" ];
	then echo -e "\n $i n'est pas present dans le sous dossier etc";
		echo -e "\nOn arrete avant d'aller plus loin\n";
		read -e -p "Presser ENTREE pour arreter ce script...  ";
		exit;
	fi;
done;

source etc/couleurs.sh;
source etc/1_trad_msg.sh;
source etc/2_trad_msg.sh;
source etc/3_trad_msg.sh;
source etc/4_trad_msg.sh;
source etc/5_trad_msg.sh;
source etc/6_trad_msg.sh;
source etc/7_trad_msg.sh;
source etc/8_trad_msg.sh;
source etc/9_trad_msg.sh;

# Make sure only root can run our script
if [[ $EUID -ne 0 ]];
		then   echo -e "\n$failed $(msgNoRoot) \n";
		read -e -p "$(msgHitEnterEnd)";
		exit;
fi;


#################
#
# Installation of Yunohost
#
#################

echo -e "\n$script $(msg100) \n";

# Update of hostname
hostname=`cat /etc/hostname`;
# msg101 : Current hostname
echo -e "\n$info $(msg101) : $hostname \n";

echo -e "\n" ; read -e -p "$(msg103) : " new_hostname;
if [ ! -z $new_hostname ];
	then echo $new_hostname > /etc/hostname
		# msg104 : hostname updated to $new_hostname
		echo -e "\n$ok $(msg104) \n";
	else # msg105 The hostname seems empty, we don't change it !
		echo -e "\n$failed $(msg105)";
		# msg101 : current hostname
		echo -e "\n$info $(msg101) : $hostname \n";
fi;


# Update of timezone
dpkg-reconfigure tzdata

# Update of locales
dpkg-reconfigure locales


# Update of packages list and installation of git
# msg118 : Update of packages list
echo -e "\n$info $(msg118) \n";
apt-get update
# On some systems there may be apache, which would fail the install, so we remove it. Same for bind9
apt-get upgrade -y
apt-get dist-upgrade -y
# Base kit to be installed
apt-get install git nano curl dnsmasq -y


#################
#
# SSH et users
#
#################

	# SSH configuration with custom file with root allowed to connect
	# msg3182 : Copy of sshd_config to /etc/ssh
	echo -e "$ok $(msg3182)";
	cp ./conf_base/sshd_config /etc/ssh/sshd_config;

	# Creation of a SSH user instead of admin
	echo -e "\n add user god";
	user=god
	adduser $user;
	adduser $user sudo;
	cp ./conf_colours/user.bashrc /home/$user/.bashrc;
	mkdir /home/$user/.ssh
	cp ./conf_colours/authorized_keys /home/$user/.ssh/authorized_keys
	chown $user:$user /home/$user/.bashrc;
	chown -R $user:$user /home/$user/.ssh;

	echo -e "\n password for root";
	# sudo passwd
	cp ./conf_colours/root.bashrc /root/.bashrc;
	cp ./conf_colours/authorized_keys /root/.ssh/authorized_keys
	source ~/.bashrc;

	# We restart SSH service
	echo -e "\n--- $(msgRestart 'SSH') \n";
	service ssh restart;
	echo -e "\n";


#################
#
# Fianl Clean
#
#################

	# msg903 : Ok, here we clean
	echo -e "\n$info $(msg903) \n";
	apt-get autoremove -qq;
	# msg904 : apt-get autoremove : Done
	echo -e "\n$ok $(msg904)";
	apt-get autoclean -qq;
	# msg905 : apt-get autoclean : Done
	echo -e "\n$ok $(msg905)";

echo -e "\n$info $(msgAllDone) \n";

