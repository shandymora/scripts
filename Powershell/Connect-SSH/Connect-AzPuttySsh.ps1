<#
    Author:         amora
    Description:    Connect to Linux over SSH (putty) from Windows
#>

<#
 .SYNOPSIS
    Connect to Linux over SSH (putty) from Windows

 .DESCRIPTION
    Connects to Linux over SSH using putty.exe located in ./bin/ directory.  
    Credentials can be obtained from Key Vault or hardcoded in config file, or provided as parameters on command line.

 .PARAMETER Hostname
    Required. If not using a configuration file.

 .PARAMETER SecretCredentials
    Required.  If obtaining credentials from a Key Vault.

 .PARAMETER Username
    Optional.  Username credential to login if not obtaining credentials from Key Vault.

 .PARAMETER Password
    Optional.  Password credential to authenticate with if not obtaining credentials from Key Vault.

 .PARAMETER ConfigFile
    Optional. If connection details are held in configuration json file.

 .PARAMETER VaultName
    Optional.  The name of the Key Vault to obtain the sercet value text credentials.  
    Secret value text should be of the form 'username / password'.  
    Requires -SecretCredentials parameter.

#>

Param(
    [string]$Hostname,
    [string]$SecretCredentials,
    [string]$Username,
    [securestring]$Password,
    [string]$ConfigFile,
    [string]$VaultName = "example-keyvault"
)

$ErrorActionPreference = "Stop"

# Helper functions
function Decrypt-SecureString {
    Param(
        [securestring]$SecureString
    )
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    $PlainTextString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    $PlainTextString
}

function Run-Putty {
    Param(
        [string]$Username,
        [string]$Password,
        [string]$Hostname
    )

    Set-Clipboard -Value "${Password}"
    try {
        Start-Process -FilePath ".\bin\putty.exe" -ArgumentList "${UserName}@${Hostname} -pw ${Password}"
    } catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host "Error:`n${ErrorMessage}"
        exit 1
    }       
    
}

if ( $ConfigFile ) {
    # Read/Load Config file
	try {
		$config = Get-Content -Raw -Path "$ConfigFile" | ConvertFrom-Json
	} catch {
		$ErrorMessage = $_.Exception.Message
		Write-Host "Connect-AzPuttySsh::ReadConfig::Error `n${ErrorMessage}"
    }
    
    if ( [bool]($config.PSobject.Properties.name -match "hostname") ) {
        $Hostname = $config.hostname
    } else {
        Write-Host "Config should provide hostname to connect to"
        exit 1
    }
    if ( [bool]($config.PSobject.Properties.name -match "secretcredentials") ) {
        $SecretCredentials = $config.secretcredentials
    } else {
        # There should be username and password instead
        if ( [bool]($config.PSobject.Properties.name -match "username") -and [bool]($config.PSobject.Properties.name -match "password") ) {
            $Username = $config.username
            $PlainTextPassword = $config.password
        } else {
            Write-Host "Config should provide Key Vault Secret value for credentials or username and password"
            exit 1
        }
    }
    
    if ( [bool]($config.PSobject.Properties.name -match "vaultname") ) {
        $VaultName = $config.vaultname
    }
}

if ( ! $Hostname ) {
    Write-Host "You must supply a hostname/ip address to connect to"
    exit 1
}
if ( $SecretCredentials ) {
    # Get Secret credentials
    Write-Host "Retrieving credentials from secret ${SecretCredentials}"

    $Creds = (Get-AzKeyVaultSecret -VaultName $VaultName -Name $SecretCredentials).SecretValueText.Split("/")
    $Username = $Creds[0].Trim()
    $PlainTextPassword = $Creds[1].Trim()

    Run-Putty -Username ${Username} -Password ${PlainTextPassword} -Hostname $Hostname

} else {
    if ( $Username -And $PlainTextPassword ) {
        Run-Putty -Username ${Username} -Password ${PlainTextPassword} -Hostname $Hostname

    } elseif ( $Username -And $Password ) {
        # Get Plaintext password
        $PlainTextPassword = Decrypt-SecureString -SecureString $Password

        Run-Putty -Username ${Username} -Password ${PlainTextPassword} -Hostname $Hostname

    } else {
        Write-Host "You must supply a Username and a Password of SecureString type"
        exit 1
    }

}
