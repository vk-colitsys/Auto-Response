<cfprocessingdirective pageencoding="utf-8" />
<cfsetting enablecfoutputonly="true" showdebugoutput="no">

<cfset xmlrpc = createObject("component", "xmlrpc")>
<cfset pingbackprocessor = createObject("component", "pingback").init()>
<cfset tools = createObject("component", "tools")>

<cfset reqData = getHTTPRequestData()>

<cfif not isDefined("reqData") or not isDefined("reqData.content") or not len(reqData.content)>
	<cfabort>
</cfif>

<cfset requestData = xmlrpc.xmlrpc2cfml(reqData.content)>

<cfset result = arrayNew(1)>
<cfset result = [0,'Generic error']>
<cfset type = "responsefault">

<cfswitch expression="#requestData.method#">

	<cfcase value="pingback.ping">
		<cfset strPagelinkedfrom = requestData.params[1]>
		<cfset strPagelinkedto = requestData.params[2]>
		
		<cfset result = arrayNew(1)>
		<cftry>
			<cfset result = pingbackprocessor.pingbackPing(strPagelinkedfrom,strPagelinkedto,CGI.HTTP_HOST)>
			
			<cfif result[1] eq -1>
				<cfset type="response">		
			</cfif> <!--- otherwise it's false --->
						
			<cfcatch>
				<cfset tools.logit(cfcatch.Message & ":" & cfcatch.Type & ", cfcatch:" & cfcatch.Detail)>
			</cfcatch>
		</cftry>
		
	</cfcase>
		
</cfswitch>

<cfset pResult = arrayNew(1)>
<cfset pResult[1] = result>
<cfset resultData = xmlrpc.cfml2xmlrpc(data=pResult,type=type)>
<!--- <cfset this.tools.logit("resultData: #resultData#")> --->

<cfcontent type="text/xml; charset=utf-8"><cfoutput><?xml version="1.0" encoding="ISO-8859-1"?>#resultData#</cfoutput>
