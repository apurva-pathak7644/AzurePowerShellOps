#----------------------------------------------------------------------------------------------------------------------------------
#Fetch a list of Application Registrations and Enterprise Applications with secrets/ certificates expiring in next 'N' days.
#
#  This scripts gets you below output files:
#
#       1. All Application Registrations with secrets/ certificates expiring in next 'n' number of days.
#       2. All Enterprise Applications with certificates expiring in next 'n' number of days.
#       3. All Application Registrations with NO secrets/ certificates associated with it.
#       4. All Enterprise Applications with NO certificates associated with it.
#
#  Prerequisites:
#      
#   Ensure you have:-
#
#       1. Ensure the identity, which you're using to run this script, has atleast 'Application.Read.All' or 'Directory.Read.All' 
#          permission(s) with MS Graph.
#       2. The identity which you are running this script with has appropriated rights to list applications in Azure AD/ Entra Id.
#
#-----------------------------------------------------------------------------------------------------------------------------------

#Global variables
$LogPath = "\Log\File\Path\Log$(Get-Date -Format "ddMMyyyyhhmmssss").txt"
$thresholdDays = "30" #Number of days for which you want to track the secret expiry
$currentdate = Get-Date
$expirationThreshold = $currentdate.AddDays($thresholdDays)
$TenantId = "TenantId"


#Define directories to save the output

$appregistrations_result_dir = "\File\Path\AppRegistrations"
$appregistrations_result_file = "AppRegistrationSecrets_ExpiringIn_$($thresholdDays)Days_$(Get-Date -Format "ddMMyyyyhhmmssss").csv"
$appregistrations_Nosecrets_dir = "\File\Path\AppRegistrations\NoSecretApps"
$appregistrations_Nosecrets_file = "NoSecretAppRegistrations_$(Get-Date -Format "ddMMyyyyhhmmssss").CSV"


$enterpriseapplications_result_dir = "\File\Path\EnterpriseApps"
$enterpriseapplications_result_file = "EnterpriseAppsCertificates_ExpiringIn_$($thresholdDays)Days_$(Get-Date -Format "ddMMyyyyhhmmssss").csv"
$enterprise_application_Nocerts_dir = "\File\Path\EnterpriseApps\NoSecretApps"
$enterprise_application_Nocerts_file = "NoCertificateEnterpriseApps_$(Get-Date -Format "ddMMyyyyhhmmssss").CSV"



#Function declarations
Function Write-Log {

param (

    $LogFilePath = $LogPath,
    $LogMessage,
    $Loglevel

)
    $Logs = "$(Get-Date -Format "dd-MM-yyyy HH:mm:ss") [$Loglevel] -  $LogMessage"
    Write-Output $Logs
    $Logs | Out-File -FilePath $LogFilePath -Append

}   
    
Function ConnectToAzure {

    try{


Write-Log -Loglevel "Info" -LogMessage "Connecting to Azure AD"
Connect-MgGraph -TenantId $TenantId 

    }

    catch {

        $errorMessage = "Error: $($_.Exception.Message)"
        Write-Log -LogMessage $errorMessage -LogLevel "Error"
        
    }

}

