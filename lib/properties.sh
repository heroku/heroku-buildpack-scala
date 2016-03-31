#!/usr/bin/env bash

get_property() {
  local propFile=$1
  local propName=$2
  local propDefault=${3:-""}

  if [ -f ${propFile} ]; then
    local propValue=$(sed '/^\#/d' ${propFile} | grep "${propName}"  | tail -n 1 | cut -d "=" -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    echo "${propValue:-$propDefault}"
  else
    echo "${propDefault}"
  fi
}
