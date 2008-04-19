#!/bin/bash

rm -rf tmp
mkdir -p tmp
cd tmp
create_book --name=Test-Common
for brand in fedora JBoss RedHat; do
	create_book --name=Test-$brand --brand=$brand;
done

for brand in Common fedora JBoss RedHat; do
	make --directory=Test-$brand html-en-US html-single-en-US pdf-en-US;
	(firefox Test-$brand/tmp/en-US/html-single/index.html &)
	(firefox Test-$brand/tmp/en-US/html/index.html&)
	(evince Test-$brand/tmp/en-US/pdf/Test-$brand.pdf &)
done

