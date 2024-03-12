Param(
    [Parameter (Mandatory = $true, Position = 1)]
    [string] $corePath
)
#_______________________________________________________________________________________________________________________________________________________________________________________________________________#
function writeLog {
    Param ($logString)
    Write-Output $logString
    Write-Output $logString >> $logFile
}
# Начало формирования имени логов 
$date = Get-Date -f yyyy-MM-dd-HHmmss
$logFileName = "NFTS_" + $date + ".log"
$folderPath = "C:\result\LOG"
#Проверка наличия папки, куда будем складывать логи
$logFile = Join-Path $folderPath $logFileName #Формируем лог файл
writeLog "Проверка каталога: $($corePath)"


function errorLog {
    Param ($logString)
    Write-Output $logString
    Write-Output $logString >> $errorLogFile
}
# Начало формирования имени логов 
$date = Get-Date -f yyyy-MM-dd-HHmmss
$errorLogFileName = "Error_" + $date + ".log"
$folderPath = "C:\result\LOG"
#Проверка наличия папки, куда будем складывать логи
$errorLogFile = Join-Path $folderPath $errorLogFileName #Формируем лог файл
writeLog "Проверка каталога: $($corePath)"

#_______________________________________________________________________________________________________________________________________________________________________________________________________________#

function New-FolderFromPath {
    param (
        $folder # Сюда путь или объект по выборки fullname
    )
    # $folder = "\\ukkalita.local\iptg\Дивизион управления недвижимостью\Департамент IT сопровождения"
    # Разбиваем строку
    $a = $folder.split("\")  
    # Получаем предпоследний элемент
    $parentNFTS = $a[-2]
    # Получаем последний элемент
    $NFTS = $a[-1]
    # Базовая папка, где будут создаваться папки для скрипта Get-NFTS
    $nftsFolderPath = "C:\result\NFTS\"
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
#_______________________________________________________________________________________________________________________________________________________________________________________________________________#
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
#Тут нужно написать блок который будет содержать получения прав с корневой папки 
$coreFolderName = $corePath.Split("\")[-1] + ".csv"
writeLog "Создание основного каталога для хранения результата"
$folderResults = New-FolderFromPath $corePath # Создание папки 
$exportResulrtToFile = Join-Path $folderResults $coreFolderName # Формирование пути для логов
writeLog "Начало экспорта данных в файл $($exportResulrtToFile)"
$resultCoreFolder = Get-Nfts $corePath 
$resultCoreFolder | select IdentityReference, FileSystemRights, AccessControlType, IsInherited, path  | Export-Csv $exportResulrtToFile -Encoding UTF8 -Delimiter "|" -NoTypeInformation
$cheackFile = (Get-ChildItem $folderResults).FullName
if ($cheackFile -Contains ($exportResulrtToFile)) {
    writeLog "Файл $($coreFolderName) создался успешно `n"
}
else {
    writeLog "Файл $($coreFolderName) не создался в каталоге `n"
}
#_______________________________________________________________________________________________________________________________________________________________________________________________________________#
$listOfFoldersInCorePath = (Get-ChildItem $corePath -Directory).FullName
foreach ($folder in $listOfFoldersInCorePath) {
    writeLog "Создание каталога для $($folder)"
    $resultFolder = New-FolderFromPath $folder
    $resultsChild = @()
    writeLog "Получение прав для каталога $($folder)"
    $perantResults = Get-Nfts $folder 
    writeLog "Получение прав для всех каталогов внутри $($folder)"
    $childFolders = (Get-ChildItem $folder -Directory -Recurse).FullName
    foreach ($childFolder in $childFolders) {
        $subFoldersPath = $childFolder.FullName
        try {
            $subFoldersPath
            $permission = Get-Nfts $childFolder
            $resultsChild += $permission
        }
        catch {
            $errorMessage = $_.Exception.Message
            errorLog "Error in folder $subFoldersPath : $errorMessage"
        }
    }
    writeLog "Процесс получения прав для всех каталогов внутри $($folder) окончен `n"
    $resultPerantFolderName = "Perant__" + $folder.split("\")[-1] + ".csv"
    $resultFolderName = $folder.split("\")[-1] + ".csv"
    # 2 переменные  - в какой файл сливать данные 
    $exportResultPerantFolderName = Join-Path $resultFolder $resultPerantFolderName 
    $exportResultFolderName = Join-Path $resultFolder $resultFolderName
    writeLog "Выгружаем результаты в каталог $($resultFolder)"
    $perantResults | select IdentityReference, FileSystemRights, AccessControlType, IsInherited, path  | Export-Csv $exportResultPerantFolderName -Encoding UTF8 -Delimiter "|" -NoTypeInformation
    $resultsChild | select IdentityReference, FileSystemRights, AccessControlType, IsInherited, path | Export-Csv $exportResultFolderName -Encoding UTF8 -Delimiter "|" -NoTypeInformation
}

writeLog "Работа скрипта оконченна"