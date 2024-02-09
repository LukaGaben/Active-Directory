function Get-OU {
    param (
        [string]$OU
    )
    $OU = $OU.trim()
    $core  = "OU=Департаменты,OU=R7 Group,DC=r7-group,DC=local" #Путь до кореной OU
    $ouList = Get-ADOrganizationalUnit -SearchBase $core -filter * | Select-Object -ExpandProperty DistinguishedName  #Получаем список OU которые относятся к департаментам
    $userOU = $ouList| Where-Object {$_ -eq $OU}
    
}