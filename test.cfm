<cfheader name="x-pingback" value="http://#CGI.HTTP_HOST#/pingback/xmlrpc.cfm"/>

<cfscript>
	variables.sourceURI = "";
	variables.targetURI = "";
	varaibles.tools = createObject("component","tools");
</cfscript>

<h2>Client IP address: <cfoutput>#CGI.REMOTE_ADDR#</cfoutput></h2>

<cfif isDefined("form.fieldnames") and StructKeyExists(form,"address") and len(form.address) gt 0>
	<cfscript>
		pringbackproc = createObject("component","pingback").init(logging=true);
		variables.targetURI = form.address;
		variables.xmlrpcserverurl = pringbackproc.discoverPingbackServerUri(url=variables.targetURI);
	</cfscript>
	
	<cfoutput>
	xmlrpcserverurl: #variables.xmlrpcserverurl#<br>
	</cfoutput>
	
	<cfscript>
	//if page supports pingbacks
	if (comparenocase(variables.xmlrpcserverurl,"false")){
		//sends pingback to quoted blog's server
		variables.structResult = pringbackproc.sendPingback(sourceURI=variables.sourceURI,targetURI=variables.targetURI,contactURI=variables.xmlrpcserverurl);
		//debug. Ignore ir in production use.
		if (isDefined("variables.structResult") and isStruct(variables.structResult)){
			varaibles.tools.dumpit(var=variables.structResult,isAbort=false);
		}
	}
	</cfscript>
	
</cfif>
<html>
	<head>
		<title>
		P-back Test Page
		</title>
		<link rel="pingback" href="<cfoutput>http://#CGI.HTTP_HOST#/pingback/xmlrpc.cfm</cfoutput>" />
	</head>
	<body>
	
		<h1>Pingback page</h1>
		<form name="pbform" action="" method="post">
		Pingback address: <input type="text" name="address" value="" style="width:250px">
		<input type="submit" name="sendit" value="Pingback it!">
		</form>
		<br><br>
		<h2>Put some text here with links/references to blogs that you want to pingback.</h2>
		<br><br>
	
	</body>
</html>
