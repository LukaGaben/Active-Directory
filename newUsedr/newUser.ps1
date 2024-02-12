#------------------------------------------------Функции#------------------------------------------------#
# Функция для генерации пароля
# Для генерации пароля используется : знаки препинания, цифры и английский алфавит. За исключением спорных символов.
function Get-Password ($length = 10) {
    $punctuation = 33..46 # Знаки препинания в таблице ASCII
    $digits = 50..57 #Цифры в таблице ASCII
    $letters = 65..72 + 74..75 + 78 + 80..90 + 97..104 + 106..107 + 109..110 + 112..122 #Буквы английского алфавита
    $randomCharacters = $punctuation + $digits + $letters
    $passwordArray = Get-Random -Count $length -InputObject $randomCharacters
    $password = -join ($passwordArray | ForEach-Object { [char]$_ })
    return $password
} 
# Функция для транслитирации логина
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
#------------------------------------------------Логирование------------------------------------------------#
#Функция написания лога
function writeLog {
    Param ($logString)
    Write-Output $logString
    Write-Output $logString >> $logFile
}
$date = Get-Date -f yyyy-MM-dd-HHmmss
$logFileName = "Create User_" + $date + ".log"
$folderPath = "C:\results"
#Проверка наличия папки, куда будем складывать логи
if (-not (Test-Path $folderPath -PathType Container)) {
    New-Item -ItemType Directory -Path $folderPath -ErrorAction SilentlyContinue | Out-Null # Если папки нет, то создаем её
}
$logFile = Join-Path $folderPath $logFileName #Формируем лог файл
#------------------------------------------------Общие данные------------------------------------------------#
writeLog "Импорт файлов `n"
$userData = Import-Csv C:\1\useerData.csv 
$core = "OU=Р7 Групп,DC=r7-group,DC=local" #Путь до кореной OU
$ouList = Get-ADOrganizationalUnit -SearchBase $core -filter *   #Получаем список OU которые относятся к департаментам
$usersAD = Get-aduser -Filter * -Properties * #Список всех сотрудников
#------------------------------------------------Формируем логин------------------------------------------------#
function Get-Login {
    param (
        $userData
    )
    $userFullName = ($userData.FullName).Trim() # Помещаем полное ФИО в переменную
    $userSurname, $userName, $userMidlName = $userFullName -split ' ' -ne ''# Разбиваем ФИО на свои переменные 
    #Проверка, что Отчество не пустое
    if (($null -eq $userName) -or ($null -eq $userSurname) -or ($null -eq $userMidlName)) {
        writeLog "ФИО указанно не полностью. Работа скрипта завершина "
        break
    }
    writeLog "Создание логина...."
    $userShortName = (Get-Translit "$($userName[0]).$userSurname") #Формируем логин и отправляем его в транлитерацию 
    if ($usersAD.samaccountname -contains $userShortName) {
        #Проверям, существует ли уже такой логин
        $userShortName = (Get-Translit "$($userName[0])+$($userMidlName[0]).$userSurname") # Если такой логин найден, то формируем новый с использованием отчества 
    }   
    writeLog "Логин для $($userFullName) - $($userShortName)`n"
    $loginData = [PSCustomObject]@{
        userFullName  = $userFullName
        userShortName = $userShortName
        userSurname   = $userSurname
        userName      = $userName
        userMidlName  = $userMidlName 
    }
    return  $loginData
}
$login = Get-Login $userData 
#------------------------------------------------Поиск Руководителя------------------------------------------------#
$manager = ($userData.Manager).Trim() # ФИО руководителя
writeLog "Поиск руководителя"  
$managerAD = $usersAD | Where-Object { $_.DisplayName -like "*$manager*" } # Ищем сотрудника по ФИО
if ($null -eq $managerAD) {
    writeLog "Руководитель не найден. Информация не будет заполнена в карточку сотрудника `n"
}
#------------------------------------------------Формирование пароля------------------------------------------------#
writeLog "Создание пароля для сотрудника $($userFullName)`n"
$userPasswordToCard = Get-Password
$userPassword = ConvertTo-SecureString -String $userPasswordToCard -AsPlainText -Force
#------------------------------------------------Выбор OU------------------------------------------------#
function Get-OU {
    param (
        $userData
    )
    $userDepartment = ($userData.Department).Trim() # Получаем департамент пользователя
    $userDivision = ($userData.Division).Trim() # Получаем подразделение пользователя
    # Ищем OU для департамента и подразделения пользователя
    $OUDepartment = $ouList | Where-Object { $_.Name -eq $userDepartment }
    $OUDivision = $ouList | Where-Object { $_.Name -eq $userDivision }
    # Выводим информацию в лог о начале проверки OU
    if ($OUDivision) {
        $OU = $OUDivision.DistinguishedName
    }
    elseif ($OUDepartment) {
        # Если OU для департамента существует, используем его
        $OU = $OUDepartment.DistinguishedName
    }
    else { 
        # Если ни одного подходящего OU не найдено, помещаем учетную запись в корневой OU
        $OU = $core
    }
    return $OU
}
$OU = Get-OU $userData
writeLog "Учетная запись будет создана в $($OU) `n"
#------------------------------------------------Сбор всех данных вместе ------------------------------------------------#
$ipPhone = ($userData.phone).Trim()
#ХЭШ талиблица для других атрибутов
$other = @{
    ipPhone = $ipPhone
}
# Основная ХЭЩ таблица для заполнения необходимых атрибутов
$userAttrubute = @{
    Name              = $login.userFullName
    GivenName         = $login.userName
    Surname           = $login.userSurname
    Company           = '"Р7 Групп"'
    userPrincipalName = $login.userShortName + "@r7-group.local"
    Department        = $userData.Division.Trim()
    Description       = $userData.Title.Trim()
    DisplayName       = $login.userFullName
    EmailAddress      = $login.userShortName + "@r7-group.ru"
    Enabled           = $true
    Manager           = $managerAD
    Path              = $OU
    SamAccountName    = $login.userShortName
    Title             = $userData.Title.Trim() 
    AccountPassword   = $userPassword 
    OfficePhone       = "+7(495)988-47-77#$($ipPhone)"
    OtherAttributes   = $other
}
#------------------------------------------------Создание учетной записи------------------------------------------------#
writeLog "Создание учетной записи сотрудника "
try {
    New-aduser @userAttrubute # Запускаем создание учетной записи 
    writeLog "Учетная запись создана успешно"
    writeLog $login.userShortName
    writeLog $userPasswordToCard 
}
catch [Microsoft.ActiveDirectory.Management.ADIdentityAlreadyExistsException] {
    # Обработка ошибки если учетка есть 
    $errorMessage = "Error: Такая учетная записоь уже существует"
    writeLog $errorMessage
}
catch {
    # Общая обработка ошибок
    $errorMessage = "An unexpected error occurred. $_"
    writeLog $errorMessage
}
Start-Sleep -Seconds 5 #Пауза для синхронизации 
#------------------------------------------------Добавление в группы------------------------------------------------#
function Add-NewUserTOGroup {
    param (
        $userData
    )
    #Получаем название группы из названия OU
    $department = (($OU.Split(",") -replace "OU=", "")[0]).Trim() 
    $department = $department.Split(" ")[0]
    #Проверяем группы и ищем нружные 
    $newUser = $login.userShortName
    if ($userData.Lead -like "*ДА*") { #Если сотрудник является руководителем
        if ($ouGroup = Get-ADGroup -Filter { Name -like "*G Руководители*" } -SearchBase $OU) {
            Add-ADGroupMember -Identity $ouGroup -Members $newUser
        }
        else {
            writeLog "Нет группы руководителя. Необходимо будет ее создать. Сотрдуник получил стандартные права"
            $department = "*$department*"
            $ouGroup = Get-ADGroup -Filter { Name -like $department } -SearchBase $OU
            Add-ADGroupMember -Identity $ouGroup -Members $newUser
        }
    }
    else {
        writeLog "Сотрудник добавлен в группы отдела"
        $department = "*$department*"
        $ouGroup = Get-ADGroup -Filter { Name -like $department } -SearchBase $OU
        Add-ADGroupMember -Identity $ouGroup -Members $newUser
    }
}
Add-NewUserTOGroup -userData $userData
#------------------------------------------------Создание файла для сотрудника------------------------------------------------#
$userData = $userData.FullName
$logFileName = $userDATA + "_" + $date + ".log"
$logFile = Join-Path $folderPath $logFileName 
writeLog "Логин -  $($login.userShortName)"
writeLog "Пароль =  $($userPasswordToCard)"
