$domainName = $args[0]

$username = $args[1]

$password = $args[2]

Set-DnsClient `
    -InterfaceAlias "Ethernet*" `
    -ConnectionSpecificSuffix $domainName

$securePassword =  ConvertTo-SecureString $password `
    -AsPlainText `
    -Force

$cred = New-Object System.Management.Automation.PSCredential($username, $securePassword)
   
Add-Computer -DomainName $domainName -Credential $cred -Restart –Force