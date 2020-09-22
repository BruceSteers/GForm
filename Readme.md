
GForm V1.5.3

(was thinking of calling it Genity)

zenity like form maker using a pipe for shell interaction
Minimum Requirements... 
If you have installed the Gambas3 package you should have all that's needed.
for the complete Gambas3 developement environment type in a terminal..
sudo apt-get install -y gambas3

Otherwise the minimum requirements for GForm are the following packages...
gambas3-runtime 
gambas3-gb-image 
gambas3-gb-gui 
gambas3-gb-form 
gambas3-gb-form-stock

sudo apt-get install -y gambas3-runtime gambas3-gb-image gambas3-gb-gui gambas3-gb-form gambas3-gb-form-stock


Work in progress.


With this app you can simmply (kind of) create GUI's in a shell script and 
monitor/react to the actions in the script using a pipe.

The goal is to be able to make functional GUI apps just with shell
scripting in bash.

It creates a form/window and currently only adds objects to it vertically.
you can create a HBox and add objects to that horizontally.
currently supported objects are...
Button, ToggleButton, ToolButton, TextBox (InputBox), TextArea, MaskBox (passwords), CheckBox, ListBox, 
GridView, DirBox, FontBox, ComboBox, Label, HBox, Spring, Menu


Provided is a few demo bash scripts and some 
help texts containing all the arguments/commands.
One of the example scripts is called 'GForm HELP.sh' 
this simply loads each help file into a TextArea object for your viewing.

Mostly the GForm program is run from within the scripts with a few args to make a GUI.
The pipe=/tmp/fifo1 argument makes the app create a pipe that the script then opens and
waits for messages from the GUI and the listen=/tmp/fifo2 argument makes a pipe for the 
script to be able to control the GUI. (There's a help file on pipe basics)
Messages come in the form of name|text or name|text|value depending on the calling object

There are various examples. Simple, Medium and advanced.
The simple pipe example greates a GUI and simply listens for events, making the script react in various ways.
The medium example is more complex in that as well as a pipe being read by the script monitoring 
messages from the GUI the script is also sending messages back to the GUI to alter objects.

The advanced script is a fully working application that will manage a pkexec policy rule file.
It lists the rules, lets you modify/add or delete rules and then save the changes.
This is not a 'Gambas' application though it is a shell script using a gambas application GForm to create it's GUI.
There is also an updated GridView Version of the pkAppMan script.

There is a simple example showing how to use GForm as a simple button choice requester.
The advantages with GForm over Zenity being able to use multiple rows of buttons.

There's a snapshot image or 2 in the folder. 

Included is the gambas basic source code
This is currently beta , some features might not work and you may find some bugs.

SEE THE EXAMPLE SCRIPTS AND HELP TEXTS FOR INFO ON HOW TO MAKE YOUR OWN SHELL GUI APP.

Happy Scripting :)
Bruce

