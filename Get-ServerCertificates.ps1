<#
    Name: Get-ServerCertificates.ps1
    Version: 0.2
    Author: Zac Molyneux
    Updated: 01/11/2023
#>

$servers = Import-csv "CSV_Location"
$creds = Get-Credentials

$allCerts = @()

foreach($s in $servers){
    try{
        $allCerts += Invoke-Command -ComputerName $s.ServerName -Credential $creds -ArgumentList $s.Application -ErrorAction Stop -ScriptBlock {
            $returnObjects_My = @()

            $localCerts = Get-ChildItem Cert:\LocalMachine\My,Cert:\LocalMachine\WebHosting -Recurse

            $returnObjects_My = $localCerts | ForEach-Object {
                $CommonName = $_ | Select-Object @{n="CommonName";e={($_.Subject).Split(',')[0]}} |
                    Select-Object -ExpandProperty CommonNAme |
                    ForEach-Object {$_.trimStart("CN=")}

                $date = $_.NotAfter
                $date = $date.GetDateTimeFormats()[97]

                $issuer = $_ | Select-Object -ExpandProperty Issuer

                $FriendlyName = $_ | Select-Object -ExpandProperty FriendlyName

                $SansFormatted = ($_.Extension | where {$_.Oid.FriendlyName -eq "Subject Alternative Name"})
                if($SansFormatted -ne $null) {$SansFormatted = $SansFormatted.format($true)};

                $returnObjects = New-Object -TypeName PSObject -Property ([ordered]@{
                    'Expiry' = $date;
                    'Server' = $env:COMPUTERNAME;
                    'Application' = $args[0];
                    'FriendlyName' = $FriendlyName;
                    'CommonName' = $CommonName;
                    'SaNs' = $SansFormatted;
                    'Issuer' = $issuer;   
                })
            }
        }
    }
    catch{
        Write-Error $_
        break
    }
}