#!/bin/bash

# Create a compressed copy of a PNG image using pngquant
#
# Example input:
# ./compress-image-png.sh path/to/file.png
#
# Example output:
# In  | 8.0K	example.png
# Out | 4.0K	example-compressed.png
#
# Good way to run on all images in a folder:
# find $(folder) -type f \( -name "*.png" \) | parallel ./compress-image.sh {}

# Grab command line input
file=$1

# Determine file name and extension
name="${file%.*}";
extension="${file##*.}";
destination="$name-compressed.$extension"

# Print input
printf "In  | %s\n" "$(du -h "$file")"

# Compress the file with pngquant
pngquant --force --strip --output "$destination" "$file"

# Print output
printf "Out | %s\n" "$(du -h "$destination")"
