$data = Import-Csv 'C:\1\userf.csv' -Delimiter "," # Список всех сотрудников из старого домена со всеми необходимыми атрибутами 
foreach ($a in $data) {

    $Name = $data.DisplayName | Write-Host
    $GivenName = $data.GivenName | Write-Host
    $Surname = $data.Surname | Write-Host
    $Company = '"Р7 Групп"' | Write-Host
    $userPrincipalName = $data.UserPrincipalName | Write-Host
    $Department = $data.Department | Write-Host
    $Description = $data.Title | Write-Host
    $DisplayName = $data.DisplayName | Write-Host
    $EmailAddress = $data.EmailAddress | Write-Host
    $Enabled = $true | Write-Host
    # $Path              = $OU
    $SamAccountName = $data.SamAccountName | Write-Host
    $Title = $data.Title
    #$AccountPassword   = $userPassword 
    $OfficePhone = $data.OfficePhone   | Write-Host


}


