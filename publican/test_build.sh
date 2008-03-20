#!/bin/bash

make srpm;

brew build --scratch --nowait dist-4E-eso `find . -name "*el4.src.rpm"`;
brew build --scratch --nowait dist-5E-eso `find . -name "*el5.src.rpm"`;
#	plague-client build publican `find . -name "*el$dist.src.rpm"` EL-$dist;

#koji build --scratch --nowait dist-f9 `find . -name "*fc9.src.rpm"`;
