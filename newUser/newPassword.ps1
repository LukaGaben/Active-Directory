function Get-Password ($length = 10) {
    $punctuation = 33..46 # Знаки препинания в таблице ASCII
    $digits = 50..57 #Цифры в таблице ASCII
    $letters = 65..72 + 74..75 + 78 + 80..90 + 97..104 + 106..107 + 109..110 + 112..122 #Буквы английского алфавита
    $randomCharacters = $punctuation + $digits + $letters
    $passwordArray = Get-Random -Count $length -InputObject $randomCharacters
    $password = -join ($passwordArray | ForEach-Object { [char]$_ })
    return $password
}