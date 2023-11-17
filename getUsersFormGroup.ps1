#Ввод имени с консоли 
Param(
[Parameter (Mandatory=$true, Position=1)]
[string] $groupName
) 
#Проверка групп. Если ошибка, то вывести сообщение
try {
    $usersGroupName = Get-ADGroupMember -Identity $groupName #.trim()
}
catch {
    Write-Host "Нет такой группы или ошибка в названии"
}
$usersInfo = @() #Переменная куда сохроняем данные 
foreach ($userGroupName in $usersGroupName ){
    $temp = Get-ADUser -Identity $userGroupName -Properties * | select Name, DistinguishedName
    $temp.DistinguishedName = $temp.DistinguishedName -replace ',OU=IPTG,DC=ukkalita,DC=local', '' 
    $temp.DistinguishedName = ($temp.DistinguishedName -replace 'OU=', '').Split(",",2)[1]
    $usersInfo +=$temp
}  
# Создание папки, где будут лежать результаты
$folderPath = "C:\results"
# Проверка существования папки
if (-not (Test-Path $folderPath -PathType Container)) {
    # Если папки нет, то создаем её
    New-Item -ItemType Directory -Path $folderPath -ErrorAction SilentlyContinue
}
$filePath = Join-Path $folderPath $nameFile # Формирование полного пути к файлу
$usersInfo | Select-Object Name, DistinguishedName | Export-Csv -Path $filePath -Encoding UTF8 -Delimiter ";" -NoTypeInformation  # Экспорт данных в CSV-файл

 


