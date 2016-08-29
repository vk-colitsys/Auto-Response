<!--- 
	Author: Marko Simic (marko.simic@gmail.com)
	Weblog: http://itreminder.blogspot.com/

	Copyright (c)2009 Computec Media AG

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
--->
<cfcomponent hint="Process and create response on pingback requests" displayname="pingback" output="false" >
	
	<cffunction name="init" hint="constructor" returntype="pingback">
		<cfargument name="logging" hint="turns logging on/off" required="no" default="false" type="boolean">
		<cfset this.xmlrpc = createObject('component','xmlrpc')>
		<cfset this.tools = createObject('component','tools')>
		<cfset this.enableLogging = arguments.logging>
		<cfreturn this/>
	</cffunction>
	
	
	<!--- 
	Full spec & error codes: http://www.hixie.ch/specs/pingback/pingback#TOC3
	--->
	<cffunction name="pingbackPing" access="public" hint="Retrieves a pingback and registers it. Returns 2-dmin array: first elem message code, second eleme is message test. OK => code = -1" returntype="array">
		<cfargument name="strPagelinkedfrom" type="string" required="yes" hint="The absolute URI of the post on the source page containing the link to the target site.">	
		<cfargument name="strPagelinkedto" type="string" required="yes" hint="The absolute URI of the target of the link, as given on the source page.">
		<cfargument name="strHomeDomain" type="string" required="no" hint="Pingback request may contain only link <pagelinkedto> from this domain">
		
		<cfscript>
		var home = arguments.strHomeDomain;
		var title = '';
		var pagelinkedfrom = arguments.strPagelinkedfrom;
		var pagelinkedto   = arguments.strPagelinkedto;		
		var strLinkToBody = "";
		var arrMessage = [-1, 'Pingback from ' & pagelinkedfrom & ' to ' & pagelinkedto & ' registered.'];
		
		pagelinkedfrom = replaceNoCase(pagelinkedfrom, '&amp;', '&', 'all');
		pagelinkedto = replaceNoCase(pagelinkedto,'&amp;', '&', 'all');
		pagelinkedto = replaceNoCase(pagelinkedto, '&', '&amp;', 'all');
		
		// Check if the page is linked to our site
		home = replaceNoCase(home, 'http://www.,http://,https://www.,https://', '{k},{k},{k},{k}');
		home = replaceNoCase(home, '{k}', '', 'all');
	
		if (!findNoCase(home,pagelinkedto)){
			arrMessage = [0, 'This link is not from correct domain'];
			if (this.enableLogging)
				this.tools.logit("pingback from " & pagelinkedfrom & " failed. home: " & home & ", pagelinkedto: " & pagelinkedto);	
			return arrMessage;//return xmlError(0, 'Is there no link to us?');
		}

		// Sends HTTP request to site that pinged us
		linea = httpget(pagelinkedfrom);
		
		if (!isStruct(linea) or !StructKeyExists(linea,'filecontent')){
			arrMessage = [16, 'The source URL does not exist.'];//return xmlError(16, 'The source URL does not exist.');
			//this.tools.logit("pingback from " & pagelinkedfrom & " failed 16");	
			return arrMessage;
		}
			
		strLinkToBody = linea.filecontent;
		
		// Work around bug in strip_tags():
		strLinkToBody = replaceNoCase(strLinkToBody,'<!DOC', '<DOC');
		strLinkToBody = REReplaceNoCase(strLinkToBody, '[\s\r\n\t]+', ' ','all'); // normalize spaces
		strLinkToBody = REReplaceNoCase(strLinkToBody,"<(h1|h2|h3|h4|h5|h6|p|th|td|li|dt|dd|pre|caption|input|textarea|button|body)[^>]*>",'{ss}','all');
		
		//check for site's title
		matches = REMatch('<title>([^<]*?)</title>', strLinkToBody);
		title = matches[1]; //should not be more then one title tag present on page
		
		//if title is not present, reject call
		if (len(title) eq 0){
			arrMessage = [32, 'We cannot find a title on that page.'];
			if (this.enableLogging)
				this.tools.logit("pingback from " & pagelinkedfrom & " failed 32");	
			return arrMessage;
		}

		//check page body to see if link to us is present
		matches = REMatch("<a[^>]+?" & REEscape(pagelinkedto) & "[^>]*>([^>]+?)</a>", strLinkToBody);
		
		// if URL isn't in a link context, issue error and reject call
		if (arraylen(matches) eq 0){
			arrMessage = [0, 'There''s no link to us?.'];//return xmlError(0, 'There''s no link to us?.');
			return arrMessage;
		}
		
		//TODO:
		//When ping is successfully verified to something: write in database and/or send some notificaiton to article author
		
		//returns message about successful verification
		return arrMessage;
		</cfscript>
	</cffunction>

	<!---
	 Ref doc: http://hixie.ch/specs/pingback/pingback#TOC3
	 --->
	<cffunction name="sendPingback" access="public" returntype="struct" hint="sends a pingback.ping method to specified XML-RPC server">
		<cfargument name="sourceURI" type="string" required="yes" hint="The absolute URI of the target of the link, as given on the source page.">
		<cfargument name="targetURI" type="string" required="yes" hint="The absolute URI of the post on the source page containing the link to the target site.">
		<cfargument name="contactURI" type="string" required="yes" hint="XML-RPC server address">
		<cfscript>
			var strxmlrpc = "";
			var data = ["pingback.ping",sourceURI,targetURI];
			strxmlrpc = this.xmlrpc.cfml2xmlrpc(data=data,type="call");
			return sendXMLRPCCall(xmlmessage=strxmlrpc,url=contactURI);
		</cfscript>
	</cffunction>
		
	<cffunction name="sendXMLRPCCall" access="public" hint="Send RPC call in XML format to desired url" returntype="struct" output="yes">
		<cfargument name="xmlmessage" hint="xml-rpc message" required="yes" type="string">
		<cfargument name="url" hint="xml-rpc server url" required="yes" type="string">		
		
		<cfset xmlrpcresponse = structNew()>
		
		<cftry>
			<cfhttp 
				url="#arguments.url#"
				method="POST" 
				charset="utf-8" 
				timeout="15" 
				useragent="Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.4) Gecko/20070515 Firefox/2.0.0.4"
				resolveurl="no"
				throwOnError="yes"
			>		
				<cfhttpparam type="xml" name="request_body" value="#trim(arguments.xmlmessage)#"> 
			</cfhttp>
			
			<cfset xmlrpcresponse = this.xmlrpc.xmlrpc2cfml(cfhttp.FileContent)>
			
			<cfcatch type="any">
				<cfif this.enableLogging>
					<cfset this.tools.logit(cfcatch.message & ", " & cfcatch.detail)>
				</cfif>
				<cfset xmlrpcresponse = this.xmlrpc.xmlrpc2cfml(xmlrpcError(code=0,message=cfcatch.message & ", " & cfcatch.detail))>
			</cfcatch>
		</cftry>
		
		<cfreturn xmlrpcresponse/>
	</cffunction>
	
	<cffunction name="xmlrpcError" access="private" returntype="string">
		<cfargument name="code" type="string" required="yes">
		<cfargument name="message" type="string" required="yes">
		<cfset var data=[code,message]>
		<cfreturn this.xmlrpc.cfml2xmlrpc(data=data,type='responsefault')/>
	</cffunction>

	<cffunction name="httpget" access="private" returntype="struct" hint="HTTP request for URI to retrieve content. Returns struct. Empty on failure.">
		<cfargument name="uri" type="string" hint="URI of web page to retrieve.">
		<cftry>
			<cfhttp 
				url="#arguments.uri#"
				method="get" 
				charset="utf-8" 
				timeout="15" 
				useragent="Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.4) Gecko/20070515 Firefox/2.0.0.4"
				resolveurl="no"
				throwOnError="yes"
				result="response"
			/>
			<cfcatch type="any">
				<cfset response = structNew()>
				<!---<cfset this.tools.logit("httpget:" & cfcatch.Type & ", " & cfcatch.Detail & ", arguments.uri: " & arguments.uri)>--->
			</cfcatch>
		</cftry>
					
		<cfreturn response>	
	</cffunction>

	<!---
	 * Finds a pingback server URI based on the given URL.
	 *
	 * Checks the HTML for the rel="pingback" link and x-pingback headers. It does
	 * a check for the x-pingback headers first and returns that, if available. The
	 * check for the rel="pingback" has more overhead than just the header.
	 * Ref doc: http://hixie.ch/specs/pingback/pingback#TOC2
	 * This is adaptation of of WordPress php function ""discover_pingback_server_uri"
	 --->
	<cffunction name="discoverPingbackServerUri" access="public" hint="Finds a pingback server URI based on the given URL." returntype="string">
		<cfargument name="url" type="string" required="yes" hint="URL to ping">
		<cfscript>
		var strPingbackDquote = "rel=""pingback""";
		var strPingbackSquote = "rel='pingback'";
		var response = structNew(); //HTTP response object as result of HTTP get request
		var contents = ""; //response body aka filecontent
		var iPingbackLinkOffsetDquote=0; //pos of strPingbackDquote
		var iPingbackLinkOffsetSquote=0; //pos of strPingbackSquote
		var iPingbackLinkOffset=0;
		var iPingbackHrefPos=0;
		var iPingbackHrefStart=0;
		var iPingbackHrefEnd=0;
		var iPingbackServerURLLen=0;
		var strPingbackServerURL = "";
		
		if ( ! isURL(arguments.url) ) // Not an URL. This should never happen.
			return false;
	
		//Retrieve the raw response from the HTTP request using the GET method.
		response = httpget(arguments.url);
		
		if ( StructKeyExists(response.responseHeader,'x-pingback'))
			return response.responseHeader['x-pingback'];
	
		// Not an (x)html, sgml, or xml page, no use going further.
		if ( StructKeyExists(response.responseHeader,'content-type') && REFindNoCase('(image|audio|video|model)', response.responseHeader['content-type']))
			return false;
	
		contents = response.fileContent;
	
		iPingbackLinkOffsetDquote = findNoCase(strPingbackDquote,contents);
		iPingbackLinkOffsetSquote = findNoCase(strPingbackSquote,contents);
		
		if ( iPingbackLinkOffsetDquote || iPingbackLinkOffsetSquote ) {
			if (iPingbackLinkOffsetDquote)
				quote = '"';
			else
				quote = '''';
				
			if (quote=='"')
				iPingbackLinkOffset  = iPingbackLinkOffsetDquote;
			else
				iPingbackLinkOffset  = iPingbackLinkOffsetSquote;
				
			iPingbackHrefPos = findNoCase('href=', contents, iPingbackLinkOffset);
			
			iPingbackHrefStart = iPingbackHrefPos+6;
			iPingbackHrefEnd = findNoCase(quote, contents, iPingbackHrefStart);
			iPingbackServerURLLen = iPingbackHrefEnd - iPingbackHrefStart;
			strPingbackServerURL = mid(contents, iPingbackHrefStart, iPingbackServerURLLen);
	
			// We may find rel="pingback" but an incomplete pingback URL
			if ( strPingbackServerURL > 0 ) { // We got it!
				return strPingbackServerURL;
			}
		}
	
		return false;
		</cfscript>
	</cffunction>	

	<!---
	 @author Shawn Seley (shawnse@aol.com) 
	 @version 1, June 26, 2002 
	--->		
	<cffunction name="REEscape" access="public" returntype="string" hint="Escapes all regular expression &quot;special characters&quot; in a string with &quot;\&quot;.Returns a string." >
		<cfargument name="theString" type="string" required="yes" hint="string to escape">
		<cfscript>
			var special_char_list      = "\,+,*,?,.,[,],^,$,(,),{,},|,-";
			var esc_special_char_list  = "\\,\+,\*,\?,\.,\[,\],\^,\$,\(,\),\{,\},\|,\-";
			return ReplaceList(theString, special_char_list, esc_special_char_list);		
		</cfscript>
	</cffunction>		

	<!---
	@author Nathan Dintenfass (nathan@changemedia.com)
	@version 1, November 22, 2001
	--->
	<cffunction name="isURL" access="public" returntype="boolean" hint="A quick way to test if a string is a URL. Returns a boolean." >
		<cfargument name="stringToCheck" type="string" required="yes" hint=" The string to check">
		<cfreturn 
			(REFindNoCase("^(((https?:|ftp:|gopher:)\/\/))[-[:alnum:]\?%,\.\/&##!@:=\+~_]+[A-Za-z0-9\/]$",stringToCheck) NEQ 0)>
	</cffunction>

</cfcomponent>