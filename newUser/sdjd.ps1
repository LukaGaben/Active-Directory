Import-Module C:\1\translit.ps1
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
        $data,
        $OU
    ) 
    $userPasswordToCard = Get-Password
    $userPassword = ConvertTo-SecureString -String $userPasswordToCard -AsPlainText -Force
    $user = $data.SamAccountName
    $folderPath = "C:\results"
    $loginFileName = $data.Name + ".txt"
    $loginFile = Join-Path $folderPath $loginFileName 
    $userAttrubute = @{
        Name              = $data.DisplayName
        GivenName         = $data.GivenName
        Surname           = $data.Surname
        Company           = '"Р7 Групп"'
        userPrincipalName = $data.UserPrincipalName.ToLower()
        Department        = $data.Department
        Description       = $data.Title
        DisplayName       = $data.DisplayName
        EmailAddress      = $data.EmailAddress
        Enabled           = $true
        Path              = $OU
        SamAccountName    = $data.SamAccountName.ToLower()
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
        set-aduser -Identity $user -ipPhone $ipPhone 
    }
    
}
function Add-NewUserTOGroup {
    $OU
    # $OU = $userData.DistinguishedName -replace "CN=[^,]+,", "" #Получаем полный адрес уз в домене и удаляем данныпе про пользователя
    #Получаем название группы из названия OU
    $department = (($OU.Split(",") -replace "OU=", "")[0]).Trim()#Вытаскиваем название департамента 
    #Проверяем группы и ищем нружные 
    if ($OU -eq $core) {
        continue
    }
    $userData = $existUser
    $newUser = $userData.SamAccountName #Получаем логин пользователя
    $newUser 
    if ($userData.Title -like "*Директор*", "*Руководитель*", "*Начальник*") {
        #Если сотрудник является руководителем
        $ouGroup = Get-ADGroup -Filter { Name -like "*Руководители*" } -SearchBase $OU | select -ExpandProperty samaccountname
        $ouGroup 
        if ($ouGroup) {
            Add-ADGroupMember -Identity $ouGroup -Members $newUser
        }
        else {
            writeLog "Нет группы руководителя. Необходимо будет ее создать. Сотрдуник получил стандартные права"
            $department = "*$department*"
            $ouGroup = Get-ADGroup -Filter { Name -like $department } -SearchBase $OU | select -ExpandProperty samaccountname
            Add-ADGroupMember -Identity $ouGroup -Members $newUser
        }
    }
    else {
        writeLog "Сотрудник добавлен в группы отдела"
        $department = "G " + $department
        $ouGroup = Get-ADGroup -Filter { Name -like $department } -SearchBase $OU | select -ExpandProperty samaccountname
        Add-ADGroupMember -Identity $ouGroup -Members $newUser
    }
}
function writeLogin {
    Param ($logString)
    Write-Output $logString
    Write-Output $logString >> $loginFile
}
foreach ($userFromOldDomain in $data) {
    
    $OU = Get-OU $userFromOldDomain 
    New-UserAD -data $userFromOldDomain -OU $OU
    $existUser = Get-ADUser -Identity $userFromOldDomain.samaccountname
    Add-NewUserTOGroup
}
$usersAD = Get-aduser -Filter * -Properties *
Start-Sleep -Seconds 10
foreach ($userFromOldDomain in $data) {
    $manager = (($userFromOldDomain.manager).replace("CN=", "")).split(",")[0] 
    $managerAD = $usersAD | Where-Object { $_.DisplayName -ilike "*$manager*" } # Ищем сотрудника по ФИО 
    if ($null -eq $managerAD) {
        writeLog "Руководитель не найден. Информация не будет заполнена в карточку сотрудника `n"
        $userFromOldDomain.Name
        continue
    }
    else {
        set-aduser -Identity $userFromOldDomain.SamAccountName -Manager $managerAD    
    }
}
#------------------------------------------------Создание файла для сотрудника------------------------------------------------#
