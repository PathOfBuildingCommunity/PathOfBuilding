FROM ubuntu:latest

# First, ensure that you have development tools installed on your system, otherwise run the command below to install them.
RUN apt update && \
    apt install -y --no-install-recommends \
    build-essential \
    libreadline-dev \
    unzip \
    curl \
    wget \
    git \
    ca-certificates

RUN cd /home

# Then to build and install Lua, run the following commands to download the package tar ball, extract, build and install it.
RUN curl -R -O http://www.lua.org/ftp/lua-5.1.5.tar.gz && \
    tar -zxf lua-5.1.5.tar.gz  && \
    cd lua-5.1.5 && \
    make linux test && \
    make install

# Download and unpack the LuaRocks tarball using following commands.
RUN wget https://luarocks.org/releases/luarocks-3.7.0.tar.gz && \
    tar zxpf luarocks-3.7.0.tar.gz && \
    cd luarocks-3.7.0 && \
    ./configure --with-lua-include=/usr/local/include && \
    make && \
    make install

# Install luajit
RUN cd /home && \
    git clone https://luajit.org/git/luajit.git && \
    cd luajit \
    make && \
    make install && \
    ln -sf luajit-2.1.0-beta3 /usr/local/bin/luajit

# Setupping test enviroment
RUN luarocks install busted && \
    luarocks install cluacov

RUN cd /root
COPY . .

ENTRYPOINT []