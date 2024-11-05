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
#       1. 'AzureADPreview Module' or 'AzureAD Module' installed.
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
Connect-AzureAD -TenantId $TenantId

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

Write-Log -Loglevel "Info" -LogMessage "Fetching all application registrations in tenant"
$applications = Get-AzureADApplication -All:$true

Write-Log -Loglevel "Info" -LogMessage "Listed all application registrations in tenant, total $($applications.count) applications registrations are found."

foreach ($application in $applications){

  
     $secrets = Get-AzureADApplicationPasswordCredential -ObjectId $application.ObjectId

    Write-Log -Loglevel "Info" -LogMessage "Application $($application.DisplayName) has $($secrets.count) secrets."

     $sec_count = $($secrets.count)

     
            foreach ($secret in $secrets){


               $secret_expiry_date = $secret.EndDate
                Write-Log -Loglevel "Info" -LogMessage "Checking secret with secret Id $($secret.KeyId) expiry for application: $($application.DisplayName)"


                if ($secret_expiry_date -ne $null -and $secret_expiry_date -lt $expirationThreshold -and $secret_expiry_date -gt $currentdate){

                    Write-Log -Loglevel "Info" -LogMessage "Secret(s) with key ID $($secret.KeyId) of Application $($application.DisplayName) with ObjectId $($application.ObjectId) is expiring on $($secret.EndDate)" | 
                    
                    Select-Object @{Name="AppName"; Expression={$($application.DisplayName)}},`
                    @{Name="AppObjId"; Expression={$($application.ObjectId)}},`
                    @{Name="SecretId"; Expression={$($secret.KeyId)}},`
                    @{Name="SecretExpiryDate"; Expression={$($secret.EndDate)}} | 

                    Export-Csv -Path "$appregistrations_result_dir\$appregistrations_result_file" -Append -NoTypeInformation
                                
                }      
                         
            
    
            }

     $certificates = Get-AzureADApplicationKeyCredential -ObjectId $application.ObjectId

     Write-Log -Loglevel "Info" -LogMessage "Application $($application.DisplayName) has $($certificates.count) certificates."

     $cert_count = $($certificates.count)
    

        foreach ($certificate in $certificates){


                $certificate_expiry_date = $certificate.EndDate

                Write-Log -Loglevel "Info" -LogMessage "Checking certificate with secret Id $($secret.KeyId) expiry for application: $($application.DisplayName)"

                if ($certificate_expiry_date -ne $null -and $certificate_expiry_date -lt $expirationThreshold -and $certificate_expiry_date -gt $currentdate){
                
                    Write-Log -Loglevel "Info" -LogMessage  "Certificate(s) with key ID $($secret.KeyId) of Application $($application.DisplayName) with ObjectId $($application.ObjectId) is expiring on $($certificate.EndDate)" | 
                    
                    Select-Object @{Name="AppName"; Expression={$($application.DisplayName)}},`
                    @{Name="AppObjId"; Expression={$($application.ObjectId)}},`
                    @{Name="SecretId"; Expression={$($secret.KeyId)}},`
                    @{Name="SecretExpiryDate"; Expression={$($certificate.EndDate)}} |

                    Export-Csv -Path "$appregistrations_result_dir\$appregistrations_Nosecrets_file" -Append -NoTypeInformation
                                                
                }
                
                if ($certificate_expiry_date -lt $currentdate ) {
                
                   Write-Log -Loglevel "Info" -LogMessage "Certificate is already expired for $($application.DisplayName)"
                                
                }                     
          
            
            }   


            if ($sec_count -eq '0'){


                if ($cert_count -eq '0'){

            
                     Write-Log -Loglevel "Info" -LogMessage "Application $($application.DisplayName) has 0 secrets/certificates it could be an Enterprise Application."| 

                     Select-Object @{Name="AppName"; Expression={$($application.DisplayName)}},`
                     @{Name="AppObjId"; Expression={$($application.ObjectId)}} |

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

# Geting certificate details for Enterprise Applications

Write-Log -Loglevel "Info" -LogMessage "Initializing flow to get Enterprise Applications certificate expiry details."

Write-Log -Loglevel "Info" -LogMessage "Fetching all Enterprise Applications in the tenant"
$enterprise_applications = Get-AzureADServicePrincipal -All $true

Write-Log -Loglevel "Info" -LogMessage "Listed all Enterprise Applications in tenant, total $($enterprise_applications.count) applications registrations are found."

foreach ($enterprise_application in $enterprise_applications){

  
     $entra_certificates = Get-AzureADServicePrincipalPasswordCredential -ObjectId $enterprise_application.ObjectId

     Write-Log -Loglevel "Info" -LogMessage "Enterprise Application $($enterprise_application.DisplayName) has $($entra_certificates.count) certificates."

     $entra_cert_count = $($entra_certificates.count)
    

        foreach ($entra_certificate in $entra_certificates){


                $entra_certificate_expiry_date = $entra_certificate.EndDate

                Write-Log -Loglevel "Info" -LogMessage "Checking certificate with secret Id $($entra_certificate.KeyId) expiry for application: $($enterprise_application.DisplayName)"

                if ($entra_certificate_expiry_date -ne $null -and $entra_certificate_expiry_date -lt $expirationThreshold -and $entra_certificate_expiry_date -gt $currentdate){
                
                    Write-Log -Loglevel "Info" -LogMessage  "Certificate(s) with key ID $($entra_certificate.KeyId) of Enterprise Application $($enterprise_application.DisplayName) with ObjectId $($enterprise_application.ObjectId) is expiring on $($entra_certificate.EndDate)" |

                    Select-Object @{Name="AppName"; Expression={$($enterprise_application.DisplayName)}},`
                    @{Name="AppObjId"; Expression={$($enterprise_application.ObjectId)}},`
                    @{Name="SecretId"; Expression={$($entra_certificate.KeyId)}},`
                    @{Name="SecretExpiryDate"; Expression={$($entra_certificate.EndDate)}} |

                    Export-Csv -Path "$enterpriseapplications_result_dir\$enterpriseapplications_result_file" -Append -NoTypeInformation
                                                
                }
                
                if ($entra_certificate_expiry_date -lt $currentdate ) {
                
                   Write-Log -Loglevel "Info" -LogMessage "Certificate is already expired for $($enterprise_application.DisplayName)"
                                
                }        
          
            
            }   

                if ($entra_cert_count -eq '0'){

            
                     Write-Log -Loglevel "Info" -LogMessage "Enterprise Application $($enterprise_application.DisplayName) has 0 certificates."|

                     Select-Object @{Name="AppName"; Expression={$($enterprise_application.DisplayName)}},`
                     @{Name="AppObjId"; Expression={$($enterprise_application.ObjectId)}} |

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
