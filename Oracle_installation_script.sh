#!/bin/bash -x
 
dir="/opt/oracle/otk/org_1.0"
if [ -d $dir ]
then
echo "Conf backup already available"
else
cp -pr /opt/oracle/otk/1.0 /opt/oracle/otk/org_1.0
echo "Backup created"
fi

source .parameter.ini
 
mkdir -p $REPO/otk $REPO/11203 $ORACLE_home
mkdir -p $REPO $DATA $BACKUP $oraInventory
chmod -R 0775 $REPO $DATA $BACKUP $oraInventory
 
date
echo "internet connectivity is required for Oracle Installation"
echo "Check internet connectivity"
ping 8.8.8.8 -c 2
if
[ $? -eq 0 ]
then
echo "Internet connectivity is fine"
else
echo "Fix the internect connectivity issue"
exit
fi
 
echo "yum install ksh wget "
yum install sshpass ksh wget zip unzip -y
if
[ $? -eq 0 ]
then
echo "ksh & wget installed"
else
echo "Manually install"
exit
fi
 
############Nested if required.#########################
echo "Oracle Repo Setup started"
cd /etc/yum.repos.d
wget http://public-yum.oracle.com/public-yum-$ORAPUB.repo
if
[ $? -eq 0 ]
then
echo "Oracle Repo Downloaded, Now downloading GPG-KEY"
wget https://public-yum.oracle.com/RPM-GPG-KEY-oracle-$ORAPUB -O /etc/pki/rpm-gpg/RPM-GPG-KEY-oracle
else
echo "Oracle Repo Key Download failed"
fi
 
 
date
echo "internet connectivity is required for Oracle Installation"
echo "Check internet connectivity"
ping 192.168.254.4 -c 2
if [[ $? -eq 0 ]] ;then
	echo "Internet connectivity is fine"
else
	echo "Fix the internect connectivity issue"
	exit 127
fi
 
