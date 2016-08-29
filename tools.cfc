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

<cfcomponent displayname="tools" hint="library of various tools" output="false">
	
	<!--- 
	Copyright (c)2009 Marko Simic
	Author: Marko Simic (marko.simic@gmail.com)
	Weblog: http://itreminder.blogspot.com/
	Note:	This code is free of charge and without warranty. Use at your own risk.
			If you make significant modifications or improvements to this component, send the resulting code to the author.
			This comment section must remain with the component in any distribution. Feel free to snip it out on your production box.	
	--->
	
	<cffunction name="structToString" returnType="string" access="public" output="false" hint="Converts a struct into string.">
		<cfargument name="data" type="struct" required="true">
		<cfargument name="structname" type="string" required="false" default="BASE">
		
		<cfset var strResult = "STRUCTURE " & structname & chr(13)>
		<cfset var keys = structKeyList(arguments.data)>
		<cfset var key = "">
		
		<cfset strResult &= chr(13) & "-----------------------------------------------------" & chr(13)>
		
		<cfloop index="key" list="#keys#">
			<cfif isStruct(arguments.data[key])>
				<cfset strResult &= chr(13) & structToString(arguments.data[key],key & " ( of " & structname & ")") & chr(13)>
			<cfelseif isArray(arguments.data[key])>
				<cfset strResult &= chr(13) & parseArray(arguments.data[key],key)>
			<cfelseif IsSimpleValue(arguments.data[key])>
				<cfset strResult &= chr(13) & key &": " & arguments.data[key] & chr(13)>
			</cfif>
		</cfloop>
		
		<cfset strResult &= chr(13) & "-----------------------------------------------------" & chr(13)>
		
		<cfreturn strResult>
	</cffunction>
	
	<cffunction name="parseArray" returntype="string" hint="Pass through array elements">
		<cfargument name="arr" required="yes" type="string">
		<cfargument name="arrname" required="no" type="string" default="array">
		<cfscript>
			s = arguments.arrname & ":" & chr(13) & "--------------------------" & chr(13);
			for (i=1;i<=arraylen(arr);i++){
				s &= chr(13) & i & ":" & arr[i] & chr(13);
			}
		</cfscript>
		<cfreturn s>
	</cffunction>
	
	<!--- 
		Taken from ColdBox Framework 
		http://www.coldboxframework.com/api/templates/content.cfm?file=C%3A%5CInetpub%5Cvhosts%5Ccoldboxframework%2Ecom%5Chttpdocs%5Cbuilds%5Ccoldbox%5F2%5F6%5F3%5Ccoldbox%5Csystem%5Cutil%5CUtil%2Ecfc#dumpit()
	--->
	<cffunction name="dumpit" access="public" hint="Facade for cfmx dump" returntype="void">
		<cfargument name="var" required="yes" type="any">
		<cfargument name="isAbort" type="boolean" default="false" required="false" hint="Abort also"/>
		<cfdump var="#var#">
		<cfif arguments.isAbort><cfabort></cfif>
	</cffunction>	
	
	<cffunction name="logit" hint="Log message into file. To every message will be attached an invocation history." access="public" returntype="void">
		<cfargument name="text" hint="message to log" required="yes" type="string">
		<cfscript>
			var logtext = "";			
			var procsteps = arrayNew(1);
			var strprocsteps = "";
			var j = 1;
			var i = 1;	
			
			//invocation history : who invoked who to reach this method
			//format: file name (source code line number)
			variables.twrl = createObject("java","java.lang.Throwable").init();
			variables.elements = variables.twrl.getStackTrace();
			
			for (i=1;i<=arrayLen(variables.elements);i++){
				if (variables.elements[i].getClassName().substring(0,2)=="cf" || variables.elements[i].getClassName().indexOf("$cf")!=-1){
					procsteps[j] = getFileFromPath(variables.elements[i].getFileName()) & "(" & variables.elements[i].getLineNumber() & ")";
					j++;
				}
			}
			
			if (arrayLen(procsteps) > 0){
				for (i=arrayLen(procsteps);i>=1;i--){ //moving backward
					strprocsteps &= procsteps[i];
					if (i!=1)
						strprocsteps &= "-->";
				}
			}
			//END invocation history
			
			logtext = strprocsteps & "--> " & arguments.text;
		</cfscript>
		
		<cflog file="pingbacklog" text="#logtext#" type="information"/>
	</cffunction>	
	
</cfcomponent>