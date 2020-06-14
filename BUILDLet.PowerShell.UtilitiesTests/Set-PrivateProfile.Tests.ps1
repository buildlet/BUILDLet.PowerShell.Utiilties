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
        $PSScriptRoot | Set-Location
    }


    # SET VALUE
	Context 'with parameter $Path, $Section and $Key' {

        $TestCases = @(

            # New Section, Key and Value (WriteTest001.ini)
            @{
                Path = $TargetDir | Join-Path -ChildPath WriteTest001.ini
                Section = 'Section2'
                Key = 'Key1'
                Value = 'Value1'
                Initial = 
@"
[SECTION1]
KEY1=VALUE1
"@
                Expected = @(
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
                )
            }

            # Existing Section, New Key and Value (WriteTest002.ini)
            @{
                Path = $TargetDir | Join-Path -ChildPath WriteTest002.ini
                Section = 'Section1'
                Key = 'Key2'
                Value = 'Value2'
                Initial = 
@"
[SECTION1]
KEY1=VALUE1
"@
                Expected = @(
                    @{
                        Section = 'SECTION1'
                        Key = 'KEY1'
                        Value ='VALUE1'
                    }
                    @{
                        Section = 'SECTION1'
                        Key = 'Key2'
                        Value ='Value2'
                    }
                )
            }

            # Existing Section and Key, New Value (WriteTest003.ini)
            @{
                Path = $TargetDir | Join-Path -ChildPath WriteTest003.ini
                Section = 'Section1'
                Key = 'Key1'
                Value = 'Value2'
                Initial = 
@"
[SECTION1]
KEY1=VALUE1
"@
                Expected = @(
                    @{
                        Section = 'SECTION1'
                        Key = 'KEY1'
                        Value ='Value2'
                    }
                )
            }
        )

		It "adds New Entry" -TestCases $TestCases {

            # PARAMETER(S)
            Param($Path, $Section, $Key, $Value, $Initial, $Expected)


            # ARRANGE (Location)
            Set-Location $TargetDir

            # ARRANGE (Remove old INI File)
            if ($Path | Test-Path) { Remove-Item -Path $Path -Force }

            # ARRANGE (Create New INI File)
            $Initial | Out-File -FilePath $Path -Encoding utf8


            # ACT
            Set-PrivateProfile -Path $Path -Section $Section -Key $Key -Value $Value


            # GET Entries for Assertion
            [psobject[]]$profile = Get-PrivateProfile -Path $Path

            # ASSERT
            for ($i = 0; $i -lt $Expected.Count; $i++) {

                # OUTPUT (only for DEBUG Build)
                if ($ActiveConfigurationName -eq 'Debug') {
                    Write-Host ("`t`t`tExpected Entries[$i] (Section, Key, Value): (`"" + $Expected[$i].Section + "`", `"" + $Expected[$i].Key + '", "' + $Expected[$i].Value + '")')
                    Write-Host ("`t`t`tActual Entries[$i] (Section, Key, Value):   (`"" + $profile[$i].Section + "`", `"" + $profile[$i].Key + '", "' + $profile[$i].Value + '")')
                }

                # ASSERT (1: Section)
                $profile[$i].Section | Should Be $Expected[$i].Section

                # ASSERT (2: Key)
                $profile[$i].Key | Should Be $Expected[$i].Key

                # ASSERT (3: Value)
                $profile[$i].Value | Should Be $Expected[$i].Value
            }

            # ASSERT (4: Count)
            $profile.Count | Should Be $Expected.Count
		}
	}
}
#>
