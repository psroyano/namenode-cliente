FROM uhadoop

LABEL maintainer="Pedro Santos" \
      version="2.0"

#Instalamos: MySQL server para el metastore de Hive. Jupyter para ejecutar programas. Dsdmainutils para herramienta hexdump
RUN   apt-get -q update && \
      apt-get -q install -y mysql-server bsdmainutils jupyter && \
      apt-get clean && \
      rm -rf /var/lib/apt/lists/*
      
# Desactivación autentificación Jupyter Notebooks
RUN mkdir -p /root/.jupyter && \
    touch /root/.jupyter/jupyter_notebook_config.py && \
    echo "c.NotebookApp.token = ''" >> /root/.jupyter/jupyter_notebook_config.py && \
    echo "c.NotebookApp.password = ''" >> /root/.jupyter/jupyter_notebook_config.py


#Instalación Apache Hive 3.1.2
RUN wget https://ftp.cixug.es/apache/hive/hive-3.1.2/apache-hive-3.1.2-bin.tar.gz && \
    tar -xvzf apache-hive-3.1.2-bin.tar.gz -C /app && \
    rm apache-hive-3.1.2-bin.tar.gz && \
    rm /app/apache-hive-3.1.2-bin/lib/log4j-slf4j-impl-2.10.0.jar
ENV HIVE_HOME /app/apache-hive-3.1.2-bin
ENV HCAT_HOME $HIVE_HOME/hcatalog
ENV PATH $PATH:$HIVE_HOME/bin
COPY /hiveconf/hive-site.xml $HIVE_HOME/conf/
COPY /hiveconf/hcat_server.sh $HIVE_HOME/hcatalog/sbin/
COPY /hiveconf/mysql-connector-java-8.0.23.jar $HIVE_HOME/lib/


#Instalación Apache Pig
RUN wget https://ftp.cixug.es/apache/pig/pig-0.17.0/pig-0.17.0.tar.gz && \
    tar -xvzf pig-0.17.0.tar.gz -C /app && \
    rm pig-0.17.0.tar.gz 	 
ENV PIG_HOME /app/pig-0.17.0
ENV PATH $PATH:$PIG_HOME/bin

#Instalación Apache Flume 1.9.0
RUN wget https://ftp.cixug.es/apache/flume/1.9.0/apache-flume-1.9.0-bin.tar.gz && \
    tar -xvzf apache-flume-1.9.0-bin.tar.gz -C /app && \
    rm apache-flume-1.9.0-bin.tar.gz && \
    rm /app/apache-flume-1.9.0-bin/lib/guava-11.0.2.jar #incompatible con versión en hadoop
ENV FLUME_HOME /app/apache-flume-1.9.0-bin 
ENV PATH $PATH:$FLUME_HOME/bin


#Instalación Apache Sqoop 
RUN wget https://ftp.cixug.es/apache/sqoop/1.4.7/sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz && \
    tar -xvzf sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz -C /app && \
    rm sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz && \ 	
    cp $HIVE_HOME/lib/hive-common-3.1.2.jar $HIVE_HOME/lib/commons-lang-2.6.jar /app/sqoop-1.4.7.bin__hadoop-2.6.0/lib 
ENV SQOOP_HOME /app/sqoop-1.4.7.bin__hadoop-2.6.0
ENV PATH $PATH:$SQOOP_HOME/bin


#Instalación MrJob y avro-python
RUN pip install mrjob avro-python3

#Copiamos datasets
COPY ./dataset /dataset

#Formateo HDFS
RUN mkdir -p /hdfs/namenode && \
    hdfs namenode -format

#Schematool
RUN /etc/init.d/mysql start && \
    mysql -e "CREATE USER 'hive'@'localhost' IDENTIFIED BY 'ubigdata'" && \
    mysql -e "GRANT ALL PRIVILEGES ON * . * TO 'hive'@'localhost'"	&& \
    schematool -dbType mysql -initSchema
 
 
EXPOSE 9870 8889 10002
