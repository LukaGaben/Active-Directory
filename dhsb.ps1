$groupName = "fa RO HR Обучение"
$groupMembers = Get-ADGroupMember -Identity $groupName

foreach ($member in $groupMembers) {
    $objectClass = (Get-ADObject -Identity $member.DistinguishedName -Properties objectClass).objectClass

    if ($objectClass -eq "user") {
        Write-Host "Пользователь: $($member.Name)"
    } elseif ($objectClass -eq "group") {
        Write-Host "Группа: $($member.Name)"
    } else {
        Write-Host "Неопределенный тип объекта для: $($member.Name)"
    }
}