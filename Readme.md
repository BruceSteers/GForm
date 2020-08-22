
GForm  (was thinking of calling it Genity)

zenity like form maker using a pipe for shell interaction

Work in progress.


With this app you can simmply (kind of) create GUI's in a shell script and 
monitor/react to the actions in the script using a pipe.

The goal is to be able to make functional GUI apps just with shell
scripting in bash.

It currently lack lots of features but is still useable.

It creates a form/window and currently only adds objects to it vertically.
you can create a HBox and add objects to that horizontally.
currently supported objects are...
Button, ToggleButton, TextBox (InputBox), CheckBox, ListBox, 
DirBox, FontBox, ComboBox, Label, HBox, Spring
<pre>
Arguments are....
(Runtime args when launching GForm)

title="Title for window top"
width=<n> , manually define a window width
font=font name , Sets the main form font Eg 'Carlito,14,Italic'
noresize , makes form non resizable
topmost or toponly , forces window to stay above others.

box , makes a Horizontal box, subsequent objects go in the box horizontally until unboxed
unbox , finishes the box

button="name|text|flags" , makes a button (close makes button close the window)
tbutton="name|text|flags" , makes a ToggleButton, use 'on' to make it down
input="name|text|flags" , makes a TextBox 
checkbox="name|text|flags" , makes a CheckBox , use 'on' for ticked
fontbox="name|FontName|flags"
dirbox="name|path|flags" , makes a dirbox derectory chooser
combobox="name|comma,seperated,list|index|flags" , makes a read-only combobox, index is selected number
listbox="name|comma,seperated,list|index|flags" , makes a list box, index is selected number
label="text" , makes a label.

For all above objects, 'flags' can be..
'on' for toggle button or checkbox state on load, 
'disabled' disables object, 
'hidden' hides the object, 'stretch' or 'nostretch' forces object resizing
'close' or 'quit' makes button close GUI after pressed

spring , adds a spring, place to push objects, eg. "box spring button unbox" will push button to the right.

pipe="path/to/pipe" , name of the pipe file (Eg. /tmp/fifo1) GForms way of talking to your script
listen="path/to/pipe", name of listening pipe file (Eg. /tmp/fifo2) your scripts way to control GForm 

quiet , suppresses any stdout messages (not pipe messages)

(Arguments sent to GForm via listening pipe)
settext=object_name=text , sets text field of named object
setindex=object_name=number , selects the numbered item in either a listbox or combobox
setlist=object_name=comma,seperated,list  , changes the whole item list in either listbox or combobox
setlistitem=object_name=text=number  , changes a single numbered item text in either listbox or combobox
hide=object_name , hides named object, use 'hide' alone to hide main wiindow
show=object name, opposite of hide
disable=object_name , disables named object, use 'disable' alone to disable main wiindow
enable=object_name , opposite of disable
setfont=object_name|font , sets font for an object
getfont=object_name , gets font name for an object
setfocus=object_name , make object active
setvalue=object_name=on or off or blank for toggle (checkbox or togglebutton)
getinfo=object_name , get info on an object (text,index,value,etc)
move=x,y,w,h , moves or resizes window, numbers can be absolute or relative +- or absent
Eg.  'move=20,20,,' moves window to position 'move=,,+20,' grows width by 20

mainfont=font name , changes GUI main font 

dialoge=type|default|flags , opens a requester dialog
type can be openfile, opendir, savefile, color, font (title sets the title)
flags can be showhidden or multi
Eg.
dialog=title|Select folder to open...
dialog=opendir|/home/|showhidden

message="Message text" , pops open a message window
stop or start , pauses the gui sending your script messages while you alter objects.

quit or close , closes the GUI
</pre>
Provided is a demo bash script.

The GForm.gambas program is run from within the script with a few args to make a GUI.
The pipe=/tmp/fifo1 argument makes the app create a pipe that the script then opens and
waits for messages from the GUI.

Messages come in the form of name|text or name|text|value depending on the calling object

A Snapshot.png image is in the folder. the arguments for this were...
tbutton="B1|Hello|on" input="Inp3|some text" box tbutton="B2|Goodbye" button="B3|oooh" unbox button="b4|well then" box label="This box" input="I3|more txt" label="another label" input="I4|will 2 be ok" unbox box checkbox="cb1|Check box this|on" combobox="cmb1|l1,list 2,the third|2" unbox button="BQ|Quit|close" pipe=/tmp/fifo1

Like i said, lots to add to this.
Vertical layout features/objects are missing because i've not written the routines yet to 
work out the apps height. currently it's working things out simply.
also plan to make it useable like zenity where it doesn't create the pipe and just 
gives all the data when closed.

Included is the gambas basic source code
This is currently beta , some features do not work and you may find some bugs.

SEE THE EXAMPLE SCRIPTS FOR INFO ON HOW TO MAKE YOUR OWN SHELL GUI APP.

Bruce

