/**
 * This script is used to format VRChat creator page info in a way I can use in my photo shoot world spreadsheet:
 * https://docs.google.com/spreadsheets/d/1ItNheoqRj6TusLqi6lZMsP1_FVT9NFj9pYbHQsMK8cw/edit?usp=sharing
 *
 * This can be run inside a browser's developer console, but is far more efficient as a bookmarklet.
 * This purposefully has no comments, so you can copy and paste it into a single line bookmarklet.
 * The bookmark content will look like `javascript:$copyAndPasteEverythingBelowThisComment`
 * This information came from https://gist.github.com/caseywatts/c0cec1f89ccdb8b469b1
 */

(async () => {

	let id = window.location.pathname.replace("/home/user/", "");
	let data = await fetch(`https://vrchat.com/api/1/users/${id}`);
	let json = await data.json();

	let linkTransforms = new Map();
	linkTransforms.set("twitter.com", (link) => link.replace("https://twitter.com/", "@"));
	linkTransforms.set("booth.pm", () => "Booth");
	linkTransforms.set("gumroad.com", () => "Gumroad");
	linkTransforms.set("twitch.tv", (link) => link.replace("https://www.twitch.tv/", ""));
	linkTransforms.set("patreon.com", (link) => link.replace("https://www.patreon.com/", ""));

	let alertData = [`=HYPERLINK("${window.location.href}", "${json.displayName}")`];

	for (let bioLink of json.bioLinks) {
		for (let [linkKey, linkTransform] of linkTransforms) {
			if (bioLink.includes(linkKey)) {

				let label = linkTransform(bioLink);
				alertData.push(`=HYPERLINK("${bioLink}", "${label}")`);

				break;
			}
		}
	}

	alert(alertData.join("\n\n"));
})()
