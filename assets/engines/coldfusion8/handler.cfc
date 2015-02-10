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

	<cffunction name="init" access="remote" returntype="any" output="no">
		<cfreturn this />
	</cffunction>


	<!--- ------------------------------------------------------------------------

		getPathToDirectory - A quick and dirty way to get the path
							to the cjFileBrowser folder. This path
							can be different depending if it's accessed
							via AJAX or directly.

		Author: Doug Jones
		http://www.cjboco.com/

	------------------------------------------------------------------------ --->
	<cffunction name="getPathToDirectory" access="private" returntype="string" output="no">
		<cfset var result = StructNew() />
		<cfset locvar['exp2'] = GetDirectoryFromPath(GetCurrentTemplatePath()) />
		<cfset locvar['exp2'] = Replace(locvar.exp2, "\", "/", "ALL") />
		<cfreturn ReplaceNoCase(locvar.exp2, "assets/engines/coldfusion8/", "", "ALL") />
	</cffunction>


	<!--- ------------------------------------------------------------------------

		isHandlerReady - Informs CJ File Browser that the handler exists
						 and also check to make sure the security file
						 file is present and appears to be valid.

		Author: Doug Jones
		http://www.cjboco.com/

	------------------------------------------------------------------------ --->
	<cffunction name="isHandlerReady" access="remote" returntype="any" output="true">
		<cfargument name="version" type="string" required="yes" />
		<cfargument name="dirPath" type="string" required="no" default="" />
		<cfargument name="timeOut" type="numeric" required="no" default="900" />
		<cfset var locvar = StructNew() />
		<cfset var result = StructNew() />
		<cfset result['error'] = false />
		<cfset result['msg'] = ArrayNew(1) />
		<cftry>

			<cfif Len(arguments.version) gt 0>

				<!--- check to see if they passed a timout value --->
				<cfif isDefined("arguments.timeOut") and isNumeric(arguments.timeOut) and arguments.timeOut gt 0>
					<cfsetting requestTimeout="#arguments.timeOut#" />
				</cfif>

				<!--- check security file version --->
				<cfset locvar['version'] = getSecuritySettings('version') />
				<cfif isStruct(locvar.version) and isDefined("locvar.version.error") and NOT locvar.version.error>
					<cfif isDefined("locvar.version.version") and locvar.version.version eq arguments.version>
						<!--- everything ok --->
					<cfelse>
						<cfset result['error'] = true />
						<cfset ArrayAppend(result.msg, "Security file version does not match the CJ File Browser version.") />
					</cfif>
				<cfelse>
					<cfset result['error'] = true />
					<cfif isDefined("locvar.version.error_msg")>
						<cfset ArrayAppend(result.msg, locvar.version.error_msg) />
					<cfelse>
						<cfset ArrayAppend(result.msg, "Problems checking security file version. (#locvar.version.msg#)") />
					</cfif>
				</cfif>

				<!--- check security file directories (and validate inital path) --->
				<cfset locvar['validatePath'] = getSecuritySettings('directories') />
				<cfif isStruct(locvar.validatePath) and isDefined("locvar.validatePath.error") and NOT locvar.validatePath.error>
					<!--- everything checks out, now validate the directory path (if provided) --->
					<cfif Len(URLDecode(arguments.dirPath)) gt 0>
						<cfset locvar['path'] = isPathValid(URLDecode(arguments.dirPath)) />
						<cfif NOT locvar.path>
							<cfset result['error'] = true />
							<cfif isDefined("locvar.version.error_msg")>
								<cfset ArrayAppend(result.msg, locvar.version.error_msg) />
							<cfelse>
								<cfset ArrayAppend(result.msg, "Invalid path (#URLDecode(arguments.dirPath)#).") />
							</cfif>
						</cfif>
					</cfif>
				<cfelse>
					<cfset result['error'] = true />
					<cfif isDefined("locvar.version.error_msg")>
						<cfset ArrayAppend(result.msg, locvar.version.error_msg) />
					<cfelse>
						<cfset ArrayAppend(result.msg, "Problems checking security file authorized directories.") />
					</cfif>
				</cfif>

				<!--- check security file actions --->
				<cfset locvar['validateAction'] = getSecuritySettings('actions') />
				<cfif isStruct(locvar.validateAction) and isDefined("locvar.validateAction.error") and NOT locvar.validateAction.error>
					<!--- everything checks out --->
				<cfelse>
					<cfset result['error'] = true />
					<cfif isDefined("locvar.version.error_msg")>
						<cfset ArrayAppend(result.msg, locvar.version.error_msg) />
					<cfelse>
						<cfset ArrayAppend(result.msg, "Problems checking security file authorized actions.") />
					</cfif>
				</cfif>

				<!--- check security file extensions --->
				<cfset locvar['isFileExtValid'] = getSecuritySettings('fileExts') />
				<cfif isStruct(locvar.isFileExtValid) and isDefined("locvar.isFileExtValid.error") and NOT locvar.isFileExtValid.error>
					<!--- everything checks out --->
				<cfelse>
					<cfset result['error'] = true />
					<cfif isDefined("locvar.version.error_msg")>
						<cfset ArrayAppend(result.msg, locvar.version.error_msg) />
					<cfelse>
						<cfset ArrayAppend(result.msg, "Problems checking security file authorized file extensions.") />
					</cfif>
				</cfif>

			<!--- we weren't passed the version --->
			<cfelse>

				<cfset result['error'] = true />
				<cfset ArrayAppend(result.msg, "Version information not provided.") />

			</cfif>
			<cfcatch type="any">
				<cfset result['error'] = true />
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
	<cffunction name="isPathValid" access="remote" returntype="boolean" output="no" hint="Validates that the given relative path is allowed within the security settings.">
		<cfargument name="baseRelPath" type="string" required="yes" />
		<cfargument name="exact" type="boolean" required="no" default="false" />
		<cfargument name="settings" type="any" required="no" default="" />
		<cfset var locvar = StructNew() />
		<cftry>
			<cfset locvar['baseRelPath'] = URLDecode(arguments.baseRelPath) />
			<cfif Len(locvar.baseRelPath) gt 0>
				<!--- to save time on disk reads, we can pass the directory list --->
				<cfif isStruct(arguments.settings) and isDefined("arguments.settings.error") and NOT arguments.settings.error and isDefined("arguments.settings.dirListRel") and ListLen(arguments.settings.dirListRel) gt 0>
					<cfset locvar['authDirs'] = arguments.settings />
				<cfelse>
					<cfset locvar['authDirs'] = getSecuritySettings('directories') />
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
	<cffunction name="isActionValid" access="remote" returntype="boolean" output="no" hint="Validates that the given action is allowed within the security settings.">
		<cfargument name="userAction" type="string" required="yes" />
		<cfargument name="settings" type="any" required="no" default="" />
		<cfset var locvar = StructNew() />
		<cftry>
			<cfif Len(arguments.userAction) gt 0>
				<!--- to save time on disk reads, we can pass the directory list --->
				<cfif isStruct(arguments.settings) and isDefined("arguments.settings.error") and NOT arguments.settings.error and isDefined("arguments.settings.actionList") and ListLen(arguments.settings.actionList) gt 0>
					<cfset locvar['authActions'] = arguments.settings />
				<cfelse>
					<cfset locvar['authActions'] = getSecuritySettings('actions') />
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
	<cffunction name="isFileExtValid" access="remote" returntype="boolean" output="no" hint="Validates that the given file extension is allowed within the security settings.">
		<cfargument name="fileExt" type="string" required="yes" />
		<cfargument name="settings" type="any" required="no" default="" />
		<cfset var locvar = StructNew() />
		<cftry>
			<cfif Len(arguments.fileExt) gt 0>
				<!--- to save time on disk reads, we can pass the directory list --->
				<cfif isStruct(arguments.settings) and isDefined("arguments.settings.error") and NOT arguments.settings.error and isDefined("arguments.settings.extList") and ListLen(arguments.settings.extList) gt 0>
					<cfset locvar['authExts'] = arguments.settings />
				<cfelse>
					<cfset locvar['authExts'] = getSecuritySettings('fileExts') />
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

		getSecuritySettings	- Reads the cjFileBrowser security file and
							  returns no error with a comma seperated list of valid
							  directories that can be modified or an error
							  with the error message

		Author: Doug Jones
		http://www.cjboco.com/

	------------------------------------------------------------------------ --->
	<cffunction name="getSecuritySettings" access="remote" returntype="any" output="no" hint="Reads the cjFileBrowser security file and returns a comma seperated list of valid  directories that can be modified.">
		<cfargument name="settingType" type="string" required="yes" />
		<cfset var locvar = StructNew() />
		<cfset var result = StructNew() />
		<cfset result['error'] = false />
		<cfset result['msg'] = "" />
		<cftry>

			<!--- we need to grab the path to this directory --->
			<cfset locvar['baseAbsPath'] = getPathToDirectory() />
			<cfif Right(locvar.baseAbsPath, 1) neq "/">
				<cfset locvar['baseAbsPath'] = locvar.baseAbsPath & "/" />
			</cfif>

			<!--- called from assets/engines/ENGINE folder
			<cfif FileExists("#locvar.baseAbsPath#security.cfm")>
				<cffile action="read" file="#locvar.baseAbsPath#security.cfm" variable="locvar.xml">
			<cfelseif FileExists("#locvar.baseAbsPath#security.php")>
				<cffile action="read" file="#locvar.baseAbsPath#security.php" variable="locvar.xml">
			<cfelse>
				<cffile action="read" file="#locvar.baseAbsPath#security.xml" variable="locvar.xml">
			</cfif> --->

			<cffile action="read" file="#locvar.baseAbsPath#security.xml" variable="locvar.xml">

			<cfif isDefined('locvar.xml') and Len(locvar.xml) gt 0>
				<cfset locvar['xml'] = XMLParse(locvar.xml) />
				<cfif isXml(locvar.xml)>

					<!--- security paths --->
					<cfif arguments.settingType eq "directories">

						<cfset locvar['xmlSettings'] = XMLSearch(locvar.xml,"cjFileBrowser/directoriesAllowed/directory") />

						<cfif ArrayLen(locvar.xmlSettings) gt 0>
							<cfset locvar['dirListAbs'] = "" />
							<cfset locvar['dirListRel'] = "" />
							<cfloop index="locvar.cnt" from="1" to="#ArrayLen(locvar.xmlSettings)#">
								<cfset locvar['attr'] = locvar.xmlSettings[locvar.cnt].XmlAttributes.type />
								<cfif locvar.attr eq "absolute">
									<cfif Len(locvar.xmlSettings[locvar.cnt].XmlText) gt 0>
										<cfset locvar['dirListAbs'] = ListAppend(locvar.dirListAbs, locvar.xmlSettings[locvar.cnt].XmlText) />
									</cfif>
								<cfelseif locvar.attr eq "relative">
									<cfif Len(locvar.xmlSettings[locvar.cnt].XmlText) gt 0>
										<cfset locvar['dirListRel'] = ListAppend(locvar.dirListRel, locvar.xmlSettings[locvar.cnt].XmlText) />
									</cfif>
								</cfif>
							</cfloop>
							<!--- they may have provided blank entries, this is not allowed --->
							<cfif ListLen(locvar.dirListRel) gt 0>
								<cfset result['error'] = false />
								<cfset result['dirListRel'] = locvar.dirListRel />
							<cfelse>
								<cfset result['error'] = true />
								<cfset result['msg'] = "There are no authorized directories set in the security file. (Cannot be blank)" />
							</cfif>
						<cfelse>
							<cfset result['error'] = true />
							<cfset result['msg'] = "There are no authorized directories set in the security file. (Cannot be blank)" />
						</cfif>

					<!--- security actions --->
					<cfelseif arguments.settingType eq "actions">

						<cfset locvar['xmlSettings'] = XMLSearch(locvar.xml,"cjFileBrowser/actionsAllowed/action") />
						<cfif ArrayLen(locvar.xmlSettings) gt 0>
							<cfset locvar['actionList'] = "" />
							<cfloop index="locvar.cnt" from="1" to="#ArrayLen(locvar.xmlSettings)#">
								<cfif Len(locvar.xmlSettings[locvar.cnt].XmlText) gt 0>
									<cfset locvar['actionList'] = ListAppend(locvar.actionList, locvar.xmlSettings[locvar.cnt].XmlText) />
								</cfif>
							</cfloop>
							<!--- they may have provided blank entries, this is not allowed --->
							<cfif ListLen(locvar.actionList) gt 0>
								<cfset result['error'] = false />
								<cfset result['actionList'] = locvar.actionList />
							<cfelse>
								<cfset result['error'] = true />
								<cfset result['msg'] = "There are no authorized actions set in the security file. (No settings will not allow any action)" />
							</cfif>
						<cfelse>
							<cfset result['error'] = true />
							<cfset result['msg'] = "There are no authorized actions set in the security file. (No settings will not allow any action)" />
						</cfif>


					<!--- security file extensions --->
					<cfelseif arguments.settingType eq "fileExts">

						<cfset locvar['xmlSettings'] = XMLSearch(locvar.xml,"cjFileBrowser/fileExtsAllowed/fileExt") />
						<cfif ArrayLen(locvar.xmlSettings) gt 0>
							<cfset locvar['extList'] = "" />
							<cfloop index="locvar.cnt" from="1" to="#ArrayLen(locvar.xmlSettings)#">
								<cfif Len(locvar.xmlSettings[locvar.cnt].XmlText) gt 0>
									<cfset locvar['extList'] = ListAppend(locvar.extList, Trim(locvar.xmlSettings[locvar.cnt].XmlText)) />
								</cfif>
							</cfloop>
							<!--- remove any spaced between the list items ", " or " ," --->
							<cfset locvar['extList'] = ReReplace(locvar.extList, "[\s]*,[\s]*",",","ALL") />
							<cfif ListLen(locvar.extList) gt 0>
								<cfset result['error'] = false />
								<cfset result['extList'] = locvar.extList />
							<cfelse>
								<cfset result['error'] = true />
								<cfset result['msg'] = "There are no authorized file extensions set in the security file. (Cannot be blank)" />
							</cfif>
						<cfelse>
							<cfset result['error'] = true />
							<cfset result['msg'] = "There are no authorized file extensions set in the security file. (Cannot be blank)" />
						</cfif>

					<!--- security file extensions --->
					<cfelseif arguments.settingType eq "version">

						<cfset result['error'] = false />
						<cfset result['version'] = locvar.xml.cjFileBrowser.XmlAttributes.version />

					<!--- unnknown security parameter --->
					<cfelse>

						<cfset result['error'] = true />
						<cfset result['msg'] = "Unknown security parameter check." />

					</cfif>

				<!--- not XML --->
				<cfelse>

					<cfset result['error'] = true />
					<cfset result['msg'] = "Problems reading in the security settings." />

				</cfif>

			<cfelse>

				<cfset result['error'] = true />
				<cfset result['msg'] = "Security file could not be found." />

			</cfif>
			<cfcatch type="any">
				<cfset result['error'] = true />
				<cfset result['msg'] = cfcatch />
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

			<cfset locvar['baseRelPath'] = URLDecode(arguments.baseRelPath) />

			<!--- check to see if they passed a timout value --->
			<cfif isDefined("arguments.timeOut") and isNumeric(arguments.timeOut) and arguments.timeOut gt 0>
				<cfsetting requestTimeout="#arguments.timeOut#" />
			</cfif>

			<!--- preload our security settings (since we have to read this in each time) --->
			<cfset locvar['authDirs'] = getSecuritySettings('directories') />
			<cfset locvar['authActions'] = getSecuritySettings('actions') />
			<cfset locvar['authExts'] = getSecuritySettings('fileExts') />

			<!--- validate "navigateDirectory" action and path --->
			<cfif NOT isPathValid(locvar.baseRelPath, false, locvar.authDirs)>

				<cfset result['error'] = true />
				<cfset result['msg'] = "Directory access denied." />

			<!--- validate that the "baseRelPath" exists --->
			<cfelseif NOT DirectoryExists(ExpandPath(locvar.baseRelPath))>

				<cfset result['error'] = true />
				<cfset result['msg'] = "Directory does not exist." />

			<cfelse>

				<cfset result['error'] = false />
				<cfset result['msg'] = "" />
				<cfset locvar['absBaseUrl'] = ExpandPath(locvar.baseRelPath) />
				<cfset locvar['dir'] = ArrayNew(1) />

				<!--- read the directory and return contents--->
				<cfif DirectoryExists(locvar.absBaseUrl)>
					<cfdirectory action="list" directory="#locvar.absBaseUrl#" name="locvar.qry" sort="name" />
					<cfif locvar.qry.recordCount gt 0>
						<cfset locvar.idx = 1 />
						<cfloop query="locvar.qry">
							<cfif (arguments.showInv or (NOT arguments.showInv and Left(locvar.qry.name,1) neq "."))>
								<cfif locvar.qry.type eq "file" and Find(".",locvar.qry.name) gt 1>
									<cfset locvar['ext'] = LCase(ListLast(locvar.qry.name,'.')) />
								<cfelse>
									<cfset locvar['ext'] = "" />
								</cfif>
								<!--- remove any spaced between the list items ", " or " ," --->
								<cfset locvar['fileExts'] = ReReplace(URLDecode(arguments.fileExts), "[\s]*,[\s]*",",","ALL") />
								<cfif locvar.fileExts eq "*" or locvar.qry.type eq "Dir" or (locvar.fileExts neq "*" and ListFindNoCase(locvar.fileExts, locvar.ext) gt 0)>
									<cfif isFileExtValid(locvar.ext,locvar.authExts) or (locvar.qry.type eq "Dir" and isActionValid('navigateDirectory',locvar.authActions))>
										<cfset locvar.temp = StructNew() />
										<cfset locvar.temp['name'] = HTMLEditFormat(locvar.qry.name) />
										<cfset locvar.temp['size'] = locvar.qry.size />
										<cfset locvar.temp['type'] = UCase(locvar.qry.type) />
										<cfif isDate(locvar.qry.dateLastModified)>
											<cfset locvar.temp['date'] = DateFormat(locvar.qry.dateLastModified,"mmmm d, yyyy") & " " & TimeFormat(locvar.qry.dateLastModified,"hh:mm:ss") />
										<cfelse>
											<cfset locvar.temp['date'] = "" />
										</cfif>
										<cfset locvar.temp['attr'] = locvar.qry.attributes />
										<cfset locvar.temp['dir'] = locvar.baseRelPath />
										<cfset locvar.temp['ext'] = UCase(locvar.ext) />
										<cfif locvar.qry.type eq "file">
											<cfset locvar.temp['mime'] = getPageContext().getServletContext().getMimeType(locvar.qry.name) />
											<cfif NOT StructKeyExists(locvar.temp, "mime") or NOT isSimpleValue(locvar.temp.mime)>
												<cfset locvar.temp['mime'] = "" />
											</cfif>
										<cfelse>
											<cfset locvar.temp['mime'] = "" />
										</cfif>
										<cfset locvar.temp['fullpath'] = locvar.absBaseUrl & locvar.qry.name />
										<!--- is this an image file? we can pass dimensions if it is --->
										<cfif ListFindNoCase(variables.webImgFileList, locvar.ext) gt 0>
											<cfimage action="read" name="locvar.img_input" source="#locvar.temp['fullpath']#" />
											<cfset locvar.temp['width'] = locvar.img_input["width"] />
											<cfset locvar.temp['height'] = locvar.img_input["height"] />
										<cfelse>
											<cfset locvar.temp['width'] = "" />
											<cfset locvar.temp['height'] = "" />
										</cfif>
										<cfset ArrayAppend(locvar.dir, locvar.temp) />
									</cfif>
								</cfif>
							</cfif>
						</cfloop>
					</cfif>
					<cfset result['dirlisting'] = locvar.dir />

				<cfelse>

					<!--- if no contents, then return an empty array --->
					<cfset result['dirlisting'] = ArrayNew(1) />

				</cfif>

			</cfif>
			<cfcatch type="any">
				<cfset result['error'] = true />
				<cfset result['msg'] = cfcatch.message />
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

			<cfset locvar['baseRelPath'] = URLDecode(arguments.baseRelPath) />

			<!--- check to see if they passed a timout value --->
			<cfif isDefined("arguments.timeOut") and isNumeric(arguments.timeOut) and arguments.timeOut gt 0>
				<cfsetting requestTimeout="#arguments.timeOut#" />
			</cfif>

			<!--- preload our security settings (since we have to read this in each time) --->
			<cfset locvar['authDirs'] = getSecuritySettings('directories') />
			<cfset locvar['authActions'] = getSecuritySettings('actions') />

			<!--- validate "navigateDirectory" action and path --->
			<cfif NOT isPathValid(locvar.baseRelPath, false, locvar.authDirs)>

				<cfset result['error'] = true />
				<cfset result['msg'] = "Directory access denied." />

			<!--- validate action --->
			<cfelseif NOT isActionValid("filePreviews",locvar.authActions)>

				<cfset result['error'] = true />
				<cfset result['msg'] = 'Image previews are not allowed.' />

			<!--- validate that the "baseRelPath" exists --->
			<cfelseif NOT DirectoryExists(ExpandPath(locvar.baseRelPath))>

				<cfset result['error'] = true />
				<cfset result['msg'] = "Directory does not exist." />

			<cfelse>

				<cfset locvar['absFilePath'] = ExpandPath(locvar.baseRelPath & arguments.fileName) />
				<cfset result['error'] = false />
				<cfset result['msg'] = "" />
				<cfset result['elemID'] = arguments.elemID />
				<cfset result['imgStr'] = "" />
				<cfif FileExists(locvar.absFilePath)>
					<cfimage action="read" name="locvar.img_input" source="#locvar.absFilePath#" />
					<cfif locvar.img_input["width"] gt variables.thumb_width or locvar.img_input["height"] gt variables.thumb_height>
						<cfset locvar['imgInfo'] 				= calcScaleInfo(locvar.img_input["width"], locvar.img_input["height"], variables.thumb_width, variables.thumb_height, "fit")>
						<cfset result['imgStr'] 				= '<img src="#locvar.baseRelPath##arguments.fileName#" border="0" width="#locvar.imgInfo.width#" height="#locvar.imgInfo.height#" style="margin-top:#locvar.imgInfo.offset.y#px;margin-left:#locvar.imgInfo.offset.x#px;" />' />
					<cfelse>
						<cfset locvar['imgInfo'] 				= StructNew() />
						<cfset locvar.imgInfo['offset'] 		= StructNew() />
						<cfset locvar.imgInfo.offset['x'] 		= Int((variables.thumb_width / 2) - (locvar.img_input["width"] / 2)) />
						<cfset locvar.imgInfo.offset['y'] 		= Int((variables.thumb_height / 2) - (locvar.img_input["height"] / 2)) />
						<cfset result['imgStr'] 				= '<img src="#locvar.baseRelPath##arguments.fileName#" border="0" width="#locvar.img_input["width"]#" height="#locvar.img_input["height"]#" style="margin-top:#locvar.imgInfo.offset.y#px;margin-left:#locvar.imgInfo.offset.x#px;" />' />
					</cfif>
				<cfelse>
					<cfset result['error'] = true />
					<cfset result['msg'] = "Problems reading image thumbnail. Invalid path. (#locvar.absFilePath#)" />
				</cfif>

			</cfif>
			<cfcatch type="any">

				<cfset result['error'] = true />
				<cfset result['msg'] = "Problems reading image thumbnail. (#cfcatch.message#)" />

			</cfcatch>
		</cftry>
		<cfreturn result />
	</cffunction>


	<!--- ------------------------------------------------------------------------

		doFileUpload - Uploads a file to the server (Handles a form POST operation)

		Author: Doug Jones
		http://www.cjboco.com/

	------------------------------------------------------------------------ --->
	<cffunction name="doFileUpload" access="remote" output="true" returntype="any">
		<cfset var locvar = StructNew() />
		<cfset var result = StructNew() />
		<cfset result['error'] = false />
		<cfset result['msg'] = ArrayNew(1) />
		<cftry>

			<!--- make sure this is a post operation --->
			<cfif cgi.request_method neq "post">

				<cfset result['error'] = true />
				<cfset result['msg'] = "HTTP request method not allowed." />

			<!--- double check we have all our variables --->
			<cfelseif
				NOT StructKeyExists(arguments,"baseUrl") or
				NOT StructKeyExists(arguments,"maxWidth") or
				NOT StructKeyExists(arguments,"maxHeight") or
				NOT StructKeyExists(arguments,"maxSize") or
				NOT StructKeyExists(arguments,"fileExts") or
				NOT StructKeyExists(arguments,"fileUploadField") or
				NOT StructKeyExists(arguments,"timeOut")>

				<cfset result['error'] = true />
				<cfset result['msg'] = "Could not complete upload. Required form variables missing." />

			<cfelse>

				<cfset locvar['baseUrl'] = URLDecode(arguments.baseUrl) />
				<cfset locvar['fileExts'] = URLDecode(arguments.fileExts) />

				<!--- check to see if they passed a timout value --->
				<cfif StructKeyExists(arguments, "timeOut") and isNumeric(arguments.timeOut) and arguments.timeOut gt 0>
					<cfsetting requestTimeout="#arguments.timeOut#" />
				</cfif>

				<!--- preload our security settings (since we have to read this in each time) --->
				<cfset locvar['authDirs'] = getSecuritySettings('directories') />
				<cfset locvar['authActions'] = getSecuritySettings('actions') />
				<cfset locvar['authExts'] = getSecuritySettings('fileExts') />
				<!---
					We can check the file size in the temp folder! Thanks Dave (aka Mister Dai)
					http://misterdai.wordpress.com/2010/02/26/upload-size-before-cffile-upload/
				--->
				<cfset locvar['fileSize'] = GetFileInfo(GetTempDirectory() & GetFileFromPath(arguments.fileUploadField)) />

				<!--- validate "navigateDirectory" action and path --->
				<cfif NOT isPathValid(locvar.baseUrl,false,locvar.authDirs)>

					<cfset result['error'] = true />
					<cfset result['msg'] = "Directory access denied." />

				<!--- validate action --->
				<cfelseif NOT isActionValid("fileUpload",locvar.authActions)>

					<cfset result['error'] = true />
					<cfset result['msg'] = "Not authorized to upload files." />

				<!--- validate that the "baseUrl" exists --->
				<cfelseif NOT DirectoryExists(ExpandPath(locvar.baseUrl))>

					<cfset result['error'] = true />
					<cfset result['msg'] = "Directory does not exist." />

				<cfelseif isDefined("locvar.fileSize.size") and locvar.fileSize.size gt (arguments.maxSize * 1024)>

					<cfset result['error'] = true />
					<cfset ArrayAppend(result.msg, "The file size of your upload excedes the allowable limit. Please upload a file smaller than #NumberFormat(arguments.maxSize,'9,999')#KB.")>

				<cfelse>

					<!--- validate that we have the proper form fields --->
					<cfif NOT DirectoryExists(ExpandPath(locvar.baseUrl))>
						<cfset result['error'] = true />
						<cfset ArrayAppend(result.msg, "You must provide a valid UPLOAD DIRECTORY.<br /><small>(Could not find directory)</small>")>
					</cfif>
					<cfif NOT isDefined("arguments.baseUrl") or (isDefined("arguments.baseUrl") and (Len(arguments.baseUrl) eq 0 or ReFind("[^a-zA-Z0-9\,\$\-\_\.\+\!\*\'\(\)\/]+",locvar.baseUrl) gt 0))>
						<cfset result['error'] = true />
						<cfset ArrayAppend(result.msg, "Variable BASEURL not defined or invalid data.") />
					</cfif>
					<cfif NOT isDefined("locvar.fileExts") or (isDefined("locvar.fileExts") and locvar.fileExts neq "*" and ReFind("[^a-zA-Z0-9\,]+", locvar.fileExts) gt 0)>
						<cfset result['error'] = true />
						<cfset ArrayAppend(result.msg, "Variable FILEEXTS not defined or invalid data.") />
					<cfelse>
						<!--- remove any spaced between the list items ", " or " ," --->
						<cfset locvar['fileExts'] = ReReplace(locvar.fileExts, "[\s]*,[\s]*",",","ALL") />
					</cfif>
					<cfif NOT isNumeric(arguments.maxSize) or (isNumeric(arguments.maxSize) and (arguments.maxSize lt 1 or arguments.maxSize gt 9999999))>
						<cfset result['error'] = true />
						<cfset ArrayAppend(result.msg, "Variable MAXSIZE not defined or invalid data.") />
					</cfif>
					<cfif NOT isNumeric(arguments.maxWidth) or (isNumeric(arguments.maxWidth) and (arguments.maxWidth lt 1 or arguments.maxSize gt 9999999))>
						<cfset result['error'] = true />
						<cfset ArrayAppend(result.msg, "Variable MAXWIDTH not defined or invalid data.") />
					</cfif>
					<cfif NOT isNumeric(arguments.maxHeight) or (isNumeric(arguments.maxHeight) and (arguments.maxHeight lt 1 or arguments.maxHeight gt 9999999))>
						<cfset result['error'] = true />
						<cfset ArrayAppend(result.msg, "Variable MAXHEIGHT not defined or invalid data.") />
					</cfif>
					<cfif NOT isDefined("arguments.fileUploadField") or (isDefined("arguments.fileUploadField") and Len(URLDecode(arguments.fileUploadField)) eq 0)>
						<cfset result['error'] = true />
						<cfset ArrayAppend(result.msg, "FILE INPUT FILED not defined or invalid data.") />
					</cfif>

					<cfif NOT result['error'] and ArrayLen(result['msg']) eq 0>

						<!---
							File Upload Notes:
							I would have rather uploaded to the temp directory and then move the file. but ColdFusion doesn't seem to check for name
							conflicts on "rename" or "move". If anyone knows an easy way around this, please share.
						--->

						<!--- upload the file --->
						<cffile action="upload" filefield="fileUploadField" destination="#ExpandPath(locvar.baseUrl)#" nameconflict="makeunique" />

						<!--- if the file uploaded, then continue --->
						<cfif cffile.filewassaved eq "Yes" and cffile.fileSize lte (arguments.maxSize * 1024)>

							<!--- make sure that the uploaded file has the correct file extension (This still doesn't mean it VALID! --->
							<cfif isFileExtValid(cffile.serverFileExt, locvar.authExts) and (locvar.fileExts eq "*" or (locvar.fileExts neq "*" and ListFindNoCase(locvar.fileExts, cffile.serverFileExt) gt 0))>

								<!---
									check file name and move out of temp directory
								—————————————————————————————————————————————————————————————————————————————————————— --->
								<cfset locvar['newFileName'] = safeFileNameFull(cffile.serverFileName) & "." & LCase(cffile.serverFileExt) />
								<cfset locvar['serverFilePath'] = Replace(cffile.ServerDirectory, '\', '/', 'ALL') & "/" & cffile.ServerFile />
								<cfset locvar['newFilePath'] = ExpandPath(Replace(locvar.baseUrl, '\', '/', 'ALL') & locvar.newFileName) />

								<!---
								 | CHECK TO SEE IF THE WAS AN IMAGE BEFORE WE SCALE IT
								 | *using isImageFile() might crash, but only if CF8 is missing an update it could crash the server.
								--->
								<cfif server.coldfusion.productname eq "Railo" or ListGetAt(server.coldfusion.productversion, 1) gt 8>
									<cfset locvar['isImg'] = isImageFile(ExpandPath('#locvar.serverFilePath#')) />
								<cfelse>
									<cfif ListFindNoCase(variables.webImgFileList, LCase(cffile.serverFileExt)) gt 0>
										<cfset locvar['isImg'] = true />
									<cfelse>
										<cfset locvar['isImg'] = false />
									</cfif>
								</cfif>

								<cfif locvar.isImg and isNumeric(arguments.maxWidth) and isNumeric(arguments.maxHeight)>
									<!---
										resize the image if it's to big
									—————————————————————————————————————————————————————————————————————————————————————— --->
									<cfimage action="read" name="locvar.imgFile" source="#locvar.newFilePath#" />
									<cfif locvar.imgFile["width"] gt arguments.maxWidth or locvar.imgFile["height"] gt arguments.maxHeight>
										<cfset ImageSetAntialiasing(locvar.imgFile, "on") />
										<cfset locvar['imgInfo'] = calcScaleInfo(locvar.imgFile["width"], locvar.imgFile["height"], arguments.maxWidth, arguments.maxHeight, "fit") />
										<cfset ImageScaleToFit(locvar.imgFile, locvar.imgInfo.width, locvar.imgInfo.height, "highestQuality", "1") />
										<cfimage action="write" source="#locvar.imgFile#" destination="#locvar.newFilePath#" overwrite="yes" />
									</cfif>

								<cfelse>

									<!--- ARgh!!!@#!@# Railo is having issues with renaming as of versiokn 3.3.1.000. Keep getting File or Directory not found. --->
									<cfif server.coldfusion.productname neq "Railo" or (server.coldfusion.productname eq "Railo" and server.railo.version neq "3.3.1.000")>
										<cffile action="rename" source="#locvar.serverFilePath#" destination="#locvar.newFilePath#" nameconflict="overwrite" />
									</cfif>

								</cfif>

							<!--- not a valid file extension --->
							<cfelse>

								<cfset result['error'] = true />
								<cfset ArrayAppend(result.msg, "You are not allowed to upload #UCase(cffile.serverFileExt)# files.") />

								<!--- delete the file --->
								<cffile action="delete" file="#ExpandPath('#locvar.baseUrl##cffile.ServerFile#')#" />

							</cfif>

						<cfelseif cffile.filewassaved eq "Yes" and cffile.fileSize gt (arguments.maxSize * 1024)>
							<!--- file is too big --->
							<cfif FileExists(ExpandPath('#locvar.baseUrl##cffile.ServerFile#'))>
								<cffile action="delete" file="#ExpandPath('#locvar.baseUrl##cffile.ServerFile#')#" />
							</cfif>
							<cfset result['error'] = true />
							<cfset ArrayAppend(result.msg, "The file size of your upload excedes the allowable limit. Please upload a file smaller than #NumberFormat(arguments.maxSize,'9,999')#KB.")>
						<cfelse>
							<!--- cffile.filewassaved = "no" --->
							<cfset result['error'] = true />
							<cfset ArrayAppend(result.msg, "Problems encountered uploading the file.")>
						</cfif>

					<cfelse>
						<!--- ArrayLen(result['msg']) > 0 --->
						<cfset result['error'] = true />
					</cfif>

				</cfif>
			</cfif>

			<cfcatch type="any">
				<cfset result['error'] = true />
				<cfset result['msg'] = cfcatch.message />
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
		<cfset locvar['binResponse'] = ToBinary( ToBase64( locvar.strHTML ) ) />
		<cfcontent reset="true" /><cfheader name="content-length" value="#ArrayLen( locvar.binResponse )#" /><cfcontent type="text/html" variable="#locvar.binResponse#" />
	</cffunction>


	<!--- ------------------------------------------------------------------------

		doDropUpload - Uploads a file that was "dropped" on the window.

		Author: Doug Jones
		http://www.cjboco.com/

	------------------------------------------------------------------------ --->
	<cffunction name="doDropUpload" access="remote" output="true" returntype="any" returnformat="json">

		<cfset var result = StructNew() />
		<cfset var locvar = StructNew() />

			<cfset var cj = StructNew() />

			<cfset result['error'] = false />
			<cfset result['msg'] = "" />

			<cftry>

				<cfset locvar['requestData'] = GetHttpRequestData() />
				<cfset cj.origFilename = LCase(URLDecode(cgi.http_x_file_name)) />

				<cfset cj.nameArr = ListToArray(cj.origFilename, ".") />
				<cfset cj.paramsStr = URLDecode(cgi.http_x_file_params) />

				<!--- first check the passed parameters --->
				<cfif Len(cj.paramsStr) eq 0 or NOT isJson(cj.paramsStr)>
					<cfset result['error'] = true />
					<cfset result['msg'] = "Could not complete upload. Invalid parameters." />
				<cfelse>
					<cfset cj.params = DeSerializeJSON(cj.paramsStr) />
					<cfif
						NOT StructKeyExists(cj.params, "baseRelPath") or
						NOT StructKeyExists(cj.params, "maxWidth") or
						NOT StructKeyExists(cj.params, "maxHeight") or
						NOT StructKeyExists(cj.params, "maxSize") or
						NOT StructKeyExists(cj.params, "fileExts") or
						NOT StructKeyExists(cj.params, "timeOut")>
							<cfset result['error'] = true />
							<cfset result['msg'] = "Could not complete upload. Required parameters missing." />
					</cfif>
				</cfif>

				<cfif NOT result['error']>

					<cfif ArrayLen(cj.nameArr) neq 2>

						<cfset result['error'] = true />
						<cfset result['msg'] = "File name missing extension. (#cj.origFilename#)" />

					<cfelseif Len(locvar.requestData.content) eq 0>

						<cfset result['error'] = true />
						<cfset result['msg'] = "No XHR content was passed. (doDropUpload)" />

					<cfelse>

						<!--- set up some initial values --->
						<cfset cj.baseRelPath = Replace(URLDecode(cj.params.baseRelPath[ArrayLen(cj.params.baseRelPath)]), '\', '/', 'ALL') />
						<cfset cj.fileName = safeFileNameFull(cj.nameArr[1]) />
						<cfset cj.fileExt = cj.nameArr[2] />

						<!--- check to see if they passed a timout value --->
						<cfif StructKeyExists(cj.params, "timeOut") and isNumeric(cj.params.timeOut) and cj.params.timeOut gt 0>
							<cfsetting requestTimeout="#cj.params.timeOut#" />
						</cfif>

						<!--- preload our security settings (since we have to read this in each time) --->
						<cfset locvar['authDirs'] = getSecuritySettings('directories') />
						<cfset locvar['authActions'] = getSecuritySettings('actions') />
						<cfset locvar['authExts'] = getSecuritySettings('fileExts') />

						<!--- validate "navigateDirectory" action and path --->
						<cfif NOT isPathValid(cj.baseRelPath, false, locvar.authDirs)>

							<cfset result['error'] = true />
							<cfset result['msg'] = "Directory access denied." />

						<!--- validate action --->
						<cfelseif NOT isActionValid("fileUpload",locvar.authActions)>

							<cfset result['error'] = true />
							<cfset result['msg'] = "Not authorized to upload files." />

						<!--- validate that the "baseRelPath" exists --->
						<cfelseif NOT DirectoryExists(ExpandPath(cj.baseRelPath))>

							<cfset result['error'] = true />
							<cfset result['msg'] = "Directory does not exist." />

						<cfelseif isDefined("locvar.fileSize.size") and locvar.fileSize.size gt (cj.params.maxSize * 1024)>

							<cfset result['error'] = true />
							<cfset result['msg'] = "The file size of your upload excedes the allowable limit. Please upload a file smaller than #NumberFormat(cj.params.maxSize, '9,999')#KB.">

						<cfelse>

							<cfset result['msg'] = ArrayNew(1) />

							<!--- validate that we have the proper form fields --->
							<cfif NOT DirectoryExists(ExpandPath(cj.baseRelPath))>
								<cfset result['error'] = true />
								<cfset ArrayAppend(result.msg, "You must provide a valid UPLOAD DIRECTORY.<br /><small>(Could not find directory)</small>")>
							</cfif>
							<cfif Len(cj.baseRelPath) eq 0 or ReFind("[^a-zA-Z0-9\,\$\-\_\.\+\!\*\'\(\)\/]+", cj.baseRelPath) gt 0>
								<cfset result['error'] = true />
								<cfset ArrayAppend(result.msg, "Variable BASEURL not defined or invalid data.") />
							</cfif>
							<cfif cj.params.fileExts neq "*" and ReFind("[^a-zA-Z0-9\,]+", URLDecode(cj.params.fileExts)) gt 0>
								<cfset result['error'] = true />
								<cfset ArrayAppend(result.msg, "Variable FILEEXTS not defined or invalid data.") />
							<cfelse>
								<!--- remove any spaced between the list items ", " or " ," --->
								<cfset cj.params.fileExts = ReReplace(URLDecode(cj.params.fileExts), "[\s]*,[\s]*",",","ALL") />
							</cfif>
							<cfif NOT isNumeric(cj.params.maxSize) or (isNumeric(cj.params.maxSize) and (cj.params.maxSize lt 1 or cj.params.maxSize gt 9999999))>
								<cfset result['error'] = true />
								<cfset ArrayAppend(result.msg, "Variable MAXSIZE not defined or invalid data.") />
							</cfif>
							<cfif NOT isNumeric(cj.params.maxWidth) or (isNumeric(cj.params.maxWidth) and (cj.params.maxWidth lt 1 or cj.params.maxSize gt 9999999))>
								<cfset result['error'] = true />
								<cfset ArrayAppend(result.msg, "Variable MAXWIDTH not defined or invalid data.") />
							</cfif>
							<cfif NOT isNumeric(cj.params.maxHeight) or (isNumeric(cj.params.maxHeight) and (cj.params.maxHeight lt 1 or cj.params.maxHeight gt 9999999))>
								<cfset result['error'] = true />
								<cfset ArrayAppend(result.msg, "Variable MAXHEIGHT not defined or invalid data.") />
							</cfif>

							<cfif NOT result.error and ArrayLen(result.msg) eq 0>

								<!--- we're all good in the hood, since cffile write doesn't make unqiue file names, loop through until we can write one --->
								<cfset locvar['tempFileName'] = cj.fileName & "." & cj.fileExt />
								<cfloop index="locvar.idx" from="1" to="999">
									<cfif NOT FileExists(ExpandPath('#cj.baseRelPath##locvar.tempFileName#'))>
										<cffile action="write" file="#ExpandPath('#cj.baseRelPath##locvar.tempFileName#')#" output="#locvar.requestData.content#" />
										<cfbreak />
									<cfelse>
										<cfset locvar['tempFileName'] = cj.fileName & locvar.idx & "." & cj.fileExt />
									</cfif>
								</cfloop>
								<cfset sleep(25) >

								<!---
								 | CHECK TO SEE IF THE WAS AN IMAGE BEFORE WE SCALE IT
								 | *using isImageFile() might crash, but only if CF8 is missing an update it could crash the server.
								--->
								<cfif server.coldfusion.productname eq "Railo" or ListGetAt(server.coldfusion.productversion, 1) gt 8>
									<cfset locvar['isImg'] = isImageFile(ExpandPath('#cj.baseRelPath##locvar.tempFileName#')) />
								<cfelse>
									<cfif ListFindNoCase(variables.webImgFileList, cj.fileExt) gt 0>
										<cfset locvar['isImg'] = true />
									<cfelse>
										<cfset locvar['isImg'] = false />
									</cfif>
								</cfif>
								<cfif locvar.isImg and isNumeric(cj.params.maxWidth) and isNumeric(cj.params.maxHeight)>

									<cfimage action="read" name="locvar.imgFile" source="#ExpandPath('#cj.baseRelPath##locvar.tempFileName#')#" />
									<cfif locvar.imgFile["width"] gt cj.params.maxWidth or locvar.imgFile["height"] gt cj.params.maxHeight>
										<cfset ImageSetAntialiasing(locvar.imgFile, "on") />
										<cfset locvar['imgInfo'] = calcScaleInfo(locvar.imgFile["width"], locvar.imgFile["height"], cj.params.maxWidth, cj.params.maxHeight, "fit") />
										<cfset ImageScaleToFit(locvar.imgFile, locvar.imgInfo.width, locvar.imgInfo.height, "highestQuality", "1") />
										<cfimage action="write" source="#locvar.imgFile#" destination="#ExpandPath('#cj.baseRelPath##locvar.tempFileName#')#" overwrite="yes" />
									</cfif>

								</cfif>

								<cfset result['sucess'] = true />
								<cfset result['error'] = false />
								<cfset result['msg'] = "" />

							</cfif>

						</cfif>

					</cfif>

				</cfif>

				<cfcatch type="any">

					<cfset result['error'] = true />
					<cfset result['msg'] = cfcatch.message />

				</cfcatch>

			</cftry>

			<cfreturn result />

	</cffunction>


	<!--- ------------------------------------------------------------------------

		doDeleteFile - Deletes a given file from the server.

		Author: Doug Jones
		http://www.cjboco.com/

	------------------------------------------------------------------------ --->
	<cffunction name="doDeleteFile" access="remote" output="false" returntype="any" returnformat="json">
		<cfargument name="baseRelPath" type="string" required="yes" />
		<cfargument name="fileName" type="string" required="yes" />
		<cfargument name="timeOut" type="numeric" required="no" default="900" />
		<cfset var locvar = StructNew() />
		<cfset var result = StructNew() />
		<cftry>

			<cfset locvar['baseRelPath'] = URLDecode(arguments.baseRelPath) />

			<!--- check to see if they passed a timout value --->
			<cfif isDefined("arguments.timeOut") and isNumeric(arguments.timeOut) and arguments.timeOut gt 0>
				<cfsetting requestTimeout="#arguments.timeOut#" />
			</cfif>

			<!--- preload our security settings (since we have to read this in each time) --->
			<cfset locvar['authDirs'] = getSecuritySettings('directories') />
			<cfset locvar['authActions'] = getSecuritySettings('actions') />

			<!--- validate "navigateDirectory" action and path --->
			<cfif NOT isPathValid(locvar.baseRelPath, false, locvar.authDirs)>

				<cfset result['error'] = true />
				<cfset result['msg'] = "Directory access denied." />

			<!--- validate action --->
			<cfelseif NOT isActionValid("fileDelete",locvar.authActions)>

				<cfset result['error'] = true />
				<cfset result['msg'] = "Not authorized to delete files." />

			<!--- validate that the "baseRelPath" exists --->
			<cfelseif NOT DirectoryExists(ExpandPath(locvar.baseRelPath))>

				<cfset result['error'] = true />
				<cfset result['msg'] = "Directory does not exist." />

			<cfelse>

				<cfif FileExists(ExpandPath("#locvar.baseRelPath##arguments.fileName#"))>
					<cffile action="delete" file="#ExpandPath("#locvar.baseRelPath##arguments.fileName#")#">
				</cfif>
				<cfset result['error'] = false />
				<cfset result['msg'] = "" />

			</cfif>
			<cfcatch type="any">
				<cfset result['error'] = true />
				<cfset result['msg'] = cfcatch.message />
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

			<cfset locvar['baseRelPath'] = URLDecode(arguments.baseRelPath) />

			<!--- check to see if they passed a timout value --->
			<cfif isDefined("arguments.timeOut") and isNumeric(arguments.timeOut) and arguments.timeOut gt 0>
				<cfsetting requestTimeout="#arguments.timeOut#" />
			</cfif>

			<!--- preload our security settings (since we have to read this in each time) --->
			<cfset locvar['authDirs'] = getSecuritySettings('directories') />
			<cfset locvar['authActions'] = getSecuritySettings('actions') />

			<!--- validate "navigateDirectory" action and path --->
			<cfif NOT isPathValid(locvar.baseRelPath, false, locvar.authDirs)>

				<cfset result['error'] = true />
				<cfset result['msg'] = "Directory access denied." />

			<!--- validate action --->
			<cfelseif NOT isActionValid("deleteDirectory",locvar.authActions)>

				<cfset result['error'] = true />
				<cfset result['msg'] = "Deleting directories is not allowed." />

			<!--- validate that the "baseRelPath" exists --->
			<cfelseif NOT DirectoryExists(ExpandPath(locvar.baseRelPath))>

				<cfset result['error'] = true />
				<cfset result['msg'] = "Directory does not exist." />

			<!--- make sure it's not the root directory!! --->
			<cfelseif Len(URLDecode(arguments.dirName)) eq 0 or URLDecode(arguments.dirName) eq "/" or URLDecode(arguments.dirName) eq "\">

				<cfset result['error'] = true />
				<cfset result['msg'] = "You cannot delete the root directory." />

			<cfelse>

				<!--- do a recursive delete --->
				<cfset result['error'] = deleteDirectory(ExpandPath("#locvar.baseRelPath##arguments.dirName#"),true) />
				<cfif result['error'] eq true>
					<cfset result['msg'] = "" />
				<cfelse>
					<cfset result['msg'] = "There was a problem deleting the directory." />
				</cfif>

			</cfif>
			<cfcatch type="any">
				<cfset result['error'] = true />
				<cfset result['msg'] = cfcatch.message />
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

			<cfset locvar['baseRelPath'] = URLDecode(arguments.baseRelPath) />

			<!--- check to see if they passed a timout value --->
			<cfif isDefined("arguments.timeOut") and isNumeric(arguments.timeOut) and arguments.timeOut gt 0>
				<cfsetting requestTimeout="#arguments.timeOut#" />
			</cfif>

			<!--- preload our security settings (since we have to read this in each time) --->
			<cfset locvar['authDirs'] = getSecuritySettings('directories') />
			<cfset locvar['authActions'] = getSecuritySettings('actions') />

			<!--- validate "navigateDirectory" action and path --->
			<cfif NOT isPathValid(locvar.baseRelPath, false, locvar.authDirs)>

				<cfset result['error'] = true />
				<cfset result['msg'] = "Directory access denied." />

			<!--- validate action --->
			<cfelseif NOT isActionValid("createDirectory",locvar.authActions)>

				<cfset result['error'] = true />
				<cfset result['msg'] = "Creating directories is not allowed." />

			<!--- validate that the "baseRelPath" exists --->
			<cfelseif NOT DirectoryExists(ExpandPath(locvar.baseRelPath))>

				<cfset result['error'] = true />
				<cfset result['msg'] = "Directory does not exist." />

			<cfelse>

				<!--- make sure we don't have any funky characters in the name --->
				<cfif ReFindNoCase("[^a-zA-Z0-9_\-]",arguments.dirName) gt 0>
					<cfset result['error'] = true />
					<cfset result['msg'] = "Invalid characters detected in directory name. (Valid [a-zA-Z0-9_-])" />
				<cfelseif Len(arguments.dirName) lt 1 or Len(arguments.dirName) gt 64>
					<cfset result['error'] = true />
					<cfset result['msg'] = "Invalid directory name length. (Valid 1-64 characters)" />
				<cfelse>
					<!--- make sure the directory doesn't already exists --->
					<cfif NOT DirectoryExists(ExpandPath(URLDecode("#locvar.baseRelPath##arguments.dirName#")))>
						<cfdirectory action="create" directory="#ExpandPath(URLDecode('#locvar.baseRelPath##arguments.dirName#'))#" >
						<cfset result['error'] = false />
						<cfset result['msg'] = "" />
					<cfelse>
						<cfset result['error'] = true />
						<cfset result['msg'] = "Directory already exists." />
					</cfif>
				</cfif>

			</cfif>
			<cfcatch type="any">
				<cfset result['error'] = true />
				<cfset result['msg'] = cfcatch.message />
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
	<cffunction name="calcScaleInfo" access="remote" returntype="struct" output="false" hint="A simple function that will return the width, height and offset of scaled image thumbnail.">
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
	<cffunction name="safeFileName" access="remote" returntype="string" output="no" hint="Searches a string for illegal filename characters, strips them and then returns the modified string.">
		<cfargument name="input" type="string" required="yes" />
		<cfset var output = arguments.input />
		<cfif Len(input) eq 0>
			<cfreturn "" />
		</cfif>
		<cfset output = REReplaceNoCase(output,'[^a-zA-Z0-9_\-]+','_','ALL')>
		<cfset output = REReplaceNoCase(output,'[_]+','_','ALL')>
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
	<cffunction name="deleteDirectory" access="remote" returntype="any" output="false">
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
			<cfset locvar['output'] = "" />
			<cftry>
				<cfif Len(arguments.input) gt 0>
					<cfset locvar['pos'] = ReFind("\.([^\.]+)$", arguments.input) />
					<cfif locvar.pos lte 0>
						<!--- there is no file extension --->
						<cfset locvar['name'] = LCase(arguments.input) />
						<cfset locvar['ext'] = "" />
					<cfelse>
						<cfif locvar.pos gt 1>
							<cfset locvar['name'] = LCase(Left(arguments.input, locvar.pos - 1)) />
						<cfelse>
							<!--- no name, just an extension? --->
							<cfset locvar['name'] = "" />
						</cfif>
						<cfif locvar.pos lt Len(arguments.input)>
							<cfset locvar['ext'] = LCase(Mid(arguments.input, locvar.pos + 1, Len(arguments.input))) />
						<cfelse>
							<!--- no extension, just an name? --->
							<cfset locvar['ext'] = "" />
						</cfif>
					</cfif>
					<cfset locvar['output'] = REReplaceNoCase(locvar.name, '[^a-zA-Z0-9_\-]+', '_', 'ALL') />
					<cfset locvar['output'] = REReplaceNoCase(locvar.output, '[_]+', '_', 'ALL') />
					<cfset locvar['output'] = REReplaceNoCase(locvar.output, '\b((and)|(or)|(at))\b', '', 'ALL') />
					<cfif Len(locvar.output) gt 0 and Len(locvar.ext) gt 0>
						<cfset locvar['output'] = locvar.output & "." & locvar.ext />
					<cfelseif Len(locvar.output) gt 0>
						<cfset locvar['output'] = locvar.output />
					<cfelseif Len(locvar.ext) gt 0>
						<cfset locvar['output'] = locvar.ext />
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
