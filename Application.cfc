<cfcomponent displayname="Application" output="false" hint="Handle the application.">

	<!--- Set up the application. --->
		<cfscript>
			this.Name 									= "CJ_FILE_BROWSER1";
			this.ApplicationTimeout 					= CreateTimeSpan(0,0,30,0);
			this.SessionManagement 						= "NO";
			this.SetClientCookies 						= "NO";
			this.secureJSON 							= "false";
		</cfscript>

	<!--- Define the page request properties. --->
		<cfsetting requesttimeout="900" showdebugoutput="false" enablecfoutputonly="false" />

	<!--- APPLICATION SCOPE VARIABLES --->
		<cffunction name="onApplicationStart" access="public" returntype="boolean" output="No" hint="Fires when the application is first created.">
			<cfset application.appName 					= "CJ_FILE_BROWSER1" />
			<cfreturn true />
		</cffunction>

</cfcomponent>
