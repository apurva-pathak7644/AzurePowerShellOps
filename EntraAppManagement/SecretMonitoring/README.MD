
# Fetch Expiring Secrets and Certificates in Azure AD Applications

This PowerShell script helps you identify application registrations and enterprise applications in Azure Active Directory (Azure AD) with expiring secrets and certificates or those without any associated secrets or certificates. It generates detailed reports as CSV files for further analysis.

## Features

1. **Identify Expiring Secrets and Certificates**:
   - Lists application registrations and enterprise applications with secrets or certificates expiring within the next `N` days.

2. **Find Applications Without Secrets/Certificates**:
   - Identifies applications and enterprise applications with no associated secrets or certificates.

3. **Generate Reports**:
   - Creates CSV files containing detailed information:
     - Expiring secrets and certificates.
     - Applications without secrets or certificates.

4. **Detailed Logging**:
   - Logs all operations to a timestamped log file for tracking and debugging.

## Prerequisites

1. **Azure PowerShell Modules**:
   - Ensure that the `AzureAD` or `AzureADPreview` module is installed. These modules are required to interact with Azure AD.

   ```powershell
   Install-Module -Name AzureAD -Force
   ```

2. **Azure AD Permissions**:
   - The identity running this script must have the appropriate permissions to list applications and service principals in Azure AD.

3. **PowerShell Version**:
   - This script requires PowerShell 5.1 or later.

## Script Usage

### Parameters

- `$thresholdDays`: The number of days within which secrets or certificates are considered expiring.
- `$TenantId`: The Azure AD Tenant ID.
- `$LogPath`: The file path where log files will be stored.
- Directory paths for output files are defined in the script.

### Steps to Run

1. Clone this repository to your local machine.
2. Open PowerShell as an administrator.
3. Update the script with the correct tenant ID and desired threshold days if needed.
4. Run the script.

### Outputs

The script generates the following CSV files:

1. **Application Registrations with Expiring Secrets/Certificates**:
   - Located at: `<DefinedPath>/AppRegistrations`
   - Example: `AppRegistrationSecrets_ExpiringIn_30Days_<Timestamp>.csv`

2. **Enterprise Applications with Expiring Certificates**:
   - Located at: `<DefinedPath>/EnterpriseApps`
   - Example: `EnterpriseAppsCertificates_ExpiringIn_30Days_<Timestamp>.csv`

3. **Application Registrations Without Secrets/Certificates**:
   - Located at: `<DefinedPath>/AppRegistrations/NoSecretApps`
   - Example: `NoSecretAppRegistrations_<Timestamp>.csv`

4. **Enterprise Applications Without Certificates**:
   - Located at: `<DefinedPath>/EnterpriseApps/NoSecretApps`
   - Example: `NoCertificateEnterpriseApps_<Timestamp>.csv`

### Log Files

Logs are stored at the path specified in `$LogPath`. Each log file is timestamped for traceability.

## Known Limitations

1. **Deprecated Modules**:
   - The script uses `AzureAD` or `AzureADPreview` modules, which are deprecated. Consider migrating to the `Microsoft.Graph` module.

2. **Rate Limits**:
   - Azure AD API rate limits may affect execution in large tenants.

3. **Performance**:
   - The script may take time to execute for tenants with many applications or service principals.

## Suggested Enhancements

1. Parameterize the script for more flexibility.
2. Transition to the `Microsoft.Graph` PowerShell module for better support.
3. Add retry logic to handle transient API errors.

## Contributing

Contributions are welcome! Please fork the repository, make your changes, and submit a pull request.


