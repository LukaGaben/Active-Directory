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
# Функция для записи логов
function writeLog {
    Param ($logString)
    Write-Output $logString
    Write-Output $logString >> $logFile
}
# Начало формирования имени логов 
$date = Get-Date -f yyyy-MM-dd-HHmmss
$logFileName = "NFTS_" + $date + ".log"
$folderPath = "C:\results"
#Проверка наличия папки, куда будем складывать логи
if (-not (Test-Path $folderPath -PathType Container)) {
    New-Item -ItemType Directory -Path $folderPath -ErrorAction SilentlyContinue | Out-Null # Если папки нет, то создаем её
}
$logFile = Join-Path $folderPath $logFileName #Формируем лог файл
# Функция получения прав на папке 
function Get-Nfts {
    param (
        [string]$Path
    )
    $output = @() # Пустой массив куда будем складывать результат 
    $folderAccess = Get-Item -Path $Path 
    $folderACL = (Get-Item -Path $folderAccess.FullName | Get-Acl).Access | Select-Object -Property IdentityReference, FileSystemRights, AccessControlType, IsInherited
    $folderACL | Add-Member -MemberType NoteProperty -name "path" -Value $Path
    $output += $folderACL
    $output
}
#_______________________________________________________________________________________________________________________________________________________________________________________________________________#

# Сначала получаем данные по корню DOM
$corePath = "\\ukkalita.local\iptg\Дивизион управления недвижимостью\DOM"
$folders = Get-ChildItem -Path $corePath -Directory 
$pathDOM = New-FolderFromPath $corePath
$logDOM = Join-Path $pathDOM "DOM.csv"
Get-Nfts $corePath | select IdentityReference, FileSystemRights, AccessControlType, IsInherited, path | Export-csv $logDOM -Encoding Default -Delimiter ";" -NoTypeInformation
$childFolder = @() #Массив куда будем складывать конечный результат 
foreach ($folder in $folders) {
    $parentFolder = get-nfts $folder.fullname # Получаем путь родительской папки 
    $subFolders = Get-ChildItem -Path $folder.FullName -Directory -Recurse # список всех папок внутри родительской
    $NFTS = (($folder.FullName).replace("\\ukkalita.local\iptg\Дивизион управления недвижимостью\", "")).replace("\", "__") # части имени
    $logFileName = $NFTS + ".csv" # конечное имя 
    $parentLogFileName = "parent " + $NFTS + ".csv" # имя для родительской папки 
    # цикл для получения прав 
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
        $childFolder += $a # получаем данные 
    }
    $resultNFTSFolderPath = New-FolderFromPath $folder.fullname
    $parentLogFileNameLog = Join-Path $resultNFTSFolderPath $parentLogFileName
    $log = Join-Path $resultNFTSFolderPath $logFileName
    $parentFolder | select IdentityReference, FileSystemRights, AccessControlType, IsInherited, path | Export-csv $parentLogFileNameLog -Encoding Default -Delimiter ";" -NoTypeInformation
    $childFolder | select IdentityReference, FileSystemRights, AccessControlType, IsInherited, path | Export-csv $log -Encoding Default -Delimiter ";" -NoTypeInformation
}