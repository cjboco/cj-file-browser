<cfoutput>
<cfsavecontent variable="myXml">
	<?xml version="1.0"?>
	<cjFileBrowser version="4.0.2">
		<!-- **********************************************
			Master list of authorized actions.
			*Actions not listed are not allowed.
		********************************************** -->
		<actionsAllowed>
			<action>navigateDirectory</action>
			<action>createDirectory</action>
			<action>deleteDirectory</action>
			<action>fileDelete</action>
			<action>fileUpload</action>
			<action>dropUpload</action>
			<action>filePreviews</action>
			<action>fileSelect</action>
		</actionsAllowed>

		<!-- **********************************************
			Master list of authorized directories.
			Use "/" to allow all directories
			*Relative from ROOT (Don't use "../" not sure that will work)
		********************************************** -->
		<directoriesAllowed>
			<cfif FileExists(ExpandPath('../../../../Application.cfc'))>
				<cfset base_url = "/#GetDirectoryFromPath(ExpandPath('../../../../Application.cfc'))#" />
				<cfset base_url = ReplaceNoCase(base_url, ExpandPath('/'), '', 'ALL') />
				<cfset base_url = Replace(base_url, '\', '/', 'ALL') />
			<cfelse>
				<cfset base_url = "/" />
			</cfif>
			<directory type="relative">#base_url#assets/content/</directory>
		</directoriesAllowed>

		<!-- **********************************************
			Master list of authorized file extensions.
			A comma seperated list of file extension.
			Use "*" to allow all file types.
			i.e. jpg,gif,tiff,tif,png
		********************************************** -->
		<fileExtsAllowed>
			<fileExt>*</fileExt>
		</fileExtsAllowed>
	</cjFileBrowser>
</cfsavecontent>
</cfoutput>
<cfset myXml = Trim(REReplace(myXml, "[\r\t\n]+", "", "ALL")) />
<cfcontent type="application/xml" reset="true" variable="#ToBinary(ToBase64(myXml))#" />