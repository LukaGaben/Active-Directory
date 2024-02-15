$corePpath = "\\ukkalita.local\iptg\Дивизион управления недвижимостью\DOM\Shared docs c Коткова"
$folders = Get-ChildItem -Path $corePpath -Directory 
$DOM = Get-NFTS $corePpath


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


#________________________________________________________________________________________________________________________________________________________________________________________________________________#
foreach ($folder in $folders) {
    $folFolder = (Get-Item $folder.fullName).FullName # Данные по папке текущей 
    $subFolders = Get-ChildItem -Path $folFolder -Directory -Recurse
    
    
    
    $logFileName = $NFTS + ".csv" 
    $log = Join-Path $resultNFTSFolderPath $logFileName
    
    $dd | select IdentityReference, FileSystemRights, AccessControlType, IsInherited, path, AreAccessRulesProtected | Export-csv $log -Encoding Default -Delimiter "," -NoTypeInformation
}


function AddResultFoldes {
    param (
        $folder
    )
    $NFTS = (($folder.FullName).replace("\\ukkalita.local\iptg\Дивизион управления недвижимостью\", "")).replace("\", "__")
    $nftsFolderPath = "C:\results\NFTS\"
    # если папки нет = то создаем
    if (-not (Test-Path  $nftsFolderPath -PathType Container)) {
        New-Item -ItemType Directory -Path  $nftsFolderPath -ErrorAction SilentlyContinue | Out-Null # Если папки нет, то создаем её
    }
    $resultNFTSFolderPath = $nftsFolderPath + $folder
    New-Item -ItemType Directory -Path $resultNFTSFolderPath -ErrorAction SilentlyContinue | Out-Null # Если папки нет, то создаем её
}