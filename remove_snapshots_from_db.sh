ONED_CONF="/etc/one/oned.conf"
DB_CONF="$(sed -n '/^DB *= *\[/,/]/p' $ONED_CONF)"
DB_BACKEND="$(echo $DB_CONF | grep -oP 'BACKEND *= *.*' | awk -F'[, \t="]*' '{print $2}')"

if [ "$DB_BACKEND" == "mysql" ]; then
    DB_SERVER="$(echo $DB_CONF | grep -oP 'SERVER *= *.*' | awk -F'[, \t="]*' '{print $2}')"
    DB_PORT="$(echo $DB_CONF | grep -oP 'PORT *= *.*' | awk -F'[, \t="]*' '{print $2}')"
    DB_USER="$(echo $DB_CONF | grep -oP 'USER *= *.*' | awk -F'[, \t="]*' '{print $2}')"
    DB_PASSWD="$(echo $DB_CONF | grep -oP 'PASSWD *= *.*' | awk -F'[, \t="]*' '{print $2}')"
    DB_NAME="$(echo $DB_CONF | grep -oP 'DB_NAME *= *.*' | awk -F'[, \t="]*' '{print $2}')"
    [ "$DB_PORT" == 0 ] && DB_PORT=3306
else
    echo "error: $DB_BACKEND is not supported"
    exit 1
fi

MYSQL_CMD="mysql -N -u${DB_USER} -p${DB_PASSWD} -D${DB_NAME} -h${DB_SERVER}"
VMID=$1

VM_METADATA=$($MYSQL_CMD -e "SELECT body FROM vm_pool WHERE oid LIKE ${VMID};")
VM_METADATA_NEW=$(echo $VM_METADATA | sed -e 's|<DISK_SNAPSHOT_TOTAL_SIZE>.*</DISK_SNAPSHOT_TOTAL_SIZE>||g' -e 's|<SNAPSHOTS>.*</SNAPSHOTS>||g')

$MYSQL_CMD -e "UPDATE vm_pool SET body=${VM_METADATA_NEW} WHERE oid LIKE ${VMID};"
