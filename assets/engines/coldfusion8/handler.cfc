<cfcomponent name="CJ_FileBrowser" displayName="CJ FileBrowser" output="true" hint="Creative Juices TinyMCE File Browser by Doug Jones (www.cjboco.com)">

	<!--- ****************************************************************************

		CJ File Browser (ColdFusion 8 Engine)
		Version: 1.1
		Date Modified: April 14th, 2010

		Author: Doug Jones
		http://www.cjboco.com/

		Copyright (c) 2007-2010, Doug Jones. All rights reserved.

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

	**************************************************************************** --->

	<!--- these are theme specific, so know what your doing before changing these --->
	<cfset variables.thumb_width = 63 />
	<cfset variables.thumb_height = 87 />

	<!--- a list of valid image types that can be displated in a web browser (only valid WEB IMAGES) --->
	<cfset variables.webImgFileList = "gif,jpg,jpeg,png" />




	<!--- ------------------------------------------------------------------------

		isHandlerReady - Informs CJ File Browser that the handler exists
						 and also check to make sure the security.xml
						 file is present and appears to be valid.

		Author: Doug Jones
		http://www.cjboco.com/

	------------------------------------------------------------------------ --->
	<cffunction name="isHandlerReady" access="remote" returntype="any" output="no">
		<cfargument name="version" type="string" required="yes" />
		<cfargument name="timeOut" type="numeric" required="no" default="900" />
		<cfset var locvar = StructNew() />
		<cfset var result = StructNew() />
		<cfset result.error = false />
		<cfset result.msg = ArrayNew(1) />
		<cftry>
			<cfif Len(arguments.version) gt 0>

				<!--- check to see if they passed a timout value --->
				<cfif isDefined("arguments.timeOut") and isNumeric(arguments.timeOut) and arguments.timeOut gt 0>
					<cfsetting requestTimeout="#arguments.timeOut#" />
				</cfif>

				<!--- check security.xml version --->
				<cfset locvar.version = getSecuritySettings('version') />
				<cfif isStruct(locvar.version) and isDefined("locvar.version.error") and NOT locvar.version.error>
					<cfif isDefined("locvar.version.version") and locvar.version.version eq arguments.version>
						<!--- everything ok --->
					<cfelse>
						<cfset result.error = true />
						<cfset ArrayAppend(result.msg, "Security.xml version does not match the CJ File Browser version.") />
					</cfif>
				<cfelse>
					<cfset result.error = true />
					<cfif isDefined("locvar.version.error_msg")>
						<cfset ArrayAppend(result.msg, locvar.version.error_msg) />
					<cfelse>
						<cfset ArrayAppend(result.msg, "Problems checking security.xml version.") />
					</cfif>
				</cfif>

				<!--- check security.xml directories --->
				<cfset locvar.validatePath = getSecuritySettings('directories') />
				<cfif isStruct(locvar.validatePath) and isDefined("locvar.validatePath.error") and NOT locvar.validatePath.error>
					<!--- everything checks out --->
				<cfelse>
					<cfset result.error = true />
					<cfif isDefined("locvar.version.error_msg")>
						<cfset ArrayAppend(result.msg, locvar.version.error_msg) />
					<cfelse>
						<cfset ArrayAppend(result.msg, "Problems checking security.xml authorized directories.") />
					</cfif>
				</cfif>

				<!--- check security.xml actions --->
				<cfset locvar.validateAction = getSecuritySettings('actions') />
				<cfif isStruct(locvar.validateAction) and isDefined("locvar.validateAction.error") and NOT locvar.validateAction.error>
					<!--- everything checks out --->
				<cfelse>
					<cfset result.error = true />
					<cfif isDefined("locvar.version.error_msg")>
						<cfset ArrayAppend(result.msg, locvar.version.error_msg) />
					<cfelse>
						<cfset ArrayAppend(result.msg, "Problems checking security.xml authorized actions.") />
					</cfif>
				</cfif>

				<!--- check security.xml file extensions --->
				<cfset locvar.isFileExtValid = getSecuritySettings('fileExts') />
				<cfif isStruct(locvar.isFileExtValid) and isDefined("locvar.isFileExtValid.error") and NOT locvar.isFileExtValid.error>
					<!--- everything checks out --->
				<cfelse>
					<cfset result.error = true />
					<cfif isDefined("locvar.version.error_msg")>
						<cfset ArrayAppend(result.msg, locvar.version.error_msg) />
					<cfelse>
						<cfset ArrayAppend(result.msg, "Problems checking security.xml authorized file extensions.") />
					</cfif>
				</cfif>

			<!--- we weren't passed the version --->
			<cfelse>

				<cfset result.error = true />
				<cfset ArrayAppend(result.msg, "Version information not provided.") />

			</cfif>
			<cfcatch type="any">
				<cfset result.error = true />
				<cfset ArrayAppend(result.msg, cfcatch.message) />
			</cfcatch>
		</cftry>
		<cfreturn result />
	</cffunction>


	<!--- ------------------------------------------------------------------------

		isPathValid - Validates that the given relative path is allowed
					  within the security settings.

		Author: Doug Jones
		http://www.cjboco.com/

	------------------------------------------------------------------------ --->
	<cffunction name="isPathValid" access="private" returntype="boolean" output="no" hint="Validates that the given relative path is allowed within the security settings.">
		<cfargument name="baseRelPath" type="string" required="yes" />
		<cfargument name="exact" type="boolean" required="no" default="false" />
		<cfargument name="settings" type="any" required="no" default="" />
		<cfset var locvar = StructNew() />
		<cftry>
			<cfset locvar.baseRelPath = URLDecode(arguments.baseRelPath) />
			<cfif Len(locvar.baseRelPath) gt 0>
				<!--- to save time on disk reads, we can pass the directory list --->
				<cfif isStruct(arguments.settings) and isDefined("arguments.settings.error") and NOT arguments.settings.error and isDefined("arguments.settings.dirListRel") and ListLen(arguments.settings.dirListRel) gt 0>
					<cfset locvar.authDirs = arguments.settings />
				<cfelse>
					<cfset locvar.authDirs = getSecuritySettings('directories') />
				</cfif>
				<cfif isDefined("locvar.authDirs.error") and locvar.authDirs.error>
					<cfreturn false />
				<cfelseif isDefined("locvar.authDirs.error") and NOT locvar.authDirs.error and isDefined("locvar.authDirs.dirListRel") and ListLen(locvar.authDirs.dirListRel) gt 0>
					<cfloop index="locvar.dir" list="#locvar.authDirs.dirListRel#">
						<cfif arguments.exact>
							<cfif LCase(locvar.baseRelPath) eq LCase(locvar.dir)>
								<cfreturn true />
								<cfbreak />
							</cfif>
						<cfelse>
							<cfif Left(LCase(locvar.baseRelPath), Len(locvar.dir)) eq LCase(locvar.dir)>
								<cfreturn true />
								<cfbreak />
							</cfif>
						</cfif>
					</cfloop>
				</cfif>
			</cfif>
			<cfcatch type="any">
				<cfreturn false />
			</cfcatch>
		</cftry>
		<cfreturn false />
	</cffunction>


	<!--- ------------------------------------------------------------------------

		isActionValid - Validates that the given action is allowed
						within the security settings.

		Author: Doug Jones
		http://www.cjboco.com/

	------------------------------------------------------------------------ --->
	<cffunction name="isActionValid" access="private" returntype="boolean" output="no" hint="Validates that the given action is allowed within the security settings.">
		<cfargument name="userAction" type="string" required="yes" />
		<cfargument name="settings" type="any" required="no" default="" />
		<cfset var locvar = StructNew() />
		<cftry>
			<cfif Len(arguments.userAction) gt 0>
				<!--- to save time on disk reads, we can pass the directory list --->
				<cfif isStruct(arguments.settings) and isDefined("arguments.settings.error") and NOT arguments.settings.error and isDefined("arguments.settings.actionList") and ListLen(arguments.settings.actionList) gt 0>
					<cfset locvar.authActions = arguments.settings />
				<cfelse>
					<cfset locvar.authActions = getSecuritySettings('actions') />
				</cfif>
				<cfif isDefined("locvar.authActions.error") and locvar.authActions.error>
					<cfreturn false />
				<cfelseif isDefined("locvar.authActions.error") and NOT locvar.authActions.error and isDefined("locvar.authActions.actionList") and ListLen(locvar.authActions.actionList) gt 0>
					<cfif ListFindNoCase(locvar.authActions.actionList, arguments.userAction) gt 0>
						<cfreturn true />
					<cfelse>
						<cfreturn false />
					</cfif>
				</cfif>
			</cfif>
			<cfcatch type="any">
				<cfreturn false />
			</cfcatch>
		</cftry>
		<cfreturn false />
	</cffunction>


	<!--- ------------------------------------------------------------------------

		isFileExtValid - Validates that the given action is allowed
						 within the security settings.

		Author: Doug Jones
		http://www.cjboco.com/

	------------------------------------------------------------------------ --->
	<cffunction name="isFileExtValid" access="private" returntype="boolean" output="no" hint="Validates that the given file extension is allowed within the security settings.">
		<cfargument name="fileExt" type="string" required="yes" />
		<cfargument name="settings" type="any" required="no" default="" />
		<cfset var locvar = StructNew() />
		<cftry>
			<cfif Len(arguments.fileExt) gt 0>
				<!--- to save time on disk reads, we can pass the directory list --->
				<cfif isStruct(arguments.settings) and isDefined("arguments.settings.error") and NOT arguments.settings.error and isDefined("arguments.settings.extList") and ListLen(arguments.settings.extList) gt 0>
					<cfset locvar.authExts = arguments.settings />
				<cfelse>
					<cfset locvar.authExts = getSecuritySettings('fileExts') />
				</cfif>
				<cfif isDefined("locvar.authExts.error") and locvar.authExts.error>
					<cfreturn false />
				<cfelseif isDefined("locvar.authExts.error") and NOT locvar.authExts.error and isDefined("locvar.authExts.extList") and ListLen(locvar.authExts.extList) gt 0>
					<cfif locvar.authExts.extList eq "*">
						<cfreturn true />
					<cfelseif ListFindNoCase(locvar.authExts.extList, arguments.fileExt) gt 0>
						<cfreturn true />
					<cfelse>
						<cfreturn false />
					</cfif>
				</cfif>
			</cfif>
			<cfcatch type="any">
				<cfreturn false />
			</cfcatch>
		</cftry>
		<cfreturn false />
	</cffunction>


	<!--- ------------------------------------------------------------------------

		getSecuritySettings	- Reads the cjFileBrowser security.xml file and
							  returns no error with a comma seperated list of valid
							  directories that can be modified or an error
							  with the error message

		Author: Doug Jones
		http://www.cjboco.com/

	------------------------------------------------------------------------ --->
	<cffunction name="getSecuritySettings" access="private" returntype="any" output="no" hint="Reads the cjFileBrowser security.xml file and returns a comma seperated list of valid  directories that can be modified.">
		<cfargument name="settingType" type="string" required="yes" />
		<cfset var locvar = StructNew() />
		<cfset var result = StructNew() />
		<cfset result.error = false />
		<cfset result.msg = "" />
		<cftry>

			<!--- called from assets/engines/ENGINE folder --->
			<cfif FileExists(ExpandPath('../../../security.xml'))>
				<cffile action="read" file="#ExpandPath('../../../security.xml')#" variable="locvar.xml">
				<cfset locvar.xml = XMLParse(locvar.xml) />
				<cfif isXml(locvar.xml)>

					<!--- security paths --->
					<cfif arguments.settingType eq "directories">

						<cfset locvar.xmlSettings = XMLSearch(locvar.xml,"cjFileBrowser/directoriesAllowed/directory") />

						<cfif ArrayLen(locvar.xmlSettings) gt 0>
							<cfset locvar.dirListAbs = "" />
							<cfset locvar.dirListRel = "" />
							<cfloop index="locvar.cnt" from="1" to="#ArrayLen(locvar.xmlSettings)#">
								<cfset locvar.attr = locvar.xmlSettings[locvar.cnt].XmlAttributes.type />
								<cfif locvar.attr eq "absolute">
									<cfif Len(locvar.xmlSettings[locvar.cnt].XmlText) gt 0>
										<cfset locvar.dirListAbs = ListAppend(locvar.dirListAbs, locvar.xmlSettings[locvar.cnt].XmlText) />
									</cfif>
								<cfelseif locvar.attr eq "relative">
									<cfif Len(locvar.xmlSettings[locvar.cnt].XmlText) gt 0>
										<cfset locvar.dirListRel = ListAppend(locvar.dirListRel, locvar.xmlSettings[locvar.cnt].XmlText) />
									</cfif>
								</cfif>
							</cfloop>
							<!--- they may have provided blank entries, this is not allowed --->
							<cfif ListLen(locvar.dirListRel) gt 0>
								<cfset result.error = false />
								<cfset result.dirListRel = locvar.dirListRel />
							<cfelse>
								<cfset result.error = true />
								<cfset result.msg = "There are no authorized directories set in the security.xml file. (Cannot be blank)" />
							</cfif>
						<cfelse>
							<cfset result.error = true />
							<cfset result.msg = "There are no authorized directories set in the security.xml file. (Cannot be blank)" />
						</cfif>

					<!--- security actions --->
					<cfelseif arguments.settingType eq "actions">

						<cfset locvar.xmlSettings = XMLSearch(locvar.xml,"cjFileBrowser/actionsAllowed/action") />
						<cfif ArrayLen(locvar.xmlSettings) gt 0>
							<cfset locvar.actionList = "" />
							<cfloop index="locvar.cnt" from="1" to="#ArrayLen(locvar.xmlSettings)#">
								<cfif Len(locvar.xmlSettings[locvar.cnt].XmlText) gt 0>
									<cfset locvar.actionList = ListAppend(locvar.actionList, locvar.xmlSettings[locvar.cnt].XmlText) />
								</cfif>
							</cfloop>
							<!--- they may have provided blank entries, this is not allowed --->
							<cfif ListLen(locvar.actionList) gt 0>
								<cfset result.error = false />
								<cfset result.actionList = locvar.actionList />
							<cfelse>
								<cfset result.error = true />
								<cfset result.msg = "There are no authorized actions set in the security.xml file. (No settings will not allow any action)" />
							</cfif>
						<cfelse>
							<cfset result.error = true />
							<cfset result.msg = "There are no authorized actions set in the security.xml file. (No settings will not allow any action)" />
						</cfif>


					<!--- security file extensions --->
					<cfelseif arguments.settingType eq "fileExts">

						<cfset locvar.xmlSettings = XMLSearch(locvar.xml,"cjFileBrowser/fileExtsAllowed/fileExt") />
						<cfif ArrayLen(locvar.xmlSettings) gt 0>
							<cfset locvar.extList = "" />
							<cfloop index="locvar.cnt" from="1" to="#ArrayLen(locvar.xmlSettings)#">
								<cfif Len(locvar.xmlSettings[locvar.cnt].XmlText) gt 0>
									<cfset locvar.extList = ListAppend(locvar.extList, Trim(locvar.xmlSettings[locvar.cnt].XmlText)) />
								</cfif>
							</cfloop>
							<!--- remove any spaced between the list items ", " or " ," --->
							<cfset locvar.extList = ReReplace(locvar.extList, "[\s]*,[\s]*",",","ALL") />
							<cfif ListLen(locvar.extList) gt 0>
								<cfset result.error = false />
								<cfset result.extList = locvar.extList />
							<cfelse>
								<cfset result.error = true />
								<cfset result.msg = "There are no authorized file extensions set in the security.xml file. (Cannot be blank)" />
							</cfif>
						<cfelse>
							<cfset result.error = true />
							<cfset result.msg = "There are no authorized file extensions set in the security.xml file. (Cannot be blank)" />
						</cfif>

					<!--- security file extensions --->
					<cfelseif arguments.settingType eq "version">

						<cfset result.error = false />
						<cfset result.version = locvar.xml.cjFileBrowser.XmlAttributes.version />

					<!--- unnknown security parameter --->
					<cfelse>

						<cfset result.error = true />
						<cfset result.msg = "Unknown security parameter check." />

					</cfif>

				<!--- not XML --->
				<cfelse>

					<cfset result.error = true />
					<cfset result.msg = "Problems reading in the security settings." />

				</cfif>

			<cfelse>

				<cfset result.error = true />
				<cfset result.msg = "Security.xml file could not be found." />

			</cfif>
			<cfcatch type="any">
				<cfset result.error = true />
				<cfset result.msg = cfcatch.message />
			</cfcatch>
		</cftry>
		<cfreturn result />
	</cffunction>


	<!--- ------------------------------------------------------------------------

		getDirectoryList - Reads and returns the contents of a given directory."",

		Author: Doug Jones
		http://www.cjboco.com/

	------------------------------------------------------------------------ --->
	<cffunction name="getDirectoryList" access="remote" output="false" returntype="any">
		<cfargument name="baseRelPath" type="string" required="yes" />
		<cfargument name="fileExts" type="string" required="no" default="" />
		<cfargument name="showInv" type="boolean" required="no" default="false" />
		<cfargument name="timeOut" type="numeric" required="no" default="900" />
		<cfset var locvar = StructNew() />
		<cfset var result = StructNew() />
		<cftry>

			<cfset locvar.baseRelPath = URLDecode(arguments.baseRelPath) />

			<!--- check to see if they passed a timout value --->
			<cfif isDefined("arguments.timeOut") and isNumeric(arguments.timeOut) and arguments.timeOut gt 0>
				<cfsetting requestTimeout="#arguments.timeOut#" />
			</cfif>

			<!--- preload our security settings (since we have to read this in each time) --->
			<cfset locvar.authDirs = getSecuritySettings('directories') />
			<cfset locvar.authActions = getSecuritySettings('actions') />
			<cfset locvar.authExts = getSecuritySettings('fileExts') />

			<!--- validate "navigateDirectory" action and path --->
			<cfif (NOT isActionValid("navigateDirectory",locvar.authActions) and NOT isPathValid(locvar.baseRelPath, true, locvar.authDirs)) or NOT isPathValid(locvar.baseRelPath, false, locvar.authDirs)>

				<cfset result.error = true />
				<cfset result.msg = "Directory access denied." />

			<!--- validate that the "baseRelPath" exists --->
			<cfelseif NOT DirectoryExists(ExpandPath(locvar.baseRelPath))>

				<cfset result.error = true />
				<cfset result.msg = "Directory does not exist." />

			<cfelse>

				<cfset result.error = false />
				<cfset result.msg = "" />
				<cfset locvar.absBaseUrl = ExpandPath(locvar.baseRelPath) />
				<cfset locvar.dir = ArrayNew(1) />

				<!--- read the directory and return contents--->
				<cfif DirectoryExists(locvar.absBaseUrl)>
					<cfdirectory action="list" directory="#locvar.absBaseUrl#" name="locvar.qry" sort="name" />
					<cfif locvar.qry.recordCount gt 0>
						<cfset locvar.idx = 1 />
						<cfloop query="locvar.qry">
							<cfif (arguments.showInv or (NOT arguments.showInv and Left(locvar.qry.name,1) neq "."))>
								<cfif locvar.qry.type eq "file" and Find(".",locvar.qry.name) gt 1>
									<cfset locvar.ext = LCase(ListLast(locvar.qry.name,'.')) />
								<cfelse>
									<cfset locvar.ext = "" />
								</cfif>
								<!--- remove any spaced between the list items ", " or " ," --->
								<cfset locvar.fileExts = ReReplace(arguments.fileExts, "[\s]*,[\s]*",",","ALL") />
								<cfif locvar.fileExts eq "*" or locvar.qry.type eq "Dir" or (locvar.fileExts neq "*" and ListFindNoCase(locvar.fileExts, locvar.ext) gt 0)>
									<cfif isFileExtValid(locvar.ext,locvar.authExts) or (locvar.qry.type eq "Dir" and isActionValid('navigateDirectory',locvar.authActions))>
										<cfif ArrayLen(locvar.dir) lt locvar.idx>
											<cfset ArrayAppend(locvar.dir, StructNew())>
										</cfif>
										<cfset locvar.dir[locvar.idx].name = HTMLEditFormat(locvar.qry.name) />
										<cfset locvar.dir[locvar.idx].size = locvar.qry.size />
										<cfset locvar.dir[locvar.idx].type = UCase(locvar.qry.type) />
										<cfif isDate(locvar.qry.datelastmodified)>
											<cfset locvar.dir[locvar.idx].datelastmodified = DateFormat(locvar.qry.datelastmodified,"mmmm d, yyyy") & " " & TimeFormat(locvar.qry.datelastmodified,"hh:mm:ss") />
										<cfelse>
											<cfset locvar.dir[locvar.idx].datelastmodified = "" />
										</cfif>
										<cfset locvar.dir[locvar.idx].attributes = locvar.qry.attributes />
										<cfset locvar.dir[locvar.idx].directory = locvar.baseRelPath />
										<cfset locvar.dir[locvar.idx].extension = UCase(locvar.ext) />
										<cfif locvar.qry.type eq "file">
											<cfset locvar.dir[locvar.idx].mime = getPageContext().getServletContext().getMimeType(locvar.qry.name) />
										<cfelse>
											<cfset locvar.dir[locvar.idx].mime = "" />
										</cfif>
										<cfset locvar.dir[locvar.idx].fullpath = locvar.absBaseUrl & locvar.qry.name />
										<!--- is this an image file? we can pass dimensions if it is --->
										<cfif ListFindNoCase(variables.webImgFileList, locvar.ext) gt 0>
											<cfimage action="read" name="locvar.img_input" source="#locvar.dir[locvar.idx].fullpath#" />
											<cfset locvar.dir[locvar.idx].width = locvar.img_input["width"] />
											<cfset locvar.dir[locvar.idx].height = locvar.img_input["height"] />
										<cfelse>
											<cfset locvar.dir[locvar.idx].width = "" />
											<cfset locvar.dir[locvar.idx].height = "" />
										</cfif>
										<cfset locvar.idx = locvar.idx + 1 />
									</cfif>
								</cfif>
							</cfif>
						</cfloop>
					</cfif>
					<cfset result.dirlisting = locvar.dir />

				<cfelse>

					<!--- if no contents, then return an empty array --->
					<cfset result.dirlisting = ArrayNew(1) />

				</cfif>

			</cfif>
			<cfcatch type="any">
				<cfset result.error = true />
				<cfset result.msg = cfcatch.message />
			</cfcatch>
		</cftry>
		<cfreturn result />
	</cffunction>


	<!--- ------------------------------------------------------------------------

		getImageThumb	- Returns a STRUCT of image data which can be used
						  to display an images scaled preview (or thumb).

		Author: Doug Jones
		http://www.cjboco.com/

	------------------------------------------------------------------------ --->
	<cffunction name="getImageThumb" access="remote" output="false" returntype="any" hint="Returns a STRUCT of image data which can be used to display an images scaled preview (or thumb).">
		<cfargument name="baseRelPath" type="string" required="yes" />
		<cfargument name="fileName" type="string" required="yes" />
		<cfargument name="elemID" type="string" required="yes" />
		<cfargument name="timeOut" type="numeric" required="no" default="900" />
		<cfset var locvar = StructNew() />
		<cfset var result = StructNew() />
		<cftry>

			<cfset locvar.baseRelPath = URLDecode(arguments.baseRelPath) />

			<!--- check to see if they passed a timout value --->
			<cfif isDefined("arguments.timeOut") and isNumeric(arguments.timeOut) and arguments.timeOut gt 0>
				<cfsetting requestTimeout="#arguments.timeOut#" />
			</cfif>

			<!--- preload our security settings (since we have to read this in each time) --->
			<cfset locvar.authDirs = getSecuritySettings('directories') />
			<cfset locvar.authActions = getSecuritySettings('actions') />

			<!--- validate "navigateDirectory" action and path --->
			<cfif (NOT isActionValid("navigateDirectory",locvar.authActions) and NOT isPathValid(locvar.baseRelPath, true, locvar.authDirs)) or NOT isPathValid(locvar.baseRelPath, false, locvar.authDirs)>

				<cfset result.error = true />
				<cfset result.msg = "Directory access denied." />

			<!--- validate action --->
			<cfelseif NOT isActionValid("filePreviews",locvar.authActions)>

				<cfset result.error = true />
				<cfset result.msg = 'Image previews are not allowed.' />

			<!--- validate that the "baseRelPath" exists --->
			<cfelseif NOT DirectoryExists(ExpandPath(locvar.baseRelPath))>

				<cfset result.error = true />
				<cfset result.msg = "Directory does not exist." />

			<cfelse>

				<cfset locvar.absFilePath = ExpandPath(locvar.baseRelPath & arguments.fileName) />
				<cfset result.error = false />
				<cfset result.msg = "" />
				<cfset result.elemID = arguments.elemID />
				<cfset result.imgStr = "" />
				<cfif FileExists(locvar.absFilePath)>
					<cfimage action="read" name="locvar.img_input" source="#locvar.absFilePath#" />
					<cfif locvar.img_input["width"] gt variables.thumb_width or locvar.img_input["height"] gt variables.thumb_height>
						<cfset locvar.img_info = calcScaleInfo(locvar.img_input["width"], locvar.img_input["height"], variables.thumb_width, variables.thumb_height, "fit")>
						<cfset result.imgStr = '<img src="#locvar.baseRelPath##arguments.fileName#" border="0" width="#locvar.img_info.width#" height="#locvar.img_info.height#" style="margin-top:#locvar.img_info.offset.y#px;margin-left:#locvar.img_info.offset.x#px;" />' />
					<cfelse>
						<cfset locvar.img_info.offset = StructNew() />
						<cfset locvar.img_info.offset.x = Int((variables.thumb_width / 2) - (locvar.img_input["width"] / 2)) />
						<cfset locvar.img_info.offset.y = Int((variables.thumb_height / 2) - (locvar.img_input["height"] / 2)) />
						<cfset result.imgStr = '<img src="#locvar.baseRelPath##arguments.fileName#" border="0" width="#locvar.img_input["width"]#" height="#locvar.img_input["height"]#" style="margin-top:#locvar.img_info.offset.y#px;margin-left:#locvar.img_info.offset.x#px;" />' />
					</cfif>
				<cfelse>
					<cfset result.error = true />
					<cfset result.msg = "Problems reading image thumbnail. Invalid path. (#locvar.absFilePath#)" />
				</cfif>

			</cfif>
			<cfcatch type="any">

				<cfset result.error = true />
				<cfset result.msg = "Problems reading image thumbnail. (#cfcatch.message#)" />

			</cfcatch>
		</cftry>
		<cfreturn result />
	</cffunction>


	<!--- ------------------------------------------------------------------------

		doFileUpload - Uploads a file to the server (Handles a form POST operation)

		Author: Doug Jones
		http://www.cjboco.com/

	------------------------------------------------------------------------ --->
	<cffunction name="doFileUpload" access="remote" output="true" returntype="none">
		<cfset var locvar = StructNew() />
		<cfset var result = StructNew() />
		<cfset result.error = false />
		<cfset result.error_msg = ArrayNew(1) />
		<cftry>

			<!--- make sure this is a post operation --->
			<cfif cgi.request_method neq "post">

				<cfset result.error = true />
				<cfset result.error_msg = "HTTP request method not allowed." />

			<!--- double check we have all our variables --->
			<cfelseif
				NOT StructKeyExists(arguments,"baseUrl") or
				NOT StructKeyExists(arguments,"maxWidth") or
				NOT StructKeyExists(arguments,"maxHeight") or
				NOT StructKeyExists(arguments,"maxSize") or
				NOT StructKeyExists(arguments,"fileExts") or
				NOT StructKeyExists(arguments,"fileUploadField") or
				NOT StructKeyExists(arguments,"timeOut")>

				<cfset result.error = true />
				<cfset result.error_msg = "Could not complete upload. Required form variables missing." />

			<cfelse>

				<!--- check to see if they passed a timout value --->
				<cfif StructKeyExists(arguments,"timeOut") and isNumeric(arguments['timeOut']) and arguments['timeOut'] gt 0>
					<cfsetting requestTimeout="#arguments['timeOut']#" />
				</cfif>

				<!--- preload our security settings (since we have to read this in each time) --->
				<cfset locvar.authDirs = getSecuritySettings('directories') />
				<cfset locvar.authActions = getSecuritySettings('actions') />
				<cfset locvar.authExts = getSecuritySettings('fileExts') />
				<!---
					We can check the file size in the temp folder! Thanks Dave (aka Mister Dai)
					http://misterdai.wordpress.com/2010/02/26/upload-size-before-cffile-upload/
				--->
				<cfset locvar.fileSize = GetFileInfo(GetTempDirectory() & GetFileFromPath(arguments['fileUploadField'])) />

				<!--- validate "navigateDirectory" action and path --->
				<cfif (NOT isActionValid("navigateDirectory",locvar.authActions) and NOT isPathValid(arguments['baseUrl'],true,locvar.authDirs)) or NOT isPathValid(arguments['baseUrl'],false,locvar.authDirs)>

					<cfset result.error = true />
					<cfset result.error_msg = "Directory access denied." />

				<!--- validate action --->
				<cfelseif NOT isActionValid("fileUpload",locvar.authActions)>

					<cfset result.error = true />
					<cfset result.error_msg = "Not authorized to upload files." />

				<!--- validate that the "baseUrl" exists --->
				<cfelseif NOT DirectoryExists(ExpandPath(URLDecode(arguments['baseUrl'])))>

					<cfset result.error = true />
					<cfset result.error_msg = "Directory does not exist." />

				<cfelseif isDefined("locvar.fileSize.size") and locvar.fileSize.size gt (form.maxSize * 1024)>

					<cfset result.error = true />
					<cfset ArrayAppend(result.error_msg, "The file size of your upload excedes the allowable limit. Please upload a file smaller than #NumberFormat(form.maxSize,'9,999')#KB.")>

				<cfelse>

					<!--- <cfset form = arguments /> --->

					<!--- validate that we have the proper form fields --->
					<cfif NOT DirectoryExists(ExpandPath(URLDecode(form.baseUrl)))>
						<cfset result.error = true />
						<cfset ArrayAppend(result.error_msg, "You must provide a valid UPLOAD DIRECTORY.<br /><small>(Could not find directory)</small>")>
					</cfif>
					<cfif NOT isDefined("form.baseUrl") or (isDefined("form.baseUrl") and (Len(form.baseUrl) eq 0 or ReFind("[^a-zA-Z0-9\,\$\-\_\.\+\!\*\'\(\)\/]+",URLDecode(form.baseUrl)) gt 0))>
						<cfset result.error = true />
						<cfset ArrayAppend(result.error_msg, "Variable BASEURL not defined or invalid data.") />
					</cfif>
					<cfif NOT isDefined("form.fileExts") or (isDefined("form.fileExts") and form.fileExts neq "*" and ReFind("[^a-zA-Z0-9\,]+",URLDecode(form.fileExts)) gt 0)>
						<cfset result.error = true />
						<cfset ArrayAppend(result.error_msg, "Variable FILEEXTS not defined or invalid data.") />
					<cfelse>
						<!--- remove any spaced between the list items ", " or " ," --->
						<cfset form.fileExts = ReReplace(URLDecode(form.fileExts), "[\s]*,[\s]*",",","ALL") />
					</cfif>
					<cfif NOT isNumeric(form.maxSize) or (isNumeric(form.maxSize) and (form.maxSize lt 1 or form.maxSize gt 9999999))>
						<cfset result.error = true />
						<cfset ArrayAppend(result.error_msg, "Variable MAXSIZE not defined or invalid data.") />
					</cfif>
					<cfif NOT isNumeric(form.maxWidth) or (isNumeric(form.maxWidth) and (form.maxWidth lt 1 or form.maxSize gt 9999999))>
						<cfset result.error = true />
						<cfset ArrayAppend(result.error_msg, "Variable MAXWIDTH not defined or invalid data.") />
					</cfif>
					<cfif NOT isNumeric(form.maxHeight) or (isNumeric(form.maxHeight) and (form.maxHeight lt 1 or form.maxHeight gt 9999999))>
						<cfset result.error = true />
						<cfset ArrayAppend(result.error_msg, "Variable MAXHEIGHT not defined or invalid data.") />
					</cfif>
					<cfif NOT isDefined("form.fileUploadField") or (isDefined("form.fileUploadField") and Len(URLDecode(form.fileUploadField)) eq 0)>
						<cfset result.error = true />
						<cfset ArrayAppend(result.error_msg, "FILE INPUT FILED not defined or invalid data.") />
					</cfif>

					<cfif NOT result.error and ArrayLen(result.error_msg) eq 0>

						<!---
							File Upload Notes:
							I would have rather uploaded to the temp directory and then move the file. but ColdFusion doesn't seem to check for name
							conflicts on "rename" or "move". If anyone knows an easy way around this, please share.
						--->

						<!--- upload the file --->
						<cffile action="upload" filefield="fileUploadField" destination="#ExpandPath(URLDecode(form.baseUrl))#" nameconflict="makeunique" />

						<!--- if the file uploaded, then continue --->
						<cfif cffile.filewassaved eq "Yes" and cffile.fileSize lte (form.maxSize * 1024)>

							<!--- make sure that the uploaded file has the correct file extension (This still doesn't mean it VALID! --->
							<cfif isFileExtValid(cffile.serverFileExt,locvar.authExts) and (form.fileExts eq "*" or (form.fileExts neq "*" and ListFindNoCase(form.fileExts, cffile.serverFileExt) gt 0))>

								<!---
									check file name and move out of temp directory
								—————————————————————————————————————————————————————————————————————————————————————— --->
								<cfset locvar.file_name = safeFileName(cffile.serverFileName) & "." & cffile.serverFileExt />
								<cffile action="rename" source="#ExpandPath(URLDecode(form.baseUrl)&cffile.ServerFile)#" destination="#ExpandPath(URLDecode(form.baseUrl)&locvar.file_name)#" />

								<!--- CHECK TO SEE IF THE WAS AN IMAGE BEFORE WE SCALE IT --->
								<!--- We could use isImageFile(), but if CF8 is missing an update it could crash the server. --->
								<cfif ListFindNoCase(variables.webImgFileList, cffile.serverFileExt) gt 0 and isNumeric(form.maxWidth) and isNumeric(form.maxHeight)>
									<!---
										resize the image if it's to big
									—————————————————————————————————————————————————————————————————————————————————————— --->
									<cfimage action="read" name="locvar.temp_file" source="#ExpandPath('#URLDecode(form.baseUrl)##locvar.file_name#')#" />
									<cfif locvar.temp_file["width"] gt form.maxWidth or locvar.temp_file["height"] gt form.maxHeight>
										<cfset ImageSetAntialiasing(locvar.temp_file, "on") />
										<cfset locvar.img_info = calcScaleInfo(locvar.temp_file["width"], locvar.temp_file["height"], form.maxWidth, form.maxHeight, "fit") />
										<cfset ImageScaleToFit(locvar.temp_file, locvar.img_info.width, locvar.img_info.height, "highestQuality", "1") />
										<cfimage action="write" source="#locvar.temp_file#" destination="#ExpandPath('#URLDecode(form.baseUrl)##locvar.file_name#')#" overwrite="yes" />
									</cfif>

								</cfif>

							<!--- not a valid file extension --->
							<cfelse>

								<cfset result.error = true />
								<cfset ArrayAppend(result.error_msg, "You are not allowed to upload #UCase(cffile.serverFileExt)# files.") />

								<!--- delete the file --->
								<cffile action="delete" file="#ExpandPath(URLDecode(form.baseUrl)&cffile.ServerFile)#" />

							</cfif>

						<cfelseif cffile.filewassaved eq "Yes" and cffile.fileSize gt (form.maxSize * 1024)>
							<!--- file is too big --->
							<cfif FileExists(ExpandPath('#URLDecode(form.baseUrl)##cffile.ServerFile#'))>
								<cffile action="delete" file="#ExpandPath('#URLDecode(form.baseUrl)##cffile.ServerFile#')#" />
							</cfif>
							<cfset result.error = true />
							<cfset ArrayAppend(result.error_msg, "The file size of your upload excedes the allowable limit. Please upload a file smaller than #NumberFormat(form.maxSize,'9,999')#KB.")>
						<cfelse>
							<!--- cffile.filewassaved = "no" --->
							<cfset result.error = true />
							<cfset ArrayAppend(result.error_msg, "Problems encountered uploading the file.")>
						</cfif>

					<cfelse>
						<!--- ArrayLen(result.error_msg) > 0 --->
						<cfset result.error = true />
						<cfset result.error_msg = result.error_msg />
					</cfif>

				</cfif>
			</cfif>

			<cfcatch type="any">
				<cfset result.error = true />
				<cfset result.error_msg = cfcatch.message />
			</cfcatch>
		</cftry>

		<cfsavecontent variable="locvar.strHTML">
			<cfoutput>
				<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
				<html>
				<head></head>
				<body>#ReReplace(Trim(HTMLEditFormat(SerializeJSON(result))),"[\t]+","","ALL")#</body>
				</html>
			</cfoutput>
		</cfsavecontent>
		<cfset locvar.binResponse = ToBinary( ToBase64( locvar.strHTML ) ) />
		<cfcontent reset="true" /><cfheader name="content-length" value="#ArrayLen( locvar.binResponse )#" /><cfcontent type="text/html" variable="#locvar.binResponse#" />
	</cffunction>


	<!--- ------------------------------------------------------------------------

		doDropUpload - Uploads a file to the server (Handles a form POST operation)

		Author: Doug Jones
		http://www.cjboco.com/

	------------------------------------------------------------------------ --->
	<cffunction name="doDropUpload" access="remote" output="true" returntype="none">

		<cfset var result = StructNew() />
		<cfset var locvar = StructNew() />
		<cfset var cj = StructNew() />
		<cfset var thread = "" />

		<cfset result.error = false />
		<cfset result.msg = "" />

		<cfif cgi.request_method eq "put" or cgi.request_method eq "post">

			<cftry>

				<cfset cj.nameArr = ListToArray(safeFileNameFull(CGI.HTTP_X_FILENAME), ".") />
				<cfset cj.paramsStr = CGI.HTTP_X_FILE_PARAMS />
				<cfset cj.maxAttempts = 99 />

				<!--- check the parameters --->
				<cfif Len(cj.paramsStr) eq 0 or NOT isJSON(cj.paramsStr)>

					<cfset result.error = true />
					<cfset result.msg = "Invalid file parameters." />

				<cfelse>

					<cfset cj.params = DeSerializeJSON(cj.paramsStr) />

					<!--- check the file name array --->
					<cfif NOT isArray(cj.nameArr) or ArrayLen(cj.nameArr) neq 2>

						<cfset result.error = true />
						<cfset result.msg = "File name missing extension. (#safeFileNameFull(CGI.HTTP_X_FILENAME)#)" />

					<cfelseif
						NOT StructKeyExists(cj.params, "baseRelPath") or
						NOT StructKeyExists(cj.params, "maxWidth") or
						NOT StructKeyExists(cj.params, "maxHeight") or
						NOT StructKeyExists(cj.params, "maxSize") or
						NOT StructKeyExists(cj.params, "fileExts") or
						NOT StructKeyExists(cj.params, "timeOut")>

						<cfset result.error = true />
						<cfset result.msg = "Could not complete upload. Required parameters missing." />

					<cfelse>

						<cfset cj.baseRelPath = URLDecode(cj.params.baseRelPath[ArrayLen(cj.params.baseRelPath)]) />

						<cfset cj.origFileName = cj.nameArr[1] />
						<cfset cj.fileName = cj.origFileName />
						<cfset cj.fileExt = cj.nameArr[2] />
						<cfset cj.attempts = 0 />


						<!--- check to see if they passed a timout value --->
						<cfif StructKeyExists(cj.params, "timeOut") and isNumeric(cj.params.timeOut) and cj.params.timeOut gt 0>
							<cfsetting requestTimeout="#cj.params.timeOut#" />
						</cfif>

						<!--- preload our security settings (since we have to read this in each time) --->
						<cfset locvar.authDirs = getSecuritySettings('directories') />
						<cfset locvar.authActions = getSecuritySettings('actions') />
						<cfset locvar.authExts = getSecuritySettings('fileExts') />


						<!--- validate "navigateDirectory" action and path --->
						<cfif (NOT isActionValid("navigateDirectory", locvar.authActions) and NOT isPathValid(cj.baseRelPath, true, locvar.authDirs)) or NOT isPathValid(cj.baseRelPath, false, locvar.authDirs)>

							<cfset result.error = true />
							<cfset result.msg = "Directory access denied." />

						<!--- validate action --->
						<cfelseif NOT isActionValid("fileUpload",locvar.authActions)>

							<cfset result.error = true />
							<cfset result.msg = "Not authorized to upload files." />

						<!--- validate that the "baseRelPath" exists --->
						<cfelseif NOT DirectoryExists(ExpandPath(cj.baseRelPath))>

							<cfset result.error = true />
							<cfset result.msg = "Directory does not exist." />

						<cfelseif isDefined("locvar.fileSize.size") and locvar.fileSize.size gt (cj.params.maxSize * 1024)>

							<cfset result.error = true />
							<cfset result.msg = "The file size of your upload excedes the allowable limit. Please upload a file smaller than #NumberFormat(cj.params.maxSize, '9,999')#KB.">

						<cfelse>

							<cfset result.msg = ArrayNew(1) />

							<!--- validate that we have the proper form fields --->
							<cfif NOT DirectoryExists(ExpandPath(cj.baseRelPath))>
								<cfset result.error = true />
								<cfset ArrayAppend(result.msg, "You must provide a valid UPLOAD DIRECTORY.<br /><small>(Could not find directory)</small>")>
							</cfif>
							<cfif Len(cj.baseRelPath) eq 0 or ReFind("[^a-zA-Z0-9\,\$\-\_\.\+\!\*\'\(\)\/]+", cj.baseRelPath) gt 0>
								<cfset result.error = true />
								<cfset ArrayAppend(result.msg, "Variable BASEURL not defined or invalid data.") />
							</cfif>
							<cfif cj.params.fileExts neq "*" and ReFind("[^a-zA-Z0-9\,]+", URLDecode(cj.params.fileExts)) gt 0>
								<cfset result.error = true />
								<cfset ArrayAppend(result.msg, "Variable FILEEXTS not defined or invalid data.") />
							<cfelse>
								<!--- remove any spaced between the list items ", " or " ," --->
								<cfset cj.params.fileExts = ReReplace(URLDecode(cj.params.fileExts), "[\s]*,[\s]*",",","ALL") />
							</cfif>
							<cfif NOT isNumeric(cj.params.maxSize) or (isNumeric(cj.params.maxSize) and (cj.params.maxSize lt 1 or cj.params.maxSize gt 9999999))>
								<cfset result.error = true />
								<cfset ArrayAppend(result.msg, "Variable MAXSIZE not defined or invalid data.") />
							</cfif>
							<cfif NOT isNumeric(cj.params.maxWidth) or (isNumeric(cj.params.maxWidth) and (cj.params.maxWidth lt 1 or cj.params.maxSize gt 9999999))>
								<cfset result.error = true />
								<cfset ArrayAppend(result.msg, "Variable MAXWIDTH not defined or invalid data.") />
							</cfif>
							<cfif NOT isNumeric(cj.params.maxHeight) or (isNumeric(cj.params.maxHeight) and (cj.params.maxHeight lt 1 or cj.params.maxHeight gt 9999999))>
								<cfset result.error = true />
								<cfset ArrayAppend(result.msg, "Variable MAXHEIGHT not defined or invalid data.") />
							</cfif>

							<cfif NOT result.error and ArrayLen(result.msg) eq 0>

								<cfloop condition="cj.attempts lte cj.maxAttempts">

									<cfset cj.attempts = cj.attempts + 1 />
									<cfset locvar.newFileName = cj.fileName & "." & cj.fileExt />
									<cfset cj.xhr = GetHttpRequestData() />

									<!--- upload the file --->
									<cffile action="write" file="#ExpandPath('#cj.baseRelPath##locvar.newFileName#')#" nameconflict="overwrite" output="#cj.xhr.content#" />
									<cfset sleep(25) >

									<cfset cj.fileInfo = GetFileInfo(ExpandPath('#cj.baseRelPath##locvar.newFileName#')) />

									<cfif cj.fileInfo.size gt (cj.params.maxSize * 1024)>

										<cfif FileExists(ExpandPath('#cj.baseRelPath##locvar.newFileName#'))>
											<cffile action="delete" file="#ExpandPath('#cj.baseRelPath##locvar.newFileName#')#" />
										</cfif>
										<cfset result.error = true />
										<cfset ArrayAppend(result.msg, "The file size of your upload excedes the allowable limit. Please upload a file smaller than #NumberFormat(cj.params.maxSize, '9,999')#KB.")>

									<cfelse>

										<cfif IsImageFile(ExpandPath('#cj.baseRelPath##locvar.newFileName#'))>

											<cfimage action="read" name="locvar.imgread" source="#ExpandPath('#cj.baseRelPath##locvar.newFileName#')#" />
											<cfset result.msg = StructNew() />
											<cfset result.msg.filename = locvar.newFileName />
											<cfset result.msg.origWidth = locvar.imgread["width"] />
											<cfset result.msg.origHeight = locvar.imgread["height"] />

											<!--- do we need to scale the image? --->
											<cfif (isNumeric(cj.params.maxWidth) and cj.params.maxWidth lt locvar.imgread["width"]) or (isNumeric(cj.params.maxHeight) and cj.params.maxHeight lt locvar.imgread["height"])>

												<!---
													resize the image if it's to big.
												—————————————————————————————————————————————————————————————————————————————————————— --->
												<cfset ImageSetAntialiasing(locvar.imgread, "on") />
												<cfset locvar.imgInfo = calcScaleInfo(locvar.imgread["width"], locvar.imgread["height"], cj.params.maxWidth, cj.params.maxHeight, 'fit') />
												<cfset ImageScaleToFit(locvar.imgread, locvar.imgInfo.width, locvar.imgInfo.height, "highestQuality", "0.8") />
												<cfimage action="write" source="#locvar.imgread#" destination="#ExpandPath('#cj.baseRelPath##locvar.newFileName#')#" overwrite="yes" />
												<cfset result.msg.scaleWidth = locvar.imgInfo.width />
												<cfset result.msg.scaleHeight = locvar.imgInfo.height />

											</cfif>

										</cfif>

									</cfif>

								</cfloop>

							</cfif>

						</cfif>

					</cfif>

				</cfif>

				<cfcatch type="any">

					<cfset result.error = true />
					<cfset result.msg = cfcatch />

				</cfcatch>

			</cftry>

		<cfelse>

			<cfset result.error = true />
			<cfset result.msg = "Invalid request method. (doDropUpload)" />

		</cfif>

		<cfcontent type="text/plain" reset="true"><cfoutput>#SerializeJSON(result)#</cfoutput><cfabort />

	</cffunction>


	<!--- ------------------------------------------------------------------------

		doDeleteFile - Deletes a given file from the server.

		Author: Doug Jones
		http://www.cjboco.com/

	------------------------------------------------------------------------ --->
	<cffunction name="doDeleteFile" access="remote" output="false" returntype="any">
		<cfargument name="baseRelPath" type="string" required="yes" />
		<cfargument name="fileName" type="string" required="yes" />
		<cfargument name="timeOut" type="numeric" required="no" default="900" />
		<cfset var locvar = StructNew() />
		<cfset var result = StructNew() />
		<cftry>

			<cfset locvar.baseRelPath = URLDecode(arguments.baseRelPath) />

			<!--- check to see if they passed a timout value --->
			<cfif isDefined("arguments.timeOut") and isNumeric(arguments.timeOut) and arguments.timeOut gt 0>
				<cfsetting requestTimeout="#arguments.timeOut#" />
			</cfif>

			<!--- preload our security settings (since we have to read this in each time) --->
			<cfset locvar.authDirs = getSecuritySettings('directories') />
			<cfset locvar.authActions = getSecuritySettings('actions') />

			<!--- validate "navigateDirectory" action and path --->
			<cfif (NOT isActionValid("navigateDirectory",locvar.authActions) and NOT isPathValid(locvar.baseRelPath, true, locvar.authDirs)) or NOT isPathValid(locvar.baseRelPath, false, locvar.authDirs)>

				<cfset result.error = true />
				<cfset result.msg = "Directory access denied." />

			<!--- validate action --->
			<cfelseif NOT isActionValid("fileDelete",locvar.authActions)>

				<cfset result.error = true />
				<cfset result.msg = "Not authorized to delete files." />

			<!--- validate that the "baseRelPath" exists --->
			<cfelseif NOT DirectoryExists(ExpandPath(locvar.baseRelPath))>

				<cfset result.error = true />
				<cfset result.msg = "Directory does not exist." />

			<cfelse>

				<cfif FileExists(ExpandPath("#locvar.baseRelPath##arguments.fileName#"))>
					<cffile action="delete" file="#ExpandPath("#locvar.baseRelPath##arguments.fileName#")#">
				</cfif>
				<cfset result.error = false />
				<cfset result.msg = "" />

			</cfif>
			<cfcatch type="any">
				<cfset result.error = true />
				<cfset result.msg = cfcatch.message />
			</cfcatch>
		</cftry>
		<cfreturn result />
	</cffunction>


	<!--- ------------------------------------------------------------------------

		doDeleteDirectory - Deletes a given directory and its contents from the server.
							This is a RECURSIVE function so it will delete
							everything inside the directory!

		Author: Doug Jones
		http://www.cjboco.com/

	------------------------------------------------------------------------ --->
	<cffunction name="doDeleteDirectory" access="remote" output="false" returntype="any">
		<cfargument name="baseRelPath" type="string" required="yes" />
		<cfargument name="dirName" type="string" required="yes" />
		<cfargument name="timeOut" type="numeric" required="no" default="900" />
		<cfset var locvar = StructNew() />
		<cfset var result = StructNew() />
		<cftry>

			<cfset locvar.baseRelPath = URLDecode(arguments.baseRelPath) />

			<!--- check to see if they passed a timout value --->
			<cfif isDefined("arguments.timeOut") and isNumeric(arguments.timeOut) and arguments.timeOut gt 0>
				<cfsetting requestTimeout="#arguments.timeOut#" />
			</cfif>

			<!--- preload our security settings (since we have to read this in each time) --->
			<cfset locvar.authDirs = getSecuritySettings('directories') />
			<cfset locvar.authActions = getSecuritySettings('actions') />

			<!--- validate "navigateDirectory" action and path --->
			<cfif (NOT isActionValid("navigateDirectory",locvar.authActions) and NOT isPathValid(locvar.baseRelPath, true, locvar.authDirs)) or NOT isPathValid(locvar.baseRelPath, false, locvar.authDirs)>

				<cfset result.error = true />
				<cfset result.msg = "Directory access denied." />

			<!--- validate action --->
			<cfelseif NOT isActionValid("deleteDirectory",locvar.authActions)>

				<cfset result.error = true />
				<cfset result.msg = "Deleting directories is not allowed." />

			<!--- validate that the "baseRelPath" exists --->
			<cfelseif NOT DirectoryExists(ExpandPath(locvar.baseRelPath))>

				<cfset result.error = true />
				<cfset result.msg = "Directory does not exist." />

			<!--- make sure it's not the root directory!! --->
			<cfelseif Len(URLDecode(arguments.dirName)) eq 0 or URLDecode(arguments.dirName) eq "/" or URLDecode(arguments.dirName) eq "\">

				<cfset result.error = true />
				<cfset result.msg = "You cannot delete the root directory." />

			<cfelse>

				<!--- do a recursive delete --->
				<cfset result.error = deleteDirectory(ExpandPath("#locvar.baseRelPath##arguments.dirName#"),true) />
				<cfif result.error eq true>
					<cfset result.msg = "" />
				<cfelse>
					<cfset result.msg = "There was a problem deleting the directory." />
				</cfif>

			</cfif>
			<cfcatch type="any">
				<cfset result.error = true />
				<cfset result.msg = cfcatch.message />
			</cfcatch>
		</cftry>
		<cfreturn result />
	</cffunction>


	<!--- ------------------------------------------------------------------------

		doCreateNewDirectory - Creates a new directory on the server.

		Author: Doug Jones
		http://www.cjboco.com/

	------------------------------------------------------------------------ --->
	<cffunction name="doCreateNewDirectory" access="remote" output="false" returntype="any">
		<cfargument name="baseRelPath" type="string" required="yes" />
		<cfargument name="dirName" type="string" required="yes" />
		<cfargument name="timeOut" type="numeric" required="no" default="900" />
		<cfset var locvar = StructNew() />
		<cfset var result = StructNew() />
		<cftry>

			<cfset locvar.baseRelPath = URLDecode(arguments.baseRelPath) />

			<!--- check to see if they passed a timout value --->
			<cfif isDefined("arguments.timeOut") and isNumeric(arguments.timeOut) and arguments.timeOut gt 0>
				<cfsetting requestTimeout="#arguments.timeOut#" />
			</cfif>

			<!--- preload our security settings (since we have to read this in each time) --->
			<cfset locvar.authDirs = getSecuritySettings('directories') />
			<cfset locvar.authActions = getSecuritySettings('actions') />

			<!--- validate "navigateDirectory" action and path --->
			<cfif (NOT isActionValid("navigateDirectory",locvar.authActions) and NOT isPathValid(locvar.baseRelPath, true, locvar.authDirs)) or NOT isPathValid(locvar.baseRelPath, false, locvar.authDirs)>

				<cfset result.error = true />
				<cfset result.msg = "Directory access denied." />

			<!--- validate action --->
			<cfelseif NOT isActionValid("createDirectory",locvar.authActions)>

				<cfset result.error = true />
				<cfset result.msg = "Creating directories is not allowed." />

			<!--- validate that the "baseRelPath" exists --->
			<cfelseif NOT DirectoryExists(ExpandPath(locvar.baseRelPath))>

				<cfset result.error = true />
				<cfset result.msg = "Directory does not exist." />

			<cfelse>

				<!--- make sure we don't have any funky characters in the name --->
				<cfif ReFindNoCase("[^a-zA-Z0-9_\-]",arguments.dirName) gt 0>
					<cfset result.error = true />
					<cfset result.msg = "Invalid characters detected in directory name. (Valid [a-zA-Z0-9_-])" />
				<cfelseif Len(arguments.dirName) lt 1 or Len(arguments.dirName) gt 64>
					<cfset result.error = true />
					<cfset result.msg = "Invalid directory name length. (Valid 1-64 characters)" />
				<cfelse>
					<!--- make sure the directory doesn't already exists --->
					<cfif NOT DirectoryExists(ExpandPath(URLDecode("#locvar.baseRelPath##arguments.dirName#")))>
						<cfdirectory action="create" directory="#ExpandPath(URLDecode('#locvar.baseRelPath##arguments.dirName#'))#" >
						<cfset result.error = false />
						<cfset result.msg = "" />
					<cfelse>
						<cfset result.error = true />
						<cfset result.msg = "Directory already exists." />
					</cfif>
				</cfif>

			</cfif>
			<cfcatch type="any">
				<cfset result.error = true />
				<cfset result.msg = cfcatch.message />
			</cfcatch>
		</cftry>
		<cfreturn result />
	</cffunction>







	<!--- UTILITY FUNCTION (Not called directly from CJ File Browser) --->

	<!--- ------------------------------------------------------------------------

		Method:
			calcScaleInfo - A simple function that will return the width, height
							and offset of scaled image thumbnail.

		Arguments:
			srcWidth	- $Numeric (required)
						  The width of the source image.

			srcHeight	- $Numeric (required)
						  The height of the source image.

			destWidth	- $Numeric (required)
						  The width of the destination image.

			destHeight	- $Numeric (required)
						  The height of the destination image.

			method		- $String (required)
						  The scaling method to use to calculate the thumbnail image dimensions.

		Return:
			STRUCT (JSON)

		** Do better understand what this function does, please visit my blog:
			http://www.cjboco.com/projects.cfm/project/cj-object-scaler/2.0.1
			http://www.cjboco.com/blog.cfm/post/easily-calculate-image-scaling

		Author: Doug Jones
		http://www.cjboco.com/

	------------------------------------------------------------------------ --->
	<cffunction name="calcScaleInfo" access="private" returntype="struct" output="false" hint="A simple function that will return the width, height and offset of scaled image thumbnail.">
		<cfargument name="srcWidth" type="numeric" required="yes" hint="The width of the source image." />
		<cfargument name="srcHeight" type="numeric" required="yes" hint="The height of the source image." />
		<cfargument name="destWidth" type="numeric" required="yes" hint="The width of the destination image." />
		<cfargument name="destHeight" type="numeric" required="yes" hint="The height of the destination image." />
		<cfargument name="method" type="string" required="no" default="fit" hint="The scaling method to use to calculate the thumbnail image dimensions." />
		<!--- Initialize our variables --->
		<cfset var err = "" />
		<cfset var scale = "" />
		<cfset var fits = false />
		<cfset var thumbInfo = StructNew() />
		<!--- Grab scale ratios --->
		<cfset var xscale = destWidth / srcWidth />
		<cfset var yscale = destHeight / srcHeight />
		<!--- Determine which scaling method is to be used --->
		<cfif method eq "fit">
			<cfset scale = Min(xscale, yscale) />
		<cfelseif method eq "fill">
			<cfset scale = Max(xscale, yscale) />
		</cfif>
		<!--- Determine if the destination is smaller or equal to the source image --->
		<cfif srcWidth gte destWidth and srcWidth gte destWidth>
			<cfset fits = true />
		</cfif>
		<!--- Set new dimensions --->
		<cfset err = StructInsert(thumbInfo, "width", Round(srcWidth * scale)) />
		<cfset err = StructInsert(thumbInfo, "height", Round(srcHeight * scale)) />
		<cfset err = StructInsert(thumbInfo, "offset", StructNew()) />
		<cfset err = StructInsert(thumbInfo.offset, "x", Round((destWidth - (srcWidth * scale)) / 2)) />
		<cfset err = StructInsert(thumbInfo.offset, "y", Round((destHeight - (srcHeight * scale)) / 2)) />
		<cfset err = StructInsert(thumbInfo, "fits", fits) />
		<!--- Return the information --->
		<cfreturn thumbInfo />
	</cffunction>


	<!--- ------------------------------------------------------------------------

		Method:
			safeFileName - 	Searches a string for illegal filename characters,
							strips them and then returns the modified string.

		Arguments:
			input   - $String (required)
						A filename that may require stripping of invalid characters.
						Example: my Fi&<lename.jpg

		Return:
			STRING

		Example:
			"my Fi&<lename.jpg" => "my_Fi_lename.jpg"

		Author: Doug Jones
		http://www.cjboco.com/

	------------------------------------------------------------------------ --->
	<cffunction name="safeFileName" access="private" returntype="string" output="no" hint="Searches a string for illegal filename characters, strips them and then returns the modified string.">
		<cfargument name="input" type="string" required="yes" />
		<cfset var output = arguments.input />
		<cfif Len(input) eq 0>
			<cfreturn "" />
		</cfif>
		<cfset output = REReplaceNoCase(output,'[^a-zA-Z0-9_]+','_','ALL')>
		<cfset output = REReplaceNoCase(output,'__','_','ALL')>
		<cfreturn LCase(output) />
	</cffunction>


	<!--- -----------------------------------------------------------------------------------
	RECURSIVELY DELETE A DIRECTORY.
	Author: Rick Root (rick@webworksllc.com)
		@param directory 	 The directory to delete. (Required)
		@param recurse 	 Whether or not the UDF should recurse. Defaults to false. (Optional)
		@return Return a boolean false = no-errors; true = error (DSJ 2010)
		@version 1, July 28, 2005
	----------------------------------------------------------------------------------- --->
	<cffunction name="deleteDirectory" access="private" returntype="any" output="false">
		<cfargument name="directory" type="string" required="yes" />
		<cfargument name="recurse" type="boolean" required="no" default="false" />
		<cfset var myDirectory = "" />
		<cfset var count = 0 />
		<cftry>
			<cfif Right(arguments.directory, 1) is not "\" AND Right(arguments.directory, 1) is not "/">
				<cfif Find("\",arguments.directory) gt 0>
					<cfset arguments.directory = arguments.directory & "\" />
				<cfelse>
					<cfset arguments.directory = arguments.directory & "/" />
				</cfif>
			</cfif>
			<cfdirectory action="list" directory="#arguments.directory#" name="myDirectory">
			<cfloop query="myDirectory">
				<cfif myDirectory.name is not "." AND myDirectory.name is not "..">
					<cfset count = count + 1>
					<cfswitch expression="#myDirectory.type#">
						<cfcase value="dir">
							<!--- If recurse is on, move down to next level --->
							<cfif arguments.recurse>
								<cfset deleteDirectory(arguments.directory & myDirectory.name, arguments.recurse) />
							</cfif>
						</cfcase>
						<cfcase value="file">
							<!--- delete file --->
							<cfif arguments.recurse>
								<cffile action="delete" file="#arguments.directory##myDirectory.name#" />
							</cfif>
						</cfcase>
					</cfswitch>
				</cfif>
			</cfloop>
			<cfif count is 0 or arguments.recurse>
				<cfdirectory action="delete" directory="#arguments.directory#" />
			</cfif>
			<cfreturn false />
			<cfcatch type="any">
				<cfreturn true />
			</cfcatch>
		</cftry>
	</cffunction>


	<!--- –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	SEARCHES A STRING FOR COMMON WORDS AND ILLEGAL FILENAME CHARACTERS AND STRIPS AND RETURNS IT.
	Author: Doug Jones
	http://www.cjboco.com/
	––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– --->
	<cffunction name="safeFileNameFull" returntype="string" output="yes" hint="Searches a string for common words and illegal filename characters and strips and returns it.">
		<cfargument name="input" type="string" required="yes" />
			<cfset var locvar = StructNew() />
			<cfset locvar.output = "" />
			<cftry>
				<cfif Len(arguments.input) gt 0>
					<cfset locvar.pos = ReFind("\.([^\.]+)$", arguments.input) />
					<cfif locvar.pos lte 0>
						<!--- there is no file extension --->
						<cfset locvar.name = LCase(arguments.input) />
						<cfset locvar.ext = "" />
					<cfelse>
						<cfif locvar.pos gt 1>
							<cfset locvar.name = LCase(Left(arguments.input, locvar.pos - 1)) />
						<cfelse>
							<!--- no name, just an extension? --->
							<cfset locvar.name = "" />
						</cfif>
						<cfif locvar.pos lt Len(arguments.input)>
							<cfset locvar.ext = LCase(Mid(arguments.input, locvar.pos + 1, Len(arguments.input))) />
						<cfelse>
							<!--- no extension, just an name? --->
							<cfset locvar.ext = "" />
						</cfif>
					</cfif>
					<cfset locvar.output = REReplaceNoCase(locvar.name, '[^a-zA-Z0-9_\-]+', '_', 'ALL') />
					<cfset locvar.output = REReplaceNoCase(locvar.output, '[_]+', '_', 'ALL') />
					<cfset locvar.output = REReplaceNoCase(locvar.output, '\b((and)|(or)|(at))\b', '', 'ALL') />
					<cfif Len(locvar.output) gt 0 and Len(locvar.ext) gt 0>
						<cfset locvar.output = locvar.output & "." & locvar.ext />
					<cfelseif Len(locvar.output) gt 0>
						<cfset locvar.output = locvar.output />
					<cfelseif Len(locvar.ext) gt 0>
						<cfset locvar.output = locvar.ext />
					</cfif>
				</cfif>
			<cfcatch type="any">
				<cfdump var="#cfcatch#" />
				<cfabort >
			</cfcatch>
			</cftry>
			<cfreturn locvar.output />
	</cffunction>

</cfcomponent>
