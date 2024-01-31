$OU = (Import-Csv "C:\1\OU.csv").OU # Список  OU, которые надо создать. 
#$allUsers = Import-Csv "C:\yourPath\usersall.csv" # Список всех сотрудников и их подразделения согласно Штатки. Подразделения должны иметь такие же названия как и файле ввыше. 
$corePath = "OU=Company,DC=DomainName,DC=local" # Корень нашей OU в которой будут создаваться контейнеры
#$existUsers = Get-ADUser -Filter * -SearchBase $corePath | select name, samaccountname # Все сотрудники в АД 
#Создание новых OU 
$userOU = "Users"
$computersOU = "Computers"
$corePath
foreach($element in $OU){
    New-ADOrganizationalUnit -Name $element -Path $corePath #Создание новых OU
    write-host "Создана OU - " $element #Минилогирование
    $subCorePath = "OU="+$element+","+$corePath
    New-ADOrganizationalUnit -Name $userOU -Path $subCorePath #Создание новых OU
    New-ADOrganizationalUnit -Name $computersOU -Path $subCorePath #Создание новых OU
    write-host "Создана OU для пользователей и компьютеров  " #Минилогирование
}
