#!/usr/bin/env bash

# This is a medium advanced example bash script to show how to use GForm to create a GUI
# and then have your shell script act upon the input by sending commands back to the GUI
# to modify the data.


# Set up our name list and run Gform.gambas with some args.
NameArray=(Fred Freda "Uncle Bob" Sally)
for s in "${NameArray[@]}"; do txt="$txt,$s"; done
NameList=${txt#,*} ; ListIndex=0

# The following is one long line split using \ to make things clearer
# as each line is each row in the form. note, using option 'quiet' to
# suppress any stdout message unlike the 'Test_GForm (simple).sh' example.

./GForm quiet font="Carlito,14,Italic" pipe="/tmp/fifo1" listen="/tmp/fifo2" title="GForm shell scrip example" \
box button="btn1|Button 1" spring unbox \
box label="Modify name" input="inp1|Fred" unbox \
box checkbox="c1|Got a check box too|on" combobox="cb1|$NameList|0|stretch" unbox \
listbox="lb1|$NameList" \
fontbox="fnt1|nostretch" \
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

Alert() {  # just using Gform to pop a message
if [ "$2" = "w" ]; then
Send "disable" # put main gui to sleep while message opens
gbr3 GForm quiet toponly title="Notice.." label="$1" button="|Okay|close" 2>/dev/null
Send "enable"
sleep 0.2  # give the GUI a moment to become enabled or messages can be missed
else
gbr3 GForm quiet toponly title="Notice.." label="$1" button="|Okay|close" 2>/dev/null&false
fi
}

Send() {
echo -e "$1\n" >/tmp/fifo2
}

DoCommand() {  
# this is the main function for processing the data coming from the GUI.
# The message will be in the form of "object_name|object_text|object_value"

if [ "$ACTIVE" = "no" ]; then  # set ACTIVE to "no" to disable this routine
return
fi

CName=${PipeText%%|*}   # get the name of the control talking to us.

TMP=${PipeText#*|}
if [[ "$TMP" = *"|"* ]]; then
 CText=${TMP%|*}        # see if rest of message has another field.
 CData=${TMP#*|}        # Toggle buttons, checkboxes, etc have other info
else
 CText="$TMP"
 CData=""
fi

# message has now been split into $CName , $CText and $CData
# so we can add our procedures here according to the GUI data.

if [ "$CName" = "btn1" ]; then 
  Alert "number 1 got pressed.\ni'll toggle the checkbox" "w" # using "w" disables main gui
 
 # Send a command to the GUI. Note, sending 'stop' <command> then 'start'
 # stops the GUI sending event messages while we alter things.

  Send "stop\nsetvalue=c1\nstart"

elif [ "$CName" = "c1" ]; then
 Alert "The Checkbox $CName it's now '$CData'" "w"

elif [ "$CName" = "inp1" ]; then
NameArray[$ListIndex]="$CText"
TMP=$ListIndex
ArrayToList
Send "stop\nsetlist=lb1=$NameList\nsetlist=cb1=$NameList\nsetindex=cb1=$TMP\nstart"

elif [ "$CName" = "fnt1" ]; then
Send "mainfont=$CText"

elif [ "$CName" = "lb1" ]; then
 ListIndex=$CData
 Send "settext=inp1=$CText\nstop\nsetindex=cb1=$ListIndex\nstart"

elif [ "$CName" = "cb1" ]; then
 ListIndex=$CData       # Remember the list position
 Send "settext=inp1=$CText\nstop\nsetindex=lb1=$ListIndex\nstart"

elif [ "$CName" = "BQ" ]; then
 Alert "You've Exited." "w"
 CleanUp
fi

}


# Main()
# This is the main loop, It opens the pipe and if a line of text comes
# through it reads it to $Pipetext and runs the DoCommand() procedure above.
# Closing the GUI deletes the pipe file so our loop runs while the file exists.

exec 3</tmp/fifo1 
  while [ -e "/tmp/fifo1" ]; do
  read -u 3 PipeText
   if [ ! -z "$PipeText" ]; then  # We got some text so process it.
    DoCommand
   fi
  done

CleanUp  # clean up and exit.


