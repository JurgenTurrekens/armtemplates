clear

$subscriptionID= "b5a01522-681d-495a-a8be-bbe85747b61f"
$networkingResourceGroup = "networking-rg"
# Get name of VM to be deployed, and truncate to 15 characters if needed
$virtualMachineName = Read-Host "Please provide the name for the new VM (15 characters max, will be truncated)"
Write-Output "`r`n"

$virtualMachineName = if ($virtualMachineName.length -gt 15) { $virtualMachineName.substring(0, 15) } else { $virtualMachineName }


# Define network interface name (default concatenate in template does not work)
# TO-DO: make it work, lazy bones

$networkInterfaceName = $virtualMachineName + "-nic"


# Select the environment we will be deploying in, and define vnet spoke accordingly 
# To-Do: subselection of subnet, and multiple spokes per environment.


[string[]]$environments = 'Test', 'Acceptation', 'Production'

Write-Output "Please choose the environment to deploy the VM in:"


1..$environments.Length | foreach-object { Write-Output "$($_): $($environments[$_-1])" }


[ValidateScript({$_ -ge 1 -and $_ -le $environments.Length})]
[int]$choice = Read-Host "Press the number to select an environment"

$vnet = switch ($choice)
{
    1 {"spoke-207-vnet"; break}
    2 {"spoke-205-vnet"; break}
    3 {"spoke-201-vnet"; break}
    default {"Please select an environment that is listed; break"}

}


# Select the Machine size we will be deploying


[string[]]$sizes = 'Small', 'Standard', 'Large'

Write-Output "`r`n"
Write-Output "Please choose the size of the VM:"


1..$sizes.Length | foreach-object { Write-Output "$($_): $($sizes[$_-1])" }


[ValidateScript({$_ -ge 1 -and $_ -le $sizes.Length})]
[int]$choice = Read-Host "Press the number to select a size"

$size = switch ($choice)
{
    1 {"small"; break}
    2 {"standard"; break}
    3 {"large"; break}
    default {"Please select a size that is listed; break"}

}


# Set virtualMachineSize parameter in function of selected size, can be changed in script without touching template


$virtualMachineSize = switch ($size)

{
    small      {"Standard_B2s"; break}
    standard   {"Standard_D2s_v3"; break}
    large      {"Standard_D8s_v3"; break}
    default    {"Please select a size that is listed; break"}

}


# Define resource-group based on 


$rgname = switch($vnet)

{

    spoke-201-vnet {"production-servers-rg"; break}
    spoke-205-vnet {"acceptation-servers-rg"; break}
    spoke-207-vnet {"test-servers-rg"; break}
}


Write-Output "`n"
$datadiskneeded = Read-Host "Do you want to add an extra data disk to this VM? (y/n)"
if ($datadiskneeded -eq 'y') {
        $disksize = Read-Host "Please specify size of disk in GB's"
        $datadiskname = $virtualMachineName+'-datadisk1'
        }


$Credentials = (Get-Credential -Message 'Enter the domain join credentials' -UserName 'MYWORKPLACE\sccm_ad_action')
$Password = $Credentials.GetNetworkCredential().Password


Write-Output "`r`n"
Write-host "The VM" $virtualMachineName "will be deployed on vnet" $vnet "using the size" $virtualMachineSize "in resource group" $rgname 
Write-host "Please wait for JSON exit results"


#concatenate $vnet into $virtualNetworkID

$virtualNetworkID = "/subscriptions/"+$subscriptionID+"/resourceGroups/"+$networkingResourceGroup+"/providers/Microsoft.Network/virtualNetworks/"+$vnet


# Do the actual deployment
az group deployment create --name DeployVM --resource-group $rgname --template-file template.json --parameters parameters.json --parameters virtualMachineName=$virtualMachineName adminPassword="cr4ZY!!f0X.." virtualMachineSize=$virtualMachineSize virtualNetworkId=$virtualNetworkID  networkInterfaceName=$networkInterfaceName
# JSONAddDomain template to join the domain
az group deployment create --resource-group $rgname --name $virtualMachineName --template-uri https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vm-domain-join-existing/azuredeploy.json --parameters vmList=$virtualMachineName domainJoinUserName="MYWORPLACE\sccm_ad_action" domainJoinUserPassword=$password domainFQDN="ad.sea-invest.net" ouPath="OU=Servers,OU=Computers,OU=INF,OU=BE,OU=SI,DC=ad,DC=sea-invest,DC=net"


if ($datadiskneeded -eq 'y') {
        write-host "creating and attaching disk"
        az vm disk attach -g $rgname --vm-name $virtualMachineName --name $datadiskname --new --size-gb $disksize --sku Standard_LRS 
    }


  