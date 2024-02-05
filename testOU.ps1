#------------------------------------------------Логирование------------------------------------------------#
#Функция написания лога
function writeLog {
    Param ($logString)
    Write-Output $logString
    Write-Output $logString >> $logFile
}
$date = Get-Date -f yyyy-MM-dd-HHmmss
$logFile = "Create User_" + $date + ".log"
$folderPath = "C:\results"
#Проверка наличия папки, куда будем складывать логи
if (-not (Test-Path $folderPath -PathType Container)) {
    New-Item -ItemType Directory -Path $folderPath -ErrorAction SilentlyContinue | Out-Null # Если папки нет, то создаем её
}
$logFile = $folderPath + "\" + $logFile #Формируем лог файл
#------------------------------------------------Общие данные------------------------------------------------#
writeLog "Импорт файлов"
$userData = Import-Csv C:\1\useerData.csv 
$core = "OU=R7 Group,DC=r7-group,DC=local" #Путь до кореной OU
$ouList = Get-ADOrganizationalUnit -SearchBase $core -filter * | Select-Object -ExpandProperty DistinguishedName  #Получаем список OU которые относятся к департаментам
$usersAD = Get-aduser -Filter * -Properties * #Список всех сотрудников
#------------------------------------------------Формируем логин------------------------------------------------#
$userFullName = ($userData.FullName).Trim() # Помещаем полное ФИО в переменную
$userSurname, $userName, $userMidlName = $userFullName -split ' '  # Разбиваем ФИО на свои переменные 
#Проверка, что Отчество не пустое
if ($null -eq $userMidlName) {
    Write-Host "Не указанно отчество"
    writeLog "Не указанно отчество"

}
writeLog "Создание логина...."
$usershortName = (Get-Translit "$($userName[0]).$userSurname") #Формируем логин и отправляем его в транлитерацию 
if ($usersAD.samaccountname -contains $usershortName) {
    #Проверям, существует ли уже такой логин
    $usershortName = (Get-Translit "$($userName[0])+$($userMidlName[0]).$userSurname") # Если такой логин найден, то формируем новый с использованием отчества 
}   
writeLog "Логин создан для сотрудника $($userFullName) - $($usershortName)"
#------------------------------------------------Поиск Руководителя------------------------------------------------#
$manager = ($userData.Manager).Trim() # ФИО руководителя
writeLog "Поиск Руководителя"  
try {
    $managerAD = $usersAD | Where-Object { $_.DisplayName -like "*$manager*" } # Ищем сотрудника по ФИО
}
catch {
    writeLog "Ошибка, руководитель не найден"
}
#------------------------------------------------Формирование пароля------------------------------------------------#
writeLog "Создание пароля для сотрудника $($userFullName)"
$userPassword = ConvertTo-SecureString -String (Get-Password) -AsPlainText -Force
#------------------------------------------------Выбор OU------------------------------------------------#
$userDepartment = ($userData.Department).Trim() #Выбираем Департамент
$userOU = "OU=" + $userDepartment + "," + $core # Формируем название OU в которую надо положить УЗ
writeLog "Проверка контейнера" 
if (($ouList -contains $userOU) -and ($null -ne $userOU)) {
    # Если OU не пустая и есть в домене - то все ок
    $OU = "OU=User," + $userOU #Формируем окончательнный путь до OU
    writeLog "Учетная запись сотрудника $($userFullName) будет создана в $($OU)"
}
else { 
    writeLog "Ошибка в название департамента и департамент не задан. Учетная сотрудника $($userFullName) запись будет помещена в $OU"
    $OU = [ref]$core # Помещаем УЗ в Корень
}
#------------------------------------------------Сбор всех данных вместе ------------------------------------------------#
$ipPhone = ($userData.phone).Trim()
#ХЭШ талиблица для других атрибутов
$other = @{
    ipPhone = $ipPhone
}
# Основная ХЭЩ таблица
$userAttrubute = @{
    Name              = $userFullName
    GivenName         = $userName
    Surname           = $userSurname
    Company           = '"Р7 Групп"'
    userPrincipalName = $usershortName + "@r7-group.local"
    Department        = $userData.Division.Trim()
    Description       = $userData.Title.Trim()
    DisplayName       = $userFullName
    EmailAddress      = $usershortName + "@r7-group.ru"
    Enabled           = $true
    Manager           = $managerAD
    Path              = $OU
    SamAccountName    = $usershortName
    Title             = $userData.Title.Trim() 
    AccountPassword   = $userPassword 
    OfficePhone       = "+7(495)988-47-77#$($ipPhone)"
    OtherAttributes   = $other
}
writeLog "Создание учетной записи сотрудника "
try {
    New-aduser @userAttrubute 
    writeLog "Учетная запись создана успешно"

}
catch {
    writeLog "Ошибка создания учетной записи"
}
#Add-ADGroupMember -Identity "fa DOM К31_Лобачевского RW"  -Members $usersAD
function Get-Password ($length = 10) {
    $punctuation = 33..46
    $digits = 50..57
    $letters = 65..72 + 74..75 + 78 + 80..90 + 97..104 + 106..107 + 109..110 + 112..122
    $randomCharacters = $punctuation + $digits + $letters
    $passwordArray = Get-Random -Count $length -InputObject $randomCharacters
    $password = -join ($passwordArray | ForEach-Object { [char]$_ })
    return $password
} 

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
