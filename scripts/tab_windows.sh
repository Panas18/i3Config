#!/bin/bash

id=`~/.scripts/list_id.py`
i3-msg [id="$id"] focus > /dev/null