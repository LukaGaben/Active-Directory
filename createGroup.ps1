$data = Import-Csv C:\1\group.csv
$corePath = "OU=Р7 Групп,DC=r7-group,DC=local"

$ouList = Get-ADOrganizationalUnit -SearchBase $corePath -filter * | Select-Object name, DistinguishedName  #Получаем список OU которые относятся к департаментам
foreach ($element in $data) {
    $groupName = ($element.group).Trim()
    $department = ($element.department).trim()
    $ouPath = $ouList | Where-Object { $_.Name -like "*$department*" }
    $ouPath
   
    if ($ouPath) {
  
        $fullName = "G_" + $groupName
        New-ADGroup -name $fullName -GroupScope Global -Path $ouPath.DistinguishedName
    }
    
    break
}
