#!/bin/bash

while true; do
  inotifywait --exclude \..*\.sw. -re modify .
  clear
  mix test --cover --include integrated &&
    MIX_ENV=test mix dialyzer --halt-exit-status
done
