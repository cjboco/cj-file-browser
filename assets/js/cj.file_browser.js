﻿/*globals window,document,jQuery,dateFormat,tinyMCE,tinyMCEPopup,XMLHttpRequest,console */
/* ***********************************************************************************

	CJ File Browser Javascript Engine

	Copyright (c) 2007-2011, Doug Jones. All rights reserved.

	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions
	are met:

	a) Redistributions of source code must retain the above copyright
	notice, this list of conditions, the following disclaimer and any
	website links included within this document.

	b) Redistributions in binary form must reproduce the above copyright
	notice, this list of conditions, the following disclaimer and any
	website links included within this document in the documentation
	and/or other materials provided with the distribution.

	c) Neither the name of the Creative Juices, Bo. Co. nor the names of its
	contributors may be used to endorse or promote products derived from
	this software without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
	"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
	LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
	A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
	OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
	SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
	LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
	DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
	THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
	OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

	For further information, visit the Creative Juices website: www.cjboco.com.

	Version History

	1.0			(2007-06-26) - Initial release.
	1.0.1		(2007-08-17) - Fixed a small bug in IE and FireFox (Windows)
								that was causing an error that prevented you
								from selecting files.
	1.0.3		(2007-08-22) - Fixed the path delimeter to work on both Windows
								AND Unix. Fixed path information in the FileBrowser.cfm
								file (leftover code). Also fixed the window reference
								error on the callback to TinyMCE.
	1.0.4		(2007-12-11) - Cleaned the code some more. Added the ability to pass
								the width and height back to the tiny_mce dialog box.
								Added a few more comments and tried to make the instructions
								a little easier. I also added an Application.cfm file to
								the cf_ibrowse directory.
	1.0.4		(2008-05-13) - I made a special edition for all of the Pre-ColdFusion 5
								users. I stripped out some of the tags that were introduced
								after CF5. Since I no longer have access to a CF5 server,
								you guys are going to have to let me know if it works or not.
								Also, I merged the _setup.cfm into the Application.cfm file.
								(Something I plan on doing in the next release anyway.)
	2.0			(2009-01-02) - First attempt at a tinyMCE plug-in version.
	3.0			(2010-03-25) - A complete rewrite. Better tinyMCE plugin support. Tried to
								improve the interface. Uses jQuery and jQuery UI.
	3.0.1		(2010-03-29) - Bug Fixes.
	3.1			(2010-04-11) - Split functionality between jQuery and Handler Engine System. This
								will allow for other server technologies besides ColdFusion.
								Major interface overhaul. Added more functionality.
								Had to re-write upload module, in order to do this.
								Added more theming options and overhauled the look.
								Added fix for IE AJAX caching issue
	3.1.1		(2010-04-25) - Fixed dblClick on FILE not passing file object bug.
								Added further typeof testing for "console" is defined.
	3.1.2		(2010-04-26) - Added proper date format check in JS and handler.
	3.1.3		(2010-07-14) - Added cookie support to remember last directory.
								Trying to fix the new CF9 Ajax Debuggin bug by
								using "&_cf_nodebug=true" in ajax calls.
									(Thank MeT and WebDuckie!)
								Fixed a filename bug where using "escape" was not
									escaping a "+" sign. (Thank tarekac!)
	4.0			(2011-11-26) - Made it into a bonified jQuery plug-in.
							   Update code structure with more effient jQuery and
								Javascript techniques.
							   Replaced all $.getJSON with $.ajax calls.
							   Updated error handling and debug mode.
							   Removed old file upload structure.
							   Added Drag-N-Drop upload support.
							   Sarted laying groundwork for use of "absolute" paths.
	4.0.1		(2011-12-05) - Squashed some more bugs.
							   Reintegrated the old fileUpload option.
							   Renamed the drag-and-drop options dropUpload.
							   Cleaned up some CSS.
	4.0.2		(2014-07-18) - Squashed some more bugs.

 *********************************************************************************** */
