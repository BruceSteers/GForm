#!/usr/bin/env bash

# This is an advanced example bash script to show how to use GForm to create a GUI
# and then have your shell script act upon the input by sending commands back to the GUI
# to modify the data.

SUSER=$(w -h|awk '{print $1}')

# Change read/save file names for testing purposes..
POLSAVE="/usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy"
POLREAD="/usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy"
#POLSAVE="/home/$SUSER/Desktop/org.freedesktop.policykit.pkexec.policy"
#POLREAD="/home/$SUSER/Desktop/org.freedesktop.policykit.pkexec.policy"

ListIndex=-1; CHANGED=0; AppOpen=0

# The following is one long line split using \ to make things clearer
# as each line is each row in the form. note, using option 'quiet' to
# suppress any stdout message unlike the 'Test_GForm (simple).sh' example.
OpenForm() {
./GForm quiet font="Carlito,14,Italic" pipe="/tmp/fifo1" listen="/tmp/fifo2" title="pkexec policy manager using GForm (full example)" \
label="|Rule List,, Add, Edit or remove items" \
listbox="lb1|$AppList||stretch" \
box label="|Descrip[tion" input="desc||disabled" unbox \
box label="|Message" input="mess||disabled" unbox \
box label="|Path" input="path||disabled readonly right" button="freq|@|disabled nostretch" unbox \
box button="add|Add New" button="del|Delete|disabled" combobox="presets|Select a Preset,Pluma,Gambas3,Xed|0" unbox \
box button="save|Save Changes|disabled" button="rel|Reload (Revert)" spring button="BQ|Quit Button|close"&sleep 1
AppOpen=1
}

CleanUp() {
AppOpen=0
if [ "$CHANGED" -eq 1 ]; then
 Ask "Configuration Changed\nwould you like to save the changes?" "Yes Save" "No Don't"
 if [ $RVAL -eq 1 ]; then
  Alert "Saving" "w"
 fi
fi

exec 3<&- 2>/dev/null # close the pipe handle
KillFiles
exit
}

KillFiles() {
if [ -e "/tmp/fifo2" ]; then
rm /tmp/fifo2
fi
if [ -e "/tmp/fifo1" ]; then
rm /tmp/fifo1
fi
}

Ask() {  # just using the GUI to pop a question
RVAL=$(gbr3 GForm return=v allstretch toponly title="Question.." label="$1" box button="1|$2" button="0|$3") #2>/dev/null
}

Alert() {  
# just using GForm to pop up a message box. if the GUi is not open it runs a seperate 
# GForm instance or it uses the running GUI's internal "message" function
if [ $AppOpen -eq 0 ]; then
gbr3 GForm quiet toponly title="Notice.." label="$1" button="|Okay|close" 2>/dev/null
return
fi
if [ "$2" = "w" ]; then
Send "disable"
Send "message=$1" 2>/dev/null
Send "enable"
sleep 0.3 # give the GUI a moment to become enabled again
else
Send "message=$1" 2>/dev/null
fi
}

Changes() {
if [ "$1" = "-1" ]; then
Send "disable=save"
CHANGED=0
return
elif [ $CHANGED -eq 0 ]; then
Send "enable=save"
CHANGED=1
fi
}

Send() {
echo -e "$1\n" >/tmp/fifo2
sleep 0.03
}

