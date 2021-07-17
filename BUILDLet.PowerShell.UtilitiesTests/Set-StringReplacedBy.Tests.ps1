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


# Set-StringReplacedBy
Describe "Set-StringReplacedBy" {

    BeforeAll {

        # Set $TargetDir
        $TargetDir = $PSScriptRoot | Join-Path -ChildPath 'bin' | Join-Path -ChildPath $ActiveConfigurationName

        # Set Current Directory
        Set-Location -Path $TargetDir
    }

    AfterAll {

        # Reset Location
        Set-Location -Path $PSScriptRoot
    }

    # Test Cases
    $TestCases = @(

        # 1) Set-StringReplacedByTest1.txt
        @{
            filepath_base = $TargetDir | Join-Path -ChildPath 'Set-StringReplacedByTest1'
            expected = 'Good morning, home.'
            content = 'Hello, world.'
            SubstitutionTable = @{
                'Hello' = 'Good morning'
                'world' = 'home'
            }
            Encoding = 'UTF8'
        }

        # 2) Set-StringReplacedByTest2.txt
        @{
            filepath_base = $TargetDir | Join-Path -ChildPath 'Set-StringReplacedByTest2'
            expected = @"
Version 1.60
2021年6月17日
"@
            content = @"
Version __VERSION__
__DATE__
"@
            SubstitutionTable = @{
                '__VERSION__' = '1.60'
                '__DATE__' = '2021年6月17日'
            }
            Encoding = 'UTF8'
        }
    )


	Context 'normally' {

		It "replaces content" -TestCases $TestCases {

            # PARAMETER(S)
            Param($filePath_base, $expected, $content, $SubstitutionTable, $Encoding)

            # Get FilePath
            $filepath = "$filePath_base.txt"

            # ARRANGE (Clean)
            if (Test-Path -Path $filepath) { Remove-Item -Path $filepath -Force }

            # ARRANGE (Create File)
            Out-File -FilePath $filepath -InputObject $content -Encoding $Encoding -NoNewline

            # ACT
            Set-StringReplacedBy -FilePath $filepath -SubstitutionTable $SubstitutionTable -Encoding $Encoding

            # ASSERT
            (Get-Content -Path $filepath -Encoding $Encoding -Raw) | Should Be "$expected"
		}
    }


	Context 'input from multiple files' {

		It "replaces content" -TestCases $TestCases {

            # PARAMETER(S)
            Param($filepath_base, $expected, $content, $SubstitutionTable, $Encoding)

            # Set Count
            $count = 5

            # for Multiple File Paths
            $filepaths = @()

            # ARRANGE for files
            for ($i = 1; $i -le $count; $i++) {

                # Get FilePath
                $filepath = "$filePath_base-$i.txt"
                
                # Clean
                if (Test-Path -Path $filepath) { Remove-Item -Path $FilePath -Force }

                # Create File
                Out-File -FilePath $filepath -InputObject ($content + "`r`n$i") -Encoding $Encoding -NoNewline

                # Add File Path
                $filepaths += $filepath
            }

            # ACT (Multiple Input)
            $filepaths | Set-StringReplacedBy -SubstitutionTable $SubstitutionTable -Encoding $Encoding

            # for files
            for ($i = 1; $i -le $count; $i++) {

                # ASSERT
                (Get-Content -Path $filepaths[$i - 1] -Encoding $Encoding -Raw) | Should Be ($expected + "`r`n$i")
            }
		}
    }
}
#>
