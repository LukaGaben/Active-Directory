$users = Get-ADUser -SearchBase "OU=Р7 Групп,OU=Дивизион управления недвижимостью,OU=IPTG,DC=ukkalita,DC=local" -Filter { userprincipalname -like "*@r7-group.com" } | select name, userprincipalname, SamAccountName
$excUsers = "n.avdeeva", "e.jurina", "dogadchenko", "a.ermolov", "Disp-L", "Reception-L", "disp"
foreach ($user in $users) {
    $userlog = $user.SamAccountName
    if ($excUsers -contains $userlog) {
        continue
    }
    else {        
        $userName = $user.name
        $newUPN = $user.SamAccountName + "@r7-group.ru"
        Set-ADUser -Identity $userlog -UserPrincipalName $newUPN
        write-host "У сотрудника" $userName "сменился логин для входа на" $newUPN
    }
}
