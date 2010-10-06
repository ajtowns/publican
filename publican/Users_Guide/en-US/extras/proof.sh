#!/bin/sh
# Jeff Fearn 2010

ASPELL_EXCLUDES=programlisting,userinput,screen,filename,command,computeroutput,abbrev,accel,orgname,surname,foreignphrase,acronym,hardware

for file in `find en-US -wholename '*/extras/*' -prune -o -name \*.xml -print`; do
	echo "Processing $file";
	aspell --list --lang=en-US --mode=sgml --add-sgml-skip={$ASPELL_EXCLUDES} < $file  | sort -u;
	echo;
done

