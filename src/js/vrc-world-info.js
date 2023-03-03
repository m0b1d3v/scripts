/**
 * This script is used to format VRChat world page info in a way I can use in my photo shoot world spreadsheet:
 * https://docs.google.com/spreadsheets/d/1ItNheoqRj6TusLqi6lZMsP1_FVT9NFj9pYbHQsMK8cw/edit?usp=sharing
 *
 * This can be run inside a browser's developer console, but is far more efficient as a bookmarklet.
 * This purposefully has no comments, so you can copy and paste it into a single line bookmarklet.
 * The bookmark content will look like `javascript:$copyAndPasteEverythingBelowThisComment`
 * This information came from https://gist.github.com/caseywatts/c0cec1f89ccdb8b469b1
 */

(async () => {

	let id = window.location.pathname.replace("/home/world/", "");
	let data = await fetch(`https://vrchat.com/api/1/worlds/${id}`);
	let json = await data.json();

	let unwantedTags = [
		"admin_approved",
		"approved",
		"system_approved",
		"system_created_recently",
		"system_labs",
		"system_updated_recently",
	];

	let filteredTags = json.tags.filter(tag => !unwantedTags.includes(tag));
	let formattedTags = filteredTags.map(tag => tag.replace("author_tag_", ""));
	let tags = formattedTags.join(", ");

	let worldSizeNode = document.querySelector('[title="World Size"]');
	let worldSizeText = worldSizeNode.innerText;
	let worldSizeNumber = worldSizeText.replace(" MB", "").replace(" kb", "");
	let worldSize = Math.round(parseFloat(worldSizeNumber));

	let alertData = [
		`=HYPERLINK("${window.location.href}", "${json.name}")`,
		`=HYPERLINK("${window.location.origin}/home/user/${json.authorId}", "${json.authorName}")`,
		worldSize,
		tags
	];

	alert(alertData.join("\n\n"));
})()
