$ukkalitaCore = "OU=Р7 Групп,OU=Дивизион управления недвижимостью,OU=IPTG,DC=ukkalita,DC=local"
$r7GroupCore = "OU=Р7 Групп,DC=r7-group,DC=local"
$usersNewDomain = get-aduser -SearchBase $r7GroupCore -Filter * -Properties * -Server "r7-group.local"
$userOldDomain = get-aduser -SearchBase $r7GroupCore -Filter * -Properties *
