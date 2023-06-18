#!/bin/bash

# This script is used to check if a list of VRChat profiles have changed their display name any
# Output here helps keep moderator lists reliant on display name up-to-date
# Take care not to run this often, be kind to the VRC API
# Whatever you do, don't remove the artificial rate limiting

# The first input to this script should be an authentication string
# I get this by logging into the website on Firefox, opening network inspector, and pulling a cookie string
# The substring desired is the value after "auth:"
cookie=$1

# The second input to this script is a path to a file that contains the profiles that should be checked
# Each line in the file should be of the form `UID knownDisplayName`
# An example would be `c1644b5b-3ca4-45b4-97c6-a2a0de70d469 tupper`
file=$2

# Process input file line-by-line, keeping count of changed profiles
changes=0
while read -r line; do

	# Tokenize and split each line into something useful
	# Skip lines without enough data (like trailing newlines)
	IFS=' ' read -r uid knownDisplayName <<< "$line"
	if [ ! "$uid" ] || [ ! "$knownDisplayName" ]; then
		continue
	fi

	# Fetch current display names from the VRC API
	data=$(curl --silent --user-agent "curl" "https://vrchat.com/api/1/users/usr_$uid" -H "Cookie: auth=$cookie")
	currentDisplayName=$(jq '.displayName' <(echo "$data") | tr -d '"')

	# Print a message with what we've learned
	printf "https://vrchat.com/home/user/usr_%s | %s" "$uid" "$knownDisplayName"
	if [ "$knownDisplayName" != "$currentDisplayName" ]; then
		printf " > %s" "$currentDisplayName"
		((changes=changes+1))
	fi
	printf "\n"

	# Artificial rate limit to be nice
	sleep 1s

done < "$file"

printf "Changes: %d\n" "$changes"
