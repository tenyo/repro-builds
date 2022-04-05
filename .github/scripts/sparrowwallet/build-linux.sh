#!/bin/bash
# Build script to reproduce and validate Sparrow Wallet binaries on Linux
# The version we are building for should be passed as an argument ($1) to this script
set -e

VER=${1}
ROOT=$(pwd)

echo "Starting sparrowwallet/build-linux.sh script for version ${VER} at $(date) ..."
ls -la

# install various dependencies
sudo apt update -y
sudo apt install -y rpm fakeroot binutils wget apt-transport-https gnupg

# install Java
# Note: Because Sparrow bundles a Java runtime in the release binaries, it is essential to have the same version of Java 
# installed when creating the release. For v1.5.0 and later, this is AdoptOpenJdk jdk-16.0.1+9 Hotspot
wget https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public
gpg --no-default-keyring --keyring ./adoptopenjdk-keyring.gpg --import public
gpg --no-default-keyring --keyring ./adoptopenjdk-keyring.gpg --export --output adoptopenjdk-archive-keyring.gpg
rm adoptopenjdk-keyring.gpg
sudo mv adoptopenjdk-archive-keyring.gpg /usr/share/keyrings
echo "deb [signed-by=/usr/share/keyrings/adoptopenjdk-archive-keyring.gpg] https://adoptopenjdk.jfrog.io/adoptopenjdk/deb $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/adoptopenjdk.list
sudo apt update -y
sudo apt install -y adoptopenjdk-16-hotspot=16.0.1+9-3
# repoint default java
sudo update-java-alternatives -s adoptopenjdk-16-hotspot-amd64
export JAVA_HOME="/usr/lib/jvm/adoptopenjdk-16-hotspot-amd64"
java --version
javac --version

# start the actual build
./gradlew jpackage

# extract original binaries from the tar.gz archive that was downloaded from the Github repo
mkdir _original
tar xzf sparrow-${VER}.tar.gz -C _original

# generated and original binaries should be here
ls -l build/jpackage/Sparrow/*
ls -l _original/Sparrow/*

# compare our binaries to the original ones, and save output to a file
echo "Comparing Sparrow binaries (build/jpackage/Sparrow <=> _original/Sparrow) for version ${VER}" | tee "${ROOT}/output.txt"
diff -r build/jpackage/Sparrow _original/Sparrow | tee -a "${ROOT}/output.txt"
DIFFERR=${PIPESTATUS[0]}
if [ ${DIFFERR} -eq 0 ]; then
   echo "OK: builds are identical" | tee -a "${ROOT}/output.txt"
elif [ ${DIFFERR} -eq 1 ]; then
   echo "FAIL: builds are different!" | tee -a "${ROOT}/output.txt"
   exit 1
else
   exit ${DIFFERR}
fi
