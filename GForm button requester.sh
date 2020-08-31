#!/usr/bin/env bash

ANS=$(./GForm allstretch return=t width=350 title="GForm button requester example" \
label="|\nthis is an example of a multiple row button requester\nPressing any button will return the button text to the shell\n" \
box button="|Button 1" button="|button 2" button="|Button 3" unbox \
box button="|Button 4" button="|Button 5" button="|Button quit")


./GForm quiet toponly title="Notice.." label="|$ANS was the selection" button="|Okay|close"

