$corePath = "\\ukkalita.local\iptg\Дивизион управления недвижимостью\DOM"
$DOM = (Get-Acl $corePath).Access | Select-Object FileSystemRights, AccessControlType, IsInherited, IdentityReference
$insideDOM = Get-ChildItem $corePath

foreach ($a in $insideDOM) {

    (Get-Acl $a.FullName).Access | Where-Object { $_.IsInherited -eq $false } |ft

}