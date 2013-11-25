#!/bin/bash
if [ "$2" ]
then
	echo "Usage: unpack FILE.{zip|rar}"
fi
filename=$1
file=`expr match "$filename" '\(.*\)\.[a-z]*'`
postfix=`expr match "$filename" '.*\.\([a-z]*\)'`
if [ "$postfix" == "rar" ]
then
	mkdir "$file"
	mv "$filename" "$file"
	cd "$file"
	unrar x "$filename"
	mv "$filename" ..
	dirnum=`ls -l|grep -e ^d|wc -l`
	if [ "$dirnum" == "1" ]
	then
		dironly=`ls`
		mv ./"$dironly"/* .
		rm -rf ./"$dironly"
	fi
	cd ..
elif [ "$postfix" == "zip" ] || [ "$postfix" == "jar" ] || [ "$postfix" == "war" ]
then
	mkdir "$file"
	mv "$filename" "$file"
	cd "$file"
	unzip "$filename"
	mv "$filename" ..
	dirnum=`ls -l|grep -e ^d|wc -l`
	if [ "$dirnum" == "1" ]
	then
		dironly=`ls`
		mv ./"$dironly"/* .
		rm -rf ./"$dironly"
	fi
	cd ..
else
	echo "Usage: unpack FILE.{zip|rar}"
fi
