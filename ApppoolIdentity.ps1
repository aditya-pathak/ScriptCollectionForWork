$ComputerName = read-host "Enter the Server Name"


write-host "==========================================================="

write-host "WebApplication on server" $ComputerName


try{
$webapps = invoke-command -ComputerName $ComputerName -ScriptBlock { Import-Module WebAdministration; get-childitem  IIS:\AppPools\ }

$list = @()
foreach ($webapp in $webapps)
{

$item = @{}

$item.WebAppName = $webapp.name
$item.UserIdentityType = $webapp.processModel.identityType
$item.Username = $webapp.processModel.userName
$item.Password = $webapp.processModel.password

$obj = New-Object PSObject -Property $item
$list += $obj
}

$list | Format-Table -a -Property "WebAppName", "Version", "State", "UserIdentityType", "Username", "Password"

}catch
{
$ExceptionMessage = "Error in Line: " + $_.Exception.Line + ". " + $_.Exception.GetType().FullName + ": " + $_.Exception.Message + " Stacktrace: " + $_.Exception.StackTrace
$ExceptionMessage
}