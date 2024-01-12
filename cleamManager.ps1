$users = get-aduser -Filter {manager -eq "userName"} 
foreach ($user in $users){
    get-aduser -Identity $user -Properties *|select Name, manager #chek manager is exists
    set-aduser -Identity $user -Manager $null # remove data from attribute
    get-aduser -Identity $user -Properties *|select Name, manager #chek manager isn't exists
}