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


# New-TestCertificate
Describe "New-TestCertificate" {

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

	Context "without parameter ('Password' parameter is specified.)" {

		It "creates certificate, and exports it as 'Test.pfx' and 'Test.cer'"  {

            # File(s) to be created
            $ExportedFiles = @(
                $TargetDir | Join-Path -ChildPath 'Test.pfx'
                $TargetDir | Join-Path -ChildPath 'Test.cer'
            )

            # ARRANGE (Clean)
            $ExportedFiles | ForEach-Object {
                if (Test-Path -Path $_) { Remove-Item -Path $_ -Force }
            }

            # ARRANGE (Password)
            $password = ConvertTo-SecureString -String '12345' -AsPlainText -Force

            # ACT
            $actual = New-TestCertificate -Password $password

            # ASSERT (Subject)
            $actual.Subject | Should Be 'CN=Code Signing Test Certificate'
            
            # ASSERT (Files)
            $ExportedFiles | ForEach-Object {
                $_ | Test-Path | Should Be $true
            }
		}
    }
    #>

	Context 'with parameters' {

        $TestCases = @(

            # 1) Same as Default
            @{
                Path = 'Test'
                Subject = 'Code Singing Test Certificate'
                ExportFormat = 'Both'
                PassString = '12345'
                ExportedFiles = @(
                    $TargetDir | Join-Path -ChildPath 'Test.pfx'
                    $TargetDir | Join-Path -ChildPath 'Test.cer'
                )
            }

            # 2) Only PFX
            @{
                Path = '.\Test2'
                Subject = 'Code Singing Test Certificate 2'
                ExportFormat = 'PFX'
                PassString = '1234ABCD'
                ExportedFiles = @(
                    $TargetDir | Join-Path -ChildPath 'Test2.pfx'
                )
            }

            # 2) Only CER
            @{
                Path = '.\Test3.CER'
                Subject = 'Code Singing Test Certificate 3'
                ExportFormat = 'CER'
                PassString = $null
                ExportedFiles = @(
                    $TargetDir | Join-Path -ChildPath 'Test3.CER.cer'
                )
            }
        )

		It "creates certificate (and exports it as PFX and/or CER file)" -TestCases $TestCases  {

            # PARAMETER(s)
            Param($Path, $Subject, $ExportFormat, $PassString, $ExportedFiles)

            # ARRANGE (Clean)
            $ExportedFiles | ForEach-Object {
                if (Test-Path -Path $_) { Remove-Item -Path $_ -Force }
            }

            # ARRANGE (Password)
            if ($PassString) {

                # Get Password
                $password = ConvertTo-SecureString -String $PassString -AsPlainText -Force
            }

            # ACT
            if (($ExportFormat.ToUpper() -eq 'BOTH') -or ($ExportFormat.ToUpper() -eq 'PFX')) {

                # ACT (Password is required.)
                $actual = New-TestCertificate `
                    -Path $Path `
                    -Subject $Subject `
                    -ExportFormat $ExportFormat `
                    -Password $password
            }
            else {
                
                # ACT (Password is NOT required.)
                $actual = New-TestCertificate `
                    -Path $Path `
                    -Subject $Subject `
                    -ExportFormat $ExportFormat
            }

            # ASSERT (Subject)
            $actual.Subject | Should Be "CN=$Subject"
            
            # ASSERT (Files)
            $ExportedFiles | ForEach-Object {
                $_ | Test-Path | Should Be $true
            }
		}
    }
    #>
}
#>
