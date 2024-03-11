﻿Import-Module C:\1\translit.ps1
Import-Module C:\1\writelog.ps1
Import-Module C:\1\newPassword.ps1
$core = "OU=Р7 Групп,DC=r7-group,DC=local" #Путь до кореной OU
writelog "Импортируем данные со старого домена"
$data = Import-Csv 'C:\1\user.csv' -Delimiter "," # Список всех сотрудников из старого домена со всеми необходимыми атрибутами 
#Функуия для получения OU 
function Get-OU {
    param (
        $data
    )
    $depOU = (($data.DistinguishedName).replace("OU=", "")).split(",")[1] #Название OU из старого домена 
    $ouList = Get-ADOrganizationalUnit -SearchBase $core -Filter *
    $OUDepartment = $ouList | Where-Object { $_.Name -eq $depOU }
    $OUDivision = $ouList | Where-Object { $_.Name -eq $data.Department }
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
#____________________________________________________________________________________________________________________________________________________________#
#Прописать логику выбора OU 
function New-UserAD {
    param (
        $data
    ) 
    $userPasswordToCard = Get-Password
    $userPassword = ConvertTo-SecureString -String $userPasswordToCard -AsPlainText -Force
    $user = $data.SamAccountName
    $folderPath = "C:\results"
    $loginFileName = $data.Name + ".txt"
    $loginFile = Join-Path $folderPath $loginFileName 
    $loginName = ($data.SamAccountName).ToLower()
    $userAttrubute = @{
        Name              = $data.DisplayName
        GivenName         = $data.GivenName
        Surname           = $data.Surname
        Company           = '"Р7 Групп"'
        userPrincipalName = $loginName + "@r7-group.ru"
        Department        = $data.Department
        Description       = $data.Title
        DisplayName       = $data.DisplayName
        EmailAddress      = ($data.EmailAddress).ToLower()
        Enabled           = $true
        Path              = $OU
        SamAccountName    = $loginName
        Title             = $data.Title
        AccountPassword   = $userPassword 
        OfficePhone       = $data.OfficePhone 
    }
    try {
        New-aduser @userAttrubute ## Запускаем создание учетной записи 
        writeLog "Учетная запись создана успешно"
        writeLogin $data.UserPrincipalName
        writeLogin $userPasswordToCard 
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityAlreadyExistsException] {
        # Обработка ошибки если учетка есть 
        $errorMessage = "Error: Такая учетная записоь уже существует"
        writeLog $errorMessage
    }
    catch [Microsoft.ActiveDirectory.Management.Commands.NewADUser] {
        WriteLog "Пароль не подходит $($data.Name)"
        $userPasswordToCard = Get-Password
        $userPassword = ConvertTo-SecureString -String $userPasswordToCard -AsPlainText -Force
        Set-ADAccountPassword -Identity $user -NewPassword $userPassword 
        Enable-ADAccount -Identity $user
        writeLogin "Логин = $($data.UserPrincipalName)"
        writeLogin "Пароль = $($userPasswordToCard)"
    }
    catch {
        #Общая обработка ошибок
        $errorMessage = "An unexpected error occurred. $_"
        writeLog $errorMessage
    }
    if ($null -eq $data.ipPhone) {
        continue
    }
    else {
        $ipPhone = $data.ipPhone
        set-aduser -Identity $user -Replace @{ipPhone = $ipPhone}
    }  
}
function Add-NewUserTOGroup {
    param (
        $userData,
        $OU
    ) 
    Write-Host "Add-NewUserTOGroup $($userData)"
    $department = (($OU.Split(",") -replace "OU=", "")[0]).Trim()#Вытаскиваем название департамента 
    #Проверяем группы и ищем нружные 
    if ($OU -eq $core) {
        continue
    }
    $user = $userData.Name
    writeLog "Сотрудник $($user) добавлен в группы отдела $($department)"
    $department = "G " + $department
    $ouGroup = Get-ADGroup -Filter { Name -like $department } -SearchBase $OU | select -ExpandProperty samaccountname
    Add-ADGroupMember -Identity $ouGroup -Members $userData
    $list = "Директор", "руководитель", "начальник", "главный бухгалтер"
    foreach ($word in $list) {
        if ($userData.Title -like "*$word*") {
            # Вывод пользователя
            $ouGroup = Get-ADGroup -Filter { Name -like "*Руководители*" } -SearchBase $OU | select -ExpandProperty samaccountname
            if ($ouGroup) {
                Add-ADGroupMember -Identity $ouGroup -Members $userData
            }
            else {
                writeLog "Нет группы руководителя. Необходимо будет ее создать. Сотрдуник получил стандартные права"
            }

        }
    }
}
function writeLogin {
    Param ($logString)
    Write-Output $logString
    Write-Output $logString >> $loginFile
}
foreach ($userFromOldDomain in $data) {
    $OU = Get-OU $userFromOldDomain 
    New-UserAD $userFromOldDomain
}
foreach ($userFromOldDomain in $data) {
    $existUser = Get-ADUser -Identity $userFromOldDomain.samaccountname -Properties *
    # Получение DistinguishedName пользователя
    $OU = $existUser.DistinguishedName
    $OU = ($OU -split ",OU=")[1..$($OU -split ",OU=").Count] -join ",OU="
    $OU = "OU=" + $OU
    # Использование регулярного выражения для извлечения OU
    # Вывод OU
    Add-NewUserTOGroup -userData $existUser -OU $OU
    $userName = $userFromOldDomain.Name
    Write-Host "This is $($userName) `n"
    $manager = $userFromOldDomain.Manager
    if ($manager) {
        $manager = ($manager -replace "CN=", "").Split(",")[0]
        $managerAD = Get-ADUser -Filter { Name -like $manager } -Properties *

        if (-not $managerAD) {
            writeLog "Руководитель '$manager' не найден. Информация не будет заполнена в карточку сотрудника."
            continue
        }
        else {
            
            Set-ADUser -Identity $userFromOldDomain.SamAccountName -Manager $managerAD
        }
    }
    else {
        writeLog "Руководитель не указан для пользователя '$userName'."
    }
}
