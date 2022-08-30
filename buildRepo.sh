#!/bin/bash

# Fail on any commands fail
set -e

check_debian () {
	if ! command -v $1 &> /dev/null
	then
		echo "Could not find $1, are you on debian based OS?"
		exit
	fi
}

check_software () {
	if ! command -v $1 &> /dev/null
	then
		echo "$1 not found, please install it to create ISO image"
		exit
	fi
}

check_debian apt-get
check_debian dpkg-scanpackages
check_debian apt-cache

# I've seen things normal users wouldn't believe
check_software grep
check_software cat
check_software rm
check_software mkisofs
check_software gzip
check_software touch

APT_CONFIG=""
PACKAGES=$(cat packages)

if [ -r sources.list ]; then
	
	if [ ! -d /tmp/buildrepo ]; then
		echo "Setting up directories..."

		mkdir -p /tmp/buildrepo/etc /tmp/buildrepo/var/cache/apt \
			/tmp/buildrepo/var/lib/dpkg /tmp/buildrepo/var/lib/apt/partial \
			/tmp/buildrepo/var/lib/apt/archives/partial
		touch /tmp/buildrepo/var/lib/dpkg/status
		touch /tmp/buildrepo/var

	else
		echo "!!! Directories are already made, to reset this state, execute:"
		echo " rm -rf /tmp/buildrepo"
		echo ""
	fi
	
	cp sources.list /tmp/buildrepo/etc/sources.list
	APT_CONFIG="-c $(pwd)/apt.conf"
fi

echo "Updating lists..."

apt-get ${APT_CONFIG} update

if [ -d repo ]; then
	echo "Directory \"repo\" exists! If you want to change packages, execute:"
	echo " rm -rf repo"
	echo ""
fi

echo "Downloading package files... (${PACKAGES})"

# https://stackoverflow.com/a/45489718

if [ ! -d repo ]; then
	mkdir repo
fi
cd repo

apt-get ${APT_CONFIG} download $(apt-cache ${APT_CONFIG} depends --recurse --no-recommends --no-suggests \
  --no-conflicts --no-breaks --no-replaces --no-enhances \
  --no-pre-depends ${PACKAGES} | grep "^\w")

echo "Removing i386 packages. If you want them, modify me!"

rm -rf *_i386.deb

cd ..

echo "Building package list for apt..."

# https://askubuntu.com/a/458754
# https://gist.github.com/awesomebytes/ce0643c1ddead589ab06e2a1e4c5861b

dpkg-scanpackages repo /dev/null | gzip -9c > Packages.gz

echo "Building ISO image..."

# https://unix.stackexchange.com/a/274751

mkisofs -lJR -o repo.iso .

if [ -r clean ]; then
	echo "Cleaning..."

	rm -rf /tmp/buildrepo
	rm -rf repo
	rm Packages.gz
fi

