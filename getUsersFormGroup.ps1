#Ввод имени с консоли 
Param(
    [Parameter (Mandatory = $true, Position = 1)]
    [string] $groupName
) 
$groupName = $groupName.Trim()
function Get-UserInfo {
    param ()
    $users = @() #Переменная куда сохроняем данные 
    $usersGroupName = Get-ADGroupMember -Identity $groupName
    foreach ($userGroupName in $usersGroupName ) {
        $objectClass = (Get-ADObject -Identity $userGroupName.DistinguishedName -Properties objectClass).objectClass
        if ($objectClass -eq "user") {
            $temp = Get-ADUser -Identity $userGroupName -Properties * | select Name, Company
            $users += $temp
        }
        elseif ($objectClass -eq "group") {
            Write-Host "Это группа, а не пользователь $($userGroupName.Name)"
            $users += $userGroupName
        }
        else {
            Write-Host "Неопределенный тип объекта для: $($userGroupName.Name)"
        }
    }  
    return $users
}
if (Get-ADGroup -Filter { Name -eq $groupName }) {
    $usersInfo = Get-UserInfo $groupName
    # Создание папки, где будут лежать результаты
    $folderPath = "C:\results"
    # Проверка существования папки
    if (-not (Test-Path $folderPath -PathType Container)) {
        # Если папки нет, то создаем её
        New-Item -ItemType Directory -Path $folderPath -ErrorAction SilentlyContinue | Out-Null
    }
    $nameFile = "Входят в $groupName.csv"
    $filePath = Join-Path $folderPath $nameFile # Формирование полного пути к файлу
    $usersInfo | Select-Object Name, Company | Export-Csv -Path $filePath -Encoding UTF8 -Delimiter ";" -NoTypeInformation  # Экспорт данных в CSV-файл
    Write-host "Результат сохранен в папке " $filePath 
}
else {
    Write-Host "Такой группы нет или ошибка в названии группы"
}
