
############################################################################################################################################
#                                                                                                                                          #
# Задача данного скрипта навести порядок в OU. А именно создать новые контейнеры и перенести туда сотрудников согласно штатному расписанию #
#                                                                                                                                          #
############################################################################################################################################
#Нужно создать 2 csv файла в которых будут указаны необходимые данные, а именно:
#1) Список OU, которые надо назвать(Название отделов. Заголовок - OU)
#2) Список сотрудников, которые есть в компании и которых надо перенести в новые OU или в существующие. Заголовки OU - для контейнеров и Useer -  для пользователей 



$OU = (Import-Csv "C:\yourPath\OU.csv").OU # Список  OU, которые надо создать. 
$allUsers = Import-Csv "C:\yourPath\usersall.csv" # Список всех сотрудников и их подразделения согласно Штатки. Подразделения должны иметь такие же названия как и файле ввыше. 
$corePath = "OU=Company,DC=DomainName,DC=local" # Корень нашей OU в которой будут создаваться контейнеры
$existUsers = Get-ADUser -Filter * -SearchBase $corePath | select name, samaccountname # Все сотрудники в АД 
#Создание новых OU 
foreach($element in $OU){
    New-ADOrganizationalUnit -Name $element -Path $corePath #Создание новых OU
    write-host"Создана OU - " $element #Минилогирование
}

foreach($users in $allUsers){ 
    $userOU = ($users."OU ").Trim()
    $user = ($users.user).Trim()
    $allOU = (Get-ADOrganizationalUnit -Filter {Name -eq $userOU }  -SearchBase $corePath| select DistinguishedName).DistinguishedName #Получаем данные контейнера.
    $userAD = Get-ADUser -Filter {name -eq $user} -SearchBase $corePath # Получаем данные по струдникам внутри контейнера. Возможно, надо будет сделать еще и проверку на существование такой уз
    Move-ADObject -Identity $userAD -TargetPath $allOU #Перемещаем сотрудников в нужную OU
    Write-Host "Пользователь " $userAD "перенесен в " $allOU #Минилогирование
 }




