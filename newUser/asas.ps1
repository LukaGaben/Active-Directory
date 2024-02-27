Import-Module C:\1\writelog.ps1
function New-UserAD {
    param (
        $data,
        $OU
    )
    $other = @{
        ipPhone = $data.ipPhone
    }
    $userAttrubute = @{
        Name              = $data.DisplayName
        GivenName         = $data.GivenName
        Surname           = $data.Surname
        Company           = '"Р7 Групп"'
        userPrincipalName = $data.UserPrincipalName
        Department        = $data.Department
        Description       = $data.Title
        DisplayName       = $data.DisplayName
        EmailAddress      = $data.EmailAddress
        Enabled           = $true
        Path              = $OU
        SamAccountName    = $data.SamAccountName
        Title             = $data.Title
        AccountPassword   = $userPassword 
        OfficePhone       = $data.OfficePhone   
        OtherAttributes   = $other 
    }
    try {
        #New-aduser @userAttrubute ## Запускаем создание учетной записи 
        writeLog "Учетная запись создана успешно"
        writeLog $data.UserPrincipalName
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
}
$OU = "djfkdfjnkdfjnkdfjvk"