#!/bin/sh
cd dockerfiles
docker build -t busted:generation -f Dockerfile .
cd ..
docker run -v $(pwd):/root --rm -i busted:generation busted --lua=luajit -r generate