
GForm  (was thinking of calling it Genity)

zenity like form maker using a pipe for shell interaction

Work in progress.


With this app you can simmply (kind of) create GUI's in a shell script and 
monitor/react to the actions in the script using a pipe.

The goal is to be able to make functional GUI apps just with shell
scripting in bash.

It creates a form/window and currently only adds objects to it vertically.
you can create a HBox and add objects to that horizontally.
currently supported objects are...
Button, ToggleButton, ToolButton, TextBox (InputBox), CheckBox, ListBox, 
DirBox, FontBox, ComboBox, Label, HBox, Spring



<pre>
Arguments are....
(Runtime args when launching GForm)
vesrion or ver , displays version number and exits.

title="Title for window top"
width=<n> , manually define a window width
font=font name , Sets the main form font Eg 'Carlito,14,Italic'
noresize , makes form non resizable
topmost or toponly , forces window to stay above others.
return=<mode> ; set behaviour if not using the pipe feature, can be 'name', 'text' or 'all'

box , makes a Horizontal box, subsequent objects go in the box horizontally until unboxed
unbox , finishes the box

button="name|text|flags" , makes a button (close makes button close the window)
tgbutton="name|text|flags" , makes a ToggleButton, use 'on' to make it down
toolbutton"name|text|flags" , makes a flat toolbar style button
input="name|text|flags" , makes a TextBox 
checkbox="name|text|flags" , makes a CheckBox , use 'on' for ticked
fontbox="name|FontName|flags"
dirbox="name|path|flags" , makes a dirbox derectory chooser
combobox="name|comma,seperated,list|index|flags" , makes a read-only combobox, index is selected number
listbox="name|comma,seperated,list|index|flags" , makes a list box, index is selected number
gridview="name|comma,seperated,COLUMN list|flags" , makes a list with rows and columns, Set column headers
griditems="gridview_name|comma,seperated,list1|comma,sep,list2..|index" , add items to named GridView
label="name|text" , makes a label.

For all above objects, 'flags' can be..
'on' for toggle button or checkbox state on load, 
'disabled' disables object, 
'hidden' hides the object, 
'stretch' or 'nostretch' forces object resizing or not
'readonly' for input box (or any other control that supports it)
'left' 'right' or 'center' for text alignment

'close' or 'quit' makes button close GUI after pressed , Note

spring , adds a spring, place to push objects, eg. "box spring button unbox" will push button to the right.

pipe="path/to/pipe" , name of the pipe file (Eg. /tmp/fifo1) GForms way of talking to your script
listen="path/to/pipe", name of listening pipe file (Eg. /tmp/fifo2) your scripts way to control GForm 

quiet , suppresses any stdout messages (not pipe messages)

(Arguments sent to GForm via listening pipe)
settext=object_name=text , sets text field of named object
setindex=object_name=number|nolock , selects the numbered item in either a listbox or combobox or gridview
  use 'nolock' if you want to trigger the list selection event as if you clicked it.
setlist=object_name=comma,seperated,list  , changes the whole item list in either listbox or combobox
setlistitem=object_name=text=number  , changes a single numbered item text in either listbox or combobox
hide=object_name , hides named object, use 'hide' alone to hide main wiindow
show=object name, opposite of hide
disable=object_name , disables named object, use 'disable' alone to disable main wiindow
dislist=lit|of|object|names , disables all objects in the list
enable=object_name , opposite of disable
enlist=lit|of|object|names , enables all objects in the list
setfont=object_name|font , sets font for an object
getfont=object_name , gets font name for an object
setfocus=object_name , make object active
setvalue=object_name=on or off or blank for toggle (checkbox or togglebutton)
getinfo=object_name , get info on an object (text,index,value,etc)
move=x,y,w,h , moves or resizes window, numbers can be absolute or relative +- or absent
Eg.  'move=20,20,,' moves window to position 'move=,,+20,' grows width by 20

mainfont=font name , changes GUI main font 

dialog=type|default|flags , opens a requester dialog
type can be openfile, opendir, savefile, color, font (title sets the title)
flags can be showhidden or multi , the dialog will message back the result to the pipe or a blank text.
Eg.
dialog=title|Select folder to open...
dialog=opendir|/home/|showhidden
read -u 3 NEWAPP
if [ -z "$NEWAPP" ]; then
echo "Change path Cancelled.."
fi

gridview=gridview_name|command|args, commands for gridview as follows...
add|comma,seperated,list|index , adds an item at index or to list end if no index supplied
del|index , delete row at index or selected row if omitted
clear , Clears list items but not the columns
getrow|index , returns comma seperated list or all items in selected row or at index
setrow|comma,sep,list|index , sets whole row to list at index or selected
gettext|row,column , get a single cell text from numbered cell
settext|row,column , Sets a single cell text at numbered cell
getall , gets ALL list items, each row is seperated by '|', each column by ','

message="Message text" , pops open a message window
stop or start , pauses the gui sending your script messages while you alter objects.
hold or unhold , stops/starts gui processing internal events like button presses.
check , makes GUI reply 'check' , use this to check if there are any messages backlogged in the pipe.
Ie , send the command 'check' to the gui then read the reply, it should just be 'check' messaged back, 
  if not then there was a command waiting, so proccess the command and read the pipe line again until it reads 'check'

quit or close , closes the GUI
</pre>

Provided is a few demo bash scripts.

The GForm.gambas program is run from within the scripts with a few args to make a GUI.
The pipe=/tmp/fifo1 argument makes the app create a pipe that the script then opens and
waits for messages from the GUI.
Messages come in the form of name|text or name|text|value depending on the calling object

There are 3 pipe mode examples. Simple, Medium and advanced.
The simple example greates a GUI and simply listens for events, making the script react in various ways.
The medium example is more complex in that as well as a pipe being read by the script monitoring 
messages from the GUI the script is also sending messages back to the GUI to alter objects.

The advanced script is a fully working application that will manage a pkexec policy rule file.
It lists the rules, lets you modify/add or delete rules and then save the changes.
This is not a 'Gambas' application it is a shell script using a gambas application GForm to create it's GUI.

There is a simple example showing how to use GForm as a simple button choice requester.
The advantages with GForm over Zenity being able to use multiple rows of buttons.

A Snapshot.png image is in the folder. the arguments for this were...
tbutton="B1|Hello|on" input="Inp3|some text" box tbutton="B2|Goodbye" button="B3|oooh" unbox button="b4|well then" box label="This box" input="I3|more txt" label="another label" input="I4|will 2 be ok" unbox box checkbox="cb1|Check box this|on" combobox="cmb1|l1,list 2,the third|2" unbox button="BQ|Quit|close" pipe=/tmp/fifo1

Included is the gambas basic source code
This is currently beta , some features might not work and you may find some bugs.

SEE THE EXAMPLE SCRIPTS FOR INFO ON HOW TO MAKE YOUR OWN SHELL GUI APP.

Bruce

