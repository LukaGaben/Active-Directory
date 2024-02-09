$path =  "OU=Р7 Групп,DC=r7-group,DC=local"
$ou = Get-ADOrganizationalUnit -Filter * -SearchBase $path

foreach ($element in $ou) {
    $path2 = $element.DistinguishedName
    if ($element.name -like "Департамент") {
        $depGroupNameLead = "G " + $element.Name + " Руководители"
        Add-NewGroup $depGroupNameLead $path2
    } else {
        $groupName = "G " + $element.Name
        $groupNameLead = "G " + $element.Name + " Руководители"
        
        Add-NewGroup $groupName $path2
        Add-NewGroup $groupNameLead $path2
    }
}
function Add-NewGroup {
    param (
        $name,
        $path
    )
    New-ADGroup -Name $name -GroupScope Global -Path $path
    Write-Host "Группа $($name) создана"
}
