#!/usr/bin/env bash

# This is a simple example bash script to show how to use GForm to create a GUI
# and then have your shell script act upon the input.


# Run Gform.gambas with some args.
./GForm pipe="/tmp/fifo1" \
box button="btn|Button 1" button="btn|Button 2" tgbutton="tbtn|Toggle button" unbox \
box label="lab1|Enter Text String & hit enter" input="inp1|Textbox here" unbox \
checkbox="c1|Got a check box too|on" \
box button="OK|Okay|close" button="BQ|Quit Button|quit"&false

 while [ ! -e "/tmp/fifo1" ]; do
  sleep 0.1
 done

CleanUp() {
exec 3<&- 2>/dev/null
if [ -e "/tmp/fifo2" ]; then
rm /tmp/fifo2
fi
if [ -e "/tmp/fifo1" ]; then
rm /tmp/fifo1
fi
 Alert "You've Exited. Quitting..." "w"
exit
}

Alert() {  # Example using Gform to pop up a message
if [ "$2" = "w" ]; then
gbr3 GForm quiet toponly title="Notice.." label="|$1" button="|Okay|close icon=ok" 2>/dev/null
else
gbr3 GForm quiet toponly title="Notice.." label="|$1" button="|Okay|close icon=ok" 2>/dev/null&false
fi
}

DoCommand() {  
# this is the main function for processing the data coming from the GUI.
# The message will be in the form of "object_name|object_text|object_value"

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

if [ "$CName" = "btn" ]; then 
 # handle both buttons here as they have the same name 'btn'
 if [ "$CText" = "Button 1" ]; then
  Alert "number 1 got pressed."
 else
  Alert "number 2 got a push."
 fi

elif [ "$CName" = "tbtn" ]; then
 Alert "The ToggleButton got pressed.\nit is now '$CData'"

elif [ "$CName" = "c1" ]; then
 Alert "The Checkbox $CName it's now '$CData'"

elif [ "$CName" = "inp1" ]; then
 echo "The textbox inp1 changed to '$CText'"

# note, alert for quit buttons adds the "w" (wait) option otherwise
# the calling shell can terminate and close the mesaage prematurely
elif [ "$CName" = "OK" ]; then
 Alert "You've closed GUI but okay pressed.\nHere your script could continue" "w"
 CleanUp
elif [ "$CName" = "BQ" ]; then
 CleanUp
fi

}


# Main()
# This is the main loop, It opens the pipe and if a line of text comes
# through it reads it to #Pipetext and runs the DoCommand() procedure above.
# Closing the GUI deletes the pipe file so our loop runs while the file exists
 
exec 3</tmp/fifo1 
  while [ -e "/tmp/fifo1" ]; do
  read -u 3 PipeText
   if [ ! -z "$PipeText" ]; then  # We got some text so process it.
    DoCommand
   fi
  done

CleanUp  # clean up and exit.


