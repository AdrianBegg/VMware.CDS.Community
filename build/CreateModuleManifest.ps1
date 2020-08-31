# Basic script to build the module and install it in Dev

[string] $BasePath = $pwd.Path.Trim("\build")
#[string] $LocalModulePath = "C:\Tools\PowerShellCore\Modules"

# Get a collection of files to add to the manifest
Set-Location $BasePath
$colPrivFunctionFiles = (Get-ChildItem .\Private\ -Recurse)
$colPublicFunctionFiles = (Get-ChildItem .\Public\ -Recurse)
$NestedModules = ($colPrivFunctionFiles | Resolve-Path -Relative | ?{$_.EndsWith(".ps1")}) + ($colPublicFunctionFiles | Resolve-Path -Relative | ?{$_.EndsWith(".ps1")})

# Now get a list of Public Functions to expose to end users
$colPublicFunctions = ($colPublicFunctionFiles | Where-Object {$_.Extension -eq ".ps1"}).BaseName

$manifest = @{
    Path              = "$BasePath\VMware.CDS.Community.psd1"
    ModuleVersion     = '0.2'
    Author            = 'Adrian Begg'
    Copyright         = '2020 Adrian Begg. All rights reserved.'
    Description       = 'A PowerShell module to interact with the VMware Cloud Director service using the VMware Cloud Services Portal (CSP).'
    ProjectUri        = 'https://github.com/AdrianBegg/VMware.CDS.Community'
    LicenseUri        = 'https://raw.githubusercontent.com/AdrianBegg/VMware.CDS.Community/master/LICENSE'
    CompatiblePSEditions = "Desktop","Core"
    PowerShellVersion = '7.0'
    NestedModules = @($NestedModules.TrimStart(".\"))
    FunctionsToExport= @(($colPublicFunctions))
}
New-ModuleManifest @manifest

