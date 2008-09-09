#!/bin/bash

rm -rf tmp
mkdir -p tmp
cd tmp
pwd=`pwd`

#for type in Book Article Set; do
for type in Book Article; do
	for brand in common fedora JBoss RedHat; do
		create_book --name=Test-$brand-$type --brand=$brand --type=$type --product=$brand;
		make --directory=Test-$brand-$type html-en-US html-single-en-US pdf-en-US;
#		make --directory=Test-$brand-$type html-single-en-US;
		(firefox $pwd/Test-$brand-$type/tmp/en-US/html-single/index.html &);
		(firefox Test-$brand-$type/tmp/en-US/html/index.html&)
		(evince Test-$brand-$type/tmp/en-US/pdf/Test-$brand-$type.pdf &)
	done
done

