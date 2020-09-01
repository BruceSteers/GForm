#!/usr/bin/env bash

# This is a medium advanced example bash script to show how to use GForm to create a GUI
# and then have your shell script act upon the input by sending commands back to the GUI
# to modify the data.

if [ -e "/tmp/fifo2" ]; then rm /tmp/fifo2; fi
if [ -e "/tmp/fifo1" ]; then rm /tmp/fifo1; fi
CurDir=$(pwd)
# Set up our list using dir to get contents of help dir and run Gform.gambas with some args.
IFS=$'\n'
HDIR="$CurDir/help"
if [ ! -e "$HDIR/2 Runtime args.txt" ]; then
 HDIR="$CurDir"
 if [ ! -e "$HDIR/2 Runtime args.txt" ]; then
  gbr3 GForm quiet toponly title="Notice.." label="|Help Files were not found|\nPlease download them from the GForm github" button="|Okay|close icon=ok" 2>/dev/null
  exit
 fi
fi
FILES=$(dir -1N "$HDIR/")
read -d '{' -a NameArray <<< "$FILES{"
for s in "${NameArray[@]}"; do txt="$txt,$s"; done
NameList=${txt#,*}

# The following is one long line split using \ to make things clearer
# as each line is each row in the form. note, using option 'quiet' to
# suppress any stdout message unlike the 'Test_GForm (simple).sh' example.

./GForm quiet font="Carlito,14,Italic" width=scr-200 pipe="/tmp/fifo1" listen="/tmp/fifo2" title="GForm medium advanced shell script example" \
box label="|Current File" input="inp1||readonly left" unbox \
listbox="lb1|$NameList||nostretch lines=6 background=200,220,220" \
textarea="ta1|Help will be here\nJust select a topic..|stretch readonly lines=10 background=210,220,210" \
box label="|Change font" fontbox="fnt1||stretch" fbutton="lft||icon=text-left" fbutton="ctr||icon=text-center" fbutton="rgt||icon=text-right" spring button="BQ|Quit|close icon=quit"&false

 while [ ! -e "/tmp/fifo1" ]; do
 sleep 0.1
 done
AppOpen=1


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

Alert() {  
# just using GForm to pop up a message box. 
# it uses the running GUI's internal "message" function
if [ $AppOpen -eq 0 ]; then
gbr3 GForm quiet toponly title="Notice.." label="|$1" button="|Okay|close icon=ok" 2>/dev/null
return
fi
Send "message=$1"
}

Send() {
echo -e "$1" >>/tmp/fifo2
}

TextToData() {
PT=$1
CName=${PT%%|*}   # get the name of the control talking to us.
TMP=${PT#*|}
if [[ "$TMP" = *"|"* ]]; then
 CText=${TMP%|*}        # see if rest of message has another field.
 CData=${TMP#*|}        # Toggle buttons, checkboxes, etc have other info
else
 CText="$TMP"; CData=""
fi
}


DoCommand() {  
# this is the main function for processing the data coming from the GUI.
# The message will be in the form of "object_name|object_text|object_value"

if [ "$CName" = "fnt1" ]; then Send "mainfont=$CText"

elif [ "$CName" = "lb1" ]; then
 ListIndex=$CData
echo "$HDIR/$CText"
 TXT=$(cat "$HDIR/$CText")
 Send "settext=inp1|$CText"
 Send "filetext=ta1|$HDIR/$CText"

elif [ "$CName" = "lft" ]; then  Send "align=ta1|l" 
elif [ "$CName" = "ctr" ]; then  Send "align=ta1|c" 
elif [ "$CName" = "rgt" ]; then  Send "align=ta1|r" 

elif [ "$CName" = "BQ" ]; then  CleanUp 

else
Alert "unknown message\n$1" "w"
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
   TextToData $PipeText
    DoCommand $PipeText
   fi
  done

CleanUp  # clean up and exit.


