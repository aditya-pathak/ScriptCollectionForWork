#Set Input and Output file path. Do not put '\' at the end.
$InputOutputPath = "C:\URLtest"
 
Function Set-UseUnsafeHeaderParsing
{
    param(
        [Parameter(Mandatory,ParameterSetName='Enable')]
        [switch]$Enable,

        [Parameter(Mandatory,ParameterSetName='Disable')]
        [switch]$Disable
    )

    $ShouldEnable = $PSCmdlet.ParameterSetName -eq 'Enable'

    $netAssembly = [Reflection.Assembly]::GetAssembly([System.Net.Configuration.SettingsSection])

    if($netAssembly)
    {
        $bindingFlags = [Reflection.BindingFlags] 'Static,GetProperty,NonPublic'
        $settingsType = $netAssembly.GetType('System.Net.Configuration.SettingsSectionInternal')

        $instance = $settingsType.InvokeMember('Section', $bindingFlags, $null, $null, @())

        if($instance)
        {
            $bindingFlags = 'NonPublic','Instance'
            $useUnsafeHeaderParsingField = $settingsType.GetField('useUnsafeHeaderParsing', $bindingFlags)

            if($useUnsafeHeaderParsingField)
            {
              $useUnsafeHeaderParsingField.SetValue($instance, $ShouldEnable)
            }
        }
    }
}

Function Test-Websites {  
## The URI list to test  
$URLListFile = "$InputOutputPath\URLList.txt"
$URLList = Get-Content $URLListFile -ErrorAction SilentlyContinue  
 
$Result = @()  
$Result200_401 = @() 
#$Result503 = @() 
  $Timelast = Measure-Command {  
  Foreach($Uri in $URLList) {  
  $time = try{  
  $request = $null  
   ## Request the URI, and measure how long the response took. 
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  Set-UseUnsafeHeaderParsing -Enable
  $result1 = Measure-Command { $request = Invoke-WebRequest -Uri $uri -UseDefaultCredential}
  $result1.TotalSeconds
  }   
  catch  
  {  
   <# If the request generated an exception (i.e.: 500 server  
   error or 404 not found), we can pull the status code from the  
   Exception.Response property #>  
   $request = $_.Exception.Response  
   $time = -1  
  } 
 
  $r = [int] $request.StatusCode 
   
   
  switch ($r) { 
    "200" { 
         $result200_401 += [PSCustomObject] @{  
          Time = Get-Date;  
          Uri = $uri;  
          StatusCode = [int] $request.StatusCode;  
          StatusDescription = $request.StatusDescription;  
          ResponseLength = $request.RawContentLength;  
          TimeTaken =  $time;} 
    }
    "401" { 
         $result200_401 += [PSCustomObject] @{  
          Time = Get-Date;  
          Uri = $uri;  
          StatusCode = [int] $request.StatusCode;  
          StatusDescription = $request.StatusDescription;  
          ResponseLength = $request.RawContentLength;  
          TimeTaken =  $time;} 
    }
    <#"503" { 
         $result503 += [PSCustomObject] @{  
          Time = Get-Date;  
          Uri = $uri;  
          StatusCode = [int] $request.StatusCode;  
          StatusDescription = $request.StatusDescription;  
          ResponseLength = $request.RawContentLength;  
          TimeTaken =  $time;} 
    } 
	#>
    default { 
         $result += [PSCustomObject] @{  
          Time = Get-Date;  
          Uri = $uri;  
          StatusCode = [int] $request.StatusCode;  
          StatusDescription = $request.StatusDescription;  
          ResponseLength = $request.RawContentLength;  
          TimeTaken =  $time;}
    } 
  }  
  } 
}  
$ExecTime = $timelast.TotalSeconds
Write-Host -f darkgreen "Script execution time:"$ExecTime -nonewline
Write-Host -f darkgreen " seconds."
 
if($result200_401 -ne $null)  
{  
    $Outputreport200_401 = "<div><H2 style='color:green;'>[Live Website(s)]</H2><Table border=1 cellpadding=5 cellspacing=0><TR bgcolor=gray align=center><TD><B>URL</B></TD><TD><b>Link</b></TD><TD><B>Status Code</B></TD><TD><B>Status</B></TD><TD><B>Time Taken</B></TD><TD><B>Response Length</B></TD><TD><B>Timestamp</B></TD</TR>"  
    Foreach($Entry in $Result200_401)  
    {  
    switch ($Entry.StatusCode) 
        { 
        "200" {$Outputreport200_401 += "<TR bgcolor='#D6FFFF' style='color:#000;'>"} 
        default {$Outputreport200_401 += "<TR>"} 
        } 
        $Outputreport200_401 += "<TD>$($Entry.uri)</TD><TD style='text-align:center;'><a href='$($Entry.uri)' target='_blank'> Go </a></TD><TD align=center>$($Entry.StatusCode)</TD><TD align=center>$($Entry.StatusDescription)</TD><TD align=center>$($Entry.TimeTaken)</TD><TD align=center>$($Entry.ResponseLength)</TD><TD align=center>$($Entry.Time)</TD></TR>"  
    }  
    $Outputreport200_401 += "</Table></div>"  
}

