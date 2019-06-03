#!/bin/sh

heading() {
  MAG='\033[0;35m'
  CLR='\033[0m'
  echo ""
  echo "${MAG}** $@ **${CLR}"
  echo ""
}

fail() {
  >&2 echo "error: $@"
  exit 1
}

has_command() {
  command -v "$1" >/dev/null 2>&1
}

