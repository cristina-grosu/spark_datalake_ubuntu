#!/bin/bash

SPARK_HOME="/opt/spark-2.1.0-bin-hadoop2.7"

echo Using SPARK_HOME=$SPARK_HOME

. "${SPARK_HOME}/sbin/spark-config.sh"

. "${SPARK_HOME}/bin/load-spark-env.sh"

export JAVA_HOME="/opt/jdk1.8.0_72/"                                                                                                                               
export PATH="$PATH:/opt/jdk1.8.0_72/bin:/opt/jdk1.8.0_72/jre/bin:/opt/hadoop/bin/:/opt/hadoop/sbin/"
export HADOOP_HOME="/opt/hadoop"
export PATH="$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$SPARK_HOME/sbin"
export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
export HADOOP_PREFIX="$HADOOP_HOME"
export HADOOP_SBIN_DIR="$HADOOP_HOME/sbin"
export HADOOP_SBIN_DIR="$HADOOP_HOME/bin"
export HADOOP_CLASSPATH="$HADOOP_HOME/share/hadoop/common/"
export JAVA_CLASSPATH="$JAVA_HOME/jre/lib/"
export JAVA_OPTS="-Dsun.security.krb5.debug=true"

rm -rf /opt/hadoop/etc/hadoop/core-site.xml

cp /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf.template /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf

if [ "$HDFS_MASTER" != "" ]; then
	sed "s/HOSTNAME/$HDFS_MASTER/" /opt/hadoop/etc/hadoop/core-site.xml.template >> /opt/hadoop/etc/hadoop/core-site.xml
else 
	mv /opt/spark-2.1.0-bin-hadoop2.7/conf/core-site.xml.datalake /opt/hadoop/etc/hadoop/core-site.xml

	
	if [ "$DEV" == "integration" ]; then 
		cp /etc/krb5.conf.integration /etc/krb5.conf
		mv /opt/spark-2.1.0-bin-hadoop2.7/conf/core-site.xml.datalake.integration /opt/hadoop/etc/hadoop/core-site.xml
		
	fi
fi

if [ "$ENCRYPTION" != "" ]; then
	sed "s/ENCRYPTION/$ENCRYPTION/" /opt/hadoop/etc/hadoop/core-site.xml >> /opt/hadoop/etc/hadoop/core-site.xml.tmp && \
	mv /opt/hadoop/etc/hadoop/core-site.xml.tmp /opt/hadoop/etc/hadoop/core-site.xml
	
	cp /opt/hadoop/etc/hadoop/core-site.xml /opt/spark-2.1.0-bin-hadoop2.7/conf/core-site.xml
	
	sed "s/ENC_KEY_PATH/${ENC_KEY_PATH}/" /opt/hadoop/etc/hadoop/core-site.xml >> /opt/hadoop/etc/hadoop/core-site.xml.tmp && \
	mv /opt/hadoop/etc/hadoop/core-site.xml.tmp /opt/hadoop/etc/hadoop/core-site.xml
	
	cp /opt/hadoop/etc/hadoop/core-site.xml /opt/spark-2.1.0-bin-hadoop2.7/conf/core-site.xml
	
	# Download Bigstep Data Lake Client Libraries
	# there is a DLEncryption already initialized error that has to be treated before enabling encryption on Spark clusters. For testing and development purposes I commented that section
	if [ "$ENCRYPTION" == "true" ]; then 
		wget https://github.com/bigstepinc/datalake-client-libraries/releases/download/1.5.2/datalake-client-libraries-1.5-SNAPSHOT.jar -P /opt/spark-2.1.0-bin-hadoop2.7/jars/
		
		if [ "$CIPHER_CLASS" != "" ]; then
			echo "spark.authenticate.encryption.aes.cipher.class=$CIPHER_CLASS" >> /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf
		fi
		if [ "$CIPHER_KEYSIZE" != "" ]; then 
			echo "spark.authenticate.encryption.aes.cipher.keySize=$CIPHER_KEYSIZE" >> /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf
		fi
		if [ "$AUTH_ENC" != "" ]; then
			echo "spark.authenticate.encryption.aes.enabled=$AUTH_ENC" >> /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf
		fi
	else
		wget https://github.com/bigstepinc/datalake-client-libraries/releases/download/untagged-9758317a72f268684537/datalake-client-libraries-1.5-SNAPSHOT.jar -P /opt/spark-2.1.0-bin-hadoop2.7/jars/
	fi
