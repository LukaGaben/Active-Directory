$OU = "OU=Р7 Групп,OU=Дивизион управления недвижимостью,OU=IPTG,DC=ukkalita,DC=local"
$usersAD = get-aduser -filter * -Properties * -SearchBase $OU
function Get-ADUserGroup {
    param (
        $user
    )
    $groupList = @()
    $userListGroup = ($user | select MemberOf).memberof # | Where-Object { $_ -like "*folder access*" }
    foreach ($element in $userListGroup) {
        $group = ($element.replace("CN=", "")).split(",")[0]  
        $groupList += [PSCustomObject]@{
            GroupName = $group
        }
    }
    return $groupList  
}
$folderPath = "C:\results\Group"
#Проверка наличия папки, куда будем складывать логи
if (-not (Test-Path $folderPath -PathType Container)) {
    New-Item -ItemType Directory -Path $folderPath -ErrorAction SilentlyContinue | Out-Null # Если папки нет, то создаем её
}
foreach ($userAD in $usersAD) {
    $login = $userad.SamAccountName
    $data = Get-ADUserGroup $userAD
    $userName = $userAD.name
    $logFileName = $userName +";" + $login + ".log"
    $fullPath = Join-Path $folderPath $logFileName
    $data | Export-Csv $fullPath -Encoding Default -Delimiter "," -NoTypeInformation
}
