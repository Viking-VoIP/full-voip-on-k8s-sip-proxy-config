#!/bin/bash

SHM_MEMORY=128
PKG_MEMORY=16

echo "SHM_MEMORY: $SHM_MEMORY"
echo "PKG_MEMORY: $PKG_MEMORY"

PUBLIC_IP=$(wget -q -O - http://169.254.169.254/latest/meta-data/public-ipv4)
PRIVATE_IP=$(wget -q -O - http://169.254.169.254/latest/meta-data/local-ipv4)
DB_ADDRESS=$(consul kv get backend/db_address)
DB_USER=$(consul kv get backend/db_user)
DB_PASS=$(consul kv get backend/db_pass)
LOCAL_SUBSCRIBER_REGEXP=$(consul kv get voice/local_subscribers_regexp)

sed -i.backup "s/{{ DBHOST }}/$DB_ADDRESS/g" /etc/kamailio/definitions.cfg /etc/kamailio/kamctlrc
sed -i.backup "s/{{ DBUSER }}/$DB_USER/g" /etc/kamailio/definitions.cfg /etc/kamailio/kamctlrc
sed -i.backup "s/{{ DBPASS }}/$DB_PASS/g" /etc/kamailio/definitions.cfg /etc/kamailio/kamctlrc
sed -i.backup "s/{{ LOCAL_SUBSCRIBER_REGEXP }}/$LOCAL_SUBSCRIBER_REGEXP/g" /etc/kamailio/definitions.cfg

sed -i.backup "s/{{ KAM_PRIVATE_IP }}/$PRIVATE_IP/g" /etc/kamailio/definitions.cfg /etc/kamailio/dispatcher.list.tpl
sed -i.backup "s/{{ KAM_PUBLIC_IP }}/$PUBLIC_IP/g" /etc/kamailio/definitions.cfg

echo "alias=$PUBLIC_IP" >> aliases.cfg
echo "alias=$PRIVATE_IP" >> aliases.cfg



# Set vars in startup file
sed "s/{{ SHM_MEMORY }}/$SHM_MEMORY/g; s/{{ PKG_MEMORY }}/$PKG_MEMORY//g" /etc/kamailio/kamailio.service > /etc/systemd/system/multi-user.target.wants/kamailio.service
sed "s/{{ SHM_MEMORY }}/$SHM_MEMORY/g; s/{{ PKG_MEMORY }}/$PKG_MEMORY//g" /etc/kamailio/kamailio.default > /etc/default/kamailio

# Copy kamailio default's file
cp /etc/kamailio/kamailio.default /etc/default/kamailio

# Configure consul's template (dispatcher)
consul-template -template="/etc/kamailio/dispatcher.list.tpl:/etc/kamailio/dispatcher.list:/usr/sbin/kamcmd dispatcher.reload" -once 2> /dev/null

SIP_DOMAIN=$(consul kv get voice/sip_domain 2> /dev/null) && if [[ "$?" -eq "0" ]]; then echo "alias=$SIP_DOMAIN" >> aliases.cfg; fi

kamdbctl create 2> /dev/null

supervisorctl start consul_watcher

#echo '
##
## Kamailio startup options
##
#
#RUN_KAMAILIO=yes
#SHM_MEMORY=64
#PKG_MEMORY=8
#USER=kamailio
#GROUP=kamailio
#CFGFILE=/etc/kamailio/kamailio.cfg
#' > /etc/default/kamailio
#service kamailio start
#/usr/sbin/kamailio -P /var/run/kamailio/kamailio.pid -f $CFGFILE -m $SHM_MEMORY -M $PKG_MEMORY -u $USER -g $GROUP -DD -E
