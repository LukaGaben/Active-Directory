$allUsers = (Import-Csv "C:\001\users.csv").name
$path = "OU=Company,DC=DomainName,DC=local"
foreach ($user in $allUsers) {
    $usersAD = (Get-ADUser -Filter {surname -eq $user} -SearchBase $path| select SamAccountName).SamAccountName
    Add-ADGroupMember -Identity "fa DOM К31_Лобачевского RW"  -Members $usersAD
    write-host "Добавлен сотрудник " $usersAD
}