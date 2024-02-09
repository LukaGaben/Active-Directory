$OU = Import-Csv C:\1\OU.csv # Список  OU, которые надо создать. 

$corePath = "OU=Р7 Групп,DC=r7-group,DC=local" # Корень нашей OU в которой будут создаваться контейнеры
foreach ($element in $OU) {
    $department = ($element.department).trim()
    $division = ($element.division).trim()
    $ouList = Get-ADOrganizationalUnit -Filter { Name -eq $department } -SearchBase $corePath | Select-Object Name, DistinguishedName
    if ($ouList.name -eq $department) {
        if ($null -eq $division) {
            continue
        }
        else {
            $departmentPath = $ouList.DistinguishedName
            New-ADOrganizationalUnit -Name $division -Path $departmentPath -ProtectedFromAccidentalDeletion $false #Создание новых OU
            writeLog "Создана OU - $($division)" #Минилогирование
        }
    }
    else {
            New-ADOrganizationalUnit -Name $department -Path $corePath -ProtectedFromAccidentalDeletion $false #Создание новых OU
            writeLog "Создана OU - $($department)" #Минилогирование
    }   
}





function writeLog {
    Param ($logString)
    Write-Output $logString
    Write-Output $logString >> $logFile
}
$date = Get-Date -f yyyy-MM-dd-HHmmss
$logFile = "Create OU_" + $date + ".log"
$folderPath = "C:\results"
#Проверка наличия папки, куда будем складывать логи
if (-not (Test-Path $folderPath -PathType Container)) {
    New-Item -ItemType Directory -Path $folderPath -ErrorAction SilentlyContinue | Out-Null # Если папки нет, то создаем её
}
$logFile = Join-Path $folderPath $logFile #Формируем лог файл
