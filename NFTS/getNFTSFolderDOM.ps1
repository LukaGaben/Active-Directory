$nftsFolderPath = "C:\result\NFTS"
# Если папки нет, то создаем
if (-not (Test-Path $nftsFolderPath -PathType Container)) {
    New-Item -ItemType Directory -Path $nftsFolderPath -ErrorAction SilentlyContinue | Out-Null
}
$groupFolderPath = "C:\result\GROUPS"
if (-not (Test-Path $groupFolderPath -PathType Container)) {
    New-Item -ItemType Directory -Path $groupFolderPath -ErrorAction SilentlyContinue | Out-Null
}
$logFolderPath = "C:\result\LOG"
if (-not (Test-Path $logFolderPath -PathType Container)) {
    New-Item -ItemType Directory -Path $logFolderPath -ErrorAction SilentlyContinue | Out-Null
}
$resultPath = "C:\result"
# Получаем текущие права доступа для пути
$CurrentAcl = Get-Acl -Path $resultPath
# Задаем параметры нового правила доступа
$identity = "UKKALITA\G_NFTS_RESULTS_TEST"
$fileSystemRights = "FullControl"
# Создаем новое правило доступа
$fileSystemAccessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList ($identity, $fileSystemRights, "ContainerInherit, ObjectInherit", "None", "Allow")
# Проверяем, содержится ли заданное правило доступа в текущих правах доступа
$ruleExists = $CurrentAcl.Access | Where-Object { $_.IdentityReference.Value -eq $fileSystemAccessRule.IdentityReference.Value -and $_.FileSystemRights -eq $fileSystemAccessRule.FileSystemRights }
# Если правило доступа не существует, то добавляем его
if (-not $ruleExists) {
    # Добавляем правило доступа к текущим правам доступа
    $CurrentAcl.AddAccessRule($fileSystemAccessRule)
    # Применяем новые права доступа рекурсивно ко всем подпапкам и файлам
    Set-Acl -Path $resultPath -AclObject $CurrentAcl
} 