fi

if [ "$SPARK_WAREHOUSE_DIR" != "" ]; then
	rm /opt/spark-2.1.0-bin-hadoop2.7/conf/core-site.xml
	echo "spark.sql.warehouse.dir=$SPARK_WAREHOUSE_DIR" >> /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf
fi

if [ "$DATALAKE_USER" != "" ]; then
	sed "s/DATALAKE_USER/$DATALAKE_USER/" /opt/hadoop/etc/hadoop/core-site.xml >> /opt/hadoop/etc/hadoop/core-site.xml.tmp && \
	mv /opt/hadoop/etc/hadoop/core-site.xml.tmp /opt/hadoop/etc/hadoop/core-site.xml
	
	cp /opt/hadoop/etc/hadoop/core-site.xml /opt/spark-2.1.0-bin-hadoop2.7/conf/core-site.xml
fi

if [ "$DATALAKE_DOMAIN" != "" ]; then
	sed "s/DATALAKE_DOMAIN/$DATALAKE_DOMAIN/" /opt/hadoop/etc/hadoop/core-site.xml >> /opt/hadoop/etc/hadoop/core-site.xml.tmp && \
	mv /opt/hadoop/etc/hadoop/core-site.xml.tmp /opt/hadoop/etc/hadoop/core-site.xml
	
	cp /opt/hadoop/etc/hadoop/core-site.xml /opt/spark-2.1.0-bin-hadoop2.7/conf/core-site.xml
fi

if [ "$KEYTAB_PATH" != "" ]; then
	sed "s/KEYTAB_PATH/${KEYTAB_PATH}/" /opt/hadoop/etc/hadoop/core-site.xml >> /opt/hadoop/etc/hadoop/core-site.xml.tmp && \
	mv /opt/hadoop/etc/hadoop/core-site.xml.tmp /opt/hadoop/etc/hadoop/core-site.xml
	
	cp /opt/hadoop/etc/hadoop/core-site.xml /opt/spark-2.1.0-bin-hadoop2.7/conf/core-site.xml
fi


if [ "$DATALAKE_NODE" != "" ]; then
	echo "spark.sql.warehouse.dir=dl://DATALAKE_NODE:14000/data_lake/USER_HOME_DIR" >> /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf

	sed "s/DATALAKE_NODE/${DATALAKE_NODE}/" /opt/hadoop/etc/hadoop/core-site.xml >> /opt/hadoop/etc/hadoop/core-site.xml.tmp && \
	mv /opt/hadoop/etc/hadoop/core-site.xml.tmp /opt/hadoop/etc/hadoop/core-site.xml
	
	sed "s/DATALAKE_NODE/${DATALAKE_NODE}/" /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf >> /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf.tmp && \
	mv /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf.tmp /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf
	
	cp /opt/hadoop/etc/hadoop/core-site.xml /opt/spark-2.1.0-bin-hadoop2.7/conf/core-site.xml

fi

if [ "$USER_HOME_DIR" != "" ]; then
	mkdir -p $USER_HOME_DIR
	sed "s/USER_HOME_DIR/$USER_HOME_DIR/" /opt/hadoop/etc/hadoop/core-site.xml >> /opt/hadoop/etc/hadoop/core-site.xml.tmp && \
	mv /opt/hadoop/etc/hadoop/core-site.xml.tmp /opt/hadoop/etc/hadoop/core-site.xml
	
	sed "s/USER_HOME_DIR/$USER_HOME_DIR/" /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf >> /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf.tmp && \
	mv /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf.tmp /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf
	
	cp /opt/hadoop/etc/hadoop/core-site.xml /opt/spark-2.1.0-bin-hadoop2.7/conf/core-site.xml
fi

if [ "$SPARK_MASTER_PORT" == "" ]; then
  SPARK_MASTER_PORT=7077
fi
if [ "$SPARK_MASTER_IP" == "" ]; then
  SPARK_MASTER_IP="0.0.0.0"
fi
if [ "$SPARK_MASTER_WEBUI_PORT" == "" ]; then
  SPARK_MASTER_WEBUI_PORT=8080