(function ($) {
	'use strict';

	$.cjFileBrowser = function ($obj, options) {

		var opts = {
				actions: ['navigateDirectory','createDirectory','deleteDirectory','fileDelete','fileUpload','dropUpload','fileSelect'],
				baseRelPath: ['/'],
				baseAbsPath: [],
				fileExts: '*',
				maxSize: 1500,
				maxWidth: 600,
				maxHeight: 800,
				showImgPreview: true,
				engine: 'coldfusion8',
				handler: 'handler.cfc',
				timeOut: 900, // 15 minutes
				callBack: null
			},

			sys = {
				version: '4.0.2',
				timer: null,
				autoCenter: null,
				currentPathIdx: 0,
				dirContents: [],
				basePath: '/',
				dragObjId: null,
				debug: false
			};



		/*
		 * Authors: Jeff Walden, Andrea Giammarchi, John Resig
		 * http://ejohn.org/blog/javascript-array-remove/#postcomment
		 */
		if (!Array.prototype.remove) {
			Array.prototype.remove = function (from, to) {
				this.splice(from, (to || from || 1) + (from < 0 ? this.length : 0));
				return this.length;
			};
		}

		// Avoid `console` errors in browsers that lack a console.
		if (!(window.console && console.log)) {
			(function() {
				var noop = function() {},
					methods = ['assert', 'clear', 'count', 'debug', 'dir', 'dirxml', 'error', 'exception', 'group', 'groupCollapsed', 'groupEnd', 'info', 'log', 'markTimeline', 'profile', 'profileEnd', 'markTimeline', 'table', 'time', 'timeEnd', 'timeStamp', 'trace', 'warn'],
					length = methods.length,
					console = window.console = {};
				while (length--) {
					console[methods[length]] = noop;
				}
			}());
		}



		/*!
		 * jQuery imagesLoaded plugin v2.1.1
		 * http://github.com/desandro/imagesloaded
		 * MIT License. by Paul Irish et al.
		 */
		$.fn.imagesLoaded = function (callback) {
			var $this = this,
				deferred = $.isFunction($.Deferred) ? $.Deferred() : 0,
				hasNotify = $.isFunction(deferred.notify),
				$images = $this.find('img').add($this.filter('img')),
				loaded = [],
				proper = [],
				broken = [],
				BLANK = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==';
			// Register deferred callbacks
			if ($.isPlainObject(callback)) {
				$.each(callback, function (key, value) {
					if (key === 'callback') {
						callback = value;
					} else if (deferred) {
						deferred[key](value);
					}
				});
			}
			function doneLoading() {
				var $proper = $(proper),
					$broken = $(broken);
				if (deferred) {
					if (broken.length) {
						deferred.reject($images, $proper, $broken);
					} else {
						deferred.resolve($images);
					}
				}
				if ($.isFunction(callback)) {
					callback.call($this, $images, $proper, $broken);
				}
			}
			function imgLoadedHandler(event) {
				imgLoaded(event.target, event.type === 'error');
			}
			function imgLoaded(img, isBroken) {
				// don't proceed if BLANK image, or image is already loaded
				if (img.src === BLANK || $.inArray(img, loaded) !== -1) {
					return;
				}
				// store element in loaded images array
				loaded.push(img);
				// keep track of broken and properly loaded images
				if (isBroken) {
					broken.push(img);
				} else {
					proper.push(img);
				}
				// cache image and its state for future calls
				$.data(img, 'imagesLoaded', {
					isBroken: isBroken,
					src: img.src
				});
				// trigger deferred progress method if present
				if (hasNotify) {
					deferred.notifyWith($(img), [isBroken, $images, $(proper), $(broken)]);
				}
				// call doneLoading and clean listeners if all images are loaded
				if ($images.length === loaded.length) {
					window.setTimeout(doneLoading);
					$images.off('.imagesLoaded', imgLoadedHandler);
				}
			}
			// if no images, trigger immediately
			if (!$images.length) {
				doneLoading();
			} else {
				$images.on('load.imagesLoaded error.imagesLoaded', imgLoadedHandler).each(function (i, el) {
					// find out if this image has been already checked for status
					// if it was, and src has not changed, call imgLoaded on it
					var src = el.src,
						cached = $.data(el, 'imagesLoaded');
					if (cached && cached.src === src) {
						imgLoaded(el, cached.isBroken);
						return;
					}
					// if complete is true and browser supports natural sizes, try
					// to check for image status manually
					if (el.complete && el.naturalWidth !== undefined) {
						imgLoaded(el, el.naturalWidth === 0 || el.naturalHeight === 0);
						return;
					}
					// cached images don't fire load sometimes, so we reset src, but only when
					// dealing with IE, or image is complete (loaded) and failed manual check
					// webkit hack from http://groups.google.com/group/jquery-dev/browse_thread/thread/eee6ab7b2da50e1f
					if (el.readyState || el.complete) {
						el.src = BLANK;
						el.src = src;
					}
				});
			}
			return deferred ? deferred.promise($this) : $this;
		};




		/*
		 * Cookie plugin
		 * Copyright (c) 2010 Klaus Hartl (stilbuero.de)
		 * Dual licensed under the MIT and GPL licenses:
		 * http://www.opensource.org/licenses/mit-license.php
		 * http://www.gnu.org/licenses/gpl.html
		 * http://plugins.jquery.com/files/jquery.cookie.min.js.txt - Modified to Pass JSLint DSJ 11/11/11
		 */
		$.cookie = function(name, value, options) {
			var expires = '',
				cookieValue = null,
				cookies, cookie, date, path, domain, secure, i;
			if (value !== undefined) { // name and value given, set cookie
				options = options || {};
				if (value === null) {
					value = '';
					options.expires = -1;
				}
				if (options.expires && (typeof options.expires === 'number' || options.expires.toUTCString)) {
					if (typeof options.expires === 'number') {
						date = new Date();
						date.setTime(date.getTime() + (options.expires * 24 * 60 * 60 * 1000));
					} else {
						date = options.expires;
					}
					expires = '; expires=' + date.toUTCString(); // use expires attribute, max-age is not supported by IE
				}
				// CAUTION: Needed to parenthesize options.path and options.domain
				// in the following expressions, otherwise they evaluate to undefined
				// in the packed version for some reason...
				path = options.path ? '; path=' + (options.path) : '';
				domain = options.domain ? '; domain=' + (options.domain) : '';
				secure = options.secure ? '; secure' : '';
				document.cookie = [name, '=', encodeURIComponent(value), expires, path, domain, secure].join('');
			} else { // only name given, get cookie
				if (document.cookie && document.cookie !== '') {
					cookies = document.cookie.split(';');
					for (i = 0; i < cookies.length; i++) {
						cookie = $.trim(cookies[i]);
						// Does this cookie string begin with the name we want?
						if (cookie.substring(0, name.length + 1) === (name + '=')) {
							cookieValue = decodeURIComponent(cookie.substring(name.length + 1));
							break;
						}
					}
				}
				return cookieValue;
			}
		};



		/*
		 * Utility Functions
		 */

		// adds "..." in the middle of long filenames
		function doShortentFileName(str, len) {
			var rval, h;
			if (typeof str === 'string' && str.length > len) {
				h = parseInt(len / 2, 10);
				rval = str.substring(0, h) + '...' + str.substring(str.length - h, str.length);
			} else {
				rval = str;
			}
			return rval;
		}

		// clears the internal timer
		function clearTimer() {
			if (sys.timer) {
				window.clearTimeout(sys.timer);
			}
			sys.timer = null;
		}

		// converts bytes to a nicer display...
		function displayFileSize(filesize) {
			if (filesize >= 1073741824) {
				filesize = parseFloat(filesize / 1073741824).toFixed(2) + ' Gb';
			} else {
				if (filesize >= 1048576) {
					filesize = parseFloat(filesize / 1048576).toFixed(2) + ' Mb';
				} else {
					if (filesize >= 1024) {
						filesize = parseFloat(filesize / 1024).toFixed(2) + ' Kb';
					} else {
						filesize = parseInt(filesize, 10) + ' bytes';
					}
				}
			}
			return filesize;
		}

		// updates the main browser window's stats
		function updateDisplayStats(path, cnt, size) {
			var stats = '';
			stats += '<div class="margins">';
			stats += '<div class="item">Path: <strong>' + path + '</strong></div>';
			stats += '<div class="item">Size: <strong>' + (typeof size === 'number' ? displayFileSize(parseInt(size, 10)) : 'NaN') + '</strong></div>';
			stats += '<div class="item">Files: <strong>' + (typeof cnt === 'number' ? cnt : 'NaN') + '</strong></div>';
			stats += '</div>';
			$('#footer .stats').html(stats);
		}


		/*
		 * CORE Browser Functions
		 */

		// copy item to new location
		function moveItem(dragID, dropID) {
			console.log('dragID:' + dragID + ' dropID:' + dropID);
		}

		// rename an item
		function renameItem() {

		}

		// displays our dialog boxes
		function displayDialog(opts) {
			// opts: type, state, label, content, cbOk, cbCancel
			if (typeof opts === 'object' && typeof opts.type === 'string' && typeof opts.state === 'string') {
				if ($('#CJModalDialog').get(0) !== undefined) {
					if (sys.autoCenter !== null) {
						// clear any autocenter intervals
						window.clearInterval(sys.autoCenter);
						sys.autoCenter = null;
					}
					$('#CJModalDialog').remove();
				}
				switch (opts.type) {
				case 'progress':
					$('body').append(
						'<div id="CJModalDialog">' +
							'<div class="innerBox">' +
								'<div class="margins">' +
									'<div class="label"></div>' +
									'<div class="indicator" style="background-position: 0px 0px"></div>' +
								'</div>' +
							'</div>' +
						'</div>'
					);
					// setup our animated progress indicator
					$('#CJModalDialog .indicator').data('storage', {
						hpos: 0
					});
					sys.autoCenter = window.setInterval(function () {
						var $bar = $('#CJModalDialog .indicator'),
							data = $bar.data('storage');
						if (data.hpos === undefined) {
							data.hpos = 0;
						} else {
							data.hpos = (data.hpos < -32) ? 0 : data.hpos - 2;
						}
						$bar.css({
							backgroundPosition: data.hpos + 'px 0px'
						});
					}, 50);
					if (typeof opts.label !== 'string') {
						opts.label = 'Loading data...';
					}
					break;
				case 'confirm':
					$('body').append(
						'<div id="CJModalDialog">' +
							'<div class="innerBox">' +
								'<div class="margins">' +
									'<div class="label"></div>' +
									'<div class="content"></div>' +
									'<div class="buttons">' +
										'<button type="button" name="buttonCANCEL" id="buttonCANCEL" class="input_button">Cancel</button>' +
										'<button type="button" name="buttonOK" id="buttonOK" class="input_button">OK</button>' +
									'</div>' +
								'</div>' +
							'</div>' +
						'</div>'
					);
					$('#CJModalDialog #buttonCANCEL').mouseup(function () {
						displayDialog({
							type: 'confirm',
							state: 'hide'
						});
					});
					if (typeof opts.label !== 'string') {
						opts.label = 'Please confirm...';
					}
					break;
				case 'throw':
					$('body').append(
						'<div id="CJModalDialog">' +
							'<div class="innerBox">' +
								'<div class="margins">' +
									'<div class="label"></div>' +
									'<div class="content"></div>' +
									'<div class="buttons">' +
										'<button type="button" name="buttonOK" id="buttonOK" class="input_button">OK</button>' +
									'</div>' +
								'</div>' +
							'</div>' +
						'</div>'
					);
					$('#CJModalDialog #buttonOK').mouseup(function () {
						displayDialog({
							type: 'throw',
							state: 'hide'
						});
					});
					if (typeof opts.label !== 'string') {
						opts.label = 'The system encountered an throw...';
					}
					break;
				default:
					break;
				}
				if (opts.state === 'show') {
					// display the background overlay
					$('#CJModalBGround').css({
						display: 'block',
						opacity: 0.65
					});
					$('#CJModalDialog .label').html(opts.label);
					if (typeof opts.content === 'string') {
						if (opts.type === 'throw') {
							$('#CJModalDialog .content').html('<div class="clearfix"><span class="ui-icon ui-icon-throw" style="float:left; margin:0 7px 20px 0;"></span>' + opts.content + '</div></div>');
						} else {
							$('#CJModalDialog .content').html(opts.content);
						}
					} else if (typeof opts.content === 'object') {
						var err_list = '';
						$.each(opts.content, function(err_idx) {
							if (typeof err_idx === 'string' && !(opts.content[err_idx] instanceof Function)) {
								err_list += '<p>' + opts.content[err_idx] + '</p>';
							}
						});
						if (err_list !== '' && opts.type === 'throw') {
							$('#CJModalDialog .content').html('<div class="clearfix"><span class="ui-icon ui-icon-throw" style="float:left; margin:0 7px 20px 0;"></span>' + err_list + '</div></div>');
						} else if (err_list !== '') {
							$('#CJModalDialog .content').html(err_list);
						} else {
							$('#CJModalDialog .content').html('<div class="clearfix"><span class="ui-icon ui-icon-throw" style="float:left; margin:0 7px 20px 0;"></span>An unknown error occurred. (Error message could not be determined)</div></div>');
						}
					}
					if (typeof opts.cbOk === 'function') {
						$('#CJModalDialog #buttonOK').mouseup(opts.cbOk);
					}
					if (typeof opts.cbCancel === 'function') {
						$('#CJModalDialog #buttonCANCEL').mouseup(opts.cbCancel);
					}
					$('#CJModalDialog').css({
						top: (parseInt(($(window).height() / 2), 10) - parseInt($('#CJModalDialog').height() / 2, 10)) + 'px',
						left: (parseInt(($(window).width() / 2), 10) - parseInt($('#CJModalDialog').width() / 2, 10)) + 'px'
					}).fadeIn();
				} else if (opts.state === 'hide') {
					if (sys.autoCenter !== null) {
						// clear any autocenter intervals
						window.clearInterval(sys.autoCenter);
						sys.autoCenter = null;
					}
					// remove any click action that may have been attached.
					$('#CJModalDialog #buttonOK').off();
					$('#CJModalDialog #buttonCANCEL').off();
					// remove the dialog
					$('#CJModalDialog').remove();
					$('#CJModalBGround').css({
						display: 'none'
					});
				}
			}
		}

		// disable all options (used before performing various options)
		function resetAllOptions() {
			$('#directoryOut,#directoryIn,#directories,#newfolder,#fileDelete,#fileSelect').attr('disabled', true);
			$('#directories option').remove();
			updateDisplayStats('', 0, 0);
		}

		// populates the directory SELECT menu
		function updateDirOptions() {
			$('#directories option').remove();
			$('#directories optgroup').remove();
			$('#directories').append('<optgroup label="Current Directory Path" title="Current Directory Path">');
			$(opts.baseRelPath).each(function (intIndex, objValue) {
				$('#directories').append('<option value="' + objValue + '"' + (intIndex === sys.currentPathIdx ? ' selected="selected"' : '') + '>' + objValue + '</option>').attr("disabled", false);
			});
			// need to see if we have more than one directory and change the directory NAVIGATION accordingly
			if (opts.baseRelPath.length > 1 && sys.currentPathIdx > 0) {
				$('#directoryOut').attr('disabled', false);
			} else {
				$('#directoryOut').attr('disabled', true);
			}
		}

		function doLoadDirectoryImage($elem, idx, currentDir) {
			if ($elem.length > 0 && currentDir === sys.currentPathIdx) {
				$elem.each(function() {
					var $this = $(this),
						fname = window.encodeURIComponent($this.find('.diritem').attr('rel')),
						json;
					json = $.parseJSON(
					$.ajax({
						type: 'post',
						url: 'assets/engines/' + opts.engine + '/' + opts.handler,
						data: {
							method: 'getImageThumb',
							returnFormat: 'json',
							timeOut: parseInt(opts.timeOut, 10),
							baseRelPath: window.encodeURIComponent(opts.baseRelPath[sys.currentPathIdx]),
							elemID: $this.attr('id'),
							fileName: fname
						},
						dataType: 'json',
						async: true,
						success: function (data) {
							if (typeof data !== 'object' || typeof data.error !== 'boolean' || data.error) {
								if (sys.debug) {
									console.log(data);
								}
								displayDialog({
									type: 'throw',
									state: 'show',
									label: 'Oops! There was a problem',
									content: data.msg
								});
							} else {
								$this.find('.icon').css('background', '#fff');
								$this.find('.icon .imgHolder').html(data.imgStr);
								$this.find('.icon .imgHolder img').imagesLoaded(function () {
									$this.find('.icon .imgHolder').css('display', 'block');
								});
							}
						},
						error: function (err) {
							if (sys.debug) {
								console.log(err.responseText);
							}
							displayDialog({
								type: 'throw',
								state: 'show',
								label: 'Oops! There was a problem',
								content: 'Problems communicating with the CFC. Unexpected results returned when loading thumbnails.'
							});
						}
					}).responseText || null);
				});
			}
		}

		// grabs an image preview for image files
		function getDirectoryImages() {
			// show image previews?
			if (opts.showImgPreview) {
				doLoadDirectoryImage($('#browser ul li.GIF, #browser ul li.JPG, #browser ul li.PNG'), 0, sys.currentPathIdx);
			}
		}


		// grabs the directory listing
		function doDirListing(clb) {

			var json;

			// do the progress bar
			displayDialog({
				type: 'progress',
				state: 'show',
				label: 'Reading directory contents...'
			});

			// erase any old data
			$('#sidebar ul').remove();
			$('#browser ul').remove();
			resetAllOptions();

			json = $.parseJSON(
			$.ajax({
				type: 'post',
				url: 'assets/engines/' + opts.engine + '/' + opts.handler,
				data: {
					method: 'getDirectoryList',
					returnFormat: 'json',
					timeOut: parseInt(opts.timeOut, 10),
					baseRelPath: window.encodeURIComponent(opts.baseRelPath[sys.currentPathIdx]),
					fileExts: window.encodeURIComponent(opts.fileExts)
				},
				dataType: 'json',
				async: true,
				success: function (data) {
					var reDBLSL = new RegExp('\/\/', 'gim');
					if (typeof data !== 'object' || typeof data.error !== 'boolean' || data.error) {
						if (sys.debug) {
							console.log(data);
						}
						sys.dirContents = [];
						displayDialog({
							type: 'throw',
							state: 'show',
							label: 'Oops! There was a problem',
							content: data.msg
						});
					} else {
						if (data.dirlisting.length >= 0) {
							sys.dirContents = data.dirlisting;
							displayDialog({
								type: 'progress',
								state: 'hide'
							});
							if (typeof sys.dirContents === 'object' && sys.dirContents.length > 0) {
								sys.basePath = opts.baseRelPath[sys.currentPathIdx];
								// fix path
								do {
									sys.basePath = sys.basePath.replace(reDBLSL, '/');
								} while (reDBLSL.test(sys.basePath));
								// save cookie
								$.cookie('cj_dir', sys.basePath, {
									expires: 1,
									path: opts.baseRelPath[0]
								});
								if (sys.debug) {
									console.log($.cookie('cj_dir'));
								}
								if ($.isFunction(clb)) {
									clb.apply();
								}
							}
						}
					}
				},
				error: function (err) {
					if (sys.debug) {
						console.log(err.responseText);
					}
					sys.dirContents = [];
					displayDialog({
						type: 'throw',
						state: 'show',
						label: 'Oops! There was a problem',
						content: 'Problems communicating with the CFC. Unexpected results returned for doDirListing.'
					});
				}
			}).responseText || null);

			// enable and re-initialize some options and buttons
			updateDirOptions();
			$('#newfolder').attr({
				disabled: false
			});
		}

		// pass the file to tinyMCE or do stand-alone selection
		function doFileSelect(fileObj) {

			if (!(typeof fileObj.attr === 'string' || typeof fileObj.date === 'string' || typeof fileObj.dir === 'string' || typeof fileObj.ext === 'string' || typeof fileObj.fullpath === 'string' || typeof fileObj.mime === 'string' || typeof fileObj.height === 'string' || typeof fileObj.height === 'number' || typeof fileObj.name !== 'string' || typeof fileObj.size !== 'number' || typeof fileObj.type !== 'string' || typeof fileObj.width === 'string' || typeof fileObj.width === 'number')) {

				// debug the file selection settings (if debug is turned on and console is available)
				if (sys.debug) {
					console.log(fileObj);
				}

				displayDialog({
					type: 'throw',
					state: 'show',
					label: 'Oops! There was a problem',
					content: 'There was a problem reading file selection information.'
				});

			} else if (typeof tinyMCE !== 'undefined' && typeof tinyMCEPopup !== 'undefined') {
				var win = tinyMCEPopup.getWindowArg('window'),
					relPath = fileObj.dir + fileObj.name;

				// insert information into the tinyMCE window
				win.document.getElementById(tinyMCEPopup.getWindowArg('input')).value = relPath;

				// for image browsers: update image dimensions
				if (win.ImageDialog) {
					if (win.ImageDialog.getImageData) {
						win.ImageDialog.getImageData();
					}
					if (win.ImageDialog.showPreviewImage) {
						win.ImageDialog.showPreviewImage(relPath);
					}
				}

				// close popup window
				tinyMCEPopup.close();

			} else {

				// We are a standalone mode. What to do, is up to you...
				if (opts.callBack !== null) {

					// user passed a callback function
					opts.callBack(fileObj);

				} else {

					// just do a simple throw
					displayDialog({
						type: 'throw',
						state: 'show',
						label: 'Standalone Mode Message',
						content: 'You selected' + (fileObj.dir + fileObj.name) + '<br />' + fileObj.fullpath
					});
				}

			}
		}

		// displays the directory listing
		function displayDirListing() {
			var dir = sys.dirContents,
				total_size = 0,
				infoStr;

			// show out progress
			displayDialog({
				type: 'progress',
				state: 'show',
				label: 'Displaying directory contents...'
			});

			if (dir.length > 0) {

				// init the sidebar list element
				$('#sidebar').append('<ul></ul>');
				$('#browser').append('<ul></ul>');

				// cycle through the json array and create our directory list items from each entry
				$.each(dir, function (intIndex, objValue) {
					var lis, lib, info;

					// create our SIDEBAR list items
					lis = $('<li>').attr({
						id: 'sidebar_ID' + intIndex,
						rel: objValue.type === 'FILE' ? 'File' : 'Directory'
					}).addClass(objValue.ext).html('<span rel="' + objValue.name + '">' + doShortentFileName(objValue.name, 20) + '</span>');

					// create our BROWSER list items
					lib = $('<li>').attr({
						id: 'browser_ID' + intIndex,
						rel: objValue.type === 'FILE' ? 'File' : 'Directory'
					}).addClass(objValue.ext);

					// add a special class to the LI if it's a viewable image
					if (opts.showImgPreview && (objValue.ext === 'GIF' || objValue.ext === 'JPG' || objValue.ext === 'PNG')) {
						lib.addClass('viewable');
					}

					// parse things that should be numeric
					objValue.width = parseInt(objValue.width, 10);
					objValue.height = parseInt(objValue.height, 10);
					objValue.size = parseInt(objValue.size, 10);

					// create our info box
					info = $('<div>').addClass('diritem').addClass(objValue.ext).attr('rel', objValue.name).append(
						'<div class="icon" rel="' + objValue.name + '">' +
							(typeof objValue.width === 'number' && typeof objValue.height === 'number' ? '<div class="imgHolder"></div><div class="mask"></div>' : '') +
						'</div>' +
						'<div class="name">' + doShortentFileName(objValue.name, 20) + '</div>' +
						'<div class="namefull">' + objValue.name + '</div>' +
						(objValue.type === 'FILE' ? '<div class="size">' + displayFileSize(parseInt(objValue.size, 10)) + '</div>' : '') +

						(parseInt(objValue.width, 10) && parseInt(objValue.height, 10) ? '<div class="dimensions"><span class="width">' + parseInt(objValue.width, 10) + '</span> x <span class="height">' + parseInt(objValue.height, 10) + '</span> pixels</div>' : '') +

						(objValue.date.length > 0 ? '<div class="modified">' + dateFormat(objValue.date, 'mmm dS, yyyy, h:MM:ss TT') + '</div>' : '') +
						'<div class="mimeType">' + objValue.mime + '</div>'
					);

					// add the file size to the directories total
					total_size += parseInt(objValue.size, 10);

					// append out info string to the list items
					infoStr = objValue.name + ' \n' + (objValue.type === 'FILE' ? displayFileSize(parseInt(objValue.size, 10)) + ' \n' : '') + (parseInt(objValue.width, 10) && parseInt(objValue.height, 10) ? parseInt(objValue.width, 10) + ' x ' + parseInt(objValue.height, 10) + ' pixels \n' : '') + dateFormat(objValue.date, 'mmm dS, yyyy, h:MM:ss TT');
					$(lis).attr('title', infoStr);
					$(lib).attr('title', infoStr).append(info);

					// add the direct list to the BROWSER and SIDEBAR windows
					$('#sidebar ul').append(lis);
					$('#browser ul').append(lib);
				});

				// set up our hover and click actions for the SIDEBAR window
				$('#sidebar ul li').on('mouseenter mousedown', function () {
					$(this).addClass('hovering');
				}).on('mouseleave mouseup', function () {
					$(this).removeClass('hovering');
				}).on('click', function (e) {
					var $this = $(this),
						$twin = $('#browser #' + ($this.attr('id')).replace('sidebar_ID', 'browser_ID'));
					if ($this.attr('rel') === 'File') {
						$('#directoryIn').attr('disabled', true).off();
						if ($this.hasClass('selected')) {
							$this.removeClass('selected');
							$twin.removeClass('selected');
							$('#fileSelect,#fileDelete').attr('disabled', true);
						} else {
							$('#sidebar ul li,#browser ul li').removeClass('selected');
							$this.addClass('selected');
							$twin.addClass('selected');
							$('#fileSelect').attr('disabled', false);
							if ($.inArray('fileDelete', opts.actions) > -1) {
								$('#fileDelete').attr('disabled', false);
							} else {
								$('#fileDelete').attr('disabled', true);
							}
							$('#browser').animate({
								scrollTop: $('#browser').scrollTop() + $twin.offset().top - $twin.height()
							}, 'fast');
						}
					} else if ($this.attr('rel') === 'Directory') {
						if ($this.hasClass('selected')) {
							$this.removeClass('selected');
							$twin.removeClass('selected');
							$('#fileSelect').attr('disabled', true);
							$('#directoryIn').attr('disabled', true).off();
						} else {
							$('#sidebar ul li,#browser ul li').removeClass('selected');
							$this.addClass('selected');
							$twin.addClass('selected');
							$('#fileSelect').attr('disabled', true);
							if ($.inArray('deleteDirectory', opts.actions) > -1) {
								$('#fileDelete').attr('disabled', false);
							} else {
								$('#fileDelete').attr('disabled', true);
							}
							$('#browser').animate({
								scrollTop: $('#browser').scrollTop() + $twin.offset().top - $twin.height()
							}, 'fast');
							$('#directoryIn').attr('disabled', false).on('click', function (e) {
								if ($this.attr('disabled') !== 'disabled' && $this.attr('disabled') !== true) {
									var path = $('#sidebar ul li.selected').find('span').attr('rel');
									opts.baseRelPath.push(opts.baseRelPath[sys.currentPathIdx] + path + '/');
									sys.currentPathIdx += 1;
									updateDirOptions();
									doDirListing(function() {
										displayDirListing();
									});
								}
							});
						}
					}
					e.stopImmediatePropagation();
				}).on('dblclick', function (e) {
					// double-click action for directories, might allow this for files eventually.
					var $this = $(this),
						path = $this.find('span').attr('rel'),
						fileObj;
					if ($this.attr('rel') === 'File') {
						fileObj = sys.dirContents[parseInt(($this.attr('ID')).replace('sidebar_ID', ''), 10)];
						doFileSelect(fileObj);
					} else if ($this.attr('rel') === 'Directory') {
						opts.baseRelPath.push(opts.baseRelPath[sys.currentPathIdx] + path + '/');
						sys.currentPathIdx += 1;
						updateDirOptions();
						doDirListing(function() {
							displayDirListing();
						});
					}
					e.stopImmediatePropagation();
				});

				// set up our hover and click actions for the BROWSER window
				$('#browser ul li').on('mouseenter mousedown', function () {
					$(this).addClass('hovering');
				}).on('mouseleave mouseup', function () {
					$(this).removeClass('hovering');
				}).on('click', function (e) {
					var $this = $(this),
						$twin = $('#sidebar #' + ($this.attr('id')).replace('browser_ID', 'sidebar_ID'));
					if ($this.attr('rel') === 'File') {
						$('#directoryIn').attr('disabled', true).off();
						if ($this.hasClass('selected')) {
							$this.removeClass('selected');
							$twin.removeClass('selected');
							$('#fileSelect,#fileDelete').attr('disabled', true);
						} else {
							$('#sidebar ul li,#browser ul li').removeClass('selected');
							$this.addClass('selected');
							$twin.addClass('selected');
							$('#fileSelect').attr('disabled', false);
							if ($.inArray('fileDelete', opts.actions) > -1) {
								$('#fileDelete').attr('disabled', false);
							} else {
								$('#fileDelete').attr('disabled', true);
							}
							$('#sidebar').animate({
								scrollTop: $('#sidebar').scrollTop() + $twin.offset().top - 43
							}, 'fast'); // #sidebar css position top = 43px
						}
					} else if ($this.attr('rel') === 'Directory') {
						if ($this.hasClass('selected')) {
							$this.removeClass('selected');
							$twin.removeClass('selected');
							$('#fileSelect').attr('disabled', true);
							$('#directoryIn').attr('disabled', true).off();
						} else {
							$('#sidebar ul li,#browser ul li').removeClass('selected');
							$this.addClass('selected');
							$twin.addClass('selected');
							$('#fileSelect').attr('disabled', true);
							if ($.inArray('deleteDirectory', opts.actions) > -1) {
								$('#fileDelete').attr('disabled', false);
							} else {
								$('#fileDelete').attr('disabled', true);
							}
							$('#sidebar').animate({
								scrollTop: $('#sidebar').scrollTop() + $twin.offset().top - 43
							}, 'fast'); // not sure why 43 is working here?!?
							$('#directoryIn').attr('disabled', false).on('click', function (e) {
								if ($this.attr('disabled') !== 'disabled' && $this.attr('disabled') !== true) {
									var path = $('#browser ul li.selected').find('.diritem').attr('rel');
									opts.baseRelPath.push(opts.baseRelPath[sys.currentPathIdx] + path + '/');
									sys.currentPathIdx += 1;
									updateDirOptions();
									doDirListing(function() {
										displayDirListing();
									});
								}
							});
						}
					}
					e.stopImmediatePropagation();
				}).on('dblclick', function (e) {
					// double-click action for directories, might allow this for files eventually.
					var $this = $(this),
						path = $this.find('.diritem').attr('rel'),
						fileObj;
					if ($this.attr('rel') === 'File') {
						fileObj = sys.dirContents[parseInt(($this.attr('ID')).replace('browser_ID', ''), 10)];
						doFileSelect(fileObj);
					} else if ($this.attr('rel') === 'Directory') {
						opts.baseRelPath.push(opts.baseRelPath[sys.currentPathIdx] + path + '/');
						sys.currentPathIdx += 1;
						updateDirOptions();
						doDirListing(function() {
							displayDirListing();
						});
					}
					e.stopImmediatePropagation();
				}).draggable({
					cursor: 'move',
					helper: 'clone',
					opacity: 0.5,
					containment: '#browser',
					scroll: true,
					start: function(event, ui) {
						var $this = $(event.target).parents('li');
						sys.dragObjId = $this.attr('id');
					},
					stop: function(event, ui) {
						var $this = $(event.target).parents('li');
						sys.dragObjId = null;
					}
				});

				// setup droppable's for directories
				$('#browser ul li[rel="Directory"]').droppable({
					over: function(event, ui) {
						$(this).addClass('hovering');
					},
					out: function(event, ui) {
						$(this).removeClass('hovering');
					},
					drop: function(event, ui) {
						var $this = $(this);
						moveItem(sys.dragObjId, $this.attr('id'));
						sys.dragObjId = null;
					}
				});

				getDirectoryImages();

			}

			// hide our progress bar
			displayDialog({
				type: 'progress',
				state: 'hide'
			});

			// update display stats info
			updateDisplayStats(opts.baseRelPath[sys.currentPathIdx], dir.length, total_size);
		}


		/*
		 * Drag-n-drop, Yo!
		 */
		function dragEnter(e) {
			var $trg = $(e.target);
			$trg.addClass('drop_hover');
			e.stopPropagation();
			e.preventDefault();
			return false;
		}

		function dragOver(e) {
			var $trg = $(e.target);
			$trg.addClass('drop_hover');
			e.stopPropagation();
			e.preventDefault();
			return false;
		}

		function dragLeave(e) {
			var $trg = $(e.target);
			$trg.removeClass('drop drop_hover');
			e.stopPropagation();
			e.preventDefault();
			return false;
		}

		function drop(e, clb) {
			var $trg = $(e.target),
				dataTransfer,
				prms;

			if ($trg.parents('li').length === 0) {

				dataTransfer = e.originalEvent.dataTransfer;
				$trg.removeClass('drop_hover').addClass('drop');

				displayDialog({
					type: 'progress',
					state: 'show',
					label: 'Uploading file' + (dataTransfer.files.length > 0 ? 's' : '') + '...'
				});

				try {
					prms = JSON.stringify(opts);
				} catch(err) {
					$trg.removeClass('drop_hover drop');
					displayDialog({
						type: 'throw',
						state: 'show',
						label: 'Oops! There was a problem',
						content: 'The upload parameters could not be determined.'
					});
					return false;
				}

				if (sys.debug) {
					console.log('prms', prms);
					console.log('dataTransfer.files', dataTransfer.files);
				}

				if (prms && dataTransfer.files.length > 0) {

					$.each(dataTransfer.files, function (i, file) {
						var xhr = new XMLHttpRequest();

						if (!file) {

							$trg.removeClass('drop_hover drop');
							displayDialog({
								type: 'throw',
								state: 'show',
								label: 'Oops! There was a problem',
								content: 'The file could not be uploaded. Could not read file.'
							});
							return false;

						} else if (file.type.length === 0 || (opts.fileExts !== "*" && opts.fileExts.indexOf(file.type) === -1)) {

							$trg.removeClass('drop_hover drop');
							displayDialog({
								type: 'throw',
								state: 'show',
								label: 'Oops! There was a problem',
								content: 'The file could not be uploaded. Wrong MIME type. [' + file.type + ']'
							});
							return false;

						} else if (file.size > opts.maxSize * 1024) {

							$trg.removeClass('drop_hover drop');
							displayDialog({
								type: 'throw',
								state: 'show',
								label: 'Oops! There was a problem',
								content: 'The file could not be uploaded. File was too large. [' + file.size + ']'
							});
							return false;

						} else {

							// do the upload
							xhr.onreadystatechange = function() {
								if (xhr.readyState === 4)  {
									if ((xhr.status >= 200 && xhr.status <= 200) || xhr.status === 304) {
										throw(xhr.responseText);
									}
								}
							};
							xhr.onload = function(ev) {
								try {
									if (sys.debug) {
										console.log(xhr.responseText);
									}
									var data = $.trim(xhr.responseText),
										json = JSON.parse(data);
									if (json && typeof json.error === 'boolean' && json.error === false) {
										doDirListing(function() {
											displayDirListing();
										});
									} else if (!json || json.error === undefined || json.error === true) {
										if (json && json.msg) {
											displayDialog({
												type: 'throw',
												state: 'show',
												label: 'Oops! There was a problem',
												content: json.msg
											});
											return false;
										} else {
											displayDialog({
												type: 'throw',
												state: 'show',
												label: 'Oops! There was a problem',
												content: 'There was a problem uploading your file' + (dataTransfer.files.length > 0 ? 's' : '') + '. Please contact technical support.'
											});
											return false;
										}
									} else {
										displayDialog({
											type: 'throw',
											state: 'show',
											label: 'Oops! There was a problem',
											content: 'There was a problem uploading your file' + (dataTransfer.files.length > 0 ? 's' : '') + '. Please contact technical support'
										});
										return false;
									}
									$trg.removeClass('drop_hover drop');
								} catch(err) {
									if (sys.debug) {
										console.log('error', err);
										console.log('xhr.responseText', xhr.responseText);
									}
									$trg.removeClass('drop_hover drop');
									displayDialog({
										type: 'throw',
										state: 'show',
										label: 'Oops! There was a problem',
										content: 'There was a problem uploading your file' + (dataTransfer.files.length > 0 ? 's' : '') + '. Please make sure that the file format is correct.</p><p>If you continue to experience problems, please contact technical support and send them the file you are trying to upload.'
									});
									return false;
								}
							};
							xhr.error = function(ev) {
								if (sys.debug) {
									console.log('upload error', ev);
								}
								displayDialog({
									type: 'throw',
									state: 'show',
									label: 'Oops! There was a problem',
									content: 'There was a problem uploading your file' + (dataTransfer.files.length > 0 ? 's' : '') + '. Please make sure that the file format is correct.</p><p>If you continue to experience problems, please contact technical support and send them the file you are trying to upload.'
								});
							};
							xhr.open(
								'POST',
								'assets/engines/' + opts.engine + '/' + opts.handler + '?method=doDropUpload&returnType=JSON',
								true
							);
							xhr.setRequestHeader('Content-Type', file.type);
							xhr.setRequestHeader('X-File-Name', window.encodeURIComponent(file.name) || window.encodeURIComponent(file.fileName));
							xhr.setRequestHeader('X-File-Params', window.encodeURIComponent(prms));
							xhr.send(file);
						}
					});
				}
			}

			e.stopPropagation();
			e.preventDefault();
			return false;
		}

		function doPostEval (r) {
			var json,
				ok = false;
			try {
				// if we don't have valid JSON, this should fail.
				json = JSON.parse(r);
				ok = true;
			} catch (ex) {}
			if (ok && typeof json === 'object' && typeof json.error === 'boolean' && !json.error) {
				doDirListing(function() {
					displayDirListing();
				});
			} else {
				displayDialog({
					type: "alert",
					state: "show",
					label: "Oops! There was a problem",
					content: ok && json && json.msg ? json.msg : ''
				});
			}
		}

		function setup() {

			// create a modal box background (make sure click throughs don't happen)
			$('body').append('<div id="CJModalBGround"></div>').on('click', function (e) {
				e.stopImmediatePropagation();
			});

			// start our progress bar and do init stuff
			displayDialog({
				type: 'progress',
				state: 'show',
				label: 'Initializing...'
			});

			// do some basic button setup (header buttons)
			$('#header button').hover(function () {
				$(this).css({
					'background-position': '0px -32px'
				});
			}, function () {
				$(this).css({
					'background-position': '0px 0px'
				});
			}).mousedown(function () {
				$(this).css({
					'background-position': '0px -96px'
				});
			}).mouseup(function () {
				$(this).css({
					'background-position': '0px 0px'
				});
			});

			// set up deselect if the user clicks the browser window
			$('#sidebar,#browser').on('click', function (e) {
				$('#sidebar li').removeClass('selected');
				$('#browser li').removeClass('selected');
				$('#fileSelect,#fileDelete').attr('disabled', true);
				$('#directoryIn').attr('disabled', true).off();
				e.stopImmediatePropagation();
			});

			// setup droppable files for the browser
			if ($.inArray('dropUpload', opts.actions) > 0) {
				$('#browser').on('dragenter', dragEnter);
				$('#browser').on('dragover', dragOver);
				$('#browser').on('dragleave', dragLeave);
				$('#browser').on('drop', drop);
			}

			// determine which buttons to show based on user passed actions
			if ($.inArray('navigateDirectory', opts.actions) === -1) {
				$('#directoryOptions').remove();
			} else {
				// set up directory NAVIGATION buttons
				$('#directoryOut').mouseup(function () {
					var $this = $(this);
					if ($this.attr('disabled') !== 'disabled' && $this.attr('disabled') !== true) {
						sys.currentPathIdx = sys.currentPathIdx - 1 >= 0 ? sys.currentPathIdx - 1 : 0;
						opts.baseRelPath.remove(sys.currentPathIdx + 1, opts.baseRelPath.length - sys.currentPathIdx + 1);
						doDirListing(function() {
							displayDirListing();
						});
					}
				});

				// set up the directories SELECT menu
				$('#directories').change(function () {
					var $this = $(this);
					if ($this.get(0).selectedIndex < sys.currentPathIdx) {
						opts.baseRelPath.remove($this.get(0).selectedIndex + 1, opts.baseRelPath.length - $this.get(0).selectedIndex + 1);
						sys.currentPathIdx = $this.get(0).selectedIndex;
						doDirListing(function() {
							displayDirListing();
						});
					}
				});
			}

			if ($.inArray('createDirectory', opts.actions) === -1) {
				$('#fileOptions #newfolder').remove();
			} else {
				// handle the NEW FOLDER action
				$('#newfolder').mouseup(function () {
					$(this).css({
						'background-position': '0px 0px'
					}).attr('disabled', true);
					displayDialog({
						type: 'confirm',
						state: 'show',
						label: 'Create a new directory...',
						content: (
							'<form name="CJNewDirectoryForm" id="CJNewDirectoryForm" action="javascript:void(0);" method="post">' +
								'<div class="fields">' +
									'<input type="text" name="directoryName" id="directoryName" class="input_text" />' +
								'</div>' +
							'</form>'
						),
						cbOk: function (str) {
							var dirName = $('#CJNewDirectoryForm #directoryName').val(),
								json;
							if (typeof dirName === 'string' && dirName.length > 0) {
								displayDialog({
									type: 'progress',
									state: 'show',
									label: 'Creating new directory...'
								});
								$('#fileSelect').attr('disabled', true);
								$('#fileDelete').attr('disabled', true);
								// set a nice timer to ensure that the CFC does not timeout
								sys.timer = window.setTimeout(function () {
									displayDialog({
										type: 'throw',
										state: 'show',
										label: 'Oops! There was a problem',
										content: 'The system timed out attempting to create a new directory.'
									});
									$('#newfolder').attr('disabled', false);
								}, parseInt(opts.timeOut, 10) * 1000);
								json = $.parseJSON(
								$.ajax({
									type: 'post',
									url: 'assets/engines/' + opts.engine + '/' + opts.handler,
									data: {
										method: 'doCreateNewDirectory',
										returnFormat: 'json',
										timeOut: parseInt(opts.timeOut, 10),
										baseRelPath: window.encodeURIComponent(opts.baseRelPath[sys.currentPathIdx]),
										dirName: window.encodeURIComponent(dirName)
									},
									dataType: 'json',
									async: true,
									success: function (data) {
										if (typeof data !== 'object' || typeof data.error !== 'boolean' || data.error) {
											if (sys.debug) {
												console.log(data);
											}
											clearTimer();
											displayDialog({
												type: 'throw',
												state: 'show',
												label: 'Oops! There was a problem',
												content: data.msg
											});
											$('#newfolder').attr('disabled', false);
										} else {
											clearTimer();
											$('#newfolder').attr('disabled', false);
											doDirListing(function() {
												displayDirListing();
											});
										}
									},
									error: function (err) {
										if (sys.debug) {
											console.log(err.responseText);
										}
										clearTimer();
										displayDialog({
											type: 'throw',
											state: 'show',
											label: 'Oops! There was a problem',
											content: 'Problems communicating with the CFC. Unexpected results returned for newfolder (click).'
										});
										$('#newfolder').attr('disabled', false);
									}
								}).responseText || null);
							}
						},
						cbCancel: function () {
							$('#newfolder').attr('disabled', false);
						}
					});
				});
			}

			if ($.inArray('deleteDirectory', opts.actions) === -1 && $.inArray('fileDelete', opts.actions) === -1) {
				$('#fileOptions #fileDelete').remove();
			} else {
				// setup our DELETE action
				$('#fileDelete').mouseup(function () {
					var type = ($('#browser ul li.selected').attr('rel')).toLowerCase();
					if ((type === 'directory' && $.inArray('deleteDirectory', opts.actions) > -1) || (type === 'file' && $.inArray('fileDelete', opts.actions) > -1)) {
						$(this).css({
							'background-position': '0px 0px'
						}).attr('disabled', true);
						displayDialog({
							type: 'confirm',
							state: 'show',
							label: 'Delete file...',
							content: 'This ' + ($('#browser ul li.selected').attr('rel')).toLowerCase() + ' will be deleted and cannot be recovered. Are you sure you want to perform this action?',
							cbOk: function () {
								var curFile = $('#browser ul li.selected .icon').attr('rel'),
									curType = $('#browser ul li.selected').attr('rel'),
									json;
								if (typeof curFile === 'string' && curFile.length > 0 && (curType === 'File' || curType === 'Directory')) {
									displayDialog({
										type: 'progress',
										state: 'show',
										label: 'Deleting file...'
									});
									$('#fileSelect').attr('disabled', true);
									$('#fileDelete').attr('disabled', true);
									// set a nice timer to ensure that the CFC does not timeout
									sys.timer = window.setTimeout(function () {
										displayDialog({
											type: 'throw',
											state: 'show',
											label: 'Oops! There was a problem',
											content: 'The system timed out attempting to delete a file.'
										});
										$('#newfolder').attr('disabled', false);
									}, parseInt(opts.timeOut, 10) * 1000);

									// delete the file or directory
									json = $.parseJSON(
									$.ajax({
										type: 'post',
										url: 'assets/engines/' + opts.engine + '/' + opts.handler,
										data: {
											method: curType === 'File' ? 'doDeleteFile' : 'doDeleteDirectory',
											returnFormat: 'json',
											timeOut: parseInt(opts.timeOut, 10),
											baseRelPath: window.encodeURIComponent(opts.baseRelPath[sys.currentPathIdx]),
											dirName: window.encodeURIComponent(curFile),
											fileName: window.encodeURIComponent(curFile)
										},
										dataType: 'json',
										async: true,
										success: function (data) {
											if (typeof data !== 'object' || typeof data.error !== 'boolean' || data.error) {
												if (sys.debug) {
													console.log(data);
												}
												clearTimer();
												displayDialog({
													type: 'throw',
													state: 'show',
													label: 'Oops! There was a problem',
													content: (typeof data.msg === 'string' && data.msg !== '') ? data.msg : 'Problems communicating with the CFC when attempting to delete a ' + curType.toLowerCase() + '.'
												});
												$('#fileDelete').attr('disabled', false);
											} else {
												clearTimer();
												$('#fileDelete').attr('disabled', false);
												doDirListing(function() {
													displayDirListing();
												});
											}
										},
										error: function (err) {
											if (sys.debug) {
												console.log(err.responseText);
											}
											clearTimer();
											displayDialog({
												type: 'throw',
												state: 'show',
												label: 'Oops! There was a problem',
												content: 'Problems communicating with the CFC. Unexpected results returned for fileDelete (click).'
											});
											$('#fileDelete').attr('disabled', false);
										}
									}).responseText || null);
								}
							},
							cbCancel: function () {
								$('#fileDelete').attr('disabled', false);
							}
						});
					}
				});
			}

			// handle the UPLOAD action
			if ($.inArray('fileUpload', opts.actions) === -1) {
				$('#fileOptions #fileUpload').remove();
			} else {
				$('#fileUpload').mouseup(function () {
					var $this = $(this);
					$this.css({
						'background-position': '0px 0px'
					}).attr('disabled', true);
					displayDialog({
						type: 'confirm',
						state: 'show',
						label: 'Upload a file...',
						content: (
							'<form name="CJUploadForm" id="CJUploadForm" action="javascript:void(0);" method="post">' +
								'<div class="fields">' +
									'<input type="file" name="fileUploadField" id="fileUploadField" />' +
								'</div>' +
							'</form>'
						),
						cbOk: function () {
							if ($('#CJUploadForm #fileUploadField').val() !== '') {
								$('#CJFileBrowser #CJFileBrowserForm').append(
									'<div class="hider">' +
										'<input type="hidden" name="baseUrl" value="' + window.encodeURIComponent(opts.baseRelPath[sys.currentPathIdx]) + '" />' +
										'<input type="hidden" name="fileExts" value="' + window.encodeURIComponent(opts.fileExts) + '" />' +
										'<input type="hidden" name="maxSize" value="' + window.encodeURIComponent(opts.maxSize) + '" />' +
										'<input type="hidden" name="maxWidth" value="' + window.encodeURIComponent(opts.maxWidth) + '" />' +
										'<input type="hidden" name="maxHeight" value="' + window.encodeURIComponent(opts.maxHeight) + '" />' +
										'<input type="hidden" name="timeOut" value="' + parseInt(opts.timeOut, 10) + '" />' +
									'</div>'
								);
								$('#CJUploadForm #fileUploadField').appendTo($('#CJFileBrowser #CJFileBrowserForm .hider'));
								displayDialog({
									type: 'confirm',
									state: 'hide'
								});
								$('#fileUpload').attr('disabled', false);
								$('#CJFileBrowserForm').submit();
							}
						},
						cbCancel: function () {
							$('#fileUpload').attr('disabled', false);
						}
					});
					// fix the file upload input
					$('#CJUploadForm #fileUploadField').css({
						opacity: 0.0
					}).change(function () {
						$('#CJUploadForm #uploadFakeFile').val($(this).val());
					});
					$('#CJUploadForm .fields').append(
					$('<div></div>').addClass('fakefile').append(
					$('<input>').attr({
						type: 'text',
						id: 'uploadFakeFile'
					}), $('<img>').attr({
						src: 'assets/images/bg_fileselect.png'
					}).css('z-index', -1))).addClass('clearfix');
				}).attr('disabled', false);

				// handle the FORM submit
				$('#CJFileBrowserForm').submit(function () {
					var $formElem = $(this),
						ifrmName = ('uploader' + (new Date()).getTime()),
						jFrame, base_path,
						fn = function () {
							jFrame.remove();
						};

					// display the progress bar...
					displayDialog({
						type: 'progress',
						state: 'show',
						label: 'Uploading file...'
					});

					// do some fancy form stuff... (posting into an iframe)
					jFrame = $('<iframe name="' + ifrmName + '" id="' + ifrmName + '" src="about:blank"></iframe>');
					jFrame.css({
						position: 'absolute',
						top: sys.debug ? '0px' : '-999px',
						left: sys.debug ? '0px' : '-999px',
						display: sys.debug ? 'block' : 'none',
						width: sys.debug ? '100%' : '1px',
						height: sys.debug ? 'auto' : '1px',
						background: '#fff',
						zIndex: 9999
					});
					jFrame.load(function (objEvent) {
						var objUploadBody = $(this).contents().find('body').html();
						if (sys.debug) {
							console.log(objUploadBody);
						}
						if ($.trim(objUploadBody) !== '') {
							$formElem.attr({
								action: function () {
									return false;
								},
								method: 'post',
								enctype: 'multipart/form-data',
								encoding: 'multipart/form-data',
								target: ''
							});
							clearTimer();
							$('#CJFileBrowserForm').find('.hider').remove();
							doPostEval($.trim(objUploadBody));
							sys.timer = window.setTimeout(fn, 100);
						}
					});
					$('body').append(jFrame);

					// set a nice timer to ensure that the CFC does not timeout
					sys.timer = window.setTimeout(function () {
						displayDialog({
							type: 'alert',
							state: 'show',
							label: 'Oops! There was a problem',
							content: 'The system timed out attempting to upload a file.'
						});
						jFrame.remove();
						$('#CJFileBrowserForm').find('.hider').remove();
						$('#fileUpload').attr('disabled', false);
					}, parseInt(opts.timeOut, 10) * 1000);

					// We don't know where we are at. So we need to determine the path to do the form submit.
					// not sure if this is elegant or a mess, but it works.
					base_path = (document.location.href.split('?')[0]).replace(/(\/|\\)(cjfilebrowser|index)\.html/g, '');
					$formElem.attr({
						action: base_path + '/assets/engines/' + opts.engine + '/' + opts.handler + '?method=doFileUpload',
						method: 'post',
						enctype: 'multipart/form-data',
						encoding: 'multipart/form-data',
						target: ifrmName
					});
					return true;
				});
			}

			// handle the file SELECT action
			if ($.inArray('fileSelect', opts.actions) === -1) {
				$('#fileOptions #fileSelect').remove();
			} else {
				$('#fileSelect').mouseup(function () {
					var fileID = parseInt($('#browser ul li.selected').attr('ID').replace('browser_ID', ''), 10);
					if (typeof fileID === 'number' && typeof sys.dirContents[fileID] === 'object') {
						doFileSelect(sys.dirContents[fileID]);
					} else {
						displayDialog({
							type: 'throw',
							state: 'show',
							label: 'Oops! There was a problem',
							content: 'Problems encountered attempting to determine file selection.'
						});
					}
				});
			}

			// make sure all dialog auto centers
			$(window).resize(function () {
				var dlg = $('#CJModalDialog');
				dlg.css({
					top: (parseInt(($(window).height() / 2), 10) - parseInt(dlg.height() / 2, 10)) + 'px',
					left: (parseInt(($(window).width() / 2), 10) - parseInt(dlg.width() / 2, 10)) + 'px'
				});
			});

			// get directory listing
			doDirListing(function() {
				displayDirListing();
			});

		}

		// initial test to see if our handler exists
		function getHandler() {
			var json,
				re = new RegExp('//|\/', 'gim'),
				reDBLSL = new RegExp('\/\/', 'gim'),
				pathArr;

			sys.basePath = $.cookie('cj_dir') || (opts.baseRelPath.length > 0 ? opts.baseRelPath[0] : null);

			// need to set the basePath based on cookie (if valid) or the opts.baseRelPath
			if (sys.basePath && sys.basePath.indexOf(opts.baseRelPath[0]) > 0) {
				// the path is valid, but we need to loop through it to populate our path object
				sys.basePath = sys.basePath.length > 1 ? sys.basePath.substring(1, sys.basePath.length - 1) : '/';
				pathArr = sys.basePath.split(re);
				$.each(pathArr, function(a, b) {
					opts.baseRelPath.push(opts.baseRelPath[opts.baseRelPath.length - 1] + b + '/');
				});
			} else {
				sys.basePath = opts.baseRelPath[0];
			}

			sys.currentPathIdx = opts.baseRelPath.length - 1;
			sys.basePath = opts.baseRelPath[sys.currentPathIdx];

			if (sys.debug) {
				console.log('sys.basePath: ' + sys.basePath);
			}

			if (!sys.basePath) {
				// if either path is invalid, then make sure the cookie get's removed.
				$.cookie('cj_dir', null, {
					expires: -1,
					path: sys.basePath
				});
				throw('Oops! There was a problem\n\nThe initial path is not valid (' + sys.basePath + ').');
			} else {

				json = $.parseJSON(
				$.ajax({
					type: 'post',
					url: 'assets/engines/' + opts.engine + '/' + opts.handler,
					data: {
						method: 'isHandlerReady',
						returnFormat: 'json',
						dirPath: window.escape(sys.basePath), // validates the initial directory path
						timeOut: parseInt(opts.timeOut, 10),
						version: sys.version
					},
					dataType: 'json',
					async: true,
					success: function (data) {
						if (typeof data !== 'object' || typeof data.error !== 'boolean' || data.error) {
							if (sys.debug) {
								console.log(data);
							}
							throw('Oops! There was a problem\n\nThe handler engine did not respond properly during initialization.');
						} else {
							setup();
						}
					},
					error: function (err) {
						if (sys.debug) {
							console.log(err.responseText);
						}
						throw('Oops! There was a problem\n\nThe handler engine did not respond properly during initialization.');
					}
				}).responseText || null);
			}
		}

		function init() {

			var tmce = typeof tinyMCE !== 'undefined' ? tinyMCE : null;

			if (typeof options === 'object' || (typeof options === 'string' && options === 'init')) {

				$obj.html(
					'<div id="header" class="ui-widget-header">' +
						'<form name="CJFileBrowserForm" id="CJFileBrowserForm" action="javascript:void(0);" method="post" enctype="multipart/form-data">' +
							'<div class="padder">' +
								'<div id="directoryOptions">' +
									'<button name="directoryOut" id="directoryOut" disabled="disabled"><span>Back Directory</span></button>' +
									'<button name="directoryIn" id="directoryIn" disabled="disabled"><span>Forward Directory</span></button>' +
									'<div class="container">' +
										'<label for="directories">Directories: </label>' +
										'<select name="directories" id="directories" disabled="disabled"><option value=""></option></select>' +
									'</div>' +
								'</div>' +
								'<div id="fileOptions">' +
									'<button type="button" name="newfolder" id="newfolder" disabled="disabled"><span>Create Folder</span></button>' +
									'<button type="button" name="fileUpload" id="fileUpload" disabled="disabled"><span>Upload</span></button>' +
									'<button type="button" name="fileDelete" id="fileDelete" disabled="disabled"><span>Delete</span></button>' +
									'<button type="button" name="fileSelect" id="fileSelect" disabled="disabled"><span>Select</span></button>' +
								'</div>' +
							'</div>' +
						'</form>' +
					'</div>' +
					'<div id="sidebar" class="ui-widget-content"></div>' +
					'<div id="browser" class="ui-widget-content"></div>' +
					'<div id="footer"></div>'
				);

				// setup the footer
				$obj.find('#footer').append('<div class="callout"><div class="margins">CJ File Browser <strong id="CJVersion">v' + sys.version + '</strong>. Created by <a href="http://www.cjboco.com/" target="_blank" title="Creative Juice Bo. Co.">Creative Juice Bo. Co.</a></div></div>');
				$obj.find('#footer').append('<div class="stats"></div>');

				// if we are a tinyMCE plug-in then we need to grab the user settings
				if (tmce) {

					console.log('hit');

					opts.actions 			= typeof tmce.activeEditor.getParam('plugin_cjfilebrowser_actions') === 'string' ? (tmce.activeEditor.getParam('plugin_cjfilebrowser_actions')).split(',') : '';
					opts.baseRelPath 		= typeof tmce.activeEditor.getParam('plugin_cjfilebrowser_assetsUrl') === 'string' ? [tmce.activeEditor.getParam('plugin_cjfilebrowser_assetsUrl')] : [''];
					opts.fileExts 			= typeof tmce.activeEditor.getParam('plugin_cjfilebrowser_fileExts') === 'string' ? tmce.activeEditor.getParam('plugin_cjfilebrowser_fileExts') : '';
					opts.maxSize 			= typeof tmce.activeEditor.getParam('plugin_cjfilebrowser_maxSize') === 'number' ? tmce.activeEditor.getParam('plugin_cjfilebrowser_maxSize') : 0;
					opts.maxWidth 			= typeof tmce.activeEditor.getParam('plugin_cjfilebrowser_maxWidth') === 'number' ? tmce.activeEditor.getParam('plugin_cjfilebrowser_maxWidth') : 0;
					opts.maxHeight 			= typeof tmce.activeEditor.getParam('plugin_cjfilebrowser_maxHeight') === 'number' ? tmce.activeEditor.getParam('plugin_cjfilebrowser_maxHeight') : 0;
					opts.showImgPreview 	= typeof tmce.activeEditor.getParam('plugin_cjfilebrowser_showImgPreview') === 'boolean' ? tmce.activeEditor.getParam('plugin_cjfilebrowser_showImgPreview') : true;
					opts.engine 			= typeof tmce.activeEditor.getParam('plugin_cjfilebrowser_engine') === 'string' ? tmce.activeEditor.getParam('plugin_cjfilebrowser_engine') : '';
					opts.handler 			= typeof tmce.activeEditor.getParam('plugin_cjfilebrowser_handler') === 'string' ? tmce.activeEditor.getParam('plugin_cjfilebrowser_handler') : '';
					opts.timeOut 			= typeof tmce.activeEditor.getParam('plugin_cjfilebrowser_timeOut') === 'number' ? tmce.activeEditor.getParam('plugin_cjfilebrowser_timeOut') : 900; // 15 minutes
					opts.callBack			= null;

				} else if (options) {
					// we are in stand-alone mode... extend our options with user passed settings
					$.extend(opts, options);
				}

				// debug the init settings (if debug is turned on and console is available)
				if (sys.debug) {
					console.log(opts);
				}

				// need to verify that we have valid setting values...
				if (
					(typeof opts.actions 			!== 'object' || opts.actions.length === 0) ||
					(typeof opts.baseRelPath 		!== 'object' || opts.baseRelPath.length === 0) ||
					(typeof opts.fileExts 			!== 'string' || opts.fileExts.length === 0) ||
					(typeof opts.maxSize 			!== 'number' || opts.maxSize === 0) ||
					(typeof opts.maxWidth 			!== 'number' || opts.maxWidth === 0) ||
					(typeof opts.maxHeight 			!== 'number' || opts.maxHeight === 0) ||
					(typeof opts.showImgPreview 	!== 'boolean') ||
					(typeof opts.engine 			!== 'string' || opts.engine === '') ||
					(typeof opts.handler 			!== 'string' || opts.handler === '') ||
					(typeof opts.timeOut 			!== 'number' || opts.timeOut < 0) ||
					(typeof opts.callBack 			!== 'function' && opts.callBack !== null) ||
					(parseInt(sys.currentPathIdx, 10) || 0)
				) {

					// problem initializing the script
					throw('Oops! There was a problem\n\nVariables were not initialized properly or missing values.');

				} else {

					// test to make sure our handler exists
					getHandler();
				}

			}

		}


		// init our navbar
		if (!JSON) {
			console.log('No json');
			$.getScript('assets/js/json2.min.js', function(data, statusText) {
				if (!statusText || statusText !== 'success') {
					throw('Problems initializing json2.min.js (cj.file_browser.js)');
				} else {
					init();
				}
			});
		} else {
			init();
		}


	};

	$.fn.extend({

		cjFileBrowser: function (options) {

			// call to the plug-in
			return this.each(function () {

				$.cjFileBrowser($(this), options);

			});

		}
	});

}(jQuery));