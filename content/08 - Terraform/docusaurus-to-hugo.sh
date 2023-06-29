#!/bin/bash 
TEMP=./tmp.file

for f in *md; do
    touch $TEMP
    sed -ir "s=/static==" $f
    rm $TEMP    
    break
done 
