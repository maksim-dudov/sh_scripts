#!/bin/sh

PATH_TO_BACKUPS="/path/to/backups/"
TMP_DIR="/path/to/tmp/dir/"
USER=root
PASS=password
DBNAME=db_name
EXTENSION=.sql.tar.gz.0
LAST_BACKUP_NAME=$DBNAME$EXTENSION

echo '\n'
echo 'STARTED at'
date +"%Y-%m-%d %H:%M:%S"

SLAVE_STATUS_INFO=$(mysql --user=$USER --password=$PASS -e "show slave status\G")
Slave_IO_Running=$(echo "$SLAVE_STATUS_INFO" | grep Slave_IO_Running | awk '{ print $2 }')
Slave_SQL_Running=$(echo "$SLAVE_STATUS_INFO" | grep Slave_SQL_Running | awk '{ print $2 }')
MASTER_LOG_POS=$(echo "$SLAVE_STATUS_INFO" | grep Exec_Master_Log_Pos | awk '{ print $2 }')
echo '\n'
echo 'check slave'
echo "Slave_SQL_Running: $Slave_SQL_Running Slave_IO_Running: $Slave_IO_Running"
if [ "$Slave_IO_Running" = "No" ] || [ "$Slave_SQL_Running" = "No" ]; then
<------>echo "extract archive "
<------>tar -x --directory=$TMP_DIR -f $PATH_TO_BACKUPS$LAST_BACKUP_NAME
else
<------>echo 'stop'
<------>exit
fi

MASTER_LOG_POS=$( ls $TMP_DIR | grep -o -E '[0-9]+' | sed -n 1p )
MASTER_BIN_LOG_FILE='mysql-bin.'$( ls $TMP_DIR | grep -o -E '[0-9]+' | sed -n 2p )
SQL_DUMP_NAME=$( ls $TMP_DIR )

echo "stop slave and clear database $DBNAME"
mysql -u $USER --password=$PASS << EOF
STOP SLAVE;
DROP DATABASE $DBNAME;
CREATE DATABASE $DBNAME;
EOF
echo "push dump to db $TMP_DIR$SQL_DUMP_NAME"
mysql -u $USER --password=$PASS $DBNAME < $TMP_DIR$SQL_DUMP_NAME
echo "ok"
echo "\n"
echo "set posistion $MASTER_LOG_POS and run slave"
mysql -u $USER --password=$PASS << EOF
RESET SLAVE;
CHANGE MASTER TO MASTER_LOG_FILE = '$MASTER_BIN_LOG_FILE', MASTER_LOG_POS = $MASTER_LOG_POS;
START SLAVE;
EOF
echo "ok"
echo "\n"
mysql -u $USER --password=$PASS -e "SHOW SLAVE STATUS\G"
echo "\n"

echo "clear tmp dir $TMP_DIR"
rm $TMP_DIR$SQL_DUMP_NAME