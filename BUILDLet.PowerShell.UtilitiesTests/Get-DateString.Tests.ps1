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


# Get-DateString
Describe "Get-DateString" {

	Context 'normally' {

        $TestCases = @(

            @{
                Date = '2020-01-30'
                LCID = 'en'
                Format = $null
                DateString = 'Thursday, January 30, 2020'
            }

            @{
                Date = '2020-01-30'
                LCID = 'en-US'
                Format = $null
                DateString = 'Thursday, January 30, 2020'
            }

            @{
                Date = '2020-01-30T09:30:00'
                LCID = 'en-US'
                Format = 'G'
                DateString = '1/30/2020 9:30:00 AM'
            }

            @{
                Date = '2020-01-30'
                LCID = 'ja'
                Format = $null
                DateString = '2020”N1ŒŽ30“ú'
            }

            @{
                Date = '2020-01-30'
                LCID = 'ja-JP'
                Format = $null
                DateString = '2020”N1ŒŽ30“ú'
            }

            @{
                Date = '2020-01-30T09:30:00'
                LCID = 'ja-JP'
                Format = 'g'
                DateString = '2020/01/30 9:30'
            }
        )

		It "returns FileVersionInfo object" -TestCases $TestCases {

            # PARAMETER(S)
            Param($Date, $LCID, $Format, $DateString)

            # ARRANGE
            # (None)

            # ACT
            if ($Format) {
                $actual = Get-DateString -Date $Date -LCID $LCID -Format $Format
            }
            else {
                $actual = Get-DateString -Date $Date -LCID $LCID
            }

            # OUTPUT (only for DEBUG Build)
            if ($ActiveConfigurationName -eq 'Debug') {
                Write-Host ("`t`t`tDateString: `"" + $actual + '"')
            }

            # ASSERT
            $actual | Should Be $DateString
		}
    }
}
#>
