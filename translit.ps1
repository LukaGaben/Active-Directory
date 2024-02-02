function Get-Password ($length = 10) {
    $punctuation = 33..46
    $digits = 50..57
    $letters = 65..72 + 74..75 + 78 + 80..90 + 97..104 + 106..107 + 109..110 +112..122
    $randomCharacters = $punctuation + $digits + $letters
    $passwordArray = Get-Random -Count $length -InputObject $randomCharacters
    $password = -join ($passwordArray | ForEach-Object { [char]$_ })
    return $password
} 
Get-Password