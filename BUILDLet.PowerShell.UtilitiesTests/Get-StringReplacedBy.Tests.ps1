<###############################################################################
 The MIT License (MIT)

 Copyright (c) 2021 Daiki Sakamoto

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


# Get-StringReplacedBy
Describe "Get-StringReplacedBy" {

    # Test Cases
    $TestCases = @(

        @{
            expected = 'Good morning, home.'
            InputObject = 'Hello, world.'
            SubstitutionTable = @{
                'Hello' = 'Good morning'
                'world' = 'home'
            }
        }

        @{
            expected = @'
Version 1.60
2021年6月17日
'@
            InputObject = @'
Version __VERSION__
__DATE__
'@
            SubstitutionTable = @{
                '__VERSION__' = '1.60'
                '__DATE__' = '2021年6月17日'
            }
        }
    )


    # $InputObject is specified as parameter
	Context 'normally' {

		It "replaces strings" -TestCases $TestCases {

            # PARAMETER(S)
            Param($expected, $InputObject, $SubstitutionTable)

            # ARRANGE
            # (None)

            # ACT
            $actual = Get-StringReplacedBy -InputObject $InputObject -SubstitutionTable $SubstitutionTable

            # ASSERT
            $actual | Should Be $expected
		}
    }


    # $InputObject is input from Pipeline
	Context 'input from pipeline' {

		It "replaces strings" -TestCases $TestCases {

            # PARAMETER(S)
            Param($expected, $InputObject, $SubstitutionTable)

            # ARRANGE
            # (None)

            # ACT & ASSERT
            $actual = Write-Output $InputObject | Get-StringReplacedBy -SubstitutionTable $SubstitutionTable

            # ASSERT
            $actual | Should Be $expected
		}
    }
}
#>
