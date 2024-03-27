FROM alpine:3.18 as base
RUN apk add --no-cache curl unzip openssl build-base readline-dev cmake readline-dev git ca-certificates libcurl curl-dev zlib parallel tar libxml2-utils

FROM base as buildbase
WORKDIR /opt
RUN wget https://www.lua.org/ftp/lua-5.1.5.tar.gz && tar -xf lua-5.1.5.tar.gz
RUN cd lua-5.1.5 && make linux && make install

FROM buildbase as luarocks
RUN wget https://luarocks.org/releases/luarocks-3.7.0.tar.gz && tar xf luarocks-3.7.0.tar.gz
RUN cd luarocks-3.7.0 && ./configure && make

FROM buildbase as luajit
RUN git clone --depth 1 --branch v2.1.0-beta3 https://github.com/LuaJIT/LuaJIT
RUN cd LuaJIT && make

FROM buildbase as emmyluadebugger
RUN git clone --depth 1 --branch 1.7.1 https://github.com/EmmyLua/EmmyLuaDebugger
RUN cd EmmyLuaDebugger && mkdir build && cd build && cmake -DCMAKE_BUILD_TYPE=Release ../ && make

FROM base
RUN --mount=type=cache,from=buildBase,source=/opt,target=/opt make -C /opt/lua-5.1.5/ install
RUN --mount=type=cache,from=luarocks,source=/opt,target=/opt make -C /opt/luarocks-3.7.0/ install

#Install here to install pkgs in pararell with compilation of emmylua and luajit
RUN luarocks install busted
RUN luarocks install cluacov
RUN luarocks install Lua-cURL
RUN luarocks install lua-zlib
RUN luarocks install luaposix

RUN --mount=type=cache,from=luajit,source=/opt,target=/opt make -C /opt/LuaJIT/ install && ln -sf /usr/local/bin/luajit-2.1.0-beta3 /usr/local/bin/luajit
RUN --mount=type=cache,from=emmyluadebugger,source=/opt,target=/opt make -C /opt/EmmyLuaDebugger/build/ install