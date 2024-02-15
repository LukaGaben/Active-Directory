$corePpath = "\\ukkalita.local\iptg\Дивизион управления недвижимостью\DOM\"
$folders = Get-ChildItem -Path $corePpath -Directory 

function writeLog {
    Param ($logString)
    Write-Output $logString
    Write-Output $logString >> $logFile
}
$date = Get-Date -f yyyy-MM-dd-HHmmss
$logFileName = "NFTS_" + $date + ".log"
$folderPath = "C:\results"
#Проверка наличия папки, куда будем складывать логи
if (-not (Test-Path $folderPath -PathType Container)) {
    New-Item -ItemType Directory -Path $folderPath -ErrorAction SilentlyContinue | Out-Null # Если папки нет, то создаем её
}
$logFile = Join-Path $folderPath $logFileName #Формируем лог файл
function Get-Nfts {
    param (
        [string]$Path
    )
    $output = @()
    #$output += "DIR: $Path `n"
    $folderAccess = Get-Item -Path $Path #-Directory 
    $folderACL = (Get-Item -Path $folderAccess.FullName | Get-Acl).Access | Select-Object -Property IdentityReference, FileSystemRights, AccessControlType, IsInherited, AreAccessRulesProtected
    $folderACL | Add-Member -MemberType NoteProperty -name "path" -Value $Path
    $output += $folderACL
    $output
}
$resultFolderPath = "C:\results\NFTS\"
if (-not (Test-Path $resultFolderPath -PathType Container)) {
    New-Item -ItemType Directory -Path $resultFolderPath -ErrorAction SilentlyContinue | Out-Null # Если папки нет, то создаем её
}
$dd = @()
foreach ($folder in $folders) {
    $subFolders = Get-ChildItem -Path $corePpath -Directory -Recurse
    $NFTS = (( $folder.FullName).replace("\\ukkalita.local\iptg\Дивизион управления недвижимостью\", "")).replace("\", "__")
    $logFileName = $NFTS + ".csv" 
    $resultFolderPath = $resultFolderPath + $folder
    foreach ($subFolder in $subFolders) {
        $subFoldersPath = $subFolder.FullName
        try {
            $subFoldersPath 
            $a = Get-Nfts $subFoldersPath 
        }
        catch {
            $errorMessage = $_.Exception.Message
            writeLog "Error in folder $subFoldersPath : $errorMessage"
        }
        
        $dd += $a
    }
    New-Item -ItemType Directory -Path $resultFolderPath -ErrorAction SilentlyContinue | Out-Null # Если папки нет, то создаем её   
    $log = Join-Path $resultFolderPath $logFileName
    $dd | select IdentityReference, FileSystemRights, AccessControlType, IsInherited, AreAccessRulesProtected, path | Export-csv $log -Encoding Default -Delimiter "," -NoTypeInformation
}