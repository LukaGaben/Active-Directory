
#import data from file 
$userData = Import-Csv C:\1\useerData.csv 
$globalDomain = "@r7-group.ru"

$core = "OU=R7 Group,DC=r7-group,DC=local"
$company = '"Р7 Групп"'
$ouList = Get-ADOrganizationalUnit -SearchBase $core -filter * | Select-Object -ExpandProperty DistinguishedName
$usersAD = Get-aduser -Filter * -Properties *
function Creat-User {
    param (
        $userData
    )
    $userFullName = $userData.FullName
    $userSurname, $userName, $userMidlName = $userFullName -split ' '  
    $usershortName = (Get-Translit "$($userName[0]).$userSurname") 
    if ($usersAD.contains($usershortName)) {
        $usershortName = (Get-Translit "$($userName[0])+$($userMidlName[0]).$userSurname")
    }
    $manager = $userData.Manager
    $managerAD = Get-aduser -Filter { displayname -eq $manager }
    $AccountPassword = ConvertTo-SecureString -String (Get-Password) -AsPlainText -Force
    $userDepartment = $userData.Department
    $userDivision = $userData.Division
    $jobTitle = $userData.Title 
    $userOU = "OU=" + $userDepartment+ "," + $core 
    $usreMailAddress = $usershortName + $globalDomain 
    $ipPhone = $userData.phone
    $userOfficePhone = "+7(495)988-47-77#$($ipPhone)"
    if (($ouList.contains($userOU)) -and ($null -ne $userOU)) { 
        $OU = $userOU
    }
    else { 
        Write-Host "Ошибка в название департамента и департамент не задан. Учетная сотрудника $($userFullName) запись будет помещена в корень"
        $OU = $core
    }
    $a = @{
        ipPhone = $ipPhone
    }
    $userAttrubute = @{
        Name            = $usershortName
        GivenName       = $userName
        Surname         = $userSurname
        Company         = $company
        Department      = $userDivision
        Description     = $jobTitle
        DisplayName     = $userFullName
        EmailAddress    = $usreMailAddress
        Enabled         = $true
        Manager         = $managerAD
        Path            = $OU
        SamAccountName  = $usershortName
        Title           = $jobTitle
        AccountPassword = $AccountPassword
        OfficePhone     = $userOfficePhone
        OtherAttributes = $a

    }

    New-aduser @userAttrubute 
}
function Get-Password ($length = 10) {
    $punctuation = 33..46
    $digits = 50..57
    $letters = 65..72 + 74..78 + 80..90 + 97..107 + 109..122
    $randomCharacters = $punctuation + $digits + $letters
    $passwordArray = Get-Random -Count $length -InputObject $randomCharacters
    $password = -join ($passwordArray | ForEach-Object { [char]$_ })
    return $password
}
function Get-Translit {
    param([string]$inString)
    #Создаем хэш-таблицу соответствия русских и латинских символов
    $Translit = @{
        [char]'а' = "a"
        [char]'А' = "a"
        [char]'б' = "b"
        [char]'Б' = "b"
        [char]'в' = "v"
        [char]'В' = "v"
        [char]'г' = "g"
        [char]'Г' = "g"
        [char]'д' = "d"
        [char]'Д' = "d"
        [char]'е' = "e"
        [char]'Е' = "e"
        [char]'ё' = "e"
        [char]'Ё' = "e"
        [char]'ж' = "zh"
        [char]'Ж' = "zh"
        [char]'з' = "z"
        [char]'З' = "z"
        [char]'и' = "i"
        [char]'И' = "i"
        [char]'й' = "y"
        [char]'Й' = "y"
        [char]'к' = "k"
        [char]'К' = "k"
        [char]'л' = "l"
        [char]'Л' = "l"
        [char]'м' = "m"
        [char]'М' = "m"
        [char]'н' = "n"
        [char]'Н' = "n"
        [char]'о' = "o"
        [char]'О' = "o"
        [char]'п' = "p"
        [char]'П' = "p"
        [char]'р' = "r"
        [char]'Р' = "r"
        [char]'с' = "s"
        [char]'С' = "s"
        [char]'т' = "t"
        [char]'Т' = "t"
        [char]'у' = "u"
        [char]'У' = "u"
        [char]'ф' = "f"
        [char]'Ф' = "f"
        [char]'х' = "kh"
        [char]'Х' = "kh"
        [char]'ц' = "ts"
        [char]'Ц' = "ts"
        [char]'ч' = "ch"
        [char]'Ч' = "ch"
        [char]'ш' = "sh"
        [char]'Ш' = "sh"
        [char]'щ' = "sch"
        [char]'Щ' = "sch"
        [char]'ъ' = ""
        [char]'Ъ' = ""
        [char]'ы' = "y"
        [char]'Ы' = "y"
        [char]'ь' = ""
        [char]'Ь' = ""
        [char]'э' = "e"
        [char]'Э' = "e"
        [char]'ю' = "yu"
        [char]'Ю' = "yu"
        [char]'я' = "ya"
        [char]'Я' = "ya"
        [char]' ' = " " #пробел
        [char]'.' = '.'

    }
    $outString = "";
    $chars = $inString.ToCharArray();
    foreach ($char in $chars) { $outString += $Translit[$char] }
    return $outString;
}
Creat-User $userData