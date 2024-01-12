$users = get-aduser -Filter {manager -eq "a.tarakanov"} 
foreach ($user in $users){
    get-aduser -Identity $user -Properties *|select Name, manager
    #set-aduser -Identity $user -Manager $null
    get-aduser -Identity $user -Properties *|select Name, manager
}