#!/usr/bin/env bash

set -x

cat Dockerfile.tmpl > Dockerfile
cat Dockerfile.tmpl > Dockerfile.buster

# Dockerfile contains bullseye, Dockerfile.buster contains the buster version
sed -i "s/\${DEBIAN_VERSION}/bullseye/g" Dockerfile
sed -i "s/\${DEBIAN_VERSION}/buster/g" Dockerfile.buster

# In case of Debian Buster, replace '# VERSION_SPECIFIC_BUILD_STEPS' with the following:
#    # building ttyd
#    ARG ttyd_tag
#    RUN cd /build && git clone --depth 1 --branch ${ttyd_tag} https://github.com/tsl0922/ttyd.git
#    RUN cd /build/ttyd && mkdir build && cmake . && make
sed -i "s/# VERSION_SPECIFIC_BUILD_STEPS/# building ttyd\nARG ttyd_tag\nRUN cd \/build \&\& git clone --depth 1 --branch \${ttyd_tag} https:\/\/github.com\/tsl0922\/ttyd.git\nRUN cd \/build\/ttyd \&\& mkdir build \&\& cmake . \&\& make/g" Dockerfile.buster
# For Bullseye, just remove it
sed -i "/\n# VERSION_SPECIFIC_BUILD_STEPS/d" Dockerfile

# Version specific dependencies
# For Bullseye, this is ttyd, which is only in bullseye-backports, not in buster
sed -i "s/<VERSION_SPECIFIC_DEPENDENCIES>/ttyd/g" Dockerfile
# For Bullseye, we manually add all dependencies from bullseye's ttyd, and we also need python3-grpcio and python3-setuptools for Python dependencies
sed -i "s/<VERSION_SPECIFIC_DEPENDENCIES>/python3-grpcio python3-setuptools libc6 libcap2 libev4 libjson-c3 libwebsockets8 libssl1.1 libuv1 zlib1g/g" Dockerfile.buster

# For Buster, we need a special filter to prevent pip from installing grpc, because it would compile it from scratch and that would take too long
# On Bullseye, pip is able to find a prebuilt wheel, so we don't need this filter
sed -i "s/<INSTALL_MAYBE_NO_GRPC>/pip3 install -r requirements.txt/g" Dockerfile
sed -i "s/<INSTALL_MAYBE_NO_GRPC>/cat requirements.txt | grep -v grpcio > requirements-nogrpcio.txt && pip3 install -r requirements-nogrpcio.txt/g" Dockerfile.buster

# For Buster, replace "# VERSION_SPECIFIC_COPY_STEPS" with "COPY --from=builder /build/ttyd /usr/bin/", for Bullseye, remove it
sed -i "/\n# VERSION_SPECIFIC_COPY_STEPS/d" Dockerfile
sed -i "s/# VERSION_SPECIFIC_COPY_STEPS/COPY --from=builder \/build\/ttyd \/usr\/bin\//g" Dockerfile.buster

# For Buster, we are building ttyd manually.
# This requires build-essential cmake libjson-c-dev libwebsockets-dev
sed -i "s/<VERSION_SPECIFIC_BUILD_DEPENDENCIES>/build-essential cmake  libjson-c-dev libwebsockets-dev/g" Dockerfile.buster
sed -i "s/ <VERSION_SPECIFIC_BUILD_DEPENDENCIES>//g" Dockerfile
