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
./GForm quiet width=400 pipe="/tmp/fifo1" listen="/tmp/fifo2" title="pkexec policy manager using GForm (full example)" \
label="|Rule List,, Add, Edit or remove items" \
gridview="gv1|Name,Description,Message,Path|stretch" \
box label="|Description" input="desc||disabled" unbox \
box label="|Message" input="mess||disabled" unbox \
box label="|Path" input="path||disabled readonly right" button="freq|@|disabled nostretch" unbox \
box button="add|Add New" button="del|Delete|disabled" combobox="presets|Select a Preset,Pluma,Gambas3,Xed|0" unbox \
box button="save|Save Changes|disabled" button="rel|Reload (Revert)|disabled" spring button="BQ|Quit|close"&false
}

CleanUp() {
AppOpen=0 # the following 'Ask' command needs to know internal 'message' command is no longer usable
if [ "$CHANGED" -eq 1 ]; then
 Ask "Configuration Changed\nwould you like to save the changes?" "Yes Save" "No Don't"
 if [ $RVAL -eq 1 ]; then
  Alert "Saving"
 fi
fi

exec 3<&-
KillFiles
exit
}

KillFiles() {  # Make sure the pipe files are gone
if [ -e "/tmp/fifo2" ]; then
rm /tmp/fifo2
fi
if [ -e "/tmp/fifo1" ]; then
rm /tmp/fifo1
fi
}

Ask() {  # just using the GUI to pop a question
RVAL=$(gbr3 GForm return=v allstretch toponly title="Question.." label="|\n$1\n" box button="1|$2" button="0|$3") #2>/dev/null
}

Alert() {  
# just using GForm to pop up a message box. if the GUi is not open it runs a seperate 
# GForm instance or it uses the running GUI's internal "message" function
if [ $AppOpen -eq 0 ]; then
gbr3 GForm quiet toponly title="Notice.." label="|$1" button="|Okay|close" 2>/dev/null
return
fi
Send "message=$1"
}

# this is run after modifying any data, it enables/disables the save/reload button and
# sets the CHANGED flag so the app know to ask to save on exit if modifications were made.
Changes() {
if [ "$1" = "-1" ]; then
Send "dislist=save|rel"
CHANGED=0
return
elif [ $CHANGED -eq 0 ]; then
Send "enlist=save|rel"
CHANGED=1
fi
}

Send() {
echo -e "$1" >>/tmp/fifo2
#sleep 0.05
}
SendQ() {
echo -e "$1" >>/tmp/fifo2
}
AskGUI() {
echo -e "$1" >>/tmp/fifo2
read -u 3 REPLY
}