echo "Software files transfer started"
date
sshpass -p $PASS scp  -o StrictHostKeyChecking=no  $USER@192.168.254.4:/data/isc/sw/3rd_party_sw/db/oracle_toolkit/Linux_x86_64/* /var/opt/oracle/otk/
echo "OTK sw files transfer Done"
date
LS=`ls $REPO/11203/p10404530_112030_Linux-*.zip | wc -l`
if [[ $LS -lt 2 ]]; then
	echo "Oracle sw files transfer started"
	sshpass -p $PASS scp  -o StrictHostKeyChecking=no  $USER@192.168.254.4:/data/isc/sw/3rd_party_sw/db/oracle/server/11.2.0.3/Linux_x86_64/p10404530_112030_Linux-*.zip $REPO/11203/
elif [[ $? -eq 0 ]];then
	echo "Oracle sw files transfer Done"
	date
else
	echo "Oracle sw files Already transfered"
fi
sshpass -p $PASS  scp  -o StrictHostKeyChecking=no $USER@192.168.254.4:/data/isc/sw/3rd_party_sw/db/OS_packages/Linux_x86_64/*.zip /var/opt/oracle/otk/
echo "OS files transfer Done"
date
echo "Software files transfer Completed"
 
 
ls -l /var/opt/oracle/otk/oratoolkit-1.0.2.1.5-1.noarch.rpm
if
[ $? -eq 0 ]
then
rpm -ivh /var/opt/oracle/otk/oratoolkit-1.0.2.1.5-1.noarch.rpm
mkdir -p /var/opt/oracle/otk/1.0/log
chown -R oracle:dba /var/opt/oracle
cp $REPO/otk/swInst*.cfg  /opt/oracle/otk/1.0/conf/installManager/.
cp $REPO/otk/*.rsp  /opt/oracle/otk/1.0/conf/installManager/response/.
cp -p $REPO/otk/*.sql /opt/oracle/otk/1.0/tools/
cp -p $REPO/otk/*.sh  /opt/oracle/otk/1.0/tools/
cp /opt/oracle/otk/1.0/conf/installManager/requirement/ora11gR2-redhat-6-x86_64.pkg.lst /opt/oracle/otk/1.0/conf/installManager/requirement/ora11gR2-redhat-7-x86_64.pkg.lst
else
echo "check OTK rpm installtion"
fi
 
 
echo 'Check Software server login & connectivity manually'
 
 
yum install oracle-rdbms-server-11gR2-preinstall -y
 
rm -f /etc/yum.repos.d/public-yum-ol7.repo
 
echo "Make changes in osSetup11gR2.cfg"
chmod +w /opt/oracle/otk/current/conf/installManager/osSetup11gR2.cfg
cd /opt/oracle/otk/current/conf/installManager/
sed -i '141s|OSDBA_DIRECTORIES="/data01 /data02 /backup01"|OSDBA_DIRECTORIES="/data /backup /opt/oracle /var/opt/oracle"|' /opt/oracle/otk/current/conf/installManager/osSetup11gR2.cfg
sed -i '150s|INVENTORY_GROUP_DIRECTORIES="/opt/oracle /var/opt/oracle /var/opt/oracle/repository"|INVENTORY_GROUP_DIRECTORIES="/data /backup /opt/oracle /var/opt/oracle /opt/oraInventory"|'  /opt/oracle/otk/current/conf/installManager/osSetup11gR2.cfg
sed -i '158s|INVENTORY_LOC="/opt/oracle/oraInventory"|INVENTORY_LOC="/opt/oraInventory"|' /opt/oracle/otk/current/conf/installManager/osSetup11gR2.cfg
 
echo "Make changes in libinstallManager.ksh"
chmod +w /opt/oracle/otk/1.0/lib/libinstallManager.ksh
sed -i '1273s/^/#/' /opt/oracle/otk/1.0/lib/libinstallManager.ksh
sed -i '1274s/^/#/' /opt/oracle/otk/1.0/lib/libinstallManager.ksh
sed -i '1327s/^/#/' /opt/oracle/otk/1.0/lib/libinstallManager.ksh
sed -i '1454s/^/#/' /opt/oracle/otk/1.0/lib/libinstallManager.ksh
echo "Make changes in libnetwork.ksh"
chmod +w /opt/oracle/otk/1.0/lib/libnetwork.ksh
sed -i '55s/^/#/' /opt/oracle/otk/1.0/lib/libnetwork.ksh
sed -i '56s/addLineToFile "TRACE_DIRECTORY_${LISTENER_NAME}=${TNS_TRACE}"/addLineToFile "ADR_BASE_${LISTENER_NAME}=${ADR_BASE}"/' /opt/oracle/otk/1.0/lib/libnetwork.ksh
#sed -i '57 i  addLineToFile "ADR_BASE_${LISTENER_NAME}=${ADR_BASE}"' /opt/oracle/otk/1.0/lib/libnetwork.ksh

sed -i 's|INVENTORY_LOCATION=/opt/oracle/oraInventory|INVENTORY_LOCATION=/opt/oraInventory|' /opt/oracle/otk/1.0/conf/installManager/response/$RESP_FILE
sed -i "s|ORACLE_HOSTNAME=xxxxxx|ORACLE_HOSTNAME=$HOSTNAME|g"  /opt/oracle/otk/1.0/conf/installManager/response/$RESP_FILE
sed -i "s/<SITE|COMPANY>/$site/g"   /opt/oracle/otk/home/.profile.custom.interactive
sed -i "s|${ORACLE_SID:-sidNotSet}|$ORA_SID|g"  /opt/oracle/otk/home/.profile.custom.interactive

 
chown -R oracle:dba $INSTALL
chown -R oracle:dba $BACKUP
chown -R oracle:dba $DATA
chown -R oracle:dba $REPO
chown -R oracle:dba $oraInventory
 
 
grep alias.custom /opt/oracle/otk/home/.profile.oracle | grep -v grep
if [ $? -eq 0 ]
then
echo "File already configured"
else
 /opt/oracle/otk/home/.profile.oracle
echo '# Description: Source custom specific aliases
#
if [ -f ~/.alias.custom ]; then
  source ~/.alias.custom
fi
# end' >> /opt/oracle/otk/home/.profile.oracle

echo "profile.oracle edited"
fi
 
 
>/opt/oracle/otk/home/.alias.custom
cat <<EOF >> /opt/oracle/otk/home/.alias.custom
. /opt/oracle/admin/$ORA_SID/setenv.ora
alias ll='ls -l'
alias pp='ps -ef|grep -v grep|grep '
alias del30='find . -type f -mtime +30 -exec rm {} \;'
alias cda='cd /opt/oracle/admin/$ORA_SID'
alias cdal='cd /opt/oracle/admin/$ORA_SID/diag/rdbms/$DB_NAME/$ORA_SID/trace'
alias cdo="cd $ORACLE_HOME"
alias sq='sqlplus / as sysdba'
alias sqh='rlwrap sqlplus / as sysdba'
alias SICAP='. /opt/oracle/admin/$ORA_SID/setenv.ora'
echo "------ running DBs ------------------------------------------------"
ps -ef|grep pmon |grep -v grep
echo "-------------------------------------------------------------------"
echo " "
EOF


 /opt/oracle/otk/current/bin/installManager osSetup osSetup11gR2.cfg



echo '################################################################################
#
# Description: Comma separated list of installManager actions for which this fi-
#              le can be used
#
# Example:     ACTION_LIST="envSetup,dbSetup"
#
ACTION_LIST="envSetup,dbSetup"
#
################################################################################
# START ENVIRONMENT SECTION
##
#
# Description: Database name
#
# Examples:    DB_NAME="test"
#              DB_NAME="prod"
#              DB_NAME="otk"
#              DB_NAME="<db_name>"
#
DB_NAME="$ORA_SID"
#export DB_NAME
#
################################################################################
#
# Description: System identifier known also as instance or SID. A SID manages
#               the database.
#
# Examples:    ORACLE_SID="$DB_NAME"
#              ORACLE_SID="OTK"
#
ORACLE_SID='$DB_NAME'
#
################################################################################
#
# Description: Oracle hostname
#
# Examples:    ORACLE_HOSTNAME="$HOSTNAME"
#              ORACLE_HOSTNAME="<hostname>"
#
ORACLE_HOSTNAME='$HOSTNAME'
#
################################################################################
#
# Description: Base directory of used Oracle release
#
# Examples:    ORACLE_HOME="$ORACLE_BASE/sesrv/10.2.0/db1"
#              ORACLE_HOME="$ORACLE_BASE/eesrv/10.2.0/db1"
#              ORACLE_HOME="$ORACLE_BASE/sesrv/11.1.0/db1"
#              ORACLE_HOME="$ORACLE_BASE/eesrv/11.1.0/db1"
#
ORACLE_HOME='$ORACLE_home'
#
################################################################################
#
# Description: Libraries of Oracle release
#
# Example:     ORACLE_HOME="$ORACLE_HOME/lib32"
#
ORACLE_LIB='$ORACLE_HOME'/lib
#
################################################################################
#
# Description: Directory of listener and netnames configuration files
#
# Examples:    TNS_ADMIN="$ORACLE_BASE/network"
#              TNS_ADMIN="$ORACLE_HOME/network/admin"
#
TNS_ADMIN='$ORACLE_base'/admin/'$ORACLE_SID'/network/admin
#
################################################################################
#
# Description: Directory where listener log files are written
#
# Example:     TNS_LOG="$OTK_LOG_BASE/network"
#              TNS_LOG="$ORACLE_BASE/network/log"
#              TNS_LOG="$ORACLE_HOME/network/log"
#
TNS_LOG='$ORACLE_base'/admin/'$ORACLE_SID'/network/log
#
################################################################################
#
# Description: Directory where listener log files are written
#
# Example:     TNS_TRACE="$OTK_LOG_BASE/network/trace"
#              TNS_TRACE="$ORACLE_BASE/network/trace"
#              TNS_TRACE="$ORACLE_HOME/network/trace"
#
TNS_TRACE='$ORACLE_base'/admin/'$ORACLE_SID'/network/trace

#
################################################################################
#
# Description: Directory of character sets
#
# Example:     ORA_NLS10='$ORACLE_HOME'/nls/data
#
ORA_NLS10='$ORACLE_HOME'/nls/data
#
################################################################################
#
# Description: National language character set for client (and database)
#
# Example:     NLS_LANG=".UTF8"
#              NLS_LANG=".WE8ISO8859P15"
#
NLS_LANG=".UTF8"
#
################################################################################
#
# Description: National date/time format
#
# Example:     NLS_DATE_FORMAT="DD.MM.YYYY HH24:MI:SS"
#
NLS_DATE_FORMAT="DD.MM.YYYY HH24:MI:SS"
#
################################################################################
#
# Description: Specifies the diagnostics directory for each database instance.
#
# Valid:       > 11.1
#
# Examples:    ADR_BASE="$OTK_VAR_BASE"
#              ADR_BASE="/var/opt/oracle/otk/1.0"
#              ADR_BASE="/u01/app/oracle"
#
ADR_BASE='$ORACLE_base'/admin/'$ORACLE_SID/'
#
################################################################################
#
# Description: Diagnostic home directory, includes sub directories like udump,
#              trace, alert und so on
#
# Example:     ADR_HOME="$ADR_BASE/diag/rdbms/$DB_NAME/$ORACLE_SID"
#              ADR_HOME="$ADMIN"
#
ADR_HOME='$ADR_BASE'/diag/rdbms/'$DB_NAME'/'$ORACLE_SID'
#
################################################################################
#
# Description: Specifies the directory where creation related scripts and logs
#              are stored.
#
# Example:     CREATE="$ADMIN/create"
#
CREATE='$ADMIN'/create
#
################################################################################
#
# Description: Contains non generic instance specific scripts
#
# Example:     SCRIPT="$ADMIN/scripts"
#
SCRIPTS='$ADMIN'/scripts
#
################################################################################
#
# Description: First data directory to store database relevant files. For not
#              clustered systems keep first example. On clustered systems use
#              for the first DB example 1, for the second example 2 and so on.
#              Example 4 corresponds to ASM directory path.
#
# Example:     DATA01="/data01/rdbms/${DB_NAME}"
#              DATA01="/data11/rdbms/${DB_NAME}"
#              DATA01="/data21/rdbms/${DB_NAME}"
#              DATA01="+DATA01/${DB_NAME}"
#              DATA01="<path>"
#
DATA01='$DATA'/'$DB_NAME'
#
################################################################################
#
# Description: Optional data directory to store database relevant files. For not
#              clustered systems keep first example. On clustered systems use
#              for the first DB example 1, for the second example 2 and so on.
#              Example 4 corresponds to ASM directory path.
#
# Example:     DATA02="/data02/rdbms/${DB_NAME}"
#              DATA02="/data12/rdbms/${DB_NAME}"
#              DATA02="/data22/rdbms/${DB_NAME}"
#              DATA02="+DATA02/${DB_NAME}"
#
DATA02='$DATA'/'${DB_NAME}'
#
################################################################################
#
# Description: Optional data directory to store further database relevant files.
#
# Example:     DATA03="/data03/rdbms/${DB_NAME}"
#              DATA03="/data13/rdbms/${DB_NAME}"
#              DATA03="/data23/rdbms/${DB_NAME}"
#
#DATA03='$DATA01'
#
################################################################################
#
# Description: Optional data directory to store further database relevant files.
#
# Example:     DATA03="/data04/rdbms/${DB_NAME}"
#              DATA03="/data14/rdbms/${DB_NAME}"
#              DATA03="/data24/rdbms/${DB_NAME}"
#
#DATA04='$DATA01'
#
################################################################################
#
# Description: Optional data directory to store further database relevant files.
#
# Example:     DATA05="/data05/rdbms/${DB_NAME}"
#              DATA05="/data15/rdbms/${DB_NAME}"
#              DATA05="/data25/rdbms/${DB_NAME}"
#
#DATA05='$DATA01'
#
################################################################################
#
# Description: First datafile directory, table location
#
# Example:     DATAFILE01="$DATA01/datafile"
#
DATAFILE01='$DATA01'/db1
#
################################################################################
#
# Description: Second datafile directory, index location
#
# Example:     DATAFILE02="$DATA02/datafile"
#
#DATAFILE02='$DATA02'/db1
#
################################################################################
#
# Description: Third datafile directory
#
# Example:     DATAFILE03="$DATA02/datafile"
#
#DATAFILE03="$DATA03/db1"
#
################################################################################
#
# Description: Fourth datafile directory
#
# Example:     DATAFILE04="$DATA04/datafile"
#
#DATAFILE04='$DATA02'/db1
#
################################################################################
#
# Description: Fifth datafile directory
#
# Example:     DATAFILE05="$DATA05/datafile"
#
#DATAFILE05='$DATA05'/db1
#
################################################################################
#
# Description: Destination where spfile is stored
#
# Examples:    SPFILE="$DATA01/pfile"
#              SPFILE="$DATA01/parameterfile"
#              SPFILE="$ADMIN/pfile"
#
SPFILE='$ADMIN'/pfile
#
################################################################################
#
# Description: Destination where password file is stored
#
# Examples:    PWFILE="/data01/rdbms/${DB_NAME}/pfile"
#              PWFILE="$ADMIN/pfile"
#
PWFILE='$ADMIN'/pfile
#
################################################################################
#
# Description: Specifies the directory of the first control file
#
# Example:     CONTROLFILE01="$DATA01/controlfile"
#
CONTROLFILE01='$DATA01'/db1
#
################################################################################
#
# Description: Specifies the directory of the second control file
#
# Example:     CONTROLFILE01="$DATA02/controlfile"
#
CONTROLFILE02='$DATA01'/rdo
#
################################################################################
#
# Description: Specifies the directory of the third control file
#
# Examples:    CONTROLFILE03=""
#              CONTROLFILE03="$DATA03/controlfile"
#
CONTROLFILE03='$DATA01'/db1
#
################################################################################
#
# Description: Specifies first redo log destination
#
# Example:     LOGFILE01="$DATA01/logfile"
#
LOGFILE01='$DATA01'/rdo
#
################################################################################
#
# Description: Specifies second redo log file destination
#
# Example:     LOGFILE02="$DATA02/logfile"
#
LOGFILE02='$DATA01'/rdo
#
################################################################################
#
# Description: Backup base directory
#
# Examples:    BACKUP_BASE="/backup01"
#              BACKUP_BASE="/backup11"
#              BACKUP_BASE="/backup21"
#              BACKUP_BASE="/backup"
#
BACKUP_BASE='$BACKUP'
#
################################################################################
#
# Description: Backup home directory where different backup types are stored
#
# Examples:    BACKUP_HOME="$BACKUP_BASE/rdbms"
#              BACKUP_HOME="$BACKUP_BASE"
#
BACKUP_HOME='$BACKUP_BASE'/rdbms
#
################################################################################
#
# Description: Backup area where physical backups are stored
#
# Examples:    BACKUP_AREA="$BACKUP_HOME/physical/$DB_NAME"
#              BACKUP_AREA="$BACKUP_HOME/rman/$DB_NAME"
#
BACKUP_AREA='$BACKUP_HOME'/physical/'$DB_NAME'
#
################################################################################
#
# Description: Flash recovery area managed by instance
#
# Example:     FLASH_AREA="$BACKUP_HOME/flasharea"
#              FLASH_AREA="+FLASH01"
#              FLASH_AREA="+FLASH02"
#
FLASH_AREA='$BACKUP_HOME'/flasharea

#
################################################################################
#
# Description: Flash recovery area size in GB
#
# Example:     FLASH_AREA_SIZE="16G"
#              FLASH_AREA_SIZE="128G"
#
FLASH_AREA_SIZE="2G"
#
################################################################################
#
# Description: Area where logical backups are stored
#
# Example:     DATAPUMP_AREA="$BACKUP_HOME/logical/$DB_NAME"
#              DATAPUMP_AREA="$BACKUP_HOME/datapump/$DB_NAME"
#
DATAPUMP_AREA='$BACKUP_HOME'/logical
#
################################################################################
#
# Description: Directory for PL/SQL file I/O operations
#
#
# Examples:    UTL="/data01/utl/$DB_NAME"
#              UTL="$ADMIN/utl"
#
UTL='$ADMIN'/utl
#
################################################################################
#
# Description: Archive directory
#
# Example:     ARCHIVE="$DATA01/archivelog"
#              ARCHIVE="/data03/rdbms/${DB_NAME}/archivelog"
#
ARCHIVE01='$DATA'/'$DB_NAME'/archive
#
################################################################################
#
# Description: Second optional archive directory
#
# Examples:    ARCHIVE02="$DATA02/archivelog"
#              ARCHIVE02="$BACKUP_AREA/archivelog"
#
ARCHIVE02='$ARCHIVE01'
#
##
# END ENVIRONMENT SECTION
################################################################################
# START DATABASE SECTION
##
# Description: Specifies (in bytes) the size of Oracle database blocks.
#              during a sequential scan.
#
# Examples:    DB_BLOCK_SIZE=4096
#              DB_BLOCK_SIZE=8192
#              DB_BLOCK_SIZE=16384
#
DB_BLOCK_SIZE=8192
#
################################################################################
#
# Description: Specifies the Character sets of database. Some possible values
#              could be UTF8, AL16UTF16, WE8ISO8859P15 and so on.
#
# Examples:    CHARACTER_SET=`echo $NLS_LANG|cut -d. -f2`
#              CHARACTER_SET="UTF8"
#              CHARACTER_SET="AL16UTF16"
#              CHARACTER_SET="WE8ISO8859P15"
#              CHARACTER_SET="and so on ..."
#
CHARACTER_SET="UTF8"
#
################################################################################
#
# Description: Specifies the National character set of the database. It is
#              usually set to UTF8 or AL16UTF16.
#
# Examples:    NCHARACTER_SET="UTF8"
#              NCHARACTER_SET="AL16UTF16"
#
NCHARACTER_SET="UTF8"
#
################################################################################
#
# Description: Specifies the size of a redo log file
#
# Examples:    LOGFILE_SIZE=32M
#              LOGFILE_SIZE=128M
#              LOGFILE_SIZE=512M
#
LOGFILE_SIZE='$REDOLOG_SIZE'
#
################################################################################
#
# Description: Specifies the number of a redo log groups
#
# Examples:    NUMBER_OF_LOGFILE_GROUPS=3
#              NUMBER_OF_LOGFILE_GROUPS=6
#
NUMBER_OF_LOGFILE_GROUPS=3
#
################################################################################
#
# Description: Specifies whether redo log files are being multiplexed or not
#
# Examples:    MULTIPLEXED_LOGFILES=TRUE
#              MULTIPLEXED_LOGFILES=FALSE
#
MULTIPLEXED_LOGFILES=TRUE
#
##
# END DATABASE SECTION
################################################################################
# START TABLESPACE SECTION
##
#
# Description: Specifies full path of system tablespace
#
# Example:     SYSTEM_TS="${DATAFILE01}/${DB_NAME}_system_01.dbf"
#
SYSTEM_TS='$DATAFILE01'/'$DB_NAME'_system_01.dbf
#
################################################################################
#
# Description: Specifies the size of the system tablespace
#
# Examples:    SYSTEM_SIZE=512M
#              SYSTEM_SIZE=1G
#
SYSTEM_SIZE=1G
#
################################################################################
#
# Description: Specifies full path of sysaux tablespace
#
# Example:     SYSAUX_TS="${DATAFILE01}/${DB_NAME}_sysaux_01.dbf"
#
SYSAUX_TS='$DATAFILE01'/'$DB_NAME'_sysaux_01.dbf
#
################################################################################
#
# Description: Specifies the size of the sysaux tablespace
#
# Examples:    SYSAUX_SIZE=512M
#              SYSAUX_SIZE=512M
#
SYSAUX_SIZE=1G
#
################################################################################
#
# Description: Specifies full path of temp tablespace
#
# Example:     SYSAUX_TS="${DATAFILE01}/${DB_NAME}_temp_01.dbf"
#
TEMP_TS='$DATAFILE01'/'$DB_NAME'_temp_01.dbf
#
################################################################################
#
# Description: Specifies the size of the temp tablespace
#
# Examples:    TEMP_SIZE=512M
#              TEMP_SIZE=2G
#
TEMP_SIZE=2G
#
################################################################################
#
# Description: Specifies full path of undo tablespace
#
# Example:     SYSAUX_TS="${DATAFILE01}/${DB_NAME}_undo_01.dbf"
#
UNDO_TS='$DATAFILE01'/'$DB_NAME'_undo_01.dbf
#
################################################################################
#
# Description: Specifies the size of the undo tablespace
#
# Examples:    UNDO_SIZE=512M
#              UNDO_SIZE=2G
#
UNDO_SIZE=2G
#
################################################################################
#
# Description: Specifies full path of users tablespace
#
# Example:     SYSAUX_TS="${DATAFILE01}/${DB_NAME}_users_01.dbf"
#
USERS_TS='$DATAFILE01'/'$DB_NAME'_users_01.dbf
#
################################################################################
#
# Description: Specifies the size of the users tablespace
#
# Examples:    USERS_SIZE=10M
#              USERS_SIZE=100M
#
USERS_SIZE=10M
#
##
#
# Syntax:
# VARIABLE=<tablespace_name>,<path>,<number of data files>,<file_size>M|G,<autoextend options>,<extent options>,<segment options>,<block size>
#
#TS1="TAB,$DATAFILE01,2,128M,AUTOEXTEND ON NEXT 128M MAXSIZE 30G,EXTENT MANAGEMENT LOCAL,SEGMENT SPACE MANAGEMENT AUTO,$DB_BLOCK_SIZE"
#TS2="IDX,$DATAFILE02,2,128M,AUTOEXTEND ON NEXT 128M MAXSIZE 30G,EXTENT MANAGEMENT LOCAL,SEGMENT SPACE MANAGEMENT AUTO,$DB_BLOCK_SIZE"
#TS3="TAB_MEDIUM,$DATAFILE01,2,64M,AUTOEXTEND ON NEXT 64M MAXSIZE 30G,EXTENT MANAGEMENT LOCAL UNIFORM SIZE 32M,SEGMENT SPACE MANAGEMENT AUTO,$DB_BLOCK_SIZE"
#TS4="IDX_MEDIUM,$DATAFILE02,2,32M,AUTOEXTEND ON NEXT 32M MAXSIZE 30G,EXTENT MANAGEMENT LOCAL UNIFORM SIZE 16M,SEGMENT SPACE MANAGEMENT AUTO,$DB_BLOCK_SIZE"
#TS5="TAB_LARGE,$DATAFILE01,5,1G,AUTOEXTEND ON NEXT 1G MAXSIZE 30G,EXTENT MANAGEMENT LOCAL UNIFORM SIZE 512M,SEGMENT SPACE MANAGEMENT AUTO,$DB_BLOCK_SIZE"
#TS6="IDX_LARGE,$DATAFILE02,5,512M,AUTOEXTEND ON NEXT 512M MAXSIZE 30G,EXTENT MANAGEMENT LOCAL UNIFORM SIZE 256M,SEGMENT SPACE MANAGEMENT AUTO,$DB_BLOCK_SIZE"
#
# Add here customized tablespace definitions
#
# Syntax:
# VARIABLE=<tablespace_name>,<path>,<number of data files>,<file_size>M|G,<autoextend options>,<extent options>,<segment options>,<block size>
#
#TS7="<TS_NAME>,$DATAFILE01,2,1G,AUTOEXTEND ON NEXT 1G MAXSIZE 30G,EXTENT MANAGEMENT LOCAL,SEGMENT SPACE MANAGEMENT AUTO,$DB_BLOCK_SIZE"
#
# Assign tablespace to tablespace list
#
# Examples: TS_LIST="$TS1:$TS2:$TS3:$TS4:$TS5:$TS6:TS7"
#           TS_LIST="$TS1:$TS2:$TS3:$TS4:$TS5:$TS6"
#           TS_LIST="$TS1:$TS2"
#
#TS_LIST='$TS1':'$TS2'
#
# Default tablespace for table segments
#
#DEFAULT_TAB_TS="TAB"
#
#
# Default tablespace for index segments
#
#DEFAULT_IDX_TS="IDX"
#
##
# END TABLESPACE SECTION
#################################################################################
# START DB USER SECTION
##
#
# Description: Password of db user SYS. SYS is corresponds to user root in OS
#              terms. It is the most powerful user and should therfore be used
#              for admin operations like start and shutdown of the database. Use
#              SYSTEM user for normal admin tasks.
#
# Examples:    PASSWORD_SYS="manager"
#              PASSWORD_SYS="install"
#
PASSWORD_SYS="manager"
#
################################################################################
#
# Description: Password of db user SYSTEM. System has DBA priviledges and can be
#              used for admin purpose like tablespace management, tuning and so
#              on.
#
# Examples:    PASSWORD_SYSTEM="manager"
#              PASSWORD_SYSTEM="install"
#
PASSWORD_SYSTEM="manager"
#
################################################################################
#
# Description: Password of db user OTK. OTK is the user of oracle tool kit, it
#              stored database objects which are using by its shell scripts and
#              provides as well common PL/SQL interfaces which can be used by
#              other DB users.
#
# Example:     PASSWORD_OTK="otk"
#
PASSWORD_OTK="otk"
#
################################################################################
#
# Description: Password of db user HAPROBE. HAPROBE is used by cluster agents to
#              monitor database availability in high availability (HA) environ-
#              ments.
#
# Example:     PASSWORD_HAPROBE="haprobe"
#
PASSWORD_HAPROBE="haprobe"
#
################################################################################
#
# Description: Password of db user PERFSTAT.
#
# Example:     PASSWORD_HAPROBE="perfstat"
#
PASSWORD_PERFSTAT="perfstat"
#
##
# END DB USER SECTION
################################################################################
# START INSTALL MANAGER SECTION
##
# Description: Specifies a period in days where database can be destroyed using
#              FORCE create mode. Note that grace test can be disabled, see next
#              variable GRACE_TEST.
#
# Examples:    GRACE_PERIOD="1"
#              GRACE_PERIOD="7"
#
GRACE_PERIOD="1"
#
################################################################################
#
# Description: Specifies whether or not grace test is enabled
#
# Examples:    GRACE_TEST="ENABLED"
#              GRACE_TEST="DISABLED"
#
GRACE_TEST="ENABLED"
#
################################################################################
#
# Description: Specify whether or not DB and listener are controlled by ctl. For
#              more information on ctl visit http://appctl.sourceforge.net/ .
#
# Examples:    APPCTL_ENABLED="TRUE"
#              APPCTL_ENABLED="FALSE"
#
APPCTL_ENABLED="TRUE"
#
################################################################################
#
# Description: Specify the usage of the database. Based on the usage object pro-
#              tection will be enabled resp. diabled. For more information on
#              object protection refer to OTK documentation.
#
# Examples:    DB_USAGE="TEST"          <- protection disabled
#              DB_USAGE="DEVELOPMENT"   <- protection disabled
#              DB_USAGE="PREPRODUCTION" <- protection enabled
#              DB_USAGE="PRODUCTION"    <- protection enabled
#              DB_USAGE="REFERENCE"     <- protection enabled
#
DB_USAGE='$USAGE'
#
################################################################################
#
# Description: Defines whether or not archiving of redo log files is enabled.
#              Use TRUE for production and pre-production environment. Use FALSE
#              if data loss can be afforded.
#
# Examples:    LOG_ARCHIVE_ENABLED="TRUE"
#              LOG_ARCHIVE_ENABLED="FALSE"
#
LOG_ARCHIVE_ENABLED="TRUE"
#
################################################################################
#
# Description: Defines the mount points which will have to be mounted on the ho-
#              st in order to start creation of the database. Those are required
#              to make sure that data files are stored in the right file system.
#              clustered environments this coresponds to devices on shared media
#              dia. Child directories of those mount points will in envSetup
#              execution mode not be created.
#
# Examples:    MOUNT_POINTS="/data01,/data02,/backup01"
#              MOUNT_POINTS="/data11,/data12,/backup11"
#
MOUNT_POINTS="/"
#
# END INSTALL MANAGER SECTION
################################################################################
# START NETWORK SECTION
##
# Description: Name of the listener which will be used in listener.ora file
#
# Example:     LISTENER_NAME=`upper $DB_NAME`
#              LISTENER_NAME="LISTENER"
#
LISTENER_NAME='$DB_NAME'
#
################################################################################
#
# Description: Hostname or IP address of the listener
#
# Examples:    LISTENER_HOSTNAME="$ORACLE_HOSTNAME"
#              LISTENER_HOSTNAME="localhost"
#
LISTENER_HOSTNAME='$ORACLE_HOSTNAME'
#
################################################################################
#
# Description: Port number of the listener
#
# Examples:    LISTENER_PORT="1521"
#              LISTENER_PORT="1531"
#
LISTENER_PORT='$DB_PORT'
#
################################################################################
#
# Description: Name of the local listener which will used as instance parameter
#              in init<SID>.ora, spfile<SID>.ora and as well as connect
#              descriptor in tnsnames.ora.
#
# Example:     LOCAL_LISTENER="LIS_${LISTENER_NAME}"
#
LOCAL_LISTENER=LIS_'$LISTENER_NAME'
#
################################################################################
#
# Description: Comma separated list of services on which the listener will
#              listen.
#
# Examples:    SERVICE_NAMES="$DB_NAME.$DB_DOMAIN"
#              SERVICE_NAMES="VCA,OTA,DMC,MMG,DS"
#
SERVICE_NAMES='$DB_NAME'
#
##
# END NETWORK SECTION
################################################################################
# START ANSI COMPLIANCE SECTION
##
#
# EMPTY
#
##
# END ANSI COMPLIANCE SECTION
################################################################################
# START BACKUP AND RESTORE SECTION
##
#
# EMPTY
#
##
# END BACKUP AND RESTORE SECTION
################################################################################
# START BFILES SECTION
##
#
# EMPTY
#
##
# END BFILES SECTION
################################################################################
# START BACKUP AND RESTORE SECTION
##
#
#Empty
#
##
# END BACKUP AND RESTORE SECTION
################################################################################
# START CURSORS AND LIBRARY CACHE SECTION
##
# Description: Specifies the maximum number of open cursors a session can have
#              at once.
#
# Example:     OPEN_CURSORS=1000
#
OPEN_CURSORS=1000
#
##
# END CURSORS AND LIBRARY CACHE SECTION
################################################################################
# START DATABASE/INSTANCE IDENTIFICATION SECTION
##
# Description: Specifies the logical location of the database within the network
#              structure.
#
# Examples:    DB_DOMAIN=""
#              DB_DOMAIN="WORLD"
#              DB_DOMAIN="<COMPANY>.COM"
#
DB_DOMAIN=""
#
##
# END DATABASE/INSTANCE IDENTIFICATION SECTION
################################################################################
# START DIAGNOSTICS AND STATISTICS SECTION
##
# Description: Specifies the maximum size of trace files (excluding the alert
#              file).
#
# Examples:    MAX_DUMP_FILE_SIZE=10M
#              MAX_DUMP_FILE_SIZE=UNLIMITED
#
MAX_DUMP_FILE_SIZE=10M
#
################################################################################
#
# Description: Specifies the level of collection for database and operating
#              system statistics. The Oracle Database collects these statistics
#              for a variety of purposes, including making self-management
#              decisions.
#
# Examples:    STATISTICS_LEVEL="TYPICAL"
#              STATISTICS_LEVEL="ALL"
#              STATISTICS_LEVEL="BASIC"
#
STATISTICS_LEVEL="TYPICAL"
#
##
# END DIAGNOSTICS AND STATISTICS SECTION
################################################################################
# START DISTRIBUTED, REPLICATION SECTION
##
# Description: Specifies whether a database link is required to have the same
#              name as the database to which it connects.
#
# Examples:    GLOBAL_NAMES="FALSE"
#              GLOBAL_NAMES="TRUE"
#
GLOBAL_NAMES="FALSE"
#
##
# END DISTRIBUTED, REPLICATION SECTION
################################################################################
# START FILE LOCATIONS, NAMES, AND SIZES SECTION
##
#
# EMPTY
#
##
# END FILE LOCATIONS, NAMES, AND SIZES SECTION
################################################################################
# START GLOBALIZATION SECTION
##
# Description: NLS numeric characters parameter
#
# Example:     NLS_NUMERIC_CHARACTERS="'.,'"
#
NLS_NUMERIC_CHARACTERS="'.,'"
#
################################################################################
#
# Description: NLS language parameter
#
# Example:     NLS_LANGUAGE="AMERICAN"
#
NLS_LANGUAGE="AMERICAN"
#
################################################################################
#
# Description: NLS territory parameter
#
# Example:     NLS_TERRITORY="AMERICA"
#
NLS_TERRITORY="AMERICA"
#
##
# END GLOBALIZATION SECTION
################################################################################
# START JAVA SECTION
##
#
# EMPTY
#
##
# END JAVA SECTION
################################################################################
# START JOB QUEUES SECTION
##
# Description: Job queue process parameter
#
# Example:     JOB_QUEUE_PROCESSES=5
#
JOB_QUEUE_PROCESSES=5
#
##
# END JOB QUEUES SECTION
################################################################################
# START LICENSE LIMITS SECTION
##
#
# EMPTY
#
##
# END LICENSE LIMITS SECTION
################################################################################
# START MEMORY, SGA, BUFFER CACHE, AND I/O SECTION
##
# Description: Specifies the total size of all SGA components (buffer cache,
#              shared pool, large pool, java pool and newly on 11g also streams
#              pool).
#
# Version:     >= 11.1
#
# Examples:    MEMORY_TARGET=356M
#              MEMORY_TARGET=2G
#
MEMORY_TARGET='$MEM'
#
################################################################################
#
# Description: Specifies the total size of all SGA components (buffer cache,
#              shared pool, large pool, java pool and newly on 11g also streams
#              pool).
#
# Version:     >= 11.1
#
# Examples:    MEMORY_MAX_TARGET=356M
#              MEMORY_MAX_TARGET=2G
#
MEMORY_MAX_TARGET='$MEMORY_TARGET'
#
################################################################################
#
# Description: Specifies the total size of all SGA components (buffer cache,
#              shared pool, large pool, java pool and newly on 11g also streams
#              pool).
#
# Examples:    SGA_TARGET=256M
#              SGA_TARGET=2G
#
SGA_TARGET=288M
#
################################################################################
#
# Description: Specifies the target aggregate PGA memory available to all server
#              processes attached to the instance..
#
# Examples:    PGA_AGGREGATE_TARGET="100M"
#
PGA_AGGREGATE_TARGET="100M"
#
################################################################################
#
# Description: Specifies the size of the DEFAULT buffer pool for buffers with
#              the primary block size.
#
# Examples:    DB_CACHE_SIZE=0
#              DB_CACHE_SIZE=1G
#
DB_CACHE_SIZE=0
#
################################################################################
#
# Description: Specifies the size of the Java pool
#
# Examples:    JAVA_POOL_SIZE=16M
#              JAVA_POOL_SIZE=64M
#
JAVA_POOL_SIZE=16M
#
################################################################################
#
# Description: Specifies the size of the large pool
#
# Examples:    LARGE_POOL_SIZE=0
#              LARGE_POOL_SIZE=0
#
LARGE_POOL_SIZE=0
#
################################################################################
#
# Description: Specifies the amount of memory (in bytes) that Oracle uses when
#              buffering redo entries to a redo log file.
#
# Examples:    LOG_BUFFER=`expr 512 \* 1024`
#              LOG_BUFFER=`expr 1024 \* 1024`
#              LOG_BUFFER=`expr 2048 \* 1024`
#
#LOG_BUFFER=`expr 512 \* 1024`
LOG_BUFFER=0
#
################################################################################
#
# Description: Specifies the size of the shared pool
#
 
# Examples:    SHARED_POOL_SIZE=0
#              SHARED_POOL_SIZE=0
#
SHARED_POOL_SIZE=0
#
##
# Description: Specifies the size of the <n>K buffers
#
# Examples:    DB_16K_CACHE_SIZE=0
#              DB_32K_CACHE_SIZE=0
#
DB_2K_CACHE_SIZE=0
DB_4K_CACHE_SIZE=0
DB_8K_CACHE_SIZE=DEFAULT
DB_16K_CACHE_SIZE=0
DB_32K_CACHE_SIZE=0
#
################################################################################
#
# Description: Specifies the maximum number of blocks read in one I/O operation
#              during a sequential scan.
#
# Examples:    DB_FILE_MULTIBLOCK_READ_COUNT=4
#              DB_FILE_MULTIBLOCK_READ_COUNT=16
#              DB_FILE_MULTIBLOCK_READ_COUNT=64
#
DB_FILE_MULTIBLOCK_READ_COUNT=32
#
################################################################################
#
# Description: Specifies the size of the keep buffer pool
#
# Examples:    DB_KEEP_CACHE_SIZE=0
#              DB_KEEP_CACHE_SIZE=1G
#
DB_KEEP_CACHE_SIZE=0
#
################################################################################
#
# Description: Specifies the size of the recycle buffer pool
#
# Examples:    DB_RECYCLE_CACHE_SIZE=0
#              DB_RECYCLE_CACHE_SIZE=1G
#
DB_RECYCLE_CACHE_SIZE=0
#
##
# END MEMORY, SGA, BUFFER CACHE, AND I/O SECTION
################################################################################
# START MISCELLANEOUS SECTION
##
# Description: Advanced queue parameter
#
# Example:     AQ_TM_PROCESSES=2
#
AQ_TM_PROCESSES=2
#
################################################################################
#
# Description: Allows to use a new release of Oracle, while at the same time
#              guaranteeing backward compatibility with an earlier release. Keep
#              DEFAULT to use the current release.
#
# Examples:    COMPATIBLE="DEFAULT"
#              COMPATIBLE="10.2.0.4.0"
#              COMPATIBLE="10.1.0.7.0"
#
COMPATIBLE="DEFAULT"
#
##
# END MISCELLANEOUS SECTION
################################################################################
# START OBJECTS AND LOBS SECTION
##
#
# EMPTY
#
##
# END OBJECTS AND LOBS SECTION
################################################################################
# START OLAP SECTION
##
#
# EMPTY
#
##
# END OLAP SECTION
################################################################################
# START OPTIMIZER SECTION
##
# Description: Establishes the default behavior for choosing an optimization
#              approach for the instance.
#
# Examples:    OPTIMIZER_MODE=FIRST_ROWS
#              OPTIMIZER_MODE=FIRST_ROWS_<1 | 10 | 100 | 1000>
#              OPTIMIZER_MODE=ALL_ROWS
#
OPTIMIZER_MODE=FIRST_ROWS
#
##
# END OPTIMIZER SECTION
################################################################################
# START PARALLEL EXECUTION SECTION
##
#
# EMPTY
#
##
# END PARALLEL EXECUTION SECTION
################################################################################
# START PL/SQL SECTION
##
#
# EMPTY
#
##
# END PL/SQL SECTION
################################################################################
# START PL/SQL COMPILER SECTION
##
#
# EMPTY
#
##
# END PL/SQL COMPILER SECTION
################################################################################
# START REAL APPLICATION CLUSTERS SECTION
##
# Description: Specify whether or not database is running in real application
#              cluster (RAC) mode.
#
# Examples:    CLUSTER_DATABASE="FALSE"
#              CLUSTER_DATABASE="TRUE"
#
CLUSTER_DATABASE="FALSE"
#
#
##
# END REAL APPLICATION CLUSTERS SECTION
################################################################################
# START REDO LOGS, ARCHIVING, AND RECOVERY SECTION
##
# Description: Specify the number of seconds the database takes to perform crash
#              recovery of a single instance.
#
# Examples:    FAST_START_MTTR_TARGET="300"
#
FAST_START_MTTR_TARGET="300"
#
################################################################################
#
# Description: Defines first destination where to archive the redo data.
#
# Example:     LOG_ARCHIVE_DEST_1="LOCATION=${ARCHIVE01}"
#
LOG_ARCHIVE_DEST_1=LOCATION='${ARCHIVE01}'
#
################################################################################
#
# Description: Defines second destination where to archive the redo data.
#
# Example:     LOG_ARCHIVE_DEST_2=""
#
LOG_ARCHIVE_DEST_2=""
#
################################################################################
#
# Description: Specifies the format of archive files
#
# Example:     LOGFILE_A_DEST="${DB1}"
#
LOG_ARCHIVE_FORMAT='${DB_NAME}'_%S_%T_%R.arc
#
##
# END REDO LOGS, ARCHIVING, AND RECOVERY SECTION SECTION
################################################################################
# START RESOURCE MANAGER SECTION
##
#
# EMPTY
#
##
# END RESOURCE MANAGER SECTION
################################################################################
# START SECURITY AND AUDITING SECTION
##
# Description: Remote login password file specifies whether Oracle checks for a
#              password file and how many databases can use the password file.
#
# Examples:    REMOTE_LOGIN_PASSWORDFILE="EXCLUSIVE"
#              REMOTE_LOGIN_PASSWORDFILE="SHARED"
#              REMOTE_LOGIN_PASSWORDFILE="NONE"
#
REMOTE_LOGIN_PASSWORDFILE="EXCLUSIVE"
#
################################################################################
#
# Description: Enables or disables password case sensitivity
#
# Version:     >= 11.1
#
# Examples:    SEC_CASE_SENSITIVE_LOGON="FALSE"
#              SEC_CASE_SENSITIVE_LOGON="TRUE"
#
SEC_CASE_SENSITIVE_LOGON="FALSE"
#
##
# END SECURITY AND AUDITING SECTION
################################################################################
# START SESSIONS AND PROCESSES SECTION
##
# Description: Process parameter
#
# Example:     PROCESSES=100
#
PROCESSES=600
#
##
# END SESSIONS AND PROCESSES SECTION
################################################################################
# START SHARED SERVER ARCHITECTURE SECTION
##
#
# EMPTY
#
##
# END SHARED SERVER ARCHITECTURE SECTION
################################################################################
# START STANDBY DATABASE SECTION
##
#
# EMPTY
#
##
# END STANDBY DATABASE SECTION
################################################################################
# START TRANSACTIONS SECTION
##
#
# EMPTY
#
##
# END TRANSACTIONS SECTION
################################################################################
# START UNDO MANAGEMENT SECTION
##
# Description: Enable / diable auto tuning of undo_retention
#
# Examples:    UNDO_AUTOTUNE="FALSE"
#              UNDO_AUTOTUNE="TRUE"
#
UNDO_AUTOTUNE="FALSE"
#
################################################################################
#
# Description: Specifies which undo space management mode the system should use.
#
# Examples:    UNDO_MANAGEMENT="AUTO"
#              UNDO_MANAGEMENT="MANUAL"
#
UNDO_MANAGEMENT="AUTO"
#
################################################################################
#
# Description: Specifies (in seconds) the low threshold value of undo retention.
#
# Examples:    UNDO_RETENTION=10800
#              UNDO_RETENTION=3600
#
UNDO_RETENTION=10800
#
################################################################################
#
# Description: Specifies the undo tablespace to be used when an instance starts
#              up.
#
# Example:     UNDO_TABLESPACE=UNDO
#
UNDO_TABLESPACE=UNDO
#
##
# END UNDO MANAGEMENT SECTION
################################################################################' > /opt/oracle/otk/1.0/conf/installManager/dbSetup-$ORA_SID.cfg
 
 

cd $INSTALL_CONF

echo '
################################################################################
#
# Description: Comma separated list of installManager actions for which this fi-
#              le can be used
#
# Example:     ACTION_LIST="swInst"
#
ACTION_LIST="swInst"
#
################################################################################
#
# Description: Path where downloaded Oracle sw packages are stored before execu-
#              tion
#
# Examples:    REPOSITORY_BASE="$INSTALL_REPOSITORY"
#              REPOSITORY_BASE="/var/opt/oracle/repository/"
#
REPOSITORY_BASE='$REPO'/11203
#
################################################################################
#
# Description: File names of the software downloaded from www.oracle.com or from
#              https://metalink.oracle.com
#
# Examples:    SW_FILE_NAMES="linux.x64_11gR2_database_1of2.zip linux.x64_11gR2_database_2of2.zip"
#              SW_FILE_NAMES="linux.x64_11gR2_client.zip"
#
SW_FILE_NAMES="'$FILE_NAME1 $FILE_NAME2'"
#
################################################################################
#
# Description: Directory where SW and runInstaller will be stored
#
# Examples:    REPOSITORY_HOME="$REPOSITORY_BASE/11.2.0/distribution/database"
#              REPOSITORY_HOME="$REPOSITORY_BASE/11.2.0/distribution/client"
#
REPOSITORY_HOME='$REPOSITORY_BASE'/distribution/database
#
################################################################################
#
# Description: Directory path in which $SW_FILE_NAME will be extracted
#
# Examples:    EXTRACT_DIR="$REPOSITORY_HOME"
#              EXTRACT_DIR="$REPOSITORY_HOME/.."
#
EXTRACT_DIR='$REPOSITORY_HOME'/..
#
################################################################################
#
# Description: Name of a response file containing parameters used by Oracle Uni-
#              versal installer to install the software. Parameter files are
#              stored in $CONF_DIR/response. CONF_DIR variable is specified in
#              $RUN/installManagerenv file.
#
# Examples:    RESPONSE_FILE="11_2_0_1_SEONE.rsp"
#              RESPONSE_FILE="11_2_0_1_SE.rsp"
#              RESPONSE_FILE="11_2_0_1_EE.rsp"
#              RESPONSE_FILE="11_2_0_1_CU_PARTITIONING.rsp"
#              RESPONSE_FILE="11_2_0_1_CLIENT.rsp"
#
RESPONSE_FILE='$RESP_FILE'
#
################################################################################
#
# Description: Additional command line parameters used by runInstaller. For a
#              full list of arguments refer to Universal Installer Concepts
#              Guide.
#
# Examples:    CMD_ARGS="-ignoreSysPrereqs -logLevel info"
#              CMD_ARGS="-executeSysPrereqs"
#
CMD_ARGS="-ignoreSysPrereqs -logLevel info -showProgress"
#
################################################################################' >$INSTALL_CONF/swInstSICAP-11203.cfg
 
su - oracle <<EOF
bash
export REPO=/var/opt/oracle
cd $INSTALL_CONF
installManager swInst swInstSICAP-11203.cfg -force


EOF


 /opt/oracle/product/11.2.0.3/root.sh



echo "################################################################################"
echo "################################################################################"
echo "################################################################################"
echo "#################### Oracle Software Installation completed ####################"
echo "################################################################################"
echo "################################################################################"
echo "################################################################################"



echo "DB Creation starting"


su - oracle <<EOF
bash
export REPO=/var/opt/oracle
cd $INSTALL_CONF
installManager dbSetup dbSetup-$ORA_SID.cfg  -force


 ln -s $ADMIN/pfile/init$ORACLE_SID.ora    $ORACLE_HOME/dbs/init$ORACLE_SID.ora
 ln -s $ADMIN/pfile/spfile$ORACLE_SID.ora  $ORACLE_HOME/dbs/spfile$ORACLE_SID.ora
 ln -s $ADMIN/pfile/orapw$ORACLE_SID       $ORACLE_HOME/dbs/orapw$ORACLE_SID


EOF
 
echo "################################################################################"
echo "################################################################################"
echo "################################################################################"
echo "#################### Oracle Instance creation completed ########################"
echo "################################################################################"
echo "################################################################################"
echo "################################################################################"
 