fi
if [ "$SPARK_WORKER_WEBUI_PORT" == "" ]; then
  SPARK_WORKER_WEBUI_PORT=8081
fi
if [ "$SPARK_UI_PORT" == "" ]; then
  SPARK_UI_PORT=4040
fi
if [ "$SPARK_WORKER_PORT" == "" ]; then
  SPARK_WORKER_PORT=8581
fi
if [ "$CORES" == "" ]; then
  CORES=1
fi
if [ "$MEM" == "" ]; then
  MEM=1g
fi
if [ "$SPARK_MASTER_HOSTNAME" == "" ]; then
  SPARK_MASTER_HOSTNAME=`hostname -f`
fi
# Setting defaults for spark and Hive parameters -> RPC error
if [ "$SPARK_NETWORK_TIMEOUT" == "" ]; then
  SPARK_NETWORK_TIMEOUT=120
fi
if [ "$SPARK_RPC_TIMEOUT" == "" ]; then
  SPARK_RPC_TIMEOUT=120
fi
if [ "$SPARK_RPC_NUM_RETRIES" == "" ]; then
  SPARK_RPC_NUM_RETRIES=3
fi
if [ "$DYNAMIC_PARTITION_VALUE" == "" ]; then
  DYNAMIC_PARTITION_VALUE=`true`
fi
if [ "$DYNAMIC_PARTITION_MODE" == "" ]; then
  DYNAMIC_PARTITION_MODE=`nonstrict`
fi
if [ "$NR_MAX_DYNAMIC_PARTITIONS" == "" ]; then
  NR_MAX_DYNAMIC_PARTITIONS=1000
fi
if [ "$MAX_DYNAMIC_PARTITIONS_PER_NODE" == "" ]; then
  MAX_DYNAMIC_PARTITIONS_PER_NODE=100
fi

cp /opt/spark-2.1.0-bin-hadoop2.7/jars/datalake-client-libraries-1.5-SNAPSHOT.jar $HADOOP_HOME/share/hadoop/common/
cp /opt/spark-2.1.0-bin-hadoop2.7/jars/datalake-client-libraries-1.5-SNAPSHOT.jar $HADOOP_HOME/share/hadoop/common/lib/
cp /opt/spark-2.1.0-bin-hadoop2.7/jars/datalake-client-libraries-1.5-SNAPSHOT.jar $HADOOP_HOME/share/hadoop/common/hdfs/
cp /root/google-collections-1.0.jar /opt/spark-2.1.0-bin-hadoop2.7/jars/
cp /bigstep/kerberos/user.keytab $KEYTAB_PATH_URI

if [ "$NOTEBOOK_DIR" != "" ]; then

	#mkdir $NOTEBOOK_DIR/$SPARK_PUBLIC_DNS/notebooks
	#cp /user/notebooks/* $NOTEBOOK_DIR/$SPARK_PUBLIC_DNS/notebooks/
	
	mkdir $NOTEBOOK_DIR
	mkdir $NOTEBOOK_DIR/$SPARK_PUBLIC_DNS
	mkdir $NOTEBOOK_DIR/$SPARK_PUBLIC_DNS/logs
	mkdir $NOTEBOOK_DIR/$SPARK_PUBLIC_DNS/work
	mkdir $NOTEBOOK_DIR/$SPARK_PUBLIC_DNS/local
	
	#sed "s/#c.NotebookApp.notebook_dir = u.*/c.NotebookApp.notebook_dir = u\'$ESCAPED_NOTEBOOK_DIR\/$SPARK_PUBLIC_DNS\/notebooks\'/" /root/.jupyter/jupyter_notebook_config.py >> /root/.jupyter/jupyter_notebook_config.py.tmp
	#mv /root/.jupyter/jupyter_notebook_config.py.tmp /root/.jupyter/jupyter_notebook_config.py
	
	cp /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-env.sh.template /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-env.sh
	echo "SPARK_WORKER_DIR=$NOTEBOOK_DIR/$SPARK_PUBLIC_DNS/work" >> /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-env.sh
	
	sed "s/LOG_DIR/${ESCAPED_NOTEBOOK_DIR}\/$SPARK_PUBLIC_DNS\/logs/" /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf >> /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf.tmp && \
	mv /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf.tmp /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf

	sed "s/LOCAL_DIR/${ESCAPED_NOTEBOOK_DIR}\/$SPARK_PUBLIC_DNS\/local/" /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf >> /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf.tmp && \
	mv /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf.tmp /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf
