# Global variables 
$tenantId = "Tenant Id"
$LogPath = "\Log\File\Path"
$LogFile = "Log$(Get-Date -Format "ddMMyyyyhhmmssss").txt"
$result_dir = "\File\Path\"
$result_file = "AllVnets_$($thresholdDays)Days_$(Get-Date -Format "ddMMyyyy").csv"
 
#Functions declarations
Function Write-Log {
 
param (
 
    $LogFilePath = "$LogPath\$LogFile",
    $LogMessage,
    $Loglevel
 
)
    $Logs = "$(Get-Date -Format "dd-MM-yyyy HH:mm:ss") [$Loglevel] -  $LogMessage"
    Write-Output $Logs
    $Logs | Out-File -FilePath $LogFilePath -Append
 
}

try {

Write-Log -Loglevel "Info" -LogMessage "Connecting to Azure"
Connect-AzAccount -TenantId $tenantId

Write-Log -Loglevel "Info" -LogMessage "Listing all active suscriptions"
$subscriptions = Get-AzSubscription | Where-Object {$_.State -EQ "Enabled"}

foreach ($subscription in $subscriptions){
if ((Get-AzContext).Subscription.Name -ne $subscription.Name){
 
Write-Log -Loglevel "Info" -LogMessage "Setting context to subscription $($subscription.Name)"
Set-AzContext -Subscription $subscription 
}

Write-Log -Loglevel "Info" -LogMessage "Listing all Virtual Networks in the subscription $($subscription.Name)"
$vnets = Get-AzVirtualNetwork

Write-Log -Loglevel "Info" -LogMessage "Total $($vnets.count) Virtual Networks found in the subscription $($subscription.Name)"

foreach ($vnet in $vnets) {

   Write-Log -Loglevel "Info" -LogMessage "Listing all subnets of Virtual Network '$($vnet.Name)' in the subscription $($subscription.Name)"
   $subnets = $vnet.Subnets.name

    foreach ($subnet in $subnets){

    Write-Log -Loglevel "Info" -LogMessage "Listing associated Route Tables and NSGs with the subnet '$($SubnetDetails.name)' of Vnet $($vnet.Name)"
    
    $SubnetDetails = Get-AzVirtualNetworkSubnetConfig -Name $subnet -VirtualNetwork $vnet  
    
    $SubnetDetails | Select-Object @{Name="VNETName"; Expression={$($vnet.Name)}}, `
                               @{Name="VNETAddressSpaces"; Expression={$($vnet.AddressSpace.AddressPrefixes)}}, `
                               @{Name="SubnetName"; Expression={$($SubnetDetails.name)}},`
                               @{Name="SubnetsPrefix"; Expression={$($SubnetDetails.AddressPrefix)}}, `
                               @{Name="SubnetNSG"; Expression={$($SubnetDetails.NetworkSecurityGroup.Id.Split('/')[8])}}, `
                               @{Name="SubnetRouteTable"; Expression={$($SubnetDetails.RouteTable.Id.Split('/')[8])}}, ` 
                               @{Name="SubnetNSGId"; Expression={$($SubnetDetails.NetworkSecurityGroup.Id)}}, `
                               @{Name="SubnetRouteTableId"; Expression={$($SubnetDetails.RouteTable.Id)}}`
                               | Export-Csv -Path $result_dir\$result_file -NoTypeInformation -Append    
        
                                 }

                          }                                             

                                         }

 }

catch {
 
    $errorMessage = "Error: $($_.Exception.Message)"
    Write-Log -LogLevel "Error" -LogMessage "Error occurred: $errorMessage"
}
    