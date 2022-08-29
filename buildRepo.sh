#!/bin/bash

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

echo "Downloading package files..."

# https://stackoverflow.com/a/45489718

PACKAGES=$(cat packages)

mkdir repo
cd repo

apt-get download $(apt-cache depends --recurse --no-recommends --no-suggests \
  --no-conflicts --no-breaks --no-replaces --no-enhances \
  --no-pre-depends ${PACKAGES} | grep "^\w")

echo "Removing i386 packages. If you want them, modify me!"

rm -rf *_i386.deb

echo "Building package list for apt..."

# https://askubuntu.com/a/458754
# https://gist.github.com/awesomebytes/ce0643c1ddead589ab06e2a1e4c5861b

dpkg-scanpackages repo /dev/null | gzip -9c > Packages.gz

echo "Building ISO image..."

# https://unix.stackexchange.com/a/274751

mkisofs -lJR -o repo.iso .

