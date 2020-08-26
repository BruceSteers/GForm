#!/usr/bin/env bash

# This is a medium advanced example bash script to show how to use GForm to create a GUI
# and then have your shell script act upon the input by sending commands back to the GUI
# to modify the data.

if [ -e "/tmp/fifo2" ]; then
rm /tmp/fifo2
fi
if [ -e "/tmp/fifo1" ]; then
rm /tmp/fifo1
fi

# Set up our name list and run Gform.gambas with some args.
NameArray=(Fred Freda "Uncle Bob" Sally)
for s in "${NameArray[@]}"; do txt="$txt,$s"; done
NameList=${txt#,*} ; ListIndex=0

# The following is one long line split using \ to make things clearer
# as each line is each row in the form. note, using option 'quiet' to
# suppress any stdout message unlike the 'Test_GForm (simple).sh' example.

./GForm quiet font="Carlito,14,Italic" pipe="/tmp/fifo1" listen="/tmp/fifo2" title="GForm medium advanced shell script example" width=350 \
box button="btnAdd|Add Name" button="btnDel|Del Name" spring unbox \
box label="|Modify name" input="inp1|Fred" unbox \
checkbox="c1|Got a check box too|on" \
listbox="lb1|$NameList|0|stretch" \
box label="|GUI font" fontbox="fnt1||stretch" unbox \
box spring button="BQ|Quit Button|close"&sleep 1


CleanUp() {
exec 3<&- 2>/dev/null # close the pipe handle
if [ -e "/tmp/fifo2" ]; then
rm /tmp/fifo2
fi
if [ -e "/tmp/fifo1" ]; then
rm /tmp/fifo1
fi

exit
}

ArrayToList() {
txt=""
for s in "${NameArray[@]}"; do txt="$txt,$s"; done
NameList=${txt#,*}
}

Alert() {  
# just using GForm to pop up a message box. 
# it uses the running GUI's internal "message" function
if [ "$2" = "w" ]; then
Send "disable"
Send "message=$1"
Send "enable"
sleep 0.3 # give the GUI a moment to become enabled again
else
Send "message=$1" 2>/dev/null
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
 TextToData "$PText"
 DoCommand "$PText"
 TextToData "$PipeText"
fi
}

DoCommand() {  
# this is the main function for processing the data coming from the GUI.
# The message will be in the form of "object_name|object_text|object_value"
if [ "$1" = "check" ]; then return; fi

if [ "$ACTIVE" = "no" ]; then  # set ACTIVE to "no" to disable this routine
return
fi


if [ "$CName" = "btnAdd" ]; then 
ListIndex="${#NameArray[@]}"
if [ "$NameList" = "" ]; then 
Send "enable=btnDel"; sleep 0.1; fi

NameArray+=( "New Name" )
ArrayToList
Send "setlist=lb1|$NameList\nsetindex=lb1|$ListIndex"

elif [ "$CName" = "btnDel" ]; then 
if [ ${#NameArray[@]} -eq 1 ]; then
NameArray=( ) ; NameList=""
else
NameArray=( "${NameArray[@]:0:$((ListIndex))}" "${NameArray[@]:$ListIndex+1}" )
ArrayToList
fi

if [ "$[ListIndex+1]" -eq ${#NameArray[@]} ]; then ((ListIndex--)); fi

Send "setlist=lb1|$NameList"
Send "setindex=lb1|$ListIndex"
 
if [ "$NameList" = "" ]; then 
sleep 0.2
Send "disable=btnDel"
Send "settext=inp1|"
fi

elif [ "$CName" = "c1" ]; then
 Alert "The Checkbox $CName it's now '$CData'"

elif [ "$CName" = "inp1" ]; then
NameArray[$ListIndex]="$CText"
TMP=$ListIndex
ArrayToList
Send "setlist=lb1|$NameList\nsetindex=lb1|$TMP"

elif [ "$CName" = "fnt1" ]; then
Send "mainfont=$CText"

elif [ "$CName" = "lb1" ]; then
TIndex=$CData
CheckAnotherCom
ListIndex=$TIndex
 Send "settext=inp1|$CText"


elif [ "$CName" = "BQ" ]; then
 Alert "You've Exited." "w"
 CleanUp
else
Alert "unknown message\n$1" "w"
fi

}


# Main()
# This is the main loop, It opens the pipe and if a line of text comes
# through it reads it to $Pipetext and runs the DoCommand() procedure above.
# Closing the GUI deletes the pipe file so our loop runs while the file exists.
IFS=$'\n'
exec 3</tmp/fifo1 
  while [ -e "/tmp/fifo1" ]; do
  read -u 3 PipeText
   if [ ! -z "$PipeText" ]; then  # We got some text so process it.
   TextToData $PipeText
    DoCommand $PipeText
   fi
  done

CleanUp  # clean up and exit.


