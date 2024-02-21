function New-FolderFromPath {
    param (
        $folder # Сюда путь или объект по выборки fullname
    )
    # Разбиваем строку
    $a = $folder.split("\")  
    # Получаем предпоследний элемент
    $parentNFTS = $a[-2]
    # Получаем последний элемент
    $NFTS = $a[-1]
    # Базовая папка, где будут создаваться папки для скрипта Get-NFTS
    $nftsFolderPath = "C:\results\NFTS\"
    # Если папки нет, то создаем
    if (-not (Test-Path $nftsFolderPath -PathType Container)) {
        New-Item -ItemType Directory -Path $nftsFolderPath -ErrorAction SilentlyContinue | Out-Null
    }
    # Создаем путь к папке, которую нужно проверить
    $cheakFolder = Join-Path $nftsFolderPath $parentNFTS
    # Получаем список папок в базовой папке
    $listCheakFolder = (Get-ChildItem $nftsFolderPath).FullName
    # Если папка существует, то создаем путь к новой папке
    if ($listCheakFolder -contains $cheakFolder) {
        $resultNFTSFolderPath = join-path $cheakFolder $NFTS
    }
    else {
        $resultNFTSFolderPath = Join-Path $nftsFolderPath $NFTS
    }
    # Создаем новую папку
    New-Item -ItemType Directory -Path $resultNFTSFolderPath -ErrorAction SilentlyContinue | Out-Null
    return $resultNFTSFolderPath
}
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
    $folderACL = (Get-Item -Path $folderAccess.FullName | Get-Acl).Access | Select-Object -Property IdentityReference, FileSystemRights, AccessControlType, IsInherited
    $folderACL | Add-Member -MemberType NoteProperty -name "path" -Value $Path
    $output += $folderACL
    $output
}
#_______________________________________________________________________________________________________________________________________________________________________________________________________________#
$corePath = "\\ukkalita.local\iptg\Дивизион управления недвижимостью\DOM"
$folders = Get-ChildItem -Path $corePath -Directory 
$pathDOM = New-FolderFromPath $corePath
$logDOM = Join-Path $pathDOM "DOM.csv"
Get-Nfts $corePath | select IdentityReference, FileSystemRights, AccessControlType, IsInherited, path | Export-csv $logDOM -Encoding Default -Delimiter ";" -NoTypeInformation
$dd = @()
foreach ($folder in $folders) {
    $f = get-nfts $folder.fullname
    $subFolders = Get-ChildItem -Path $folder.FullName -Directory -Recurse
    $NFTS = (($folder.FullName).replace("\\ukkalita.local\iptg\Дивизион управления недвижимостью\", "")).replace("\", "__")
    $logFileName = $NFTS + ".csv" 
    $logFileName2 = "parent " + $NFTS + ".csv" 
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
    $resultNFTSFolderPath = New-FolderFromPath $folder.fullname
    $log = Join-Path $resultNFTSFolderPath $logFileName2
    $log2 = Join-Path $resultNFTSFolderPath $logFileName
    $f | select IdentityReference, FileSystemRights, AccessControlType, IsInherited, path | Export-csv $log2 -Encoding Default -Delimiter ";" -NoTypeInformation
    $dd | select IdentityReference, FileSystemRights, AccessControlType, IsInherited, path | Export-csv $log -Encoding Default -Delimiter ";" -NoTypeInformation
}