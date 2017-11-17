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
if [[ ! -e 1_git_clone_and_install_YunoHost.sh ]];
	then if [[ -d yunohost_auto_config_basic ]];
		then cd yunohost_auto_config_basic || {
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
apt-get remove apache2 bind9 -y
apt-get upgrade -y
apt-get dist-upgrade -y
# Base kit to be installed
apt-get install git nano dnsmasq -y


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
	sudo passwd
	cp ./conf_colours/root.bashrc /root/.bashrc;
	cp ./conf_colours/authorized_keys /root/.ssh/authorized_keys
	source ~/.bashrc;

	# We restart SSH service
	echo -e "\n--- $(msgRestart 'SSH') \n";
	service ssh restart;
	echo -e "\n";


# Installation of Yunohost from git
# msg119 : Installation of Yunohost v2 from git sources
echo -e -p "\n$script $(msg119) \n";

git clone https://github.com/YunoHost/install_script /tmp/install;
/tmp/install/install_yunohostv2;

echo -e -p "Yunohost installé !";


#################
#
# Hardening ssl & Nginx
#
#################


# Creation of sslcert group if it doesn't exists
# msg417 : Creating group sslcert
echo -e "$ok $(msg417)"
getent group sslcert  || groupadd sslcert
# msg418 : Added to sslcert group : $1
for g in amavis dovecot mail metronome mysql openldap postfix postgrey root vmail www-data
do
	usermod -G sslcert $g
	echo -e "$(msg418 $g)"
done



# drop TLSv1 ans TLSv1.1
sed -i "s/ssl_protocols\ TLSv1\ TLSv1.1\ TLSv1.2/ssl_protocols\ TLSv1.2/g" /etc/nginx/nginx.conf;
sed -i "s/ssl_protocols\ TLSv1\ TLSv1.1\ TLSv1.2/ssl_protocols\ TLSv1.2/g" /etc/nginx/conf.d/*.conf;
sed -i "s/ssl_protocols\ TLSv1\ TLSv1.1\ TLSv1.2/ssl_protocols\ TLSv1.2/g" /usr/share/yunohost/yunohost-config/nginx/*.conf;

sed -i "s/ssl_ciphers\ ALL\:\!aNULL\:\!eNULL\:\!LOW\:\!EXP\:\!RC4\:\!3DES\:+HIGH\:+MEDIUM/ssl_ciphers\ EECDH+AESGCM\:EDH+AESGCM/g" /etc/nginx/nginx.conf;
sed -i "s/ssl_ciphers\ ALL\:\!aNULL\:\!eNULL\:\!LOW\:\!EXP\:\!RC4\:\!3DES\:+HIGH\:+MEDIUM/ssl_ciphers\ EECDH+AESGCM\:EDH+AESGCM/g" /etc/nginx/conf.d/*.conf;
sed -i "s/ssl_ciphers\ ALL\:\!aNULL\:\!eNULL\:\!LOW\:\!EXP\:\!RC4\:\!3DES\:+HIGH\:+MEDIUM/ssl_ciphers\ EECDH+AESGCM\:EDH+AESGCM/g" /usr/share/yunohost/yunohost-config/nginx/*.conf;


# DH 4096

# debug : on zappe le DH pour gagner du temps
#openssl dhparam -out /etc/ssl/private/dh4096.pem -outform PEM -2 4096;
touch /etc/ssl/private/dh4096.pem;

sed -i "22 a \ \ \ \ ssl_dhparam\ \/etc\/ssl\/private\/dh4096.pem\;\\n" /etc/nginx/conf.d/yunohost_admin.conf;
sed -i "22 a ssl_dhparam\ \/etc\/ssl\/private\/dh4096.pem\;\\n" /usr/share/yunohost/yunohost-config/nginx/yunohost_admin.conf;
sed -i "s/#ssl_dhparam\ \/etc\/ssl\/private\/dh2048.pem/ssl_dhparam\ \/etc\/ssl\/private\/dh4096.pem/g" /etc/nginx/nginx.conf;
sed -i "s/#ssl_dhparam\ \/etc\/ssl\/private\/dh2048.pem/ssl_dhparam\ \/etc\/ssl\/private\/dh4096.pem/g" /etc/nginx/conf.d/*.conf;
sed -i "s/#ssl_dhparam\ \/etc\/ssl\/private\/dh2048.pem/ssl_dhparam\ \/etc\/ssl\/private\/dh4096.pem/g" /usr/share/yunohost/yunohost-config/nginx/*.conf;

mkdir /etc/yunohost/certs/CAcerts;
wget http://www.cacert.org/certs/root.crt -O /etc/yunohost/certs/CAcerts/ca.pem;
wget http://www.cacert.org/certs/class3.crt -O /etc/yunohost/certs/CAcerts/intermediate_ca.pem;

sed -i "s/\=\ AU/\=\ FR/g" /etc/ssl/openssl.cnf;
sed -i "s/Some-State/\ /g" /etc/ssl/openssl.cnf;
sed -i "s/Internet\ Widgits\ Pty\ Ltd/Zurp/g" /etc/ssl/openssl.cnf;

current_dir=`pwd`

for D in `find /etc/yunohost/certs/. -type d`
do
	if [ $D != '/etc/yunohost/certs/.' ] && [ $D != '/etc/yunohost/certs/./CAcerts' ] && [ $D != '/etc/yunohost/certs/./yunohost.org' ];
	then
		cd $D;
		mkdir backup;
		mv *.pem backup;
		echo -e "\n Certificat pour $D";
		openssl genrsa -out ssl.key 4096;
		openssl req -new -key ssl.key -out ssl.csr;
		echo "CSR for $D";
		cat ssl.csr;
		
		touch ssl.crt;
		echo -e "\nColler le certificat signé ici : ";
		end_cert="-----END CERTIFICATE-----";
		end=false;
		until $end ;
		do
				read  cert;
				echo $cert >> ssl.crt;
				if [ "$cert" == "$end_cert" ]
						then end=true;
				fi;
		done;
		
		openssl rsa -in ssl.key -out key.pem -outform PEM;
		cat ssl.crt /etc/yunohost/certs/CAcerts/intermediate_ca.pem /etc/yunohost/certs/CAcerts/ca.pem | tee crt.pem;
		rm ssl.key;
		rm ssl.csr;
		rm ssl.crt;
		chown www-data:sslcert *.pem;
		chmod 640 *.pem;
	fi;
done;

cd $current_dir;

# restart nginx
echo -e "\n--- $(msgRestart 'NGINX & PHP5-FPM') \n"
service nginx restart
service php5-fpm restart

#################
#
# This script aims to configure apticron so that emails would be sent
#
#################

	current_host=`cat /etc/yunohost/current_host`;
	email_default=admin@$current_host;

	# We defnie sender's and receiver's email address
	# msg603 : Define apticron sender's email address
	echo -e "\n" ; read -e -p "$(msg603) : " -i "$email_default" email_apti_s;
	# msg604 : Define receiving email address of apticron's reports
	read -e -p "$(msg604) : " -i "$email_apti_s" email_apti_r;

	apti=/etc/apticron/apticron.conf;
	cron=/etc/cron.d/apticron;

	# msg605 : apticron Sender's email
	echo -e "\n$ok $(msg605) : $email_apti_s";
	# msg606 : apticron Receiver's email
	echo -e "$ok $(msg606) : $email_apti_r\n";

	# We start by installing the right software;
	# msg607 : Installation of apticron software
	echo -e "$info $(msg607) ...";
	apt-get update -qq > /dev/null 2>&1;
	apt-get install -qq -y apticron > /dev/null 2>&1;

	# Then we configure apticron
	# msg608 : Configuring apticron to send emails from $email_apti_s
	echo -e "$ok $(msg608) ";
	sed -i "s/EMAIL=\"root\"/EMAIL=\"$email_apti_s\"/g" $apti;
	sed -i "s/# NOTIFY_NO_UPDATES=\"0\"/NOTIFY_NO_UPDATES=\"1\"/g" $apti;
	# msg609 : Configuring apticron to receive emails to $email_apti_r
	echo -e "$ok $(msg609) ";
	sed -i "s/# CUSTOM_FROM=\"\"/CUSTOM_FROM=\"$email_apti_r\"/g" $apti;

	# We adjust the cron
	# msg610 : Adjustment of $cron
	echo -e "$ok $(msg610)";
	sed -i "s/\* \* \* \*/4 \* \* \*/g" $cron;


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

