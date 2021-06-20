<###############################################################################
 The MIT License (MIT)

 Copyright (c) 2020 Daiki Sakamoto

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
################################################################################>

#
# This is a PowerShell Unit Test file.
# You need a unit test framework such as Pester to run PowerShell Unit tests. 
# You can download Pester from https://go.microsoft.com/fwlink/?LinkID=534084
#

# Target Module Name
$ModuleName = 'BUILDLet.PowerShell.Utilities'

# Import "BUILDLet.WindowsPowerShell.EnvDTE" Module
$PSScriptRoot | Join-Path -ChildPath .\BUILDLet.WindowsPowerShell.EnvDTE.dll | Import-Module

# Get ConfigurationName ('Debug'|'Release')
$ActiveConfigurationName = Get-DTEActiveConfigurationName -Path ($PSScriptRoot | Join-Path -ChildPath "..\$ModuleName.sln")

# Import Target Module
$PSScriptRoot | Join-Path -ChildPath "bin\$ActiveConfigurationName\$ModuleName" | Import-Module


# Get-FileVersionInfo
Describe "Get-FileVersionInfo" {

    BeforeAll {

        # SET $TargetDir
        $TargetDir = $PSScriptRoot | Join-Path -ChildPath 'bin' | Join-Path -ChildPath $ActiveConfigurationName
    }

    AfterAll {

        # Reset Location
        Set-Location -Path $PSScriptRoot
    }

	Context 'normally' {

        $TestCases = @(

            @{
                FilePath = $TargetDir | Join-Path -ChildPath BUILDLet.PowerShell.Utilities | Join-Path -ChildPath DotNetZip.dll
                FileVersion = '1.15.0'
                ProductVersion = '1.15.0.065e51'
            }
        )

		It "returns FileVersionInfo object" -TestCases $TestCases {

            # PARAMETER(S)
            Param($FilePath, $FileVersion, $ProductVersion)

            # ARRANGE
            Set-Location -Path $TargetDir

            # ACT
            $actual = Get-FileVersionInfo -FilePath $FilePath

            # OUTPUT (only for DEBUG Build)
            if ($ActiveConfigurationName -eq 'Debug') {
                Write-Host ("`t`t`tVersionInfo.FileVersion:    " + ([System.Diagnostics.FileVersionInfo]$actual).FileVersion)
                Write-Host ("`t`t`tVersionInfo.ProductVersion: " + ([System.Diagnostics.FileVersionInfo]$actual).ProductVersion)
            }

            # ASSERT
            ([System.Diagnostics.FileVersionInfo]$actual).FileVersion | Should Be $FileVersion
            ([System.Diagnostics.FileVersionInfo]$actual).ProductVersion | Should Be $ProductVersion
		}
    }
}
#>
