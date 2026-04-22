#!/bin/bash
set -e
failed=0
for file in "$@"; do
  if [ -f "$file" ] && [[ "$file" == *.sh ]]; then
    if [ ! -x "$file" ]; then
      echo "Not executable: $file"
      failed=1
    fi
  fi
done
exit $failed
