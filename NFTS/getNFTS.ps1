Param(
    [Parameter (Mandatory = $true, Position = 1)]
    [string] $corePath
)
#_______________________________________________________________________________________________________________________________________________________________________________________________________________#
function writeLog {
    Param ($logString)
   
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

#_______________________________________________________________________________________________________________________________________________________________________________________________________________#function New-FolderFromPath {
function New-FolderFromPath {
    param (
        $folder # Сюда путь или объект по выборки fullname
    )

    $parentFolder = $folder.Split("\")[-2]
    Write-Host "$($parentFolder)"
    $folderName = Split-Path $folder -Leaf
    $baseFolderPath = "C:\result\NFTS\Дивизион управления недвижимостью"
    New-Item -ItemType Directory -Path $baseFolderPath -ErrorAction SilentlyContinue | Out-Null
    $baseFolderPathlast = Split-Path $baseFolderPath -Leaf
    if ($folderName -eq $baseFolderPathlast ) {
        Write-Host "Это хорошо папка есть "
        $resultFolderPath = $baseFolderPath
    }
    else {
        Write-Host "RWRE"
        $cheakFolder = Join-Path $baseFolderPath $parentFolder
        # Получаем список папок в базовой папке
        $listCheakFolder = (Get-ChildItem $baseFolderPath).FullName
        # Если папка существует, то создаем путь к новой папке
        if ($listCheakFolder -contains $cheakFolder) {
            $resultFolderPath = join-path $cheakFolder $folderName
        }
        else {
            $resultFolderPath = Join-Path $baseFolderPath $folderName
        }
        New-Item -ItemType Directory -Path $resultFolderPath -ErrorAction SilentlyContinue | Out-Null
    }  
    return $resultFolderPath    
}
#______________________________________________________________________________________________________________________________________________________________________________________________________________#
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
$folderResults = New-FolderFromPath $corePath # Создание папки 

$exportResulrtToFile = Join-Path $folderResults $coreFolderName # Формирование пути для логов
writeLog "Начало экспорта данных в файл $($exportResulrtToFile)"
Get-Nfts $corePath | select IdentityReference, FileSystemRights, AccessControlType, IsInherited, path  | Export-Csv $exportResulrtToFile -Encoding UTF8 -Delimiter "|" -NoTypeInformation
$cheackFile = (Get-ChildItem $folderResults).FullName
if ($cheackFile -Contains ($exportResulrtToFile)) {
    writeLog "Файл $($coreFolderName) создался успешно `n"
}
else {
    writeLog "Файл $($coreFolderName) не создался в каталоге `n"
}
$cheackFolder = (Get-ChildItem $folderResults).name
Start-Sleep -Seconds 10

#_______________________________________________________________________________________________________________________________________________________________________________________________________________#
$listOfFoldersInCorePath = (Get-ChildItem $corePath -Directory).FullName
foreach ($folder in $listOfFoldersInCorePath) {  
    $s = (Get-Item $folder).name
    if ($cheackFolder -contains ($s)) {
        Write-Host "Hahahaha"
        continue
    }
    else {
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

        $exportResultPerantFolderName = Join-Path $resultFolder $resultPerantFolderName 
        $exportResultFolderName = Join-Path $resultFolder $resultFolderName
        writeLog "Выгружаем результаты в каталог $($resultFolder)"
        $perantResults | select IdentityReference, FileSystemRights, AccessControlType, IsInherited, path  | Export-Csv $exportResultPerantFolderName -Encoding UTF8 -Delimiter "|" -NoTypeInformation
        $resultsChild | select IdentityReference, FileSystemRights, AccessControlType, IsInherited, path | Export-Csv $exportResultFolderName -Encoding UTF8 -Delimiter "|" -NoTypeInformation
        
    }
}
#>
writeLog "Работа скрипта оконченна"