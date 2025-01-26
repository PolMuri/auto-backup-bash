#!/bin/bash

# ---------------------------------------------
# Script de còpies de seguretat per a bases de dades
# ---------------------------------------------

# Credencials de la base de dades a mode d'exemple
DB_USER="pol1"
DB_PASS="pol1"
DB_NAME="web1"
TABLE_NAME="formulari"

# Directori de còpies de seguretat i altres variables
LOCAL_BACKUP_DIR="/home/poldebian/backups"
DEST_DIR="/home/ubackup/backups"
REPORT_FILE="/home/poldebian/reports/report.txt"
BACKUP_HOST="ubackup@192.168.1.16"
SSH_KEY="/home/poldebian/.ssh/id_rsaubackup"
TMPFILE="/home/poldebian/tmp/backup_files.tmp"  # Fitxer temporal per la llista de fitxers
CMDFILE="/home/poldebian/tmp/delete_commands.sh" # Fitxer temporal per les comandes de borrat
TODAY=$(date +%Y%m%d)
YESTERDAY=$(date +%Y%m%d --date "yesterday")
DAY_OF_MONTH=$(date +%d)
TDATE=$(date +%Y%m%d --date "7 days ago")  # Data límit per fitxers generals (fa 7 dies)
YDATE=$(date +%Y%m%d --date "1 year ago") # Data límit per fitxers antics (fa 1 any)

# Assegurem que els directoris existeixen
mkdir -p ${LOCAL_BACKUP_DIR}
mkdir -p $(dirname ${TMPFILE})

# Creem el fitxer d'informe
echo "Report-copia-de-seguretat-web1" > ${REPORT_FILE}
echo "----------------------------------------------" >> ${REPORT_FILE}

# ---------------------------------------------
# Realitzem la còpia de seguretat
# ---------------------------------------------
echo "[`date '+%Y-%m-%d %H:%M:%S%z'`]: Realitzant còpia de seguretat" >> ${REPORT_FILE}
mysqldump -u ${DB_USER} -p${DB_PASS} ${DB_NAME} ${TABLE_NAME} > ${LOCAL_BACKUP_DIR}/backup-${TODAY}.sql
gzip -f ${LOCAL_BACKUP_DIR}/backup-${TODAY}.sql
echo "[`date '+%Y-%m-%d %H:%M:%S%z'`]: Còpia de seguretat completada" >> ${REPORT_FILE}

# ---------------------------------------------
# Creem el directori remot (si no existeix)
# ---------------------------------------------
sftp -i ${SSH_KEY} ${BACKUP_HOST} <<EOF
mkdir ${DEST_DIR} || true
bye
EOF

# ---------------------------------------------
# Esborrar còpies de seguretat antigues del servidor
# ---------------------------------------------
echo "[`date '+%Y-%m-%d %H:%M:%S%z'`]: Esborrant còpies de seguretat antigues" >> ${REPORT_FILE}

# Generem la llista de fitxers del directori remot
sftp -i ${SSH_KEY} ${BACKUP_HOST} <<EOF > ${TMPFILE}
ls ${DEST_DIR}
bye
EOF

# Si hi ha fitxers a revisar
if [ -f "$TMPFILE" ]; then
    # Creem el fitxer que tindrà les comandes d'esborrat
    touch ${CMDFILE}

    # Carreguem la llista de fitxers a un array
    lista=($(<${TMPFILE}))

    # Iterem sobre la llista
    for ((FNO=0; FNO<${#lista[@]}; FNO+=9)); do
        FILENAME=${lista[$((FNO + 8))]}
        FDATE=${FILENAME:0:8}
        DAYDATE=${FDATE:6:2}

        # Comprovem si el fitxer s'ha d'eliminar
        if [[ ${FDATE} -lt ${TDATE} && ${DAYDATE} -ne "01" && ${DAYDATE} -ne "15" ]]; then
            echo "rm ${DEST_DIR}/${FILENAME}" >> ${CMDFILE}
        elif [[ ${FDATE} -lt ${YDATE} ]]; then
            echo "rm ${DEST_DIR}/${FILENAME}" >> ${CMDFILE}
        fi
    done

    # Executem les comandes d'eliminació
    sftp -i ${SSH_KEY} ${BACKUP_HOST} < ${CMDFILE}
    echo "[`date '+%Y-%m-%d %H:%M:%S%z'`]: Còpies de seguretat antigues eliminades" >> ${REPORT_FILE}
else
    echo "[`date '+%Y-%m-%d %H:%M:%S%z'`]: No s'han trobat fitxers/còpies de seguretat antigues a esborrar" >> ${REPORT_FILE}
fi

# ---------------------------------------------
# Pujar la còpia de seguretat al servidor
# ---------------------------------------------
echo "[`date '+%Y-%m-%d %H:%M:%S%z'`]: Pujant còpia de seguretat al servidor" >> ${REPORT_FILE}
sftp -i ${SSH_KEY} ${BACKUP_HOST} <<EOF
cd ${DEST_DIR}
put ${LOCAL_BACKUP_DIR}/backup-${TODAY}.sql.gz
bye
EOF
echo "[`date '+%Y-%m-%d %H:%M:%S%z'`]: Còpia de seguretat pujada correctament" >> ${REPORT_FILE}

# ---------------------------------------------
# Enviar l'informe per correu electrònic
# ---------------------------------------------
EMAIL="usuari@gmail.com"
echo "[`date '+%Y-%m-%d %H:%M:%S%z'`]: Enviant informe per correu electrònic" >> ${REPORT_FILE}
cat ${REPORT_FILE} | mutt -s "Informe de còpia de seguretat" ${EMAIL}
echo "[`date '+%Y-%m-%d %H:%M:%S%z'`]: Informe enviat a ${EMAIL}" >> ${REPORT_FILE}

# Fi de l'script
echo "[`date '+%Y-%m-%d %H:%M:%S%z'`]: Script finalitzat correctament" >> ${REPORT_FILE}
