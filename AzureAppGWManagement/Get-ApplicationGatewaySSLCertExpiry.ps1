#----------------------------------------------------------------------------------------------------------------------------------------------
# [Apurva Pathak]- PowerShell script to fetch a list of all directly uploaded Application Gateway SSL Certificates expiring in next 'N' days.
#
#   This script outputs you a list of SSL certificates, along with their Application Gateway details where those are installed across 
#   all subscription in the tenant, which are to be expired in next 'N' days.
#   
#   Prerequisites:
#      
#      Ensure you have:-
#  
#       1. PowerShell "Az" module installed
#       2. Ensure the identity, which you're using to run this script, has atleast Read access.
#


# Global variables
 
$thresholdDays = "30" #Number of days for which you want to track the certificate expiry
$currentdate = Get-Date
$expirationThreshold = $currentdate.AddDays($thresholdDays)
$tenantId = "Tenant Id"
$LogPath = "\Log\File\Path"
$LogFile = "Log$(Get-Date -Format "ddMMyyyyhhmmssss").txt"
$result_dir = "\File\Path\AppGatewayCertExpiry"
$result_file = "AppGatewaysCert_ExpiringIn_$($thresholdDays)Days_$(Get-Date -Format "ddMMyyyyhhmmssss").csv"
 
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
 
Function Decode-Certificate($certBytes) {
 
    $p7b = New-Object System.Security.Cryptography.Pkcs.SignedCms
    $p7b.Decode($certBytes)
    return $p7b.Certificates[0]
}
 
Function Connect-ToAzure {
 
try {
 
Write-Log -Loglevel "Info" -LogMessage "Connecting to Azure"
Connect-AzAccount -TenantId $tenantId
 
}
 
catch {
 
    $errorMessage = "Error: $($_.Exception.Message)"
    Write-Log -LogLevel "Error" -LogMessage "Error occurred in function Connect-ToAzure. Error: $errorMessage"
}
 
 
}
 
Function Get-ApplicationGatewaySSLCertExpiry{
 
$certificates = @()
 
try {
 
Write-Log -Loglevel "Info" -LogMessage "Listing all active business suscriptions"
$subscriptions = Get-AzSubscription | Where-Object {$_.State -EQ "Enabled"}
foreach ($subscription in $subscriptions){
if ((Get-AzContext).Subscription.Name -ne $subscription.Name){
 
Write-Log -Loglevel "Info" -LogMessage "Setting context to subscription $($subscription.Name)"
Set-AzContext -Subscription $subscription 
}
 
Write-Log -Loglevel "Info" -LogMessage "Listing all Application Gateways in the subscription $($subscription.Name)"
$appgateways = Get-AzApplicationGateway
 
Write-Log -Loglevel "Info" -LogMessage "Total $($appgateways.count) Application Gateways found in the subscription $($subscription.Name)"
if (($appgateways).Count -gt 0){
foreach ($appgateway in $appgateways) {

    foreach ($sslcertificate in $appgateways.SslCertificates) {     
        if ($sslcertificate.PublicCertData -ne $null){
        Write-Log -Loglevel "Info" -LogMessage "Processing SSL Certificate '$($sslcertificate.Name)' of App Gateway $($appgateway.Name)"
        $certBytes = [Convert]::FromBase64String($sslcertificate.PublicCertData)
        $x509 = Decode-Certificate $certBytes
        $certexpirydate = $x509.NotAfter
 
        Write-Log -Loglevel "Info" -LogMessage "Expiry Date of SSL Certificate '$($sslcertificate.Name)' is $($x509.NotAfter)"
        if ($certexpirydate -ne $null -and $certexpirydate -lt $expirationThreshold -and $certexpirydate -gt $currentdate){
        Write-Log -Loglevel "Alert" -LogMessage "Expiry Date is within $thresholdDays days threshold"
        $certificatedetail = [PSCustomObject]@{
                AppGatewayName = $appgateway.Name
                ResourceGroup = $appgateway.ResourceGroupName                
                CertThumbprint = $x509.Thumbprint
                CertExpiration = $x509.NotAfter
                CertSubject = $x509.Subject
                }
 
                $certificates += $certificatedetail              
             }          
           }
         } 
     }
 
}
}
}
 
catch {
 
    $errorMessage = "Error: $($_.Exception.Message)"
    Write-Log -LogLevel "Error" -LogMessage "Error occurred in function Get-ApplicationGatewaySSLCertExpiry. Error: $errorMessage"
}
 
Write-Log -Loglevel "Info" -LogMessage "Exporting the list of Application Gateway SSL Certificates which are expiring in next 30 Days"
$certificates | Export-Csv -Path $result_dir\$result_file -NoClobber -Append -NoTypeInformation
Write-Log -Loglevel "Info" -LogMessage "Data exported to $result_dir\$result_file"
}
 
# Call functions to trigger the flow
 
Connect-ToAzure
Get-ApplicationGatewaySSLCertExpiry