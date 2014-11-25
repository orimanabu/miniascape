#!/bin/sh

source ./subr.sh

mysql_user=root
mysql_password=mysql

do_query "SHOW VARIABLES LIKE 'server_id';" -t
do_query "SHOW SLAVE STATUS\G"
do_query "SET GLOBAL SQL_SLAVE_SKIP_COUNTER=1;"
do_query "START SLAVE;"
do_query "SHOW SLAVE STATUS\G"
