$Pathes = Import-Csv "C:\001\path.csv"

foreach ($path in $Pathes) {
    $path = $path.name
    $corePath = "\\ukkalita.local\iptg\Дивизион управления недвижимостью\" + $Path
    $folders = Get-childitem $corePath -Directory
    $folders = $folders.fullname
    $b = @() 
    foreach ($folder in $folders) {
        if ($folder -ne "\\ukkalita.local\iptg\Дивизион управления недвижимостью\DOM") {
            Write-Host "We are here " $folder
            $allFolder = Get-childitem $folder -Recurse -Directory 
            $allFolder = $allFolder.fullName
            foreach ($bb in  $allFolder) {
                $a = get-acl -LiteralPath $folder | select Path, AreAccessRulesProtected
                $b += $a
                $a = get-acl -LiteralPath $bb | select Path, AreAccessRulesProtected
                if ($a.AreAccessRulesProtected -eq $true) {
                    $a.path = $a.Path -replace ".*::", ""
                    $b += $a
                }
            }
        }
        #$folderName = $folder -replace "\\ukkalita.local\iptg\Дивизион управления недвижимостью\Департамент эксплуатации объектов недвижимости", ""
        $folderName += $folder -replace [regex]::Escape("\\ukkalita.local\iptg\Дивизион управления недвижимостью\"), ""
    }
    $path 
    $b | Export-Csv "C:\001\3\$path.csv" -Encoding UTF8 -Delimiter ";" -NoTypeInformation 
}