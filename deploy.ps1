<#

.DESCRIPTION
  
    This script will gather the necessary input needed to deploy a VM to Azure in the Sea-Invest subscription.
    Parameters will be injected in the ARM template placeholders (github)

    This machine will be joined to the ad.sea-invest.net domain using the following domain join template:
    https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vm-domain-join-existing/azuredeploy.json

    Default SKU is Windows 2016 Small Disk. Can be changed in the default template specified (currently on personal Github).

    "imageReference": {
                        "publisher": "MicrosoftWindowsServer",
                        "offer": "WindowsServer",
                        "sku": "2016-Datacenter",
                        "version": "latest"


    Tags will be required for deployment, other tags will be inherited from the chosen resourcegroup/environment

.PARAMETER <Parameter_Name>
    
    Not parametrised. Otherwise you'd just run the resulting AZ command.. :-)

.NOTES
  Version:        1.0
  Author:         Turrekens Jurgen
  Creation Date:  29/10/2020
  Purpose/Change: Initial script development
  

#>

# Will pop-up login dialog and redirect to localhost:8400, which results in red warning. Can be changed to "az login --use-device-code" when ran from authorized machine.

az login
Clear-Host

$subscriptionID = "b5a01522-681d-495a-a8be-bbe85747b61f"
$networkingResourceGroup = "networking-rg"


# Get name of VM to be deployed, and truncate to 15 characters if needed

Clear-Host
$virtualMachineName = Read-Host "Please provide the name for the new VM (15 characters max, will be truncated)"
Write-Output "`r`n"

$virtualMachineName = if ($virtualMachineName.length -gt 15) { $virtualMachineName.substring(0, 15) } else { $virtualMachineName }

# Define network interface name (default concatenate in template does not work reliably)
# TO-DO: make it work, lazy bones

$networkInterfaceName = $virtualMachineName + "-nic"


# Select the environment we will be deploying in, and define vnet spoke name accordingly (prod=201, test=207, acc=205 etc..)

[string[]]$environments = 'Test', 'Acceptation', 'Production'

Write-Output "Please choose the environment to deploy the VM in:"

1..$environments.Length | foreach-object { Write-Output "$($_): $($environments[$_-1])" }

[ValidateScript( { $_ -ge 1 -and $_ -le $environments.Length })]
[int]$choice = Read-Host "Press the number to select an environment"

$vnet = switch ($choice) {
    1 { "spoke-207-vnet"; break }
    2 { "spoke-205-vnet"; break }
    3 { "spoke-201-vnet"; break }
    default { "Please select an environment that is listed; break" }

}


# Select the Machine size we will be deploying
# Results in 


[string[]]$sizes = 'Small', 'Standard', 'Large'

Write-Output "`r`n"
Write-Output "Please choose the size of the VM:"


1..$sizes.Length | foreach-object { Write-Output "$($_): $($sizes[$_-1])" }


[ValidateScript( { $_ -ge 1 -and $_ -le $sizes.Length })]
[int]$choice = Read-Host "Press the number to select a size"

$size = switch ($choice) {
    1 { "small"; break }
    2 { "standard"; break }
    3 { "large"; break }
    default { "Please select a size that is listed; break" }

}


# Set virtualMachineSize parameter in function of selected size, can be changed in script without touching template


$virtualMachineSize = switch ($size) {
    small { "Standard_B2ms"; break }
    standard { "Standard_D2s_v3"; break }
    large { "Standard_D8s_v3"; break }
    default { "Please select a size that is listed; break" }

}


# Define resource-group based on vnet selection


$rgname = switch ($vnet) {

    spoke-201-vnet { "production-servers-rg"; break }
    spoke-205-vnet { "acceptation-servers-rg"; break }
    spoke-207-vnet { "test-servers-rg"; break }
}


# Deploy in subnet, different from default subnet?


Write-Output "`n"

# default subnet = subnet1 (10.20x.1.0/24)

$subnetname = "subnet1"
$differentsubnetwanted = Read-Host "Do you want to a different subnet than the standard subnet1 (10.xxx.1.0/24) - (y/n)"
if ($differentsubnetwanted -eq 'y') {
        

        
    [string[]]$environments = 'subnet 1 (10.xxx.1.0/24)', 'subnet 2 (10.xxx.2.0/24)', 'subnet 3 (10.xxx.3.0/24)'


    Write-Output "Please choose the subnet to deploy the VM in:"
    Write-Output "`n"


    1..$environments.Length | foreach-object { Write-Output "$($_): $($environments[$_-1])" }


    [ValidateScript( { $_ -ge 1 -and $_ -le $environments.Length })]
    [int]$choice = Read-Host "Press the number to select a subnet"

    $subnetname = switch ($choice) {
        1 { "subnet1"; break }
        2 { "subnet2"; break }
        3 { "subnet3"; break }
        default { "Please select a subnet that is listed; break" }

    }
}

Write-Output "`n"

$datadiskneeded = Read-Host "Do you want to add an extra data disk to this VM? (y/n)"
if ($datadiskneeded -eq 'y') {
    $disksize = Read-Host "Please specify size of disk in GB's (specify 64GB increments for efficiency)"
    $datadiskname = $virtualMachineName + '-datadisk1'
}



### Tagging

Clear-Host
        
[string[]]$availability = 'Ma-Vrij_06-22', 'Ma-Zo_00-24'


Write-Output "`r`n"
Write-Output "[TAG] Please choose the needed availability:"
Write-Output "`r`n"


1..$availability.Length | foreach-object { Write-Output "$($_): $($availability[$_-1])" }


[ValidateScript( { $_ -ge 1 -and $_ -le $availability.Length })]
[int]$choice = Read-Host "Press the number to select a option"

$availability = switch ($choice) {
    1 { "Ma-Vrij_06-22"; break }
    2 { "Ma-Zo_00-24"; break }
    default { "Please select an option that is listed; break" }

}

Write-Output "`r`n" 
if (($expirationdate = Read-Host -Prompt "[TAG] Please specify the wanted expiration date for this resource (dd/mm/yyyy): [N/A]") -eq "") { $expirationdate = "N/A" } 

Write-Output "`r`n"      
if (($application = Read-Host -Prompt "[TAG] Please specify the application: [N/A]") -eq "") { $application = "N/A" } 

        
[string[]]$impact = 'low', 'medium', 'high'

Write-Output "`r`n"
Write-Output "[TAG] Please choose the downtime impact:"
Write-Output "`r`n"


1..$impact.Length | foreach-object { Write-Output "$($_): $($impact[$_-1])" }


[ValidateScript( { $_ -ge 1 -and $_ -le $impact.Length })]
[int]$choice = Read-Host "Press the number to select a option"

$impact = switch ($choice) {
    1 { "low"; break }
    2 { "medium"; break }
    3 { "high"; break }
    default { "Please select an option that is listed; break" }

}

Write-Output "`r`n"      
if (($productresponsible = Read-Host -Prompt "[TAG] Please specify the application responsible (shorthand): [N/A]") -eq "") { $productresponsible = "N/A" }
      
Write-Output "`r`n"
if (($service = Read-Host -Prompt "[TAG] Please specify the application service: [N/A]") -eq "") { $service = "N/A" }
      
Write-Output "`r`n"
if (($supplier = Read-Host -Prompt "[TAG] Please specify the application supplier: [N/A]") -eq "") { $supplier = "N/A" }
    
Write-Output "`r`n"
if (($company = Read-Host -Prompt "[TAG] Please specify the application company: [N/A]") -eq "") { $company = "N/A" }
      
Write-Output "`r`n"
if (($notes = Read-Host -Prompt "[TAG] Please specify a short description for the resource: [N/A]") -eq "") { $notes = "N/A" }


$Credentials = (Get-Credential -Message 'Enter the domain join credentials' -UserName 'MYWORKPLACE\sccm_ad_action')
$Password = $Credentials.GetNetworkCredential().Password


Clear-Host

write-host "###########################"
Write-Output "`r"
write-host "       DEPLOYING VM        "
Write-Output "`r"
write-host "###########################"
Write-Output "`r"


Write-Output "`r`n"
Write-host "The VM" $virtualMachineName "will be deployed on vnet" $vnet, "subnet" $subnetname "using the size" $virtualMachineSize "in resource group" $rgname 
Write-host "Please wait for JSON exit results"
Write-Output "`r`n"



$virtualNetworkID = "/subscriptions/" + $subscriptionID + "/resourceGroups/" + $networkingResourceGroup + "/providers/Microsoft.Network/virtualNetworks/" + $vnet


# Do the actual deployment

az deployment group create --name DeployVM --resource-group $rgname --template-uri https://raw.githubusercontent.com/JurgenTurrekens/armtemplates/master/deploy.template.json --parameters https://raw.githubusercontent.com/JurgenTurrekens/armtemplates/master/deploy.parameters.json --parameters virtualMachineName=$virtualMachineName adminPassword="cr4ZY!!f0X.." virtualMachineSize=$virtualMachineSize virtualNetworkId=$virtualNetworkID subnetName=$subnetname networkInterfaceName=$networkInterfaceName

write-host "###########################"
Write-Output "`r"
write-host "        TAGGING VM         "
Write-Output "`r"
write-host "###########################"
Write-Output "`r"


az vm update --name $virtualMachineName --resource-group $rgname --set tags.Application=$application tags.Availability=$availability  tags.Company=$company tags.Expiration=$expirationdate tags.Impact=$impact tags.Notes=$notes tags.ProductResponsible=$productresponsible tags.Service=$service tags.Supplier=$supplier


write-host "###########################"
Write-Output "`r"
write-host "      JOINING DOMAIN       "
Write-Output "`r"
write-host "###########################"
Write-Output "`r"

# JSONAddDomain template to join the domain
az deployment group create --name JoinVM --resource-group $rgname  --template-uri https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vm-domain-join-existing/azuredeploy.json --parameters vmList=$virtualMachineName domainJoinUserName="MYWORPLACE\sccm_ad_action" domainJoinUserPassword=$password domainFQDN="ad.sea-invest.net" ouPath="OU=Servers,OU=Computers,OU=INF,OU=BE,OU=SI,DC=ad,DC=sea-invest,DC=net" 



if ($datadiskneeded -eq 'y') {
    write-host "###########################"
    Write-Output "`r"
    write-host "CREATING AND ATTACHING DISK"
    Write-Output "`r"
    write-host "###########################"
    Write-Output "`r"

    az vm disk attach -g $rgname --vm-name $virtualMachineName --name $datadiskname --new --size-gb $disksize --sku Standard_LRS 
}


