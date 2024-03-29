#!/bin/bash

# This script comes with ABSOLUTELY NO WARRANTY, use at own risk
# Copyright (C) 2019 Osiris Alejandro Gomez <osiux@osiux.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

# shellcheck disable=SC2129
# shellcheck disable=SC2002
# shellcheck disable=SC1117

START="$(date +%s)"

RED="$(tput setaf 196)"

TMP0=$(mktemp)
TMP1=$(mktemp)
TMP2=$(mktemp)

TXT='links.txt'
BAK='links.bak'
LST='lists.txt'
HDR="$HOME/blog/header-links.txt"

BIN_BASH="$(command -v bash)"

die()
{
  printf "%s\n" "${RED}[ERROR] $1 $NORMAL" && exit 1
}

stderror ()
{
  echo >&2 "$1"
}

get_title()
{
  $BIN_BASH url2title "$U" \
  | tr -d '[]'               \
  | sed 's/GitHub - .*: //g'
}

[[ -z "$1" ]] || TXT="$1"
[[ -z "$2" ]] || LST="$2"
[[ -z "$3" ]] || HDR="$3"

for FILE in $TXT $HRD
do
  [[ ! -e "$FILE" ]] && die "NOT FOUND $FILE"
  [[ ! -s "$FILE" ]] && die "EMPTY $FILE"
done

BAK="$(basename "$TXT" .txt).bak"

sed -i 's/+$//g' "$TXT"
sed -i 's/ + +/ +/g' "$TXT"
sed -i 's/blob\/master\/README.md//gI' "$TXT"
sed -i 's/blob\/dev\/README.md//gI' "$TXT"

sort -u "$TXT" | sponge "$TXT"

awk '{print $2}' "$TXT" | sort -u > "$TMP0"

true > "$BAK"

grep -f "$TMP0" "$TXT" | sort -u | sort -k3 | while read -r D U C
do
  DATE=$(echo "$D" | grep -E -o '[0-9]{4}-[0-9]{2}-[0-9]{2}')
  CATEGORY=$(echo "$C" | tr ' ' '\n' | head -1)

  [[ -z "$CATEGORY" ]] && CATEGORY="+unknown"

  printf "%s %s %s\\n" "$CATEGORY" "$DATE" "$U"

  echo "$D $U $CATEGORY" >> "$BAK"
done > "$TMP1"

sort -u "$BAK" > "$TXT"

awk '{print $1}' "$TMP1" | sort -u > "$TMP2"

[[ -e "$LST" ]] && true         >  "$LNK"
[[ -e "$HDR" ]] && cat "$HDR"   >> "$LST"

printf "\\n## Recents links\\n\\n" >> "$LST"

tail -30 "$TXT" | sort -nr | while read -r DATE U C
do

  TITLE="$(get_title "$U")"

  if [[ -z "$TITLE" ]]
  then
    printf "=> %s\\n" "$U"
  else
    printf "=> %s %s\\n" "$U" "$TITLE"
  fi

done >> "$LST"

printf "\\n" >> "$LST"

cat "$TMP2" | while read -r C
do
  printf "\\n## %s\\n\\n" "$C"

  REGEXP="^\+$C"
  grep -E "$REGEXP" "$TMP1" | sort -u | while read -r _ DATE U
  do

    [[ -z "$U" ]] && continue
    [[ -z "$DATE" ]] && continue
    stderror "$U"
    TITLE="$(get_title "$U")"

    if [[ -z "$TITLE" ]]
    then
      printf "=> %s\\n" "$U"
    else
      printf "=> %s %s\\n" "$U" "$TITLE"
    fi

  done

done >> "$LST"

rm -f "$TMP0"
rm -f "$TMP1"
rm -f "$TMP2"

END="$(date +%s)"

SECONDS="$((END-START))"

stderror "total time $SECONDS seconds"
