Requires:
 - Azure Powershell (Az) version 3.x.x

The binaries wfreerdp.exe and xfreerdp are in the bin/ directory.  Either leave as default or update the script to point to an alternative version.

To run:
```
Connect-AzRdp.ps1 -ConfigFile <config_file.json>
```
```
$Password = ConvertTo-SecureString -String 'ExamplePassword' -AsPlainText -Force
Connect-AzRdp.ps1 -Hostname 127.0.0.1 -Username exampleuser -Password $Password 
```
```
Connect-AzRdp.ps1 -Hostname examplehost.example.com -SecretCredentials example-system-creds -VaultName example-keyvault
```
The secret credentials should be stored in the following form:
```
<username> / <password>
```
 eg.  exampleusername / examplepassword
Try not to use the "/" forward slash in either the username or password.
To create the secret and store in Key Vault:
```
$secret = ConvertTo-SecureString -String 'exampleusername / examplepassword' -AsPlainText -Force
Set-AzKeyVault -VaultName example-keyvault -Name example-system-creds -SecretValue $secret

```


