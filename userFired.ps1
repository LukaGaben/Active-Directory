Param(
    [Parameter (Mandatory = $true, Position = 1)]
    [string] $userFullName
)  
$date = (get-date).ToString("dd-MM-yyyy HH:mm:ss") 
$R7OU = "OU=Р7 Групп,OU=Дивизион управления недвижимостью,OU=IPTG,DC=ukkalita,DC=local"
$userAD = get-aduser -SearchBase $R7OU -Filter { Name -eq $userFullName } -Properties * 
Set-ADUser -Identity $userAD -Enabled $False -Clear manager -Replace @{extensionAttribute1 = $date } 
$userAD = $userAD.DistinguishedName
$adUserPath = "OU=blocked,OU=!Accounts,DC=ukkalita,DC=local"
Move-ADObject -Identity $userAD -TargetPath $adUserPath
Write-Host "Пользователь  $userFullName перенесен в blocked"