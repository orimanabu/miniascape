#!/bin/bash

source ./subr.sh

dumpdir=/root/setup/dump
flavor=$(date '+%Y%m%d-%H%M%S')
database=ALL
table=ALL

while [[ $# > 1 ]]; do
	key="$1"
	shift
	case $key in
	-f|--flavor)
		flavor="$1"
		shift
		;;
	-t|--table)
		table="$1"
		shift
		;;
	-d|--database)
		database="$1"
		shift
		;;
	*)
		echo "unknown option: $key"
		;;
	esac
done

echo "* flavor=${flavor}"
echo "* table=${table}"
echo "* database=${vip}"

if [ x"${database}" = x"ALL" ]; then
	option_db_table="--all-databases"
else
	if [ x"${table}" = x"ALL" ]; then
		option_db_table="--database ${database}"
	else
		option_db_table="--skip-add-drop-table ${database} ${table}"
	fi
fi

dumpfile=${dumpdir}/dump.${flavor}.${database}.${table}.sql
echo "* dumpfile=${dumpdir}/dump.${flavor}.${database}.${table}.sql"

mkdir -p ${dumpdir}
do_command mysqldump -u${mysql_user} -p${mysql_password} --single-transaction --master-data=1 ${option_db_table} '>' ${dumpfile}
