#!/bin/bash

# Create a compressed copy of an image using CWEBP
#
# Example input:
# ./compress-image-webp.sh path/to/file.png
#
# Example output:
# In  | 8.0K	example.png
# Out | 4.0K	example.webp
#
# Good way to run on all images in a folder:
# find $(folder) -type f \( -name "*.png" -o "*.jpg" \) | parallel ./compress-image-webp.sh {}

# Grab command line input
file=$1

# Print input
printf "In  | %s\n" "$(du -h "$file")"

# Compress the file with WEBP
cwebp -q 90 -quiet "$file" -o "$file.webp"

# Print output
printf "Out | %s\n\n" "$(du -h "$file.webp")"
