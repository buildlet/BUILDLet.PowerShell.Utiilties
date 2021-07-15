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
$ModuleName = 'BUILDLet.PowerShell.UtilitiesTests'

# Import "BUILDLet.WindowsPowerShell.EnvDTE" Module
$PSScriptRoot | Join-Path -ChildPath .\BUILDLet.WindowsPowerShell.EnvDTE.dll | Import-Module

# Get ConfigurationName ('Debug'|'Release')
$ActiveConfigurationName = Get-DTEActiveConfigurationName -Path ($PSScriptRoot | Join-Path -ChildPath "..\BUILDLet.PowerShell.Utilities.sln")

# Import Target Module
$PSScriptRoot | Join-Path -ChildPath "bin\$ActiveConfigurationName\$ModuleName" | Import-Module


# Test-ResolvedPath
Describe "Test-ResolvedPath" {

    # Valid Path
	Context 'when $Path parameter is valid' {

        $TestCases = @(

            # Absolute Path
            @{
                InputPath = $PSScriptRoot | Join-Path -ChildPath BUILDLet.WindowsPowerShell.EnvDTE.*
                ExpectedPath = @(
                    $PSScriptRoot | Join-Path -ChildPath BUILDLet.WindowsPowerShell.EnvDTE.dll
                )
            }

            # Relative Path (1)
            @{
                InputPath = ".\BUILDLet.WindowsPowerShell.EnvDTE.*"
                ExpectedPath = @(
                    $PSScriptRoot | Join-Path -ChildPath BUILDLet.WindowsPowerShell.EnvDTE.dll
                )
            }

            # Relative Path (2)
            @{
                InputPath = ".\BUILDLet.*"
                ExpectedPath = @(
                    [string]($PSScriptRoot | Join-Path -ChildPath "BUILDLet.PowerShell.UtilitiesTests.pssproj"),
                    [string]($PSScriptRoot | Join-Path -ChildPath "BUILDLet.WindowsPowerShell.EnvDTE.dll")
                )
            }
        )

		It "returns Resolved Path(s)" -TestCases $TestCases {

            # PARAMETER(S)
            Param($InputPath, [string[]]$ExpectedPath)

            # ARRANGE
            Set-Location -Path $PSScriptRoot

            # ACT
            [string[]]$actual = Test-ResolvedPath -Path $InputPath

            # ASSERT
            for ($i = 0; $i -lt $ExpectedPath.Count; $i++) {

                # OUTPUT (only for DEBUG Build)
                if ($ActiveConfigurationName -eq 'Debug') {
                    Write-Host ("`t`t`tExpected Path[$i]: `"" + $ExpectedPath[$i] + '"')
                    Write-Host ("`t`t`tActual Path[$i]:   `"" + $actual[$i] + '"')
                }

                # ASSERT (1)
                $actual[$i] | Should Be $ExpectedPath[$i]
            }

            # ASSERT (2: Count)
            $actual.Count | Should Be $ExpectedPath.Count
		}
    }
    #>

    # Invalid Path
	Context 'when $Path parameter is invalid' {

        $TestCases = @(

            # Absolute Path
            @{
                InputPath = $PSScriptRoot | Join-Path -ChildPath "[Test]"
            }

            # Relative Path
            @{
                InputPath = ".\[Test]"
            }
        )

		It "returns zero-length [string]path array" -TestCases $TestCases {

            # PARAMETER(S)
            Param($InputPath)

            # ARRANGE
            Set-Location -Path $PSScriptRoot

            # ACT
            $actual = Test-ResolvedPath -Path $InputPath

            # ASSERT
            $actual.Count | Should Be 0
		}
    }
    #>
}
#>
