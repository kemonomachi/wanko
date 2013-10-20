#!/usr/bin/bash

DIV="------------------------------------------------------------------------"
COLOR=$(tput setaf 46)
RESET=$(tput sgr0)

if (( $# == 0 ))
then
  testfiles=( test_*.rb )
else
  testfiles=( "$@" )
fi

for file in "${testfiles[@]}"
do
  echo "${COLOR}$DIV"
  echo "$file:${RESET}"
  ruby "$file"
done