# Geeting certificate/ secret details for application registrations
Function GetAppRegistrationSecrets { 

try {

Write-Log -Loglevel "Info" -LogMessage "Initializing flow to get Application Registration secret/certificate expiry details."

Write-Log -Loglevel "Info" -LogMessage "Fetching all Application Registrations in tenant"
$applications = Get-MgApplication -All

Write-Log -Loglevel "Info" -LogMessage "Listed all Application Registrations in tenant, total $($applications.count) Application Registrations found."
foreach ($application in $applications){
  
     $secrets = (Get-MgApplication -ApplicationId $application.Id).PasswordCredentials | Where-Object DisplayName -NotContains "CWAP_AuthSecret"
     Write-Log -Loglevel "Info" -LogMessage "Application '$($application.DisplayName)' has $($secrets.count) secret(s)."

     $sec_count = $($secrets.count)
     
            foreach ($secret in $secrets){

               $secret_expiry_date = $secret.EndDateTime
               Write-Log -Loglevel "Info" -LogMessage "Checking secret with key Id $($secret.KeyId) expiry for application: $($application.DisplayName)"

                if ($secret_expiry_date -ne $null -and $secret_expiry_date -lt $expirationThreshold -and $secret_expiry_date -gt $currentdate){

                    Write-Log -Loglevel "Info" -LogMessage "Secret with key ID $($secret.KeyId) of Application $($application.DisplayName) with ObjectId $($application.Id) is expiring on $($secret.EndDate)" | 
                    
                    Select-Object @{Name="AppName"; Expression={$($application.DisplayName)}},`
                    @{Name="AppObjId"; Expression={$($application.Id)}},`
                    @{Name="SecretId"; Expression={$($secret.KeyId)}},`
                    @{Name="SecretExpiryDate"; Expression={$($secret.EndDateTime)}} |
                    Export-Csv -Path "$appregistrations_result_dir\$appregistrations_result_file" -Append -NoTypeInformation                                
                }

                if ($secret_expiry_date -lt $currentdate ) {
                
                    Write-Log -Loglevel "Info" -LogMessage "Secret is already expired for '$($application.DisplayName)'"
                                 
                 }
    
            }

     $certificates = (Get-MgApplication -ApplicationId $application.Id).KeyCredentials
     Write-Log -Loglevel "Info" -LogMessage "Application '$($application.DisplayName)' has $($certificates.count) certificate(s)."

     $cert_count = $($certificates.count)    

        foreach ($certificate in $certificates){

                $certificate_expiry_date = $certificate.EndDateTime
                Write-Log -Loglevel "Info" -LogMessage "Checking certificate with key Id $($secret.KeyId) expiry for application: $($application.DisplayName)"

                if ($certificate_expiry_date -ne $null -and $certificate_expiry_date -lt $expirationThreshold -and $certificate_expiry_date -gt $currentdate){
                
                    Write-Log -Loglevel "Info" -LogMessage  "Certificate with key ID $($secret.KeyId) of Application $($application.DisplayName) with ObjectId $($application.Id) is expiring on $($certificate.EndDate)" | 
                    
                    Select-Object @{Name="AppName"; Expression={$($application.DisplayName)}},`
                    @{Name="AppObjId"; Expression={$($application.Id)}},`
                    @{Name="SecretId"; Expression={$($secret.KeyId)}},`
                    @{Name="SecretExpiryDate"; Expression={$($certificate.EndDateTime)}} |
                    Export-Csv -Path "$appregistrations_result_dir\$appregistrations_result_file" -Append -NoTypeInformation
                                                
                }
                
                if ($certificate_expiry_date -lt $currentdate ) {
                
                   Write-Log -Loglevel "Info" -LogMessage "Certificate is already expired for '$($application.DisplayName)'"
                                
                }          
            
            }

            if ($sec_count -eq '0'){

                if ($cert_count -eq '0'){
            
                     Write-Log -Loglevel "Info" -LogMessage "Application '$($application.DisplayName)' has 0 secrets/certificates, it might be an Enterprise Application."| 

                     Select-Object @{Name="AppName"; Expression={$($application.DisplayName)}},`
                     @{Name="AppObjId"; Expression={$($application.Id)}} |
                     Export-Csv -Path "$appregistrations_Nosecrets_dir\$appregistrations_Nosecrets_file" -Append -NoTypeInformation

                                    }                            
                        }
               

}

}
catch {

    $errorMessage = "Error: $($_.Exception.Message)"
    Write-Log -LogMessage $errorMessage -LogLevel "Error"
    
}
}

Function GetEnterpiseAppCerts { 

    try {

# Get certificate details for Enterprise Applications

Write-Log -Loglevel "Info" -LogMessage "Initializing flow to get Enterprise Applications certificate expiry details."

Write-Log -Loglevel "Info" -LogMessage "Fetching all Enterprise Applications in the tenant"
$enterprise_applications = Get-MgServicePrincipal -All | Where-Object {$_.ServicePrincipalType -NE "ManagedIdentity"}

Write-Log -Loglevel "Info" -LogMessage "Listed all Enterprise Applications in tenant, total $($enterprise_applications.count)  Enterprise Applications found."
foreach ($enterprise_application in $enterprise_applications){

  
     $entra_certificates = (Get-MgServicePrincipal -ServicePrincipalId $enterprise_application.Id).PasswordCredentials
     Write-Log -Loglevel "Info" -LogMessage "Enterprise Application '$($enterprise_application.DisplayName)' has $($entra_certificates.count) certificate(s)."

     $entra_cert_count = $($entra_certificates.count)    

        foreach ($entra_certificate in $entra_certificates){

                $entra_certificate_expiry_date = $entra_certificate.EndDateTime
                Write-Log -Loglevel "Info" -LogMessage "Checking certificate with key Id $($entra_certificate.KeyId) expiry for application: $($enterprise_application.DisplayName)"

                if ($entra_certificate_expiry_date -ne $null -and $entra_certificate_expiry_date -lt $expirationThreshold -and $entra_certificate_expiry_date -gt $currentdate){
                
                    Write-Log -Loglevel "Info" -LogMessage  "Certificate with key ID $($entra_certificate.KeyId) of Enterprise Application $($enterprise_application.DisplayName) with ObjectId $($enterprise_application.ObjectId) is expiring on $($entra_certificate.EndDate)" |

                    Select-Object @{Name="AppName"; Expression={$($enterprise_application.DisplayName)}},`
                    @{Name="AppObjId"; Expression={$($enterprise_application.Id)}},`
                    @{Name="SecretId"; Expression={$($entra_certificate.KeyId)}},`
                    @{Name="SecretExpiryDate"; Expression={$($entra_certificate.EndDateTime)}} |
                    Export-Csv -Path "$enterpriseapplications_result_dir\$enterpriseapplications_result_file" -Append -NoTypeInformation                                                
                }
                
                if ($entra_certificate_expiry_date -lt $currentdate ) {
                
                   Write-Log -Loglevel "Info" -LogMessage "Certificate is already expired for '$($enterprise_application.DisplayName)'"

                }        
          
            
            }   

                if ($entra_cert_count -eq '0'){

            
                     Write-Log -Loglevel "Info" -LogMessage "Enterprise Application $($enterprise_application.DisplayName) has 0 certificates."|

                     Select-Object @{Name="AppName"; Expression={$($enterprise_application.DisplayName)}},`
                     @{Name="AppObjId"; Expression={$($enterprise_application.Id)}} |
                     Export-Csv -Path "$enterprise_application_Nocerts_dir\$enterprise_application_Nocerts_file" -Append -NoTypeInformation

                                    }

}

}

catch {

    $errorMessage = "Error: $($_.Exception.Message)"
    Write-Log -LogMessage $errorMessage -LogLevel "Error"
    
}

}

#Call functions to start the flow

ConnectToAzure
GetAppRegistrationSecrets
GetEnterpiseAppCerts
