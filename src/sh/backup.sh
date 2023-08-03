#!/bin/bash

# Makes a backup of all the files I find important on my machine
# In order to copy files to an external drive from WSL, I had to mount it manually:
#  - sudo mkdir /mnt/d
#  - sudo mount -t drvfs D: /mnt/d

globalFlags="$@"

sync() {

	local source=$1
	local destination=$2

	rsync \
    	--compress \
    	--exclude '**.jpg.webp' \
    	--exclude '**.png.webp' \
    	--exclude '.git' \
    	--exclude '.gradle' \
    	--exclude '.idea' \
    	--exclude '.tmp.drivedownload' \
    	--exclude 'build' \
    	--exclude 'node_modules' \
    	--inplace \
    	--itemize-changes \
    	--no-group \
    	--no-owner \
    	--omit-dir-times \
    	--protect-args \
    	--recursive \
    	--verbose \
    	$globalFlags $source $destination
}

backupLocation=/mnt/c/Users/Mobi/Downloads/backup

rm -rf $backupLocation
mkdir $backupLocation
sync /mnt/c/Users/Mobi/Google/ $backupLocation/google
sync /home/mobius_k/projects/ $backupLocation/projects