fi

if [ "$PERSISTENT_NB_DIR" != "" ]; then

	mkdir $PERSISTENT_NB_DIR/notebooks
	cp /user/notebooks/* $PERSISTENT_NB_DIR/notebooks/
	
	sed "s/#c.NotebookApp.notebook_dir = u.*/c.NotebookApp.notebook_dir = u\'$ESCAPED_PERSISTENT_NB_DIR\/notebooks\'/" /root/.jupyter/jupyter_notebook_config.py >> /root/.jupyter/jupyter_notebook_config.py.tmp
	mv /root/.jupyter/jupyter_notebook_config.py.tmp /root/.jupyter/jupyter_notebook_config.py
	
fi

if [ "$CLEANUP_ENABLED" != "" ]; then
	sed "s/CLEANUP_ENABLED/$CLEANUP_ENABLED/" /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf >> /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf.tmp && \
	mv /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf.tmp /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf
fi

if [ "$CLEANUP_INTERVAL" != "" ]; then
	sed "s/CLEANUP_INTERVAL/$CLEANUP_INTERVAL/" /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf >> /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf.tmp && \
	mv /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf.tmp /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf
fi

if [ "$CLEANUP_APPDATA" != "" ]; then
	sed "s/CLEANUP_APPDATA/$CLEANUP_APPDATA/" /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf >> /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf.tmp && \
	mv /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf.tmp /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf
fi

sed "s/HOSTNAME_MASTER/$SPARK_MASTER_HOSTNAME/" /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf >> /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf.tmp && \
mv /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf.tmp /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf

sed "s/SPARK_UI_PORT/$SPARK_UI_PORT/" /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf >> /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf.tmp && \
mv /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf.tmp /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf

#Disable AnacondaCloud extension
sed "s/\"nb_anacondacloud\": true/\"nb_anacondacloud\": false/" /opt/conda/envs/python3/etc/jupyter/jupyter_notebook_config.json >> /opt/conda/envs/python3/etc/jupyter/jupyter_notebook_config.json.tmp 
mv /opt/conda/envs/python3/etc/jupyter/jupyter_notebook_config.json.tmp /opt/conda/envs/python3/etc/jupyter/jupyter_notebook_config.json

sed "s/\"nb_anacondacloud\": true/\"nb_anacondacloud\": false/" /opt/conda/etc/jupyter/jupyter_notebook_config.json >> /opt/conda/etc/jupyter/jupyter_notebook_config.json.tmp
mv /opt/conda/etc/jupyter/jupyter_notebook_config.json.tmp /opt/conda/etc/jupyter/jupyter_notebook_config.json

sed "s/\"nb_anacondacloud\": true/\"nb_anacondacloud\": false/" /opt/conda/pkgs/_nb_ext_conf-0.3.0-py27_0/etc/jupyter/jupyter_notebook_config.json >> /opt/conda/pkgs/_nb_ext_conf-0.3.0-py27_0/etc/jupyter/jupyter_notebook_config.json.tmp 
mv /opt/conda/pkgs/_nb_ext_conf-0.3.0-py27_0/etc/jupyter/jupyter_notebook_config.json.tmp /opt/conda/pkgs/_nb_ext_conf-0.3.0-py27_0/etc/jupyter/jupyter_notebook_config.json

sed "s/\"nb_anacondacloud\": true/\"nb_anacondacloud\": false/" /opt/conda/pkgs/_nb_ext_conf-0.3.0-py35_0/etc/jupyter/jupyter_notebook_config.json >> /opt/conda/pkgs/_nb_ext_conf-0.3.0-py35_0/etc/jupyter/jupyter_notebook_config.json.tmp
mv /opt/conda/pkgs/_nb_ext_conf-0.3.0-py35_0/etc/jupyter/jupyter_notebook_config.json.tmp /opt/conda/pkgs/_nb_ext_conf-0.3.0-py35_0/etc/jupyter/jupyter_notebook_config.json

