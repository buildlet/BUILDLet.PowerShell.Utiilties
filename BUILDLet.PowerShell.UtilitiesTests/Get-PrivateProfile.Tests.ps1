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

            # Get-PrivateProfileTest1.ini
            @{
                Path = $PSScriptRoot | Join-Path -ChildPath Get-PrivateProfileTest1.ini
                Section = 'Section'
                Key = 'Key'
                Value = 'VALUE'
            }
        )

		It "returns Value" -TestCases $TestCases {

            # PARAMETER(S)
            Param($Path, $Section, $Key, $Value)

            # ARRANGE
            Set-Location -Path $PSScriptRoot

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

            # Get-PrivateProfileTest1.ini
            @{
                Path = $PSScriptRoot | Join-Path -ChildPath Get-PrivateProfileTest1.ini
                Section = 'Section'
                Entries = @(
                    @{
                        Key = 'KEY'
                        Value ='VALUE'
                    }
                )
            }

            # Get-PrivateProfileTest2.ini
            @{
                Path = $PSScriptRoot | Join-Path -ChildPath Get-PrivateProfileTest2.ini
                Section = 'Section2'
                Entries = @(
                    @{
                        Key = 'KEY1'
                        Value ='VALUE1'
                    }
                    @{
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
            Set-Location -Path $PSScriptRoot

            # ACT
            $actual = Get-PrivateProfile -Path $Path -Section $Section

            # ASSERT (for Entries)
            $Entries | % {

                # SET Expected Entry
                $expected_entry = $_

                # OUTPUT (only for DEBUG Build)
                if ($ActiveConfigurationName -eq 'Debug') {
                    Write-Host ("`t`t`tEntry: `"" + $expected_entry.Key + '", "' + $actual[$expected_entry.Key] + '"')
                }

                # ASSERT (1: Entry)
                $actual[$expected_entry.Key] | Should Be $expected_entry.Value
            }

            # ASSERT (2: Count)
            $actual.Count | Should Be $Entries.Count
		}
	}


    # GET ALL SECTION(S) from File
	Context 'with parameter $Path only' {

        $TestCases = @(

            # Get-PrivateProfileTest2.ini
            @{
                Path = $PSScriptRoot | Join-Path -ChildPath Get-PrivateProfileTest2.ini
                Sections = @(
                    @{
                        Name = 'SECTION1'
                        Entries = @(
                            @{
                                Key = 'KEY1'
                                Value ='VALUE1'
                            }
                        )
                    }
                    @{
                        Name = 'SECTION2'
                        Entries = @(
                            @{
                                Key = 'KEY1'
                                Value ='VALUE1'
                            }
                            @{
                                Key = 'KEY2'
                                Value ='VALUE2'
                            }
                        )
                    }
                )
            }
        )

		It "returns All Entries in the file" -TestCases $TestCases {

            # PARAMETER(S)
            Param($Path, $Sections)

            # ARRANGE
            Set-Location -Path $PSScriptRoot

            # ACT
            $actual = Get-PrivateProfile -Path $Path

            # ASSERT (for Sections)
            $Sections | % {

                # SET Expected Secction
                $expected_section = $_

                # OUTPUT (only for DEBUG Build)
                if ($ActiveConfigurationName -eq 'Debug') {
                    Write-Host ("`t`t`tSection Name: `"" + $expected_section.Name + '"')
                }

                # ASSERT (1: Section Name)
                $actual.ContainsKey($expected_section.Name) | Should Be $true

                # for Entries
                $expected_section.Entries | % {

                    # SET Expected Entry
                    $expected_entry = $_

                    # OUTPUT (only for DEBUG Build)
                    if ($ActiveConfigurationName -eq 'Debug') {
                        Write-Host ("`t`t`tEntry: `"" + $expected_entry.Key + '", "' + $actual[$expected_section.Name][$expected_entry.Key] + '"')
                    }

                    # ASSERT (2: Entry)
                    $actual[$expected_section.Name][$expected_entry.Key] | Should Be $expected_entry.Value
                }

                # ASSERT (3: Count of Entries)
                $actual[$expected_section.Name].Count | Should Be $expected_section.Entries.Count
            }

            # ASSERT (4: Count of Sections)
            $actual.Count | Should Be $Sections.Count
		}
	}


    # GET ALL SECTION(S) from $InputObject
	Context 'with parameter $InputObject' {

        # 1)
        $TestCases = @(

            @{
                InputObject =
@"
[SECTION]
KEY=VALUE
"@
                Sections = @(
                    @{
                        Name = 'SECTION'
                        Entries = @(
                            @{
                                Key = 'KEY'
                                Value ='VALUE'
                            }
                        )
                    }
                )
            }

            # 2)
            @{
                InputObject =
@"
[SECTION1]
KEY1=VALUE1
[SECTION2]
KEY1=VALUE1
KEY2=VALUE2
"@
                Sections = @(
                    @{
                        Name = 'SECTION1'
                        Entries = @(
                            @{
                                Key = 'KEY1'
                                Value ='VALUE1'
                            }
                        )
                    }
                    @{
                        Name = 'SECTION2'
                        Entries = @(
                            @{
                                Key = 'KEY1'
                                Value ='VALUE1'
                            }
                            @{
                                Key = 'KEY2'
                                Value ='VALUE2'
                            }
                        )
                    }
                )
            }
        )

		It "returns All Entries in content" -TestCases $TestCases {

            # PARAMETER(S)
            Param($InputObject, $Sections)

            # ARRANGE
            Set-Location -Path $PSScriptRoot

            # ACT
            $actual = Get-PrivateProfile -InputObject $InputObject

            # ASSERT (for Sections)
            $Sections | % {

                # SET Expected Secction
                $expected_section = $_

                # OUTPUT (only for DEBUG Build)
                if ($ActiveConfigurationName -eq 'Debug') {
                    Write-Host ("`t`t`tSection Name: `"" + $expected_section.Name + '"')
                }

                # ASSERT (1: Section Name)
                $actual.ContainsKey($expected_section.Name) | Should Be $true

                # for Entries
                $expected_section.Entries | % {

                    # SET Expected Entry
                    $expected_entry = $_

                    # OUTPUT (only for DEBUG Build)
                    if ($ActiveConfigurationName -eq 'Debug') {
                        Write-Host ("`t`t`tEntry: `"" + $expected_entry.Key + '", "' + $actual[$expected_section.Name][$expected_entry.Key] + '"')
                    }

                    # ASSERT (2: Entry)
                    $actual[$expected_section.Name][$expected_entry.Key] | Should Be $expected_entry.Value
                }

                # ASSERT (3: Count of Entries)
                $actual[$expected_section.Name].Count | Should Be $expected_section.Entries.Count
            }

            # ASSERT (4: Count of Sections)
            $actual.Count | Should Be $Sections.Count
		}
	}
}
#>
