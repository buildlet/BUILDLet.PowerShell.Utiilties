BUILDLet Utilities for PowerShell (BUILDLet.PowerShell.Utilities)
=================================================================

Introduction
------------

This project provides utility commands (Cmdlets and Functions) for PowerShell.

Getting Started
---------------

The Artifact of this project is PowerShell Module, which is provided and is installable from
[PowerShell Gallery](https://www.powershellgallery.com).  
Copy and Paste the following command to install this package using [PowerShellGet](https://docs.microsoft.com/en-us/powershell/module/powershellget).

```PowerShell
Install-Module -Name BUILDLet.PowerShell.Utilities
```

Build and Test
--------------

This project (Visual Studio Solution) is built on Visual Studio with *PowerShell Tools for Visual Studio*, and tested by [Pester](https://pester.dev/) (<https://pester.dev> or <https://github.com/pester/>) integrated in *Visual Studio Code*.

Remarks
-------

1. ~~The following packages might be kept for backward compatibility with Windows PowerShell.~~  
   ~~The following versions do work with Windows PowerShell 5.1.~~

   - ~~System.Text.Encoding.CodePages v4.5.0 (DO NOT update to v4.7.1)~~
   - ~~System.Security.Permissions v4.5.0 (DO NOT update to v4.7.0)~~
   - ~~System.Runtime.CompilerServices.Unsafe v4.5.0 (DO NOT update to v4.7.1)~~

2. *PowerShellGet* Version 2.0.1 was required to publish thie package.
   (*PowerShellGet* Version 2.2.4.1 (or 2.2.4) did not correctly work.)

License
-------

This project is licensed under the [MIT](https://opensource.org/licenses/MIT) License.
