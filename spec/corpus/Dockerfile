FROM ghcr.io/pathofbuildingcommunity/pathofbuilding-tests@sha256:171dc3da232b8c874882e4ae3b3aa4a6e130a6c9450a31904b312435a6bf5daf
RUN apk add --no-cache git libxml2-utils zlib-dev && luarocks install lua-zlib 1.4-0
ENV HOME=/tmp