sed "s/\"nb_anacondacloud\/main\": true/\"nb_anacondacloud\/main\": false/" /opt/conda/envs/python3/etc/jupyter/nbconfig/notebook.json >> /opt/conda/envs/python3/etc/jupyter/nbconfig/notebook.json.tmp
mv /opt/conda/envs/python3/etc/jupyter/nbconfig/notebook.json.tmp /opt/conda/envs/python3/etc/jupyter/nbconfig/notebook.json

sed "s/\"nb_anacondacloud\/main\": true/\"nb_anacondacloud\/main\": false/" /opt/conda/etc/jupyter/nbconfig/notebook.json >> /opt/conda/etc/jupyter/nbconfig/notebook.json.tmp
mv /opt/conda/etc/jupyter/nbconfig/notebook.json.tmp /opt/conda/etc/jupyter/nbconfig/notebook.json

# Change the Home Icon 
sed "s/<i class=\"fa fa-home\"><\/i>/\/user/" /opt/conda/envs/python3/lib/python3.5/site-packages/notebook/templates/tree.html >> /opt/conda/envs/python3/lib/python3.5/site-packages/notebook/templates/tree.html.tmp
mv /opt/conda/envs/python3/lib/python3.5/site-packages/notebook/templates/tree.html.tmp /opt/conda/envs/python3/lib/python3.5/site-packages/notebook/templates/tree.html

sed "s/<i class=\"fa fa-home\"><\/i>/\/user/" /opt/conda/lib/python2.7/site-packages/notebook/templates/tree.html >> /opt/conda/lib/python2.7/site-packages/notebook/templates/tree.html.tmp
mv /opt/conda/lib/python2.7/site-packages/notebook/templates/tree.html.tmp /opt/conda/lib/python2.7/site-packages/notebook/templates/tree.html

sed "s/<i class=\"fa fa-home\"><\/i>/\/user/" /opt/conda/pkgs/notebook-4.2.3-py27_0/lib/python2.7/site-packages/notebook/templates/tree.html >> /opt/conda/pkgs/notebook-4.2.3-py27_0/lib/python2.7/site-packages/notebook/templates/tree.html.tmp
mv /opt/conda/pkgs/notebook-4.2.3-py27_0/lib/python2.7/site-packages/notebook/templates/tree.html.tmp /opt/conda/pkgs/notebook-4.2.3-py27_0/lib/python2.7/site-packages/notebook/templates/tree.html

sed "s/<i class=\"fa fa-home\"><\/i>/\/user/" /opt/conda/pkgs/notebook-4.2.3-py35_0/lib/python3.5/site-packages/notebook/templates/tree.html >> /opt/conda/pkgs/notebook-4.2.3-py35_0/lib/python3.5/site-packages/notebook/templates/tree.html.tmp
mv /opt/conda/pkgs/notebook-4.2.3-py35_0/lib/python3.5/site-packages/notebook/templates/tree.html.tmp /opt/conda/pkgs/notebook-4.2.3-py35_0/lib/python3.5/site-packages/notebook/templates/tree.html    

if [ "$SPARK_MASTER_URL" == "" ]; then 
	SPARK_MASTER_URL="spark://$SPARK_MASTER_HOSTNAME:$SPARK_MASTER_PORT"
	echo "Using SPARK_MASTER_URL=$SPARK_MASTER_URL"
fi

export SPARK_OPTS="--driver-java-options=-$JAVA_DRIVER_OPTS --driver-java-options=-Dlog4j.logLevel=info --master $SPARK_MASTER_URL --files /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml"

if [ "$POSTGRES_HOSTNAME" != "" ]; then
	sed "s/POSTGRES_HOSTNAME/$POSTGRES_HOSTNAME/" /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml >> /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml.tmp && \
	mv /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml.tmp /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml
fi

if [ "$POSTGRES_PORT" != "" ]; then
	sed "s/POSTGRES_PORT/$POSTGRES_PORT/" /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml >> /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml.tmp && \
	mv /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml.tmp /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml
fi

if [ "$SPARK_POSTGRES_DB" != "" ]; then
	sed "s/SPARK_POSTGRES_DB/$SPARK_POSTGRES_DB/" /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml >> /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml.tmp && \
	mv /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml.tmp /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml
fi