TextToData() {
PT=$1
if [ "$PT" = "check" ]; then
return
fi
CName=${PT%%|*}   # get the name of the control talking to us.
TMP=${PT#*|}
if [[ "$TMP" = *"|"* ]]; then
 CText=${TMP%|*}        # see if rest of message has another field.
 CData=${TMP#*|}        # Toggle buttons, checkboxes, etc have other info
else
 CText="$TMP"
 CData=""
fi
}

CheckAnotherCom() {
Send "check"
read -u 3 PText
if [ $PText != "check" ]; then
 TextToData $PText
 DoCommand $PText
 TextToData $PipeText
fi
}

DoCommand() {  
# this is the main function for processing the data coming from the GUI.
# The message will be in the form of "object_name|object_text|object_value"

# set ACTIVE to "no" in the script somewhere to disable this routine anytime.
if [ "$ACTIVE" = "no" ]; then return; fi

if [ "$1" = "check" ]; then return; fi

# message has now been split into $CName , $CText and $CData
# so we can add our procedures here according to the GUI data.

if [ "$CName" = "add" ]; then 
AddField

elif [ "$CName" = "del" ]; then 
DeleteField


elif [ "$CName" = "lb1" ]; then
if [ $ListIndex -eq -1 ]; then
 Send "enlist=del|desc|mess|path|freq"
fi
CheckAnotherCom
 ListIndex=$CData
 ANAME=$CText
 GetFields

elif [ "$CName" = "desc" ]; then
DESC="$CText"
FARRAY[$DPOS]="    <description>$CText</description>"
WriteApps
Changes
elif [ "$CName" = "mess" ]; then
MESS="$CText"
FARRAY[$MPOS]="    <message>$CText</message>"
WriteApps
Changes

elif [ "$CName" = "freq" ]; then
Send "dialog=title|Select app to use"
Send "dialog=openfile|/usr/bin/NewApp|showhidden"
sleep 0.1
read -u 3 NEWAPP
if [ -z "$NEWAPP" ]; then
Alert "Change path Cancelled.." "w"
return
fi
PTH=$NEWAPP
FARRAY[$PPOS]="    <annotate key="org.freedesktop.policykit.exec.path">$PTH</annotate>"
WriteApps
Changes

elif [ "$CName" = "save" ]; then
SavePFile
Changes "-1"
sleep 0.1

elif [ "$CName" = "presets" ]; then
AddField "$CText"
 
elif [ "$CName" = "BQ" ]; then
 Alert "You've Exited." "w"
 CleanUp
else
echo "unknown message\n$PipeText"
fi

}

AddField() {
CNT=0 ; SKIP=0; NTXT=""

if [ -z $1 ]; then
 Send "dialog=title|Select app to add to pkexec list"
 Send "dialog=openfile|/usr/bin/NewApp|showhidden"
 sleep 0.1
 read -u 3 NEWAPP
  if [ -z "$NEWAPP" ]; then
   Alert "Adding Cancelled.." "w"
  return
  fi
 ANAME=${NEWAPP##*/}
 else
 ANAME=$1
 NEWAPP=$(which "${1,,}")
 if [ -z $NEWAPP ]; then
 Alert "Command not found!\nMake sure it's installed." "w"
 return
 fi
fi

while [ $CNT -lt ${#FARRAY[@]} ]; do
TXT="${FARRAY[$CNT]}"
  if [[ "$TXT" = *"</policyconfig>"* ]]; then
  NTXT="$NTXT  <action id=\"org.freedesktop.policykit.pkexec.run-$ANAME\">
    <description>$ANAME</description>
    <message>$ANAME requires SuperUser access</message>
    <defaults>
      <allow_any>no</allow_any>
      <allow_inactive>no</allow_inactive>
      <allow_active>auth_admin_keep</allow_active>
    </defaults>
    <annotate key=\"org.freedesktop.policykit.exec.path\">$NEWAPP</annotate>
    <annotate key=\"org.freedesktop.policykit.exec.allow_gui\">TRUE</annotate>
  </action>
$TXT"
elif [[ "TXT" = *"exec.path\">$NEWAPP"* ]]; then
Alert "Already in List\n$NEWAPP"
return
else
 NTXT="$NTXT$TXT
"
fi # end if found /policyconfig
((CNT++))
done
PFILE="$NTXT"
Changes
if [ $ListIndex -eq -1 ]; then
Send "enlist=del|desc|mess|path|freq"
fi

ReadApps
ListIndex=$[RULECOUNT-1]
Send "setlist=lb1|$AppList"
Send "setindex=lb1|$ListIndex"

}


DeleteField() {
CNT=0 ; MODE=0; FND=0; NTXT=""; RC=$RULECOUNT
((RC--))

if [ "$ListIndex" -eq "$RC" ]; then ((ListIndex--)); fi
while [ $CNT -lt ${#FARRAY[@]} ]; do
TXT="${FARRAY[$CNT]}"
if [ $MODE -eq 0 ]; then
  if [[ $TXT = *"pkexec.run-$ANAME"* ]]; then
  FND=1
  MODE=1
  else
#   if [[ $TXT = *"<action id="* ]]; then
#   TXT="
#$TXT"
#   fi
  NTXT="$NTXT$TXT
"
  fi
else # MODE=1
 if [[ $TXT = *"</action>"* ]]; then
 MODE=0
 fi
fi
((CNT++))
done

 if [ $FND -eq 0 ]; then
 Alert "Item '$ANAME' not found!"
 else
 Changes
 PFILE="$NTXT"
 ReadApps
 Send "setlist=lb1|$AppList"
if [ "$AppList" = "" ]; then 
Send "dislist=del|desc|mess|path|freq"

else
Send "setindex=lb1|$ListIndex"
fi
 fi
}

SavePFile() {
 sudo false
  echo -e "$PFILE" >"$POLSAVE"
  Changes "-1"
  sleep 0.1
  Alert "pkexec policy file saved." "w"
}

ReadFile() {
CHANGED=0
PFILE=""
if [ -e "$POLREAD" ]; then
PFILE=$(cat "$POLREAD")
else
PFILE="<?xml version="1.0" encoding=\"UTF-8\"?>
<!DOCTYPE policyconfig PUBLIC
 \"-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN\"
 \"http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd\">
<policyconfig>

</policyconfig>
 "
 Alert "Just a Note..\n\na current pkexec policy file did not exist\nso a new one will be created upon saving." "w"
fi
}

WriteApps() {
WCNT=0 ; PFILE=""
while [ $WCNT -lt ${#FARRAY[@]} ]; do
PFILE="$PFILE${FARRAY[$WCNT]}
"
((WCNT++))
done
}

ReadApps() {

read -d '{' -a FARRAY <<< "$PFILE{"
CNT=0 ; RULECOUNT=0; AppList=""
while [ $CNT -lt ${#FARRAY[@]} ]; do
TXT="${FARRAY[$CNT]}"

 if [[ "$TXT" = *"<action id="* ]]; then
  ((RULECOUNT++))
 APP=${TXT#*exec.run-} ; APP=${APP%\"*}
#"
  if [ ! -z "$AppList" ]; then
  AppList="$AppList,$APP"
  else
   if [ "$SMODE" = "LST" ]; then
   echo "$APP"
   else
   AppList="$APP"
   fi
  fi
 fi
((CNT++))

done
}

GetFields() {
CN=0 ; MODE=0 ; GOT=0
while [ $CN -lt ${#FARRAY[@]} ]; do
TXT="${FARRAY[$CN]}"
if [ $MODE -eq 0 ]; then
 if [[ $TXT = *"pkexec.run-$ANAME"* ]]; then
 MODE=3
 GOT=1
 fi 
else
 if [[ $TXT = *"<description>"* ]]; then
 DATA=${TXT#*>} ; DESC=${DATA%</*}; DPOS=$CN
 ((MODE--))
 elif [[ $TXT = *"<message>"* ]]; then
 DATA=${TXT#*>} ; MESS=${DATA%</*}; MPOS=$CN
 ((MODE--))
 elif [[ $TXT = *"policykit.exec.path"* ]]; then
 DATA=${TXT#*>} ; PTH=${DATA%</*}; PPOS=$CN
 ((MODE--))
 fi 
fi
((CN++))
done
if [ $GOT -eq 1 ]; then
Send "settext=desc|$DESC"
Send "settext=mess|$MESS"
Send "settext=path|$PTH"
fi
}

# Main()
# This is the main loop, It opens the pipe and if a line of text comes
# through it reads it to $Pipetext and runs the DoCommand() procedure above.
# Closing the GUI deletes the pipe file so our loop runs while the file exists.

IFS=$'\n'

KillFiles
ReadFile
ReadApps
OpenForm

exec 3</tmp/fifo1 
  while [ -e "/tmp/fifo1" ]; do
  read -u 3 PipeText
   if [ ! -z "$PipeText" ]; then  # We got some text so process it.
    TextToData $PipeText
    DoCommand $PipeText
   fi
  done

CleanUp  # clean up and exit.


