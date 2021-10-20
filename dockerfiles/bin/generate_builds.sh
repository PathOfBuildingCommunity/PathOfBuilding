#!/bin/sh
cd dockerfiles
docker build -t busted:generation -f Dockerfile_generation .
cd ..
docker run -v $(pwd):/root --rm -i busted:generation busted --lua=luajit -r generate