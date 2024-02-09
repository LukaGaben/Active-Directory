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
$logFile = Join-Path $folderPath $logFile #Формируем лог файл







#------------------------------------------------Общие данные------------------------------------------------#
writeLog "Импорт файлов `n"
$userData = Import-Csv C:\1\useerData.csv 
$core = "OU=Р7 Групп,DC=r7-group,DC=local" #Путь до кореной OU
#$ouList = Get-ADOrganizationalUnit -SearchBase $core -filter * | Select-Object -ExpandProperty DistinguishedName  #Получаем список OU которые относятся к департаментам
#$usersAD = Get-aduser -Filter * -Properties * #Список всех сотрудников
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
   # if ($usersAD.samaccountname -contains $userShortName) {
        #Проверям, существует ли уже такой логин
    #    $userShortName = (Get-Translit "$($userName[0])+$($userMidlName[0]).$userSurname") # Если такой логин найден, то формируем новый с использованием отчества 
    #}   
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
$loginData = Get-Login $userData 

$loginData = Get-Login $userData 
break








#------------------------------------------------Поиск Руководителя------------------------------------------------#
$manager = ($userData.Manager).Trim() # ФИО руководителя
writeLog "Поиск руководителя"  
$managerAD = $usersAD | Where-Object { $_.DisplayName -like "*$manager*" } # Ищем сотрудника по ФИО
if ($null -eq $managerAD) {
    writeLog "Руководитель не найден. Информация не будет заполнена в карточку сотрудника `n"
}
#------------------------------------------------Формирование пароля------------------------------------------------#
writeLog "Создание пароля для сотрудника $($userFullName)`n"
$userPassword = ConvertTo-SecureString -String (Get-Password) -AsPlainText -Force
#------------------------------------------------Выбор OU------------------------------------------------#
$userDepartment = ($userData.Department).Trim() #Выбираем Департамент
$userOU = "OU=" + $userDepartment + "," + $core # Формируем название OU в которую надо положить УЗ
writeLog "Проверка OU" 
if (($ouList -contains $userOU) -and ($null -ne $userOU)) {
    # Если OU не пустая и есть в домене - то все ок
    $OU = "OU=User," + $userOU #Формируем окончательный путь до OU
    writeLog "Учетная запись сотрудника $($userFullName) будет создана в $($OU) `n"
}
else { 
    $OU = $core # Помещаем УЗ в Корень
    writeLog "Ошибка в название департамента и департамент не задан. Учетная сотрудника $($userFullName) запись будет помещена в $OU `n"
}
#------------------------------------------------Сбор всех данных вместе ------------------------------------------------#
$ipPhone = ($userData.phone).Trim()
#ХЭШ талиблица для других атрибутов
$other = @{
    ipPhone = $ipPhone
}
# Основная ХЭЩ таблица для заполнения необходимых атрибутов
$userAttrubute = @{
    Name              = $loginData.userFullName.Trim()
    GivenName         = $loginData.userName.Trim()
    Surname           = $loginData.userSurname.Trim()
    Company           = '"Р7 Групп"'
    userPrincipalName = $loginData.userShortName + "@r7-group.local"
    Department        = $userData.Division.Trim()
    Description       = $userData.Title.Trim()
    DisplayName       = $loginData.userFullName.Trim()
    EmailAddress      = $loginData.userShortName + "@r7-group.ru"
    Enabled           = $true
    Manager           = $managerAD
    Path              = $OU
    SamAccountName    = $loginData.userShortName.Trim()
    Title             = $userData.Title.Trim() 
    AccountPassword   = $userPassword 
    OfficePhone       = "+7(495)988-47-77#$($ipPhone)"
    OtherAttributes   = $other
}
$userAttrubute
#------------------------------------------------Создание учетной записи------------------------------------------------#
writeLog "Создание учетной записи сотрудника "
New-aduser @userAttrubute 
<#
try {
    New-aduser @userAttrubute # Запускаем создание учетной записи 
    writeLog "Учетная запись создана успешно"

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
#-
#>#-----------------------------------------------Добавление в группы------------------------------------------------#
#Add-ADGroupMember -Identity "fa DOM К31_Лобачевского RW"  -Members $usersAD

#------------------------------------------------Функции#------------------------------------------------
# Функция для генерации пароля
# Для генерации пароля используется : знаки препинания, цифры и английский алфавит. За исключением спорных символов.
$a = Get-Translit "авиаи"
$a