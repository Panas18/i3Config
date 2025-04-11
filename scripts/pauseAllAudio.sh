#!/bin/bash

/bin/bash -c "/usr/bin/amixer -q -D pulse sset Master mute; /usr/bin/killall -q -STOP 'pulseaudio'"

