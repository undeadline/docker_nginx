FROM debian:stable-20221114-slim

# Runtime env variables for printing output masseges
ARG MS_DIVIDER='==================================' \
    DOCKER_MSG_COLOR='\033[92m\033[100m' \
    DOCKER_RESET_COLOR='\033[0m'
ARG BEF="${DOCKER_MSG_COLOR}\n\n${MESSAGE_DIVIDER}\n" \
    AFT="\n${MESSAGE_DIVIDER}\n${DOCKER_RESET_COLOR}\n"

ENV DEBIAN_FRONTEND noninteractive

# Update and install make gcc groff-base libtool
RUN echo "${BEF}Update and install make gcc groff-base libtool${AFT}"
RUN apt-get update -y && apt-get install -y git make gcc groff-base libtool

# Remove default packages as ca-certeficates and openssl
RUN echo "${BEF}Remove default packages as ca-certeficates and openssl${AFT}"
RUN apt-get remove -y openssl && apt-get autoremove -y

# Don't show git message about not existing parent branch
RUN echo "${BEF}Don't show git message about not existing parent branch${AFT}"
RUN git config --global advice.detachedHead false

# Create directory for git clone program
RUN echo "${BEF}Create directory for git clone program${AFT}"
RUN mkdir /tmp/openssl /tmp/curl /tmp/pcre /opt/openssl /opt/curl

# Copy ld config file with all paths to dynamic libraries
RUN echo "${BEF}Copy ld config file with all paths to dynamic libraries${AFT}"
COPY ld.so.conf /etc
# Create new cache file with paths
RUN echo "${BEF}Create new cache file with paths${AFT}"
RUN ldconfig

# Clone OpenSSL(3.1.0-alpha1) package
RUN echo "${BEF}Clone OpenSSL(3.1.0-alpha1) package${AFT}"
WORKDIR /tmp/openssl
RUN git clone --depth=1 --branch=openssl-3.1 https://github.com/openssl/openssl.git .

# Configure openssl with not default location and run make, make install
RUN echo "${BEF}Configure openssl with not default location and run make, make install${AFT}"
RUN ./Configure --prefix=/opt/openssl && make 1>/dev/null && make install 1>/dev/null

# Create symlink for openssl
# RUN ln -s /opt/openssl/lib/* /usr/lib64/openssl
# RUN ln -s /opt/openssl/lib/* /usr/local/lib
# RUN ln -s /opt/openssl/bin/openssl /usr/bin/openssl

# Clone Curl package
RUN echo "${BEF}Clone Curl package${AFT}"
WORKDIR /tmp/curl
RUN git clone --depth=1 --branch=curl-7_86_0 https://github.com/curl/curl.git .

# Configure curl with not default location and run make, make install
RUN echo "${BEF}Configure curl with not default location and run make, make install${AFT}"
RUN ./configure --with-ssl=/opt/openssl --prefix=/opt/curl LDFLAGS="-L/opt/openssl/lib64" CPPFLAGS="-I/opt/openssl/include" \
    && make 1>/dev/null \
    && make install 1>/dev/null

# Create symlink for curl
RUN echo "${BEF}Create symlink for curl${AFT}"
# RUN ln -s /opt/curl/bin/curl /usr/bin/curl

# Clone and build PCRE package