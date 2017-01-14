#!/bin/bash

# Dieses Skript schickt über ebusctl Kommandos an einen EBUS-Teilnehmer und speichert das Antworttelegramm.

# Maximale Anzahl an Wiederholungen
MAXLOOPS=10

# Schrittweite (STEP <= 9)
STEP=9

# Startadresse
STARTADDRESS=0

# Endadresse (ENDADDRESS <= 65535)
# Nach 6768 (0x1A70) kam keine gültige Antwort mehr
ENDADDRESS=STARTADDRESS+15*STEP
#ENDADDRESS=2564

# Trennzeichen für die Ausgabe
SEPARATOR=";"

# Zieladresse EBUS-Teilnehmer
# in HEX
EBUS_ZZ=35

# EBUS-Kommando 
EBUS_CMD=0902

# ANZAHL der folgenden Bytes - hier Adresse 0x0000 + Länge 0x00 
# in HEX
EBUS_COUNT=03

# Umwandlung der Schrittweite in HEX-Wert
printf -v EBUS_LENGTH "%02X" "$((STEP*2))"

# Pfad zum Kommando
CMD=/usr/bin/ebusctl

now=$(date +"%Y-%m-%d_%I-%M")

# Pfad zur Ergebnis-Datei
RESULTFILE="scan.$now.csv"

# Hier wird das NULLRESULT berechnet
NULLRESULT="$EBUS_LENGTH"
for(( i=0; i<STEP; i++ ))
do
  NULLRESULT+="0000"
done

# Datei neu anlegen/überschreiben
echo "" > $RESULTFILE
echo "Startadresse: $STARTADDRESS" >> $RESULTFILE
echo "Endadresse:   $ENDADDRESS" >> $RESULTFILE
echo "Schrittweite: $STEP" >> $RESULTFILE
echo "MaxVersuche: $MAXLOOPS" >> $RESULTFILE
echo "keineAntwort: $NULLRESULT" >> $RESULTFILE
echo >> $RESULTFILE

for(( address=STARTADDRESS; address<=ENDADDRESS; address+=STEP ))
do
  for(( loop=1; loop<=MAXLOOPS; loop++ ))
  do
    printf -v EBUS_ADDRESS_HIGH "%02X" "$((address/255))"
    printf -v EBUS_ADDRESS_LOW  "%02X" "$((address&255))"

    COMMAND=( "$CMD hex $EBUS_ZZ$EBUS_CMD$EBUS_COUNT$EBUS_ADDRESS_LOW$EBUS_ADDRESS_HIGH$EBUS_LENGTH" )

    #  echo $COMMAND
    RESULT=`$COMMAND`

    # RESULT ist NULLRESULT
    if [[ $RESULT == $NULLRESULT ]] 
    then
      # MaxLoops erreicht?
      if [ $loop == $MAXLOOPS ]
      then
        echo $(date +"%T"): $address: $COMMAND: $RESULT $loop "FAIL"
        echo $(date +"%T")$SEPARATOR$COMMAND$SEPARATOR$address$SEPARATOR$RESULT$SEPARATOR$loop$SEPARATOR"FAIL" >> $RESULTFILE
      fi
    # RESULT beginnt mit ERR*
    elif [[ $RESULT == ERR* ]]
    then
      # MaxLoops erreicht?
      if [ $loop == $MAXLOOPS ]
      then
        echo $(date +"%T"): $address: $COMMAND: $RESULT $loop "FAIL"
        echo $(date +"%T")$SEPARATOR$COMMAND$SEPARATOR$address$SEPARATOR$NULLRESULT$SEPARATOR$loop$SEPARATOR"FAIL"$SEPARATOR$RESULT >> $RESULTFILE
      fi
    # RESULT-Länge ungleich Soll-Länge
    elif [[ ${#RESULT} != ${#NULLRESULT} ]]
    then
      # MaxLoops erreicht?
      if [ $loop == $MAXLOOPS ]
      then
        echo $(date +"%T"): $address: $COMMAND: $RESULT $loop "FAIL"
        echo $(date +"%T")$SEPARATOR$COMMAND$SEPARATOR$address$SEPARATOR$NULLRESULT$SEPARATOR$loop$SEPARATOR"FAIL"$SEPARATOR$RESULT >> $RESULTFILE
      fi
    # Gutfall
    else
      echo $(date +"%T"): $address: $COMMAND: $RESULT $loop "OK"
      echo $(date +"%T")$SEPARATOR$COMMAND$SEPARATOR$address$SEPARATOR$RESULT$SEPARATOR$loop$SEPARATOR"OK" >> $RESULTFILE
      break
    fi
    sleep 0.5
  done
done 
