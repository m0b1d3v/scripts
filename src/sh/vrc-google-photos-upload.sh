#!/bin/bash

# This script takes a VRChat photo album and uploads to Google Photos in a very opinionated manner
# Output will be the files uploaded in order, or more likely a crash on the Photos API
# The deepest and last directory in reverse alphabetical order is visited first
# The last file in reverse alphabetical order is then uploaded
# As directories are climbed out of a text separator is added to the album with the directory name
# This upload order coupled with sorting the album by recently added gives me the photo order I desire

# The first input to this script should be the directory to upload images from
uploadFolder=$1

clientId=""
tokenLocation=token.txt

# See if a file exists on disk modified within the past 50 minutes (tokens usually last one hour)
checkIfOauthTokenIsMissingOrExpired() {

	local tokenFound
	tokenFound=$(test -f $tokenLocation && echo true || echo false)

    if [ "$tokenFound" = true ]; then

    	currentUnixTime=$(date +%s)
    	tokenWriteUnixTime=$(stat -c %Y $tokenLocation)
    	tokenLifetimeInSeconds=$((currentUnixTime - ""$tokenWriteUnixTime""))

    	if [ $tokenLifetimeInSeconds -gt 3000 ]; then
    		echo "Token found but might expire within 10 minutes, cannot use it."
    	else
    		echo "Token found, $tokenLifetimeInSeconds seconds old"
    		return 0
    	fi
    fi

    return 1
}

# Output a URL to be manually clicked for getting an access token in the browser
outputOauthUrlPrompt() {

	local scopes="https://www.googleapis.com/auth/photoslibrary.readonly"
	scopes+="+https://www.googleapis.com/auth/photoslibrary.appendonly"
	scopes+="+https://www.googleapis.com/auth/photoslibrary.sharing"

	local oauthUrl="https://accounts.google.com/o/oauth2/v2/auth?redirect_uri=http://localhost&response_type=token"
	oauthUrl+="&client_id=$clientId"
	oauthUrl+="&scope=$scopes"

	echo $oauthUrl
}

# If we don't have a fresh Google authentication token, we should prompt the user for one
# -r Don't mangle characters with any backslash input
# -s Don't show the input on screen as this is sensitive information
# -p Prompt the user
tokenFetch() {
    if ! checkIfOauthTokenIsMissingOrExpired; then
    	outputOauthUrlPrompt
    	read -r -s -p 'Access token from browser URL: ' token
    	echo "$token" > $tokenLocation
    	echo ""
    fi
}

sendApiData() {

	local path=$1
	local data=$2
	local token;

	token=$(cat $tokenLocation)

	curl --silent \
		-H "Authorization: Bearer $token" \
		-H "Content-Type: application/json" \
		-X POST \
		-d "$data" \
		"https://photoslibrary.googleapis.com/v1/$path"
}

sendApiFile() {

	local file=$1
	local mimeType=$2;
	local token;

	token=$(cat $tokenLocation)

	curl --silent \
		-H "Authorization: Bearer $token" \
		-H "Content-Type: application/octet-stream" \
		-H "X-Goog-Upload-Content-Type: $mimeType" \
		-H "X-Goog-Upload-Protocol: raw" \
		-X POST \
		--data-binary "@$file" \
		"https://photoslibrary.googleapis.com/v1/uploads"
}

main() {

	tokenFetch

    # Create a new album
    read -r -p 'Album title: ' albumTitle
    album=$(sendApiData "albums" "{'album':{'title':'$albumTitle'}}")
    albumId=$(jq -r '.id' <(echo "$album"))
    albumProductUrl=$(jq -r '.productUrl' <(echo "$album"))
    echo "Created Album: $albumProductUrl"

    # Share the album so that people can see it and comment on it, but not add to it
    share=$(sendApiData "albums/$albumId:share" "{'sharedAlbumOptions':{'isCollaborative':'false','isCommentable':'true'}}")
    albumShareUrl=$(jq -r '.shareInfo.shareableUrl' <(echo "$share"))
    printf "Shared album: %s\n\n" "$albumShareUrl"

    # Get a list of all the files in the "recently added" sort order we want
	#  -f Print full path prefix
	#  -i No indentation printing
	#  -n No color printing
	#  -r Reverse sort order
	files=$(tree -finr --noreport "$uploadFolder")
	files="$(echo "$files" | cut -d$'\n' -f2-)";

	IFS=$'\n'
	currentDirName=""
	recentlyAddedCheck=false
	for file in $files; do

		if [ ! -f "$file" ]; then
			continue
		fi

		dirName=$(dirname "$file")
		dirName=$(basename "$dirName")

		mimeType=$(file -i "$file" | cut -d' ' -f2)
		mimeType=${mimeType::-1}
		if [ "$mimeType" != "image/png" ] && [ "$mimeType" != "image/jpg" ]; then
			continue
		fi

		if [ "$currentDirName" != "" ] && [ "$currentDirName" != "$dirName" ]; then
			textLabel=$(sendApiData "albums/$albumId:addEnrichment" "{'newEnrichmentItem':{'textEnrichment':{'text':'$currentDirName'}},'albumPosition':{'position':'FIRST_IN_ALBUM'}}")
			textLabelId=$(jq -r '.enrichmentItem.id' <(echo "$textLabel"))
			printf "%s %s\n\n" "$currentDirName" "$textLabelId"
		fi

		uploadToken=$(sendApiFile "$file")

		printf "%s" "$file"

		fileName=$(basename "$file")
		uploadResult=$(sendApiData "mediaItems:batchCreate" "{'albumId':'$albumId','albumPosition':{'position':'FIRST_IN_ALBUM'}, 'newMediaItems':[{'simpleMediaItem':{'fileName':'$fileName','uploadToken':'$uploadToken'}}]}")
		uploadResultMessage=$(jq -r '.newMediaItemResults[0].status.message' <(echo "$uploadResult"))

		printf " %s\n" "$uploadResultMessage"

		if [ "$recentlyAddedCheck" = false ]; then
			echo "First image uploaded. Perform these steps manually now to ensure proper order and labeling: Edit Album > Sort Photos > Recently Added"
			read -r -p 'Press enter to continue'
			echo ""
			recentlyAddedCheck=true
		fi

		currentDirName=$dirName;
	done

	printf "\nDon't forget to set the album cover image!\n"
}

main
