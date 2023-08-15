<#
TODO:
- lots of room for optimization here, possibly create GUI tool for QoL use
- producing duplicate entries
- commit to using sessions or not
- create functions to pass values
- make it easy to change servers / folders / what to check
#>

$servers = `
"Server01",
"Server02"

# recusively check all folders below these for file and content matches
$CheckRootFolder = `
"C:\Application\",
"D:\TEMP\"

$CheckFiles = `
"*.csv",
"*exe.config",
"*web.config"

$CheckContent = `
"Some Content",
"Other Stuff"

$sessions = New-PSSession -ComputerName $servers

$output = Invoke-Command -Session $sessions -ArgumentList $CheckRootFolder,$CheckFiles,$CheckContent -ScriptBlock {
    write-host $env:ComputerName -ForegroundColor Green
    $RFIFolders = Get-ChildItem -Path $args[0] 

    $Files = @()
    Foreach($fileType in $args[1]){
        $Files += $RFIFolders | Get-ChildItem -Recurse -Filter $fileType
    }

    if($Files -ne $null){
        if($Files.Count -eq 1){
            Write-host $Files.FullName -ForegroundColor Green
        }else{
            for($i = 0; $i -lt $Files.Count; $i++){
                Write-Host $Files[$i].FullName -ForegroundColor Green
            }
        }
    }

    $CheckContent = $args[2]

    if($CheckContent -ne $null){
        For($FileIter = 0; $FileIter -lt $Files.Count; $FileIter++){
            For($i = 0; $i -lt $CheckContent.Count; $i++){
                $search = ($Files[$FileIter] | Get-Content | Select-String -Pattern $CheckContent[$i]).Matches.Success
                if($search){
                    Write-Host "$($Files[$FileIter].FullName) : has $($CheckContent[$i])" -ForegroundColor Green
                }
            }
        }
    }
    Write-Host " "
}

$output

$sessions | Remove-PSSession