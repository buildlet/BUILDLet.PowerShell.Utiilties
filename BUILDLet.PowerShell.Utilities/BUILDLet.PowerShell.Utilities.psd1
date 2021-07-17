#
# Module manifest for module 'BUILDLet.PowerShell.Utilities'
#
# Generated by: Daiki Sakamoto
#
# Generated on: 2020/01/22 22:16:15
#

@{

# Script module or binary module file associated with this manifest.
# RootModule = 'BUILDLet.PowerShell.Utilities.psm1'

# Version number of this module.
ModuleVersion = '1.6.3'

# ID used to uniquely identify this module
GUID = '8f433de9-112b-4c56-bf26-698924347c03'

# Author of this module
Author = 'Daiki Sakamoto'

# Company or vendor of this module
CompanyName = 'BUILDLet'

# Copyright statement for this module
Copyright = '(c) 2020 Daiki Sakamoto. All rights reserved.'

# Description of the functionality provided by this module
Description = 'BUILDLet Utilities for PowerShell'

# Minimum version of the Windows PowerShell engine required by this module
# PowerShellVersion = ''

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
RequiredAssemblies = @(
	'BUILDLet.Standard.Utilities.dll'
	'BUILDLet.Standard.Diagnostics.dll'
	'DotNetZip.dll'
	'System.Text.Encoding.CodePages.dll'
	'System.Runtime.CompilerServices.Unsafe.dll'
	'System.Security.Permissions.dll'
)

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
NestedModules = @(
	'BUILDLet.PowerShell.Utilities.psm1'
	'BUILDLet.PowerShell.Utilities.dll'
)

# Functions to export from this module
FunctionsToExport = @(
    'Get-DateString'
    'Get-AuthenticodeSignerName'
    'Get-FileVersionInfo'
    'Get-FileVersion'
    'Get-ProductVersion'
    'Get-ProductName'
    'Get-FileDescription'
    'ConvertTo-WslPath'
    'Send-MagicPacket'
    'Get-StringReplacedBy'
    'Set-StringReplacedBy'
    'New-TestCertificate'
)

# Cmdlets to export from this module
CmdletsToExport = @(
    'Get-PrivateProfile'
    'Set-PrivateProfile'
    'Expand-ZipFile'
    'New-ZipFile'
    'Invoke-Process'
    'Get-HtmlContent'
)

# Variables to export from this module
# VariablesToExport = '*'

# Aliases to export from this module
# AliasesToExport = '*'

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
FileList = @(
	'BUILDLet.PowerShell.Utilities.psd1'
	'BUILDLet.PowerShell.Utilities.psm1'
	'BUILDLet.PowerShell.Utilities.dll'
	'BUILDLet.Standard.Utilities.dll'
	'BUILDLet.Standard.Diagnostics.dll'
	'DotNetZip.dll'
	'System.Text.Encoding.CodePages.dll'
	'System.Runtime.CompilerServices.Unsafe.dll'
	'System.Security.Permissions.dll'
)

# Private data to pass to the module specified in RootModule/ModuleToProcess
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        # Tags = @()

        # A URL to the license for this module.
        LicenseUri = 'https://opensource.org/licenses/MIT'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/buildlet/BUILDLet.PowerShell.Utiilties'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        # ReleaseNotes = ''

        # Prerelease string of this module
        # Prerelease = 'beta3'

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        # ExternalModuleDependencies = @()

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}
