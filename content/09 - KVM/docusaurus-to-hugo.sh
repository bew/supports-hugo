#!/bin/bash 
TEMP=./tmp.file

for f in ??-*md; do
    touch $TEMP
    i=${f/-*/}
    title=$( cat $f | grep -e "^# " | head -n 1 | sed -r "s/^# //" ) 
    cat << EOF > $TEMP
---
title: "$title" 
weight: $i 
---
EOF
    cat $f | grep -v "^# " | sed -r "s=/static==" >> $TEMP
    cat $TEMP > $f
    rm $TEMP    
done 
