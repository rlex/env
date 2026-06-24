#!/bin/bash
CURRENT=$(kitten @ ls | jq -r '.[] | select(.is_focused) | .background_opacity')
[ "$CURRENT" = "1.0" ] && kitten @ set-background-opacity 0.8 || kitten @ set-background-opacity 1.0