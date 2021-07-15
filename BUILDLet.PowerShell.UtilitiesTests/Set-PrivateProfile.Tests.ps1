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


# Set-PrivateProfile
Describe "Set-PrivateProfile" {

    BeforeAll {

        # SET $TargetDir
        $TargetDir = $PSScriptRoot | Join-Path -ChildPath 'bin' | Join-Path -ChildPath $ActiveConfigurationName
    }

    AfterAll {

        # Reset Location
        Set-Location -Path $PSScriptRoot
    }


    # SET VALUE
	Context 'with parameter $Path, $Section and $Key' {

        $TestCases = @(

            # New Section, Key and Value (Set-PrivateProfileTest1.ini)
            @{
                Path = $TargetDir | Join-Path -ChildPath Set-PrivateProfileTest1.ini
                Section = 'Section2'
                Key = 'Key1'
                Value = 'Value1'
                Content =
@"
[SECTION1]
KEY1=VALUE1
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
                        )
                    }
                )
            }

            # Existing Section, New Key and Value (Set-PrivateProfileTest2.ini)
            @{
                Path = $TargetDir | Join-Path -ChildPath Set-PrivateProfileTest2.ini
                Section = 'Section1'
                Key = 'Key2'
                Value = 'Value2'
                Content =
@"
[SECTION1]
KEY1=VALUE1
"@
                Sections = @(
                    @{
                        Name = 'SECTION1'
                        Entries = @(
                            @{
                                Key = 'KEY1'
                                Value ='VALUE1'
                            }
                            @{
                                Key = 'Key2'
                                Value ='Value2'
                            }
                        )
                    }
                )
            }

            # Existing Section and Key, New Value (Set-PrivateProfileTest3.ini)
            @{
                Path = $TargetDir | Join-Path -ChildPath Set-PrivateProfileTest3.ini
                Section = 'Section1'
                Key = 'Key1'
                Value = 'Value2'
                Content =
@"
[SECTION1]
KEY1=VALUE1
"@
                Sections = @(
                    @{
                        Name = 'SECTION1'
                        Entries = @(
                            @{
                                Key = 'KEY1'
                                Value ='Value2'
                            }
                        )
                    }
                )
            }
        )

		It "adds New Entry" -TestCases $TestCases {

            # PARAMETER(S)
            Param($Path, $Section, $Key, $Value, $Content, $Sections)


            # ARRANGE (Location)
            Set-Location -Path $TargetDir

            # ARRANGE (Remove old INI File)
            if ($Path | Test-Path) { Remove-Item -Path $Path -Force }

            # ARRANGE (Create New INI File)
            $Content | Out-File -FilePath $Path -Encoding utf8


            # ACT
            Set-PrivateProfile -Path $Path -Section $Section -Key $Key -Value $Value


            # GET Entries for Assertion
            $actual = Get-PrivateProfile -Path $Path

            # ASSERT (for Sections)
            $Sections | ForEach-Object {

                # SET Expected Secction
                $expected_section = $_

                # OUTPUT (only for DEBUG Build)
                if ($ActiveConfigurationName -eq 'Debug') {
                    Write-Host ("`t`t`tSection Name: `"" + $expected_section.Name + '"')
                }

                # ASSERT (1: Section Name)
                $actual.ContainsKey($expected_section.Name) | Should Be $true

                # for Entries
                $expected_section.Entries | ForEach-Object {

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
