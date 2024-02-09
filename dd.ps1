$userData = Import-Csv C:\1\useerData.csv
<#function New-Login {
    param (
        $userData
    )
    $userFullName = ($userData.FullName).Trim() # Помещаем полное ФИО в переменную
    $userSurname, $userName, $userMidlName = $userFullName -split ' ' -ne ''# Разбиваем ФИО на свои переменные 
    #Проверка, что Отчество не пустое
    if (($null -eq $userName) -or ($null -eq $userSurname) -or ($null -eq $userMidlName)) {
        #writeLog "ФИО указанно не полностью. Работа скрипта завершина "
        break
    }
    #writeLog "Создание логина...."
    $usershortName = (Get-Translit "$($userName[0]).$userSurname") #Формируем логин и отправляем его в транлитерацию 
    if ($usersAD.samaccountname -contains $usershortName) {
        #Проверям, существует ли уже такой логин
        $usershortName = (Get-Translit "$($userName[0])+$($userMidlName[0]).$userSurname") # Если такой логин найден, то формируем новый с использованием отчества 
    }   
    #writeLog "Логин для $($userFullName) - $($usershortName)`n"
    return $usershortName, $userName,$userSurname,$userMidlName
}
(New-Login $userData)[0]
#>

$person = [PSCustomObject]@{
    $userFullName = ($userData.FullName).Trim() # Помещаем полное ФИО в переменную
    $userSurname, $userName, $userMidlName = $userFullName -split ' ' -ne ''# Разбиваем ФИО на свои переменные 
    #Проверка, что Отчество не пустое
    if (($null -eq $userName) -or ($null -eq $userSurname) -or ($null -eq $userMidlName)) {
        #writeLog "ФИО указанно не полностью. Работа скрипта завершина "
        break
    }
    #writeLog "Создание логина...."
    $usershortName = (Get-Translit "$($userName[0]).$userSurname") #Формируем логин и отправляем его в транлитерацию 
    if ($usersAD.samaccountname -contains $usershortName) {
        #Проверям, существует ли уже такой логин
        $usershortName = (Get-Translit "$($userName[0])+$($userMidlName[0]).$userSurname") # Если такой логин найден, то формируем новый с использованием отчества 
    }   
    #writeLog "Логин для $($userFullName) - $($usershortName)`n"
    return $usershortName, $userName,$userSurname,$userMidlName

}
$person.

function Get-Translit {
    param([string]$inString)
    #Создаем хэш-таблицу соответствия русских и латинских символов
    $Translit = @{
        [char]'а' = "a"; [char]'А' = "a"; [char]'б' = "b"; [char]'Б' = "b"; [char]'в' = "v"; [char]'В' = "v"; [char]'г' = "g"; [char]'Г' = "g";
        [char]'д' = "d"; [char]'Д' = "d"; [char]'е' = "e"; [char]'Е' = "e"; [char]'ё' = "e"; [char]'Ё' = "e"; [char]'ж' = "zh"; [char]'Ж' = "zh";
        [char]'з' = "z"; [char]'З' = "z"; [char]'и' = "i"; [char]'И' = "i"; [char]'й' = "y"; [char]'Й' = "y"; [char]'к' = "k"; [char]'К' = "k";
        [char]'л' = "l"; [char]'Л' = "l"; [char]'м' = "m"; [char]'М' = "m"; [char]'н' = "n"; [char]'Н' = "n"; [char]'о' = "o"; [char]'О' = "o";
        [char]'п' = "p"; [char]'П' = "p"; [char]'р' = "r"; [char]'Р' = "r"; [char]'с' = "s"; [char]'С' = "s"; [char]'т' = "t"; [char]'Т' = "t";
        [char]'у' = "u"; [char]'У' = "u"; [char]'ф' = "f"; [char]'Ф' = "f"; [char]'х' = "kh"; [char]'Х' = "kh"; [char]'ц' = "ts"; [char]'Ц' = "ts";
        [char]'ч' = "ch"; [char]'Ч' = "ch"; [char]'ш' = "sh"; [char]'Ш' = "sh"; [char]'щ' = "sch"; [char]'Щ' = "sch"; [char]'ъ' = ""; [char]'Ъ' = "";
        [char]'ы' = "y"; [char]'Ы' = "y"; [char]'ь' = ""; [char]'Ь' = ""; [char]'э' = "e"; [char]'Э' = "e"; [char]'ю' = "yu"; [char]'Ю' = "yu";
        [char]'я' = "ya"; [char]'Я' = "ya"; [char]' ' = " "; [char]'.' = "."        
    }
    $outString = ""
    $chars = $inString.ToCharArray()
    foreach ($char in $chars) { 
        $outString += $Translit[$char] 
    }
    return $outString
}
