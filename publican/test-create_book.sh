#!/bin/bash

rm -rf tmp
mkdir -p tmp
cd tmp
create_book --name=Test-Common
for brand in fedora JBoss RedHat; do
	create_book --name=Test-$brand --brand=$brand;
done

for brand in Common fedora JBoss RedHat; do
	make --directory=Test-$brand html html-single;
	firefox Test-$brand/tmp/en-US/html-single/index.html;
	firefox Test-$brand/tmp/en-US/html/index.html;
done
