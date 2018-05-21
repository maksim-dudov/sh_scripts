#!/bin/sh

DBNAME=database
USER=root
PASS=password
RPASS=password

echo '\n'
echo 'STARTED at'
date +"%Y-%m-%d %H:%M:%S"


echo 'Starting create dump...'
echo '- stopping SLAVE...'
ssh root@127.0.0.1 'mysql --password=password --user=root << EOF
stop slave
EOF
'
echo ' ok!\n'

echo ' getting exec_master_log_position... \n'

SLAVE_STATUS_INFO=$(ssh root@127.0.0.1 "mysql --user=$USER --password=$RPASS -e \"show slave status\G\"")
echo $SLAVE_STATUS_INFO > slave_status.txt
SLAVE_IO_RUNNING=$(echo "$SLAVE_STATUS_INFO" | grep Slave_IO_Running | awk '{ print $2 }')
MASTER_LOG_POS=$(echo "$SLAVE_STATUS_INFO" | grep Exec_Master_Log_Pos | awk '{ print $2 }')
MASTER_LOG_FILE=$(echo "$SLAVE_STATUS_INFO" | sed -e 's/^[[:space:]]*//' | grep ^Master_Log_File | awk '{ print $2 }')

echo '\n'
echo 'check slave'
echo "Slave_SQL_Running: $Slave_SQL_Running Slave_IO_Running: $Slave_IO_Running"
if [ "$Slave_IO_Running" = "No" ] || [ "$Slave_SQL_Running" = "No" ]; then
        echo "Slave has died. "
        echo "Slave has died \n\n $SLAVE_STATUS_INFO" | mail -s "slave has died" some_email@mail.ru
		exit
else
	echo "slave is okey\n"
fi

echo ' got: '
echo 'MASTER_LOG_POS: '$MASTER_LOG_POS
echo 'MASTER_LOG_FILE: '$MASTER_LOG_FILE
echo ' \n'

echo '- making dump...'
NAME_PREFIX=_EMLP_
SQL_DUMP_NAME=$DBNAME$NAME_PREFIX$MASTER_LOG_POS'-'$MASTER_LOG_FILE.sql
echo $SQL_DUMP_NAME
ssh root@127.0.0.1 "mysqldump $DBNAME -u root --password=password > /path/to/file/$SQL_DUMP_NAME"
echo ' ok!\n'
echo '- starting SLAVE...'
ssh root@127.0.0.1 'mysql --password=password --user=root << EOF
start slave
EOF
'
echo ' ok!\n'
echo 'Done.\n'


date +"%Y-%m-%d %H:%M:%S"
echo 'Compress dump...'
ssh root@127.0.0.1 "
cd /path/to/file/;
tar -czf $DBNAME.sql.tar.gz $SQL_DUMP_NAME;
"
echo 'Done.\n'






date +"%Y-%m-%d %H:%M:%S"
echo 'Copy dump to Somewhere...'
nice -n 19 scp root@127.0.0.1:/path/to/file/database.sql.tar.gz /path/to/file/
echo 'Done.\n'

date +"%Y-%m-%d %H:%M:%S"
echo 'Remove sql file...'
ssh root@127.0.0.1 "
cd /path/to/file/;
rm -v $SQL_DUMP_NAME;
"
echo 'Done.\n'


date +"%Y-%m-%d %H:%M:%S"
echo 'Rotate local dumps...'
ssh root@127.0.0.1 'savelog -l -c 40 /path/to/file/database.sql.tar.gz'
echo 'Done.\n'

date +"%Y-%m-%d %H:%M:%S"
echo 'Rotate remote dumps...'
nice -n 20 savelog -l -c 9 /path/to/file/database.sql.tar.gz
echo 'Done.\n'


echo 'FINISHED at'
date +"%Y-%m-%d %H:%M:%S"