TextToData() {
PT=$1
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


DoCommand() {  
# this is the main function for processing the data coming from the GUI.
# The message will be in the form of "object_name|object_text|object_value"

# set ACTIVE to "no" in the script somewhere to disable this routine anytime.
if [ "$ACTIVE" = "no" ]; then return; fi

#echo "got command '$1'"
# message has now been split into $CName , $CText and $CData
# so we can add our procedures here according to the GUI data.

if [ "$CName" = "add" ]; then 
#echo "Adding..."
AddField

elif [ "$CName" = "del" ]; then 
DeleteField


elif [ "$CName" = "gv1" ]; then
if [ $ListIndex -eq -1 ]; then
 Send "enlist=del|desc|mess|path|freq"
fi
ListIndex=$CData
GetFields

elif [ "$CName" = "desc" ]; then
Send "gridview=gv1|settext|$CText|$ListIndex,1"
Changes
elif [ "$CName" = "mess" ]; then
Send "gridview=gv1|settext|$CText|$ListIndex,2"
Changes

elif [ "$CName" = "freq" ]; then
Send "dialog=title|Select app to use"
AskGUI "dialog=openfile|/usr/bin/NewApp|showhidden"
if [ -z "$REPLY" ]; then
Alert "Change path Cancelled.."
return
fi
Send "gridview=gv1|settext|$REPLY|$ListIndex,3\nsettext=path|$REPLY"
Changes

elif [ "$CName" = "rel" ]; then
ReadApps
ListIndex=-1
Send "settext=desc|\nsettext=mess|\nsettext=path|\ndislist=del|desc|mess|path|freq"
Changes "-1"

elif [ "$CName" = "save" ]; then
SavePFile

elif [ "$CName" = "presets" ]; then
if [ $CData -eq 0 ]; then return; fi
AddField "$CText"
Send "setindex=presets|0"
elif [ "$CName" = "BQ" ]; then
 CleanUp
else
echo -e "unknown message recieved\n$PipeText"
fi

}

AddField() {

if [ -z $1 ]; then
 Send "dialog=title|Select app to add to pkexec list"
 AskGUI "dialog=openfile|/usr/bin/NewApp|showhidden"
NEWAPP="$REPLY"
  if [ -z "$NEWAPP" ]; then
   Alert "Adding Cancelled.."
  return
  fi
 ANAME=${NEWAPP##*/}
 else
 ANAME="$1"
 NEWAPP="/usr/bin/${1,,}"
fi

CText="gv1|add|$ANAME,$ANAME,$ANAME requires SuperUser access,$NEWAPP"
Send "gridview=$CText"
((RULECOUNT++))
Changes
if [ $ListIndex -eq -1 ]; then
Send "enlist=del|desc|mess|path|freq"
fi

ListIndex=$[RULECOUNT-1]
Send "setindex=gv1|$ListIndex|nolock"
GetFields
}


DeleteField() {

if [ "$ListIndex" -eq "$[RULECOUNT-1]" ]; then ((ListIndex--)); fi
Send "gridview=gv1|del"
((RULECOUNT--))
 Changes

if [ $RULECOUNT -eq 0 ]; then
Send "settext=desc|\nsettext=mess|\nsettext=path|\ndislist=del|desc|mess|path|freq"
else
Send "setindex=gv1|$ListIndex|nolock"
#AskGUI "gridview=gv1|getrow"
#CText="gv1|nop|$REPLY"
#GetFields
fi
}

SavePFile() {
WriteApps
sudo echo -e "$PFILE" >"$POLSAVE"
Changes "-1"
Alert "pkexec policy file saved."
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
 Alert "Just a Note..\n\na current pkexec policy file did not exist\nso a new one will be created upon saving."
fi
}


WriteApps() {
WCNT=0 ; PFILE=""
AskGUI "gridview=gv1|getall"
PFILE="<?xml version="1.0" encoding=\"UTF-8\"?>
<!DOCTYPE policyconfig PUBLIC
 \"-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN\"
 \"http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd\">
<policyconfig>\n\n"

IFS=$'|'
read -a ARRY <<< "$REPLY"
IFS=$','
while [ $WCNT -lt ${#ARRY[@]} ]; do
read -a LN <<< ${ARRY[$WCNT]}

PFILE="$PFILE  <action id=\"org.freedesktop.policykit.pkexec.run-${LN[0]}\">
    <description>${LN[1]}</description>
    <message>${LN[2]}</message>
    <defaults>
      <allow_any>no</allow_any>
      <allow_inactive>no</allow_inactive>
      <allow_active>auth_admin_keep</allow_active>
    </defaults>
    <annotate key=\"org.freedesktop.policykit.exec.path\">${LN[3]}</annotate>
    <annotate key=\"org.freedesktop.policykit.exec.allow_gui\">TRUE</annotate>
  </action>\n\n"
((WCNT++))
done
PFILE="$PFILE</policyconfig>\n"
IFS=$'\n'
}

ReadApps() {
Send "gridview=gv1|clear"
read -d '{' -a FARRAY <<< "$PFILE{"
CN=0 ;MODE=0; RULECOUNT=0; GOT=0
while [ $CN -lt ${#FARRAY[@]} ]; do
TXT="${FARRAY[$CN]}"

if [ $MODE -eq 0 ]; then
  if [[ "$TXT" = *"<action id="* ]]; then
  ((RULECOUNT++))
  APP=${TXT#*exec.run-} ; APP=${APP%\"*}    #"}
  MODE=4
  GOT=1
  fi 
else
  if [[ "$TXT" = *"<description>"* ]]; then
  DATA=${TXT#*>} ; DESC=${DATA%</*}
  ((MODE--))
  elif [[ $TXT = *"<message>"* ]]; then
  DATA=${TXT#*>} ; MESS=${DATA%</*}
  ((MODE--))
 elif [[ $TXT = *"policykit.exec.path"* ]]; then
  DATA=${TXT#*>} ; PTH=${DATA%</*}
  ((MODE--))
  fi 
fi
((CN++))

if [ $MODE -eq 1 ]; then
Send "gridview=gv1|add|$APP,$DESC,$MESS,$PTH"
MODE=0
fi
done
}

GetFields() {
IFS=$','
read -a ARY <<< "$CText"
IFS=$'\n'
Send "settext=desc|${ARY[1]}\nsettext=mess|${ARY[2]}\nsettext=path|${ARY[3]}"
}

# Main()
# This is the main loop, It opens the pipe and if a line of text comes
# through it reads it to $Pipetext and runs the DoCommand() procedure above.
# Closing the GUI deletes the pipe file so our loop runs while the file exists.

# IMPORTANT, set the generic text splitting variable (IFS) to newline so white spaces won't count.
IFS=$'\n'

KillFiles
ReadFile
sudo false

OpenForm

  while [ ! -e "/tmp/fifo1" ]; do
  sleep 0.1
  done
AppOpen=1
ReadApps

exec 3</tmp/fifo1 

  while [ -e "/tmp/fifo1" ]; do
  read -u 3 PipeText

   if [ ! -z "$PipeText" ]; then  # We got some text so process it.
    TextToData $PipeText
    DoCommand $PipeText
   fi
  done

CleanUp  # clean up and exit.