if [ "$SPARK_POSTGRES_USER" != "" ]; then
	sed "s/SPARK_POSTGRES_USER/$SPARK_POSTGRES_USER/" /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml >> /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml.tmp && \
	mv /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml.tmp /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml
fi

if [ "$DYNAMIC_PARTITION_VALUE" != "" ]; then
	sed "s/DYNAMIC_PARTITION_VALUE/$DYNAMIC_PARTITION_VALUE/" /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml >> /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml.tmp && \
	mv /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml.tmp /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml
fi

if [ "$DYNAMIC_PARTITION_MODE" != "" ]; then
	sed "s/DYNAMIC_PARTITION_MODE/$DYNAMIC_PARTITION_MODE/" /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml >> /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml.tmp && \
	mv /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml.tmp /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml
fi

if [ "$NR_MAX_DYNAMIC_PARTITIONS" != "" ]; then
	sed "s/NR_MAX_DYNAMIC_PARTITIONS/$NR_MAX_DYNAMIC_PARTITIONS/" /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml >> /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml.tmp && \
	mv /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml.tmp /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml
fi

if [ "$MAX_DYNAMIC_PARTITIONS_PER_NODE" != "" ]; then
	sed "s/MAX_DYNAMIC_PARTITIONS_PER_NODE/$MAX_DYNAMIC_PARTITIONS_PER_NODE/" /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml >> /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml.tmp && \
	mv /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml.tmp /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml
fi


export SPARK_POSTGRES_PASSWORD=$(cat $SPARK_SECRETS_PATH/SPARK_POSTGRES_PASSWORD)

sed "s/SPARK_POSTGRES_PASSWORD/$SPARK_POSTGRES_PASSWORD/" /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml >> /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml.tmp && \
mv /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml.tmp /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml
cp /opt/spark-2.1.0-bin-hadoop2.7/conf/hive-site.xml /opt/hadoop/etc/hadoop/

export POSTGRES_PASSWORD=$(cat $SPARK_SECRETS_PATH/POSTGRES_PASSWORD)
export PGPASSWORD=$POSTGRES_PASSWORD 

psql -h $POSTGRES_HOSTNAME -p $POSTGRES_PORT  -U $POSTGRES_USER -d $POSTGRES_DB -c "CREATE USER $SPARK_POSTGRES_USER WITH PASSWORD '$SPARK_POSTGRES_PASSWORD';"

psql -h $POSTGRES_HOSTNAME -p $POSTGRES_PORT  -U $POSTGRES_USER -d $POSTGRES_DB -c "CREATE DATABASE $SPARK_POSTGRES_DB;"

psql -h $POSTGRES_HOSTNAME -p $POSTGRES_PORT  -U $POSTGRES_USER -d $POSTGRES_DB -c "grant all PRIVILEGES on database $SPARK_POSTGRES_DB to $SPARK_POSTGRES_USER;" 

cd /opt/spark-2.1.0-bin-hadoop2.7/jars

export PGPASSWORD=$SPARK_POSTGRES_PASSWORD

psql -h $POSTGRES_HOSTNAME -p $POSTGRES_PORT  -U  $SPARK_POSTGRES_USER -d $SPARK_POSTGRES_DB -f /opt/spark-2.1.0-bin-hadoop2.7/jars/hive-schema-1.2.0.postgres.sql

hdfs dfs -mkdir /tmp
hdfs dfs -mkdir /tmp/hive 

#Check if there is no workaround this permissions
hdfs dfs -chmod -R 777 /tmp/hive




export NOTEBOOK_PASSWORD=$(cat $SPARK_SECRETS_PATH/NOTEBOOK_PASSWORD)

pass=$(python /opt/password.py  $NOTEBOOK_PASSWORD)
sed "s/#c.NotebookApp.password = u.*/c.NotebookApp.password = u\'$pass\'/" /root/.jupyter/jupyter_notebook_config.py >> /root/.jupyter/jupyter_notebook_config.py.tmp && \
mv /root/.jupyter/jupyter_notebook_config.py.tmp /root/.jupyter/jupyter_notebook_config.py


if [ "$EX_MEM" != "" ]; then
	sed "s/EX_MEM/$EX_MEM/" /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf >> /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf.tmp && \
	mv /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf.tmp /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf
