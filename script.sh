#!/bin/bash

#Avant de lancer le script :
#installation JDK
#on modifie dans /etc/hostname "kafka.example.com"
#on ajoute la ligne 127.0.1.1 dans /etc/hosts "127.0.1.1 kafka.example.com kafka" 

sudo apt-get install krb5-admin-server krb5-kdc 
#default realm :"EXAMPLE.COM" kerberos server:"kafka.example.com"

sudo apt-get install krb5-user 
#default realm :"EXAMPLE.COM" kerberos server:"kafka.example.com"

sudo krb5_newrealm

mkdir /etc/kafka/keytabs

sudo kadmin.local -q "addprinc -randkey kafka/kafka.example.com@EXAMPLE.COM"

sudo kadmin.local -q "ktadd -e des3-cbc-sha1 -k /etc/kafka/keytabs/kafka.keytab kafka/kafka.example.com@EXAMPLE.COM"

sudo kadmin.local -q "addprinc -randkey zookeeper/kafka.example.com@EXAMPLE.COM"

sudo kadmin.local -q "ktadd -e des3-cbc-sha1 -k /etc/kafka/keytabs/zookeeper.keytab zookeeper/kafka.example.com@EXAMPLE.COM"

sudo kadmin.local -q "addprinc -randkey kafkaclient/kafka.example.com@EXAMPLE.COM"

sudo kadmin.local -q "ktadd -e des3-cbc-sha1 -k /etc/kafka/keytabs/kafkaclient.keytab kafkaclient/kafka.example.com@EXAMPLE.COM"

sudo chmod 777 /etc/kafka/keytabs/*

file=/etc/kafka/kafka_server_jaas.conf
echo "KafkaServer {" >> $file
echo  "com.sun.security.auth.module.Krb5LoginModule required" >> $file
echo  "storeKey=true" >> $file
echo  "useKeyTab=true" >> $file
echo  'keyTab="/etc/kafka/keytabs/kafka.keytab"' >> $file
echo  'principal="kafka/kafka.example.com@EXAMPLE.COM";' >> $file
echo "};" >> $file

echo "Client {" >> $file
echo  "com.sun.security.auth.module.Krb5LoginModule required" >> $file
echo  "useKeyTab=true" >> $file
echo  "storeKey=true" >> $file
echo  'keyTab="/etc/kafka/keytabs/kafka.keytab"' >> $file
echo  'principal="kafka/kafka.example.com@EXAMPLE.COM";' >> $file
echo "};" >> $file

file1=/etc/kafka/zookeeper_jaas.conf
echo "Server {" >> $file1
echo  "com.sun.security.auth.module.Krb5LoginModule required" >> $file1
echo  "useKeyTab=true" >> $file1
echo  "storeKey=true" >> $file1
echo  'keyTab="/etc/kafka/keytabs/zookeeper.keytab"' >> $file1
echo  'principal="zookeeper/kafka.example.com@EXAMPLE.COM";' >> $file1
echo "};" >> $file1

file2=/etc/kafka/kafka_client_jaas.conf
echo "KafkaClient {" >> $file2
echo  "com.sun.security.auth.module.Krb5LoginModule required" >> $file2
echo  "useKeyTab=true" >> $file2
echo  "storeKey=true" >> $file2
echo  'keyTab="/etc/kafka/keytabs/kafkaclient.keytab"' >> $file2
echo  'principal="kafkaclient/kafka.example.com@EXAMPLE.COM";' >> $file2
echo "};" >> $file2

echo "authProvider.1=org.apache.zookeeper.server.auth.SASLAuthenticationProvider" >> /etc/kafka/config/zookeeper.properties
echo "jaasLoginRenew=3600000" >> /etc/kafka/config/zookeeper.properties
echo "kerberos.removeHostFromPrincipal=true" >> /etc/kafka/config/zookeeper.properties
echo "kerberos.removeRealmFromPrincipal=true" >> /etc/kafka/config/zookeeper.properties

echo "listeners=SASL_PLAINTEXT://kafka.example.com:9092" >> /etc/kafka/config/server.properties
echo "security.inter.broker.protocol=SASL_PLAINTEXT" >> /etc/kafka/config/server.properties
echo "sasl.mechanism.inter.broker.protocol=GSSAPI" >> /etc/kafka/config/server.properties
echo "sasl.enabled.mechanism=GSSAPI" >> /etc/kafka/config/server.properties
echo "sasl.kerberos.service.name=kafka" >> /etc/kafka/config/server.properties
#Dans server.properties on modifie zookeeeper.connect=kafka.example.com:2181

file=/etc/kafka/config/producer_sasl.properties
echo "bootstrap.servers=kafka.example.com:9092" >> $file
echo "security.protocol=SASL_PLAINTEXT" >> $file
echo "sasl.kerberos.service.name=kafka" >> $file

file=/etc/kafka/config/consumer_sasl.properties
echo "bootstrap.servers=kafka.example.com:9092" >> $file
echo "group.id=securing-kafka-group" >> $file
echo "security.protocol=SASL_PLAINTEXT" >> $file
echo "sasl.kerberos.service.name=kafka" >> $file


cd /etc/kafka

export KAFKA_OPTS="-Djava.security.krb5.conf=/etc/krb5.conf -Djava.security.auth.login.config=/etc/kafka/zookeeper_jaas.conf -Dsun.security.krb5.debug=true"

bin/zookeeper-server-start.sh config/zookeeper.properties

#Dans un autre terminal
#sudo gnome-terminal -e cd /etc/kafka 
#export KAFKA_OPTS="-Djava.security.krb5.conf=/etc/krb5.conf -Djava.security.auth.login.config=/etc/kafka/kafka_server_jaas.conf -Dsun.security.krb5.debug=true"

#bin/kafka-server-start.sh config/server.properties




