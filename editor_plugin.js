/*globals window,tinyMCE*/
/*
	tinyMCE Editor Stub
	http://wiki.moxiecode.com/index.php/TinyMCE:Custom_filebrowser
*/
function CJFileBrowser_tinyMCE_Callback(field_name, url, type, win) {
	"use strict";
	var cmsURL;
	if (!url) {
		cmsURL = tinyMCE.activeEditor.getParam('plugin_cjfilebrowser_browseUrl') + "?type=" + type;
	} else {
		// script URL - use an absolute path!
		cmsURL = window.location.toString();
		if (cmsURL.indexOf("?") < 0) {
			//add the type as the only query parameter
			cmsURL = cmsURL + "?type=" + type;
		}
		else {
			//add the type as an additional query parameter
			cmsURL = cmsURL + "&type=" + type;
		}
	}
	tinyMCE.activeEditor.windowManager.open({
		file: cmsURL,
		title: 'File Browser',
		// The dimensions from the settings
		width: typeof tinyMCE.activeEditor.getParam('plugin_cjfilebrowser_winWidth') === "number" ? tinyMCE.activeEditor.getParam('plugin_cjfilebrowser_winWidth') : 720,
		height: typeof tinyMCE.activeEditor.getParam('plugin_cjfilebrowser_winHeight') === "number" ? tinyMCE.activeEditor.getParam('plugin_cjfilebrowser_winHeight') : 500,
		resizable: "yes",
		// This parameter only has an effect if you use the inlinepopups plugin!
		inline: "yes",
		close_previous: "no"
	}, {
		window: win,
		input: field_name
	});
	return false;
}