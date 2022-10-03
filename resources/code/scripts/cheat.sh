#!/bin/bash

if [[ -n "$1" ]]; then
  while (( "$#" )); do
    if [[ ! ( "$1" =~ ^[0-9]+$ ) ]]; then
      echo "Cheat code has to be an integer, got '$1'"
      # Cannot exit because we are sourcing
      # exit 1
    else
      echo "Running and installing cheat $1"
      cheat=$( printf 'cheat-%02d.sh' $1  ) 
      ( cat ~/environment/restore-cheats.txt; echo $cheat ) | sort -u > ~/environment/restore-cheats.txt
      source ~/environment/aws-fault-injection-simulator-workshop/resources/code/scripts/$cheat
  
      fgrep '~/environment/aws-fault-injection-simulator-workshop/resources/code/scripts/cheat.sh' ~/.bashrc > /dev/null
      if [[ $? -eq 1 ]]; then
        echo 'source ~/environment/aws-fault-injection-simulator-workshop/resources/code/scripts/cheat.sh' >> ~/.bashrc
      fi
  
    fi
    shift
  done
else
  echo "Restoring achievements"
  for file in $( cat ~/environment/restore-cheats.txt ); do
    source ~/environment/aws-fault-injection-simulator-workshop/resources/code/scripts/$file
  done
fi
