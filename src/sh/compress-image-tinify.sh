#!/bin/bash

# Create a compressed copy of an image using Tinify Web API
#
# You must have an environment variable of `TINIFY_API_KEY`
#
# Example input:
# ./compress-image-tinify.sh path/to/file.png
#
# Example output:
# In  | 8.0K	example.png
# Out | 4.0K	example-compressed.png
#
# Good way to run on all images in a folder:
# find $(folder) -type f \( -name "*.png" -o "*.jpg" \) | parallel ./compress-image-tinify.sh {}

# Grab command line input
file=$1

# Determine file name and extension
name="${file%.*}";
extension="${file##*.}";
destination="$name-compressed.$extension"

# Print input
printf "In  | %s\n" "$(du -h "$file")"

# Compress the file with Tinify API
tinify=$(curl --progress-bar --user api:"${TINIFY_API_KEY}" --data-binary @"$file" https://api.tinify.com/shrink)
tinifyUrl=$(jq '.output.url' <(echo "$tinify") | tr -d '"')
curl --progress-bar --user api:"${TINIFY_API_KEY}" --output "$destination" "$tinifyUrl"

# Print output
printf "Out | %s\n" "$(du -h "$destination")"
