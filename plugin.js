/*globals window,document,tinymce,cjfilebrowser */
/**
 * plugin.js
 *
 * Copyright, Doug Jones
 * Released under MIT license.
 *
 */
tinymce.PluginManager.add('cjfilebrowser', function (editor) {

    tinymce.activeEditor.settings.file_browser_callback = cjfilebrowser;

    function cjfilebrowser(id, value, type, win) {

        var url = [], urltype = 2, // file
        	url_re = new RegExp(',', 'gim');

        if (type == 'image') {
            urltype = 1;
        } else if (type == 'media') {
            urltype = 3;
        }

        if (editor.settings.plugin_cjfilebrowser_browserUrl) {
            url.push('browserUrl=' + window.encodeURIComponent(editor.settings.plugin_cjfilebrowser_browserUrl));
        }

        if (editor.settings.plugin_cjfilebrowser_actions) {
            url.push('actions=' + window.encodeURIComponent(editor.settings.plugin_cjfilebrowser_actions));
        }

        if (editor.settings.plugin_cjfilebrowser_winWidth) {
            url.push('winWidth=' + window.encodeURIComponent(editor.settings.plugin_cjfilebrowser_winWidth));
        }

        if (editor.settings.plugin_cjfilebrowser_winHeight) {
            url.push('winHeight=' + window.encodeURIComponent(editor.settings.plugin_cjfilebrowser_winHeight));
        }

        if (editor.settings.plugin_cjfilebrowser_assetsUrl) {
            url.push('assetsUrl=' + window.encodeURIComponent(editor.settings.plugin_cjfilebrowser_assetsUrl));
        }

        if (editor.settings.plugin_cjfilebrowser_fileExts) {
            url.push('fileExts=' + window.encodeURIComponent(editor.settings.plugin_cjfilebrowser_fileExts));
        }

        if (editor.settings.plugin_cjfilebrowser_maxSize) {
            url.push('maxSize=' + window.encodeURIComponent(editor.settings.plugin_cjfilebrowser_maxSize));
        }

        if (editor.settings.plugin_cjfilebrowser_maxWidth) {
            url.push('maxWidth=' + window.encodeURIComponent(editor.settings.plugin_cjfilebrowser_maxWidth));
        }

        if (editor.settings.plugin_cjfilebrowser_maxHeight) {
            url.push('maxHeight=' + window.encodeURIComponent(editor.settings.plugin_cjfilebrowser_maxHeight));
        }

        if (editor.settings.plugin_cjfilebrowser_showImgPreview) {
            url.push('showImgPreview=' + window.encodeURIComponent(editor.settings.plugin_cjfilebrowser_showImgPreview));
        }

        if (editor.settings.plugin_cjfilebrowser_engine) {
            url.push('engine=' + window.encodeURIComponent(editor.settings.plugin_cjfilebrowser_engine));
        }

        if (editor.settings.plugin_cjfilebrowser_handler) {
            url.push('handler=' + window.encodeURIComponent(editor.settings.plugin_cjfilebrowser_handler));
        }

        if (editor.settings.plugin_cjfilebrowser_timeOut) {
            url.push('timeOut=' + window.encodeURIComponent(editor.settings.plugin_cjfilebrowser_timeOut));
        }

        url = url.toString().replace(url_re, '&');

		if (editor.settings.plugin_cjfilebrowser_browserUrl) {
			if (editor.settings.plugin_cjfilebrowser_browserUrl.indexOf('?') > -1) {
				url = editor.settings.plugin_cjfilebrowser_browserUrl + (url.length ? '&' + url : '');
			} else if (editor.settings.plugin_cjfilebrowser_browserUrl.indexOf('?') === -1) {
				url = editor.settings.plugin_cjfilebrowser_browserUrl + (url.length ? '?' + url : '');
			}
		} else {
			url = '/';
		}

        tinymce.activeEditor.windowManager.open({
            title: 'CJ File Browser',
            file: url || '/',
            width: editor.settings.plugin_cjfilebrowser_winWidth || 720,
            height: editor.settings.plugin_cjfilebrowser_winHeight || 500,
            resizable: true,
            maximizable: true,
            inline: 1,
            type: urltype
        }, {
            fileSelectCallback: function (url) {
                var fieldElm = win.document.getElementById(id);
                fieldElm.value = editor.convertURL(url);
                //if ('fireEvent' in fieldElm) {
                if (fieldElm !== undefined && fieldElm.hasOwnProperty('fireEvent')) {
                    fieldElm.fireEvent('onchange');
                } else {
                    var evt = document.createEvent('HTMLEvents');
                    evt.initEvent('change', false, true);
                    fieldElm.dispatchEvent(evt);
                }
            }
        });
    }

    return false;
});