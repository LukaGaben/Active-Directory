function Get-Login {
    param (
        $userData
    )
    $userFullName = ($userData.FullName).Trim() # Помещаем полное ФИО в переменную
    $userSurname, $userName, $userMidlName = $userFullName -split ' ' -ne ''# Разбиваем ФИО на свои переменные 
    #Проверка, что Отчество не пустое
    if (($null -eq $userName) -or ($null -eq $userSurname) -or ($null -eq $userMidlName)) {
        break
    }
    $userShortName = (Get-Translit "$($userName[0]).$userSurname") #Формируем логин и отправляем его в транлитерацию 
    if ($usersAD.samaccountname -contains $userShortName) {
        #Проверям, существует ли уже такой логин
        $userShortName = (Get-Translit "$($userName[0])+$($userMidlName[0]).$userSurname") # Если такой логин найден, то формируем новый с использованием отчества 
    }   
    $loginData = [PSCustomObject]@{
        userFullName  = $userFullName
        userSurname   = $userSurname
        userName      = $userName
        userMidlName  = $userMidlName 
        userShortName = $userShortName
    }
    return  $loginData
}
