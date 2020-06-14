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


# Get-PrivateProfile
Describe "Get-PrivateProfile" {

    # GET VALUE
	Context 'with parameter $Path, $Section and $Key' {

        $TestCases = @(

            # Get-PrivateProfile_Test1.ini
            @{
                Path = $PSScriptRoot | Join-Path -ChildPath Get-PrivateProfile_Test1.ini
                Section = 'Section'
                Key = 'Key'
                Value = 'VALUE'
            }
        )

		It "returns Value" -TestCases $TestCases {

            # PARAMETER(S)
            Param($Path, $Section, $Key, $Value)

            # ARRANGE
            Set-Location $PSScriptRoot

            # ACT
            $actual = Get-PrivateProfile -Path $Path -Section $Section -Key $Key

            # OUTPUT (only for DEBUG Build)
            if ($ActiveConfigurationName -eq 'Debug') {
                Write-Host "`t`t`tExpected: `"$Value`""
                Write-Host "`t`t`tActual:   `"$actual`""
            }

            # ASSERT
            $actual | Should Be $Value
		}
	}

    # GET SECTION
	Context 'with parameter $Path and $Section' {

        $TestCases = @(

            # Get-PrivateProfile_Test1.ini
            @{
                Path = $PSScriptRoot | Join-Path -ChildPath Get-PrivateProfile_Test1.ini
                Section = 'Section'
                Entries = @(
                    @{
                        Section = 'SECTION'
                        Key = 'KEY'
                        Value ='VALUE'
                    }
                )
            }

            # Get-PrivateProfile_Test2.ini
            @{
                Path = $PSScriptRoot | Join-Path -ChildPath Get-PrivateProfile_Test2.ini
                Section = 'Section2'
                Entries = @(
                    @{
                        Section = 'SECTION2'
                        Key = 'KEY1'
                        Value ='VALUE1'
                    }
                    @{
                        Section = 'SECTION2'
                        Key = 'KEY2'
                        Value ='VALUE2'
                    }
                )
            }
        )

		It "returns All Entries in the Section" -TestCases $TestCases {

            # PARAMETER(S)
            Param($Path, $Section, $Entries)

            # ARRANGE
            Set-Location $PSScriptRoot

            # ACT
            [psobject[]]$actual = Get-PrivateProfile -Path $Path -Section $Section

            # ASSERT
            for ($i = 0; $i -lt $Entries.Count; $i++) {

                # OUTPUT (only for DEBUG Build)
                if ($ActiveConfigurationName -eq 'Debug') {
                    Write-Host ("`t`t`tExpected Entries[$i] (Section, Key, Value): (`"" + $Entries[$i].Section + "`", `"" + $Entries[$i].Key + '", "' + $Entries[$i].Value + '")')
                    Write-Host ("`t`t`tActual Entries[$i] (Section, Key, Value):   (`"" + $actual[$i].Section + "`", `"" + $actual[$i].Key + '", "' + $actual[$i].Value + '")')
                }

                # ASSERT (1: Section)
                $actual[$i].Section | Should Be $Section

                # ASSERT (2: Key)
                $actual[$i].Key | Should Be $Entries[$i].Key

                # ASSERT (3: Value)
                $actual[$i].Value | Should Be $Entries[$i].Value
            }

            # ASSERT (4: Count)
            $actual.Count | Should Be $Entries.Count
		}
	}


    # GET ALL SECTION(S)
	Context 'with parameter $Path only' {

        $TestCases = @(

            # Get-PrivateProfile_Test2.ini
            @{
                Path = $PSScriptRoot | Join-Path -ChildPath Get-PrivateProfile_Test2.ini
                Entries = @(
                    @{
                        Section = 'SECTION1'
                        Key = 'KEY1'
                        Value ='VALUE1'
                    }
                    @{
                        Section = 'SECTION2'
                        Key = 'KEY1'
                        Value ='VALUE1'
                    }
                    @{
                        Section = 'SECTION2'
                        Key = 'KEY2'
                        Value ='VALUE2'
                    }
                )
            }
        )

		It "returns All Entries in the file" -TestCases $TestCases {

            # PARAMETER(S)
            Param($Path, $Entries)

            # ARRANGE
            Set-Location $PSScriptRoot

            # ACT
            [psobject[]]$actual = Get-PrivateProfile -Path $Path

            # ASSERT
            for ($i = 0; $i -lt $Entries.Count; $i++) {

                # OUTPUT (only for DEBUG Build)
                if ($ActiveConfigurationName -eq 'Debug') {
                    Write-Host ("`t`t`tExpected Entries[$i] (Section, Key, Value): (`"" + $Entries[$i].Section + "`", `"" + $Entries[$i].Key + '", "' + $Entries[$i].Value + '")')
                    Write-Host ("`t`t`tActual Entries[$i] (Section, Key, Value):   (`"" + $actual[$i].Section + "`", `"" + $actual[$i].Key + '", "' + $actual[$i].Value + '")')
                }

                # ASSERT (1: Section)
                $actual[$i].Section | Should Be $Entries[$i].Section

                # ASSERT (2: Key)
                $actual[$i].Key | Should Be $Entries[$i].Key

                # ASSERT (3: Value)
                $actual[$i].Value | Should Be $Entries[$i].Value
            }

            # ASSERT (4: Count)
            $actual.Count | Should Be $Entries.Count
		}
	}
}
#>
