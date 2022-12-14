FROM debian:stable-20221114-slim

# Runtime env variables for printing output masseges
ARG MESSAGE_DIVIDER='==================================' \
    DOCKER_MSG_COLOR='\033[92m\033[100m' \
    DOCKER_RESET_COLOR='\033[0m'
ARG BEF="${DOCKER_MSG_COLOR}\n\n${MESSAGE_DIVIDER}\n" \
    AFT="\n${MESSAGE_DIVIDER}\n${DOCKER_RESET_COLOR}\n"

ENV DEBIAN_FRONTEND noninteractive

# Update and install make gcc groff-base libtool
RUN echo "${BEF}Update and install make gcc groff-base libtool${AFT}" \
    && apt-get update -y \
    && apt-get install -y git make gcc groff-base libtool

# Remove default packages as ca-certeficates and openssl
RUN echo "${BEF}Remove default packages as ca-certeficates and openssl${AFT}" \
    && apt-get remove -y openssl \
    && apt-get autoremove -y

# Don't show git message about not existing parent branch
RUN echo "${BEF}Don't show git message about not existing parent branch${AFT}" \
    && git config --global advice.detachedHead false

# Create directory for git clone program
RUN echo "${BEF}Create directory for git clone program${AFT}" \
    && mkdir -p \
    /tmp/openssl \
    /tmp/curl \
    /tmp/pcre \
    /tmp/nginx \
    /opt/openssl \
    /opt/curl \
    /opt/pcre \
    /usr/local/lib64 \
    /usr/local/include/openssl

# Copy ld config file with all paths to dynamic libraries
RUN echo "${BEF}Copy ld config file with all paths to dynamic libraries${AFT}" 
COPY ld.so.conf /etc

# Create new cache file with paths
RUN echo "${BEF}Create new cache file with paths${AFT}" \
    && ldconfig

# Clone OpenSSL(3.1.0-alpha1) repository
WORKDIR /tmp/openssl
RUN echo "${BEF}Clone OpenSSL(3.1.0-alpha1) repository${AFT}" \
    && git clone --depth=1 --branch=openssl-3.1 https://github.com/openssl/openssl.git .

# Configure openssl with not default location and run make, make install
RUN echo "${BEF}Configure openssl with not default location and run make, make install${AFT}" \
    && ./Configure --prefix=/opt/openssl \
    && echo "${BEF}Processing install... May take several minutes${AFT}" \
    && make 1>/dev/null \
    && make install 1>/dev/null

# Create symlink for openssl
RUN ln -s /opt/openssl/lib64/libcrypto.so /usr/local/lib64 \
    && ln -s /opt/openssl/lib64/libssl.so /usr/local/lib64 \
    && ln -s /opt/openssl/include/openssl/* /usr/local/include/openssl \
    && ln -s /opt/curl/bin/openssl /usr/local/bin \
    && ldconfig

# Clone Curl repository
WORKDIR /tmp/curl
RUN echo "${BEF}Clone Curl repository${AFT}" \
    && git clone --depth=1 --branch=curl-7_86_0 https://github.com/curl/curl.git .

# Configure curl with not default location and run make, make install
RUN echo "${BEF}Configure curl with not default location and run make, make install${AFT}" \
    && autoreconf -fi \
    && ./configure --with-ssl=/opt/openssl --prefix=/opt/curl \
    && echo "${BEF}Processing install... May take several minutes${AFT}" \
    && make 1>/dev/null \
    && make install 1>/dev/null

# Create symlink for curl bin and libs
RUN echo "${BEF}Create symlink for curl bin and libs${AFT}" \
    && ln -s /opt/curl/bin/curl /usr/bin/curl \
    && ln -s /opt/curl/lib/libcurl.so /usr/local/lib \
    && ldconfig

# Clone and build PCRE repository
WORKDIR /tmp/pcre
RUN echo "${BEF}Clone and build PCRE repository${AFT}" \
    && git clone --depth=1 --branch=pcre2-10.41 https://github.com/PCRE2Project/pcre2.git .

# Generate configure file
RUN echo "${BEF}Generate configure file${AFT}" \
    && ./autogen.sh

# Configure pcre with not default location and run make, make install
RUN echo "${BEF}Configure pcre with not default location and run make, make install${AFT}" \
    && ./configure --prefix=/opt/pcre --enable-jit \
    && echo "${BEF}Processing install... May take several minutes${AFT}" \
    && make \
    && make install

# Create symlink for pcre libs
RUN echo "${BEF}Create symlink for pcre libs${AFT}" \
    && ln -s /opt/pcre/lib/libpcre2.so /usr/local/lib

# Clone NGINX Unit repository
WORKDIR /tmp/nginx
RUN echo "${BEF}Clone NGINX Unit repository${AFT}" \
    && git clone --depth=1 --branch=1.28.0 https://github.com/nginx/unit.git .

# Configure nginx with not default location and run make, make install
RUN echo "${BEF}Configure nginx with not default location and run make, make install${AFT}" \
    && ./configure --openssl --prefix=/opt/nginx --log=/var/log/nginx/unit.log --group=www-data --user=www-data \
    && echo "${BEF}Processing install... May take several minutes${AFT}" \
    && make \
    && make install