fi
if [ "$EX_CORES" != "" ]; then
	sed "s/EX_CORES/$EX_CORES/" /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf >> /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf.tmp && \
	mv /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf.tmp /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf
fi
if [ "$DRIVER_MEM" != "" ]; then
	sed "s/DRIVER_MEM/$DRIVER_MEM/" /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf >> /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf.tmp && \
	mv /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf.tmp /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf
fi
if [ "$DRIVER_CORES" != "" ]; then
	sed "s/DRIVER_CORES/$DRIVER_CORES/" /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf >> /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf.tmp && \
	mv /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf.tmp /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf
fi

if [ "$SPARK_NETWORK_TIMEOUT" != "" ]; then
	sed "s/SPARK_NETWORK_TIMEOUT/$SPARK_NETWORK_TIMEOUT/" /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf >> /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf.tmp && \
	mv /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf.tmp /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf
fi
if [ "$SPARK_RPC_TIMEOUT" != "" ]; then
	sed "s/SPARK_RPC_TIMEOUT/$SPARK_RPC_TIMEOUT/" /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf >> /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf.tmp && \
	mv /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf.tmp /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf
fi

if [ "$SPARK_RPC_NUM_RETRIES" != "" ]; then
	sed "s/SPARK_RPC_NUM_RETRIES/$SPARK_RPC_NUM_RETRIES/" /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf >> /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf.tmp && \
	mv /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf.tmp /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf
fi

if [ "$SPARK_HEARTBEAT" != "" ]; then
	sed "s/SPARK_HEARTBEAT/$SPARK_HEARTBEAT/" /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf >> /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf.tmp && \
	mv /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf.tmp /opt/spark-2.1.0-bin-hadoop2.7/conf/spark-defaults.conf
fi

export TERM=xterm


if [ "$MODE" == "" ]; then
MODE=$1
fi

CLASSPATH=/opt/spark-2.1.0-bin-hadoop2.7/jars/

if [ "$MODE" == "master" ]; then 
	${SPARK_HOME}/bin/spark-class "org.apache.spark.deploy.master.Master" -h $SPARK_MASTER_HOSTNAME --port $SPARK_MASTER_PORT --webui-port $SPARK_MASTER_WEBUI_PORT &
	jupyter notebook --ip=0.0.0.0 --log-level DEBUG --allow-root --NotebookApp.iopub_data_rate_limit=10000000000 --Spark.url="http://$SPARK_PUBLIC_DNS:$SPARK_UI_PORT"

elif [ "$MODE" == "worker" ]; then
	${SPARK_HOME}/bin/spark-class "org.apache.spark.deploy.worker.Worker" --webui-port $SPARK_WORKER_WEBUI_PORT --port $SPARK_WORKER_PORT $SPARK_MASTER_URL -c $CORES -m $MEM -d $NOTEBOOK_DIR/$SPARK_PUBLIC_DNS/work/

elif [ "$MODE" == "thrift" ]; then 
	${SPARK_HOME}/bin/spark-class "org.apache.spark.deploy.master.Master" -h $SPARK_MASTER_HOSTNAME --port $SPARK_MASTER_PORT --webui-port $SPARK_MASTER_WEBUI_PORT &
	${SPARK_HOME}/bin/spark-submit --class org.apache.spark.sql.hive.thriftserver.HiveThriftServer2 --name "Thrift JDBC/ODBC Server"  --master $SPARK_MASTER_URL
else
	${SPARK_HOME}/bin/spark-class "org.apache.spark.deploy.master.Master" -h $SPARK_MASTER_HOSTNAME --port $SPARK_MASTER_PORT --webui-port $SPARK_MASTER_WEBUI_PORT &
	${SPARK_HOME}/bin/spark-class "org.apache.spark.deploy.worker.Worker" --webui-port $SPARK_WORKER_WEBUI_PORT --port $SPARK_WORKER_PORT $SPARK_MASTER_URL	-c $CORES -m $MEM -d $NOTEBOOK_DIR/$SPARK_PUBLIC_DNS/work/ &
	jupyter notebook --ip=0.0.0.0 --log-level DEBUG --allow-root --NotebookApp.iopub_data_rate_limit=10000000000 --Spark.url="http://$SPARK_PUBLIC_DNS:$SPARK_UI_PORT"
fi
