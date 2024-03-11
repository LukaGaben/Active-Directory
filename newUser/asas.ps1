Import-Module C:\1\translit.ps1
Import-Module C:\1\writelog.ps1
Import-Module C:\1\newPassword.ps1
$core = "OU=Р7 Групп,DC=r7-group,DC=local" #Путь до кореной OU
writelog "Импортируем данные со старого домена"
$data = Import-Csv 'C:\1\user.csv' -Delimiter "," # Список всех сотрудников из старого домена со всеми необходимыми атрибутами 
#Функуия для получения OU 

#____________________________________________________________________________________________________________________________________________________________#
#Прописать логику выбора OU 

function Add-NewUserTOGroup {
    param (
        $userData,
        $OU
    ) 
    Write-Host "Add-NewUserTOGroup $($userData)"
    $department = (($OU.Split(",") -replace "OU=", "")[0]).Trim()#Вытаскиваем название департамента 
    $department
    #Проверяем группы и ищем нружные 
    if ($OU -eq $core) {
        continue
    }

    writeLog "Сотрудник добавлен в группы отдела $($department)"
    $department = "G " + $department
    $ouGroup = Get-ADGroup -Filter { Name -like $department } -SearchBase $OU | select -ExpandProperty samaccountname
    $ouGroup
    Add-ADGroupMember -Identity $ouGroup -Members $userData
    $list = "Директор", "руководитель", "начальник", "главный бухгалтер"


    foreach ($word in $list) {
        if ($userData.Title -like "*$word*") {
            # Вывод пользователя
            $ouGroup = Get-ADGroup -Filter { Name -like "*Руководители*" } -SearchBase $OU | select -ExpandProperty samaccountname
            if ($ouGroup) {
                Write-Host "Add"
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
        $existUser = Get-ADUser -Identity $userFromOldDomain.samaccountname

        # Получение DistinguishedName пользователя
        $OU = $existUser.DistinguishedName

        # Использование регулярного выражения для извлечения OU
        $OU = $OU -replace '^.*?,', ''

        # Вывод OU

        $existUser = $existUser.samaccountname
        Add-NewUserTOGroup -userData $existUser -OU $OU



        $userName = $userFromOldDomain.Name
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



    #------------------------------------------------Создание файла для сотрудника------------------------------------------------#