#Prepare email body in HTML format for Unsuccess table 
if($result -ne $null) 
{  
    $Outputreport = "<div><H2>[Website(s) Unavailable or Something Went Wrong!]</H2><Table border=1 cellpadding=5 cellspacing=0><TR bgcolor=gray align=center><TD><B>URL</B></TD><TD><b>Link</b></TD><TD><B>Status Code</B></TD><TD><B>Status</B></TD><TD><B>Time Taken</B></TD><TD><B>Response Length</B></TD><TD><B>Timestamp</B></TD</TR>"
    Foreach($Entry in $Result)  
    {  
    switch ($Entry.StatusCode) 
        { 
        "404" {$Outputreport += "<TR bgcolor='#FF704D' style='color:#fff;'>"}
        "0" {$Outputreport += "<TR bgcolor='#FF704D' style='color:#fff;'>"}
		##"401" {$Outputreport += "<TR bgcolor='#FF704D' style='color:#fff;'>"}
        default {$Outputreport += "<TR>"}
        } 
        $Outputreport += "<TD>$($Entry.uri)</TD><TD style='text-align:center;'><a href='$($Entry.uri)' target='_blank'> Go </a></TD><TD align=center>$($Entry.StatusCode)</TD><TD align=center>$($Entry.StatusDescription)</TD><TD align=center>$($Entry.TimeTaken)</TD><TD align=center>$($Entry.ResponseLength)</TD><TD align=center>$($Entry.Time)</TD></TR>"  
    }  
    $Outputreport += "</Table></div>"  
}
<# 
if($result503 -ne $null)  
{   
    $Outputreport503 = "<div><H2 style='color:grey;'>[Website(s) 'Offline' or The Service Is Unavailable]</H2><Table border=1 cellpadding=5 cellspacing=0><TR bgcolor=gray align=center><TD><B>URL</B></TD><TD><b>Link</b></TD><TD><B>Status Code</B></TD><TD><B>Status</B></TD><TD><B>Time Taken</B></TD><TD><B>Response Length</B></TD><TD><B>Timestamp</B></TD</TR>"  
    Foreach($Entry in $Result503)  
    {  
    switch ($Entry.StatusCode) 
        { 
        "503" {$Outputreport503 += "<TR bgcolor='#D6FFFF' style='color:#000;'>"} 
        default {$Outputreport503 += "<TR>"} 
        } 
        $Outputreport503 += "<TD>$($Entry.uri)</TD><TD style='text-align:center;'><a href='$($Entry.uri)' target='_blank'> Go </a></TD><TD align=center>$($Entry.StatusCode)</TD><TD align=center>$($Entry.StatusDescription)</TD><TD align=center>$($Entry.TimeTaken)</TD><TD align=center>$($Entry.ResponseLength)</TD><TD align=center>$($Entry.Time)</TD></TR>"  
    }  
    $Outputreport503 += "</Table></div>"  
} #>
$Results = "<div>In total <b>" + $URLList.count + " </b> websites where tested in " + $ExecTime + " seconds, see results below:</div>" 
$Results += "<TITLE style='color:red;'>[Errors] Website Availability Report</TITLE><BODY background-color:peachpuff>$Outputreport200_401 $Outputreport</BODY>" 
$Date = (Get-Date -format "yyyyMMdd_HHmmss") 
$OutputFile = "$InputOutputPath\WebURLTestResults_$Date.htm" 
$Results | out-file $OutputFile
Invoke-Expression $OutputFile
}

<# 
Function Send-mail { 
if ($Result.Count -gt 0) { 
    #Send email with atachment 
    $EmailFrom = "mail@mail.com" 
    $EmailTo = "mail@mail.com" 
    $SMTPServer = "smtp.mail.com" 
    $EmailSubject = "URL Monitoring Result"  
 
    #Send mail with output 
    $mailmessage = New-Object system.net.mail.mailmessage  
    $mailmessage.from = ($EmailFrom)  
    $mailmessage.To.add($EmailTo) 
    $mailmessage.Subject = $EmailSubject 
    $mailmessage.Body = $body 
    $mailmessage.IsBodyHTML = $true 
    $SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer,587)   
    $SMTPClient.Credentials = New-Object System.Net.NetworkCredential("mail@mail.com", "password");  
    $SMTPClient.EnableSsl = $true  
    $SMTPClient.Send($mailmessage) 
} 
}
#>
##$body = 
Test-Websites
##Send-mail($body)
