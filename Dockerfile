FROM alpine:3.18 AS base
# Common dependencies
RUN apk add --no-cache cmake readline-dev build-base tar

FROM base AS buildbase
# Build dependencies
RUN apk add --no-cache git
WORKDIR /opt
RUN wget https://www.lua.org/ftp/lua-5.1.5.tar.gz && tar -xf lua-5.1.5.tar.gz
RUN cd lua-5.1.5 && make linux && make install

FROM buildbase AS luarocks
RUN wget https://luarocks.org/releases/luarocks-3.7.0.tar.gz && tar xf luarocks-3.7.0.tar.gz
RUN cd luarocks-3.7.0 && ./configure && make

FROM buildbase AS luajit
RUN git clone https://github.com/LuaJIT/LuaJIT && cd LuaJIT && git checkout c7db8255e1eb59f933fac7bc9322f0e4f8ddc6e6
RUN cd LuaJIT && make

FROM buildbase AS emmyluadebugger
RUN git clone --depth 1 --branch 1.7.1 https://github.com/EmmyLua/EmmyLuaDebugger
RUN cd EmmyLuaDebugger && mkdir build && cd build && cmake -DCMAKE_BUILD_TYPE=Release ../ && make

FROM base
# Luarocks packages dependencies
RUN apk add --no-cache curl unzip openssl

RUN --mount=type=cache,from=buildBase,source=/opt,target=/opt make -C /opt/lua-5.1.5/ install
RUN --mount=type=cache,from=luarocks,source=/opt,target=/opt make -C /opt/luarocks-3.7.0/ install

# Install here to install lua rocks pkgs in pararell with compilation of emmylua and luajit
RUN luarocks install busted 2.2.0-1;\
	luarocks install cluacov 0.1.2-1;\
	luarocks install luacov-coveralls 0.2.3-1

RUN --mount=type=cache,from=emmyluadebugger,source=/opt,target=/opt make -C /opt/EmmyLuaDebugger/build/ install
RUN --mount=type=cache,from=luajit,source=/opt,target=/opt make -C /opt/LuaJIT/ install

CMD [ "echo", "This container is meant to be ran with docker compose. See: https://github.com/PathOfBuildingCommunity/PathOfBuilding/blob/dev/CONTRIBUTING.md" ]
