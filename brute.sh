#!/bin/bash

# Dieses Skript schickt über ebusctl Kommandos an einen EBUS-Teilnehmer und speichert das Antworttelegramm.

# Trennzeichen für die Ausgabe
SEPARATOR=";"

# Zieladresse EBUS-Teilnehmer
# in HEX
EBUS_ZZ=08

# EBUS-Kommando 
EBUS_CMD=5000

# Umwandlung der Schrittweite in HEX-Wert
printf -v EBUS_LENGTH "%02X" "$((STEP*2))"

# Pfad zum Kommando
CMD=/usr/bin/ebusctl

now=$(date +"%Y-%m-%d_%I-%M")

# Pfad zur Ergebnis-Datei
RESULTFILE="brute.$now.csv"

# Datei neu anlegen/überschreiben
#echo "" > $RESULTFILE
#echo >> $RESULTFILE

for(( address=0; address<=255; address+=1 ))
do
    printf -v CHECK  "%02X" "$((address&255))"

    COMMAND=( "$CMD hex $EBUS_ZZ$EBUS_CMD"03"$CHECK""0505" )

    echo $COMMAND
    RESULT=`$COMMAND`
    echo $RESULT

    if [[ $RESULT != ERR* ]]
    then
	break
    fi
    
#    sleep 0.5
done