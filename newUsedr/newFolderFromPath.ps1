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
}
