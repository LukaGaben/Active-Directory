$existUsersName = Import-Csv "C:\001\existUsersName.csv"
$usersFired = Import-Csv "C:\001\users.csv"
# Получить данные о пользователях Active Directory
$users = Get-ADUser -Filter *
$a = @()
# Пройти по каждому уволенному сотруднику
foreach ($userFired in $usersFired) {
    $matchedUser = $users | Where-Object { $_.Name -eq $userFired.name }
    # Write-Host "____"
    if ($matchedUser) {
        if ($matchedUser.Enabled -eq $true <#-and $existUsersName.Contains($matchedUser#>) {
            #Write-Host "$($matchedUser.Name) "
            $a += $matchedUser
        
        }
    }
}
$a | select Name, UserPrincipalName, SamAccountName, Enabled, DistinguishedName   | Export-Csv "C:\001\notBlocked1.csv" F