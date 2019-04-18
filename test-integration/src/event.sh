#!/usr/bin/env bash

#%include std/event.sh

# Test that both steps of event signatures and function signatures chain properly

$%on ev1 ev2 dostuff(eventname) {
    echo "Stuff on event _${eventname}_"
}

event:trigger "ev1"
