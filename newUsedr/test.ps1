
$corePpath = "\\ukkalita.local\iptg\Дивизион управления недвижимостью\DOM\Система качества, сертификаты"
$folders = Get-ChildItem -Path $corePpath -Directory -Recurse
$dd = @()
function Get-Nfts {
    param (
        [string]$Path
    )
    $output = @()
    #$output += "DIR: $Path `n"
    $folderAccess = Get-Item -Path $Path #-Directory 
    $folderACL = (Get-Item -Path $folderAccess.FullName | Get-Acl).Access | Select-Object -Property IdentityReference, FileSystemRights, AccessControlType, IsInherited
    $folderACL | Add-Member -MemberType NoteProperty -name "path" -Value $Path | ft
    $output += $folderACL
    $output
}

foreach ($folder in $folders) {
 
    $foldersPath = $folder.FullName
    $a = Get-Nfts $foldersPath |ft
    $dd += $a
    break
}
$dd
 $dd | select IdentityReference, FileSystemRights, AccessControlType, IsInherited, path| Export-csv C:\script\test.csv -Encoding UTF8 -Delimiter ";" -NoTypeInformation 
 


















 $corePpath = "\\ukkalita.local\iptg\Дивизион управления недвижимостью\DOM\Система качества, сертификаты"
$folders = Get-ChildItem -Path $corePpath -Directory -Recurse
$dd = @()
function Get-Nfts {
    param (
        [string]$Path
    )
    $output = @()
    #$output += "DIR: $Path `n"
    $folderAccess = Get-Item -Path $Path #-Directory 
    $folderACL = (Get-Item -Path $folderAccess.FullName | Get-Acl).Access | Select-Object -Property IdentityReference, FileSystemRights, AccessControlType, IsInherited
    $folderACL | Add-Member -MemberType NoteProperty -name "path" -Value $Path
    $output += $folderACL
    $output
}

foreach ($folder in $folders) {
 
    $foldersPath = $folder.FullName
    $a = Get-Nfts $foldersPath
    $dd += $a
}

$dd | select IdentityReference, FileSystemRights, AccessControlType, IsInherited, path | Export-csv C:\script\test.csv -Encoding Default -Delimiter "," -NoTypeInformation



$