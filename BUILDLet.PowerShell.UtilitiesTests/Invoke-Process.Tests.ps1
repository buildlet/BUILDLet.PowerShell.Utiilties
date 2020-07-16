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


# Invoke-Process
Describe "Invoke-Process" {

    BeforeAll {

        # SET $TargetDir
        $TargetDir = $PSScriptRoot | Join-Path -ChildPath 'bin' | Join-Path -ChildPath $ActiveConfigurationName
    }

    AfterAll {

        # Reset Location
        Set-Location -Path $PSScriptRoot
    }


	Context 'External Program' {

        $TestCases = @(

            # 1) C:\Windows\System32\PING.EXE (Full Path)
            @{
                FilePath = 'C:\Windows\System32\PING.EXE'
                ArgumentList = @('127.0.0.1', '-n 1')
                OutputEncoding = [System.Text.Encoding]::GetEncoding('shift_jis')
                ExitCode = 0
                WoW64 = $false
            }

            # 2) PING.EXE
            @{
                FilePath = 'PING.EXE'
                ArgumentList = @('127.0.0.1', '-n 1')
                OutputEncoding = [System.Text.Encoding]::GetEncoding('shift_jis')
                ExitCode = 0
                WoW64 = $false
            }

            # 3) PING
            @{
                FilePath = 'PING'
                ArgumentList = @('127.0.0.1', '-n 1')
                OutputEncoding = [System.Text.Encoding]::GetEncoding('shift_jis')
                ExitCode = 0
                WoW64 = $false
            }

            # 4) WSL: pwd
            @{
                FilePath = 'WSL'
                ArgumentList = 'pwd'
                OutputEncoding = [System.Text.Encoding]::UTF8
                ExitCode = 0
                WoW64 = $true
            }

            # 5) WSL: ls-l
            @{
                FilePath = 'WSL'
                ArgumentList = 'ls -l'
                OutputEncoding = [System.Text.Encoding]::UTF8
                ExitCode = 0
                WoW64 = $true
            }

            # 6) WSL: ping
            @{
                FilePath = 'WSL'
                ArgumentList = @('ping', '-c1', '127.0.0.1')
                OutputEncoding = [System.Text.Encoding]::UTF8
                ExitCode = 0
                WoW64 = $true
            }

            <# 7) SignTool.exe
            @{
                FilePath = 'C:\Program Files (x86)\Windows Kits\10\bin\10.0.19041.0\x86\signtool.exe'
                ArgumentList = @('sign', '/f Test.pfx', '/p 12345', '/t http://timestamp.digicert.com/?alg=sha1', '/v', 'Test.exe')
                OutputEncoding = [System.Text.Encoding]::UTF8
                ExitCode = 0
                WoW64 = $false
            }
            #>
        )

		It "returns 0" -TestCases $TestCases {

            # PARAMETER(S)
            Param($FilePath, $ArgumentList, $OutputEncoding, $ExitCode, $WoW64)

            # Inconclusive on Visual Studio
            if ($WoW64 -and ($Host.Name -eq 'PowerShell Tools for Visual Studio Test Adapter')) {

                # SET Test Result "Inconclusive"
                Set-TestInconclusive -Message ("'$FilePath' is invisible from host '" + $Host.Name + "'")
            }


            # ARRANGE (Location)
            Set-Location -Path $TargetDir

            # ACT
            if ($ArgumentList) {
                $actual = Invoke-Process -FilePath $FilePath -ArgumentList $ArgumentList -OutputEncoding $OutputEncoding -PassThru -OutVariable stdout -WarningVariable warning 3> $null
            }
            else {
                $actual = Invoke-Process -FilePath $FilePath -OutputEncoding $OutputEncoding -PassThru -OutVariable stdout -WarningVariable warning 3> $null
            }

            # OUTPUT (only for DEBUG Build)
            if ($ActiveConfigurationName -eq 'Debug') {
                $warning | % {
                    Write-Host "`t`t`tWARNING: $_"
                }
                $stdout | % {
                    Write-Host "`t`t`tOUTPUT: $_"
                }
            }

            # ASSERT
            $actual | Should Be $ExitCode
		}
	}


	Context 'when Current Location is set by DirectoryInfo object' {

        $TestCases = @(

            # 1) C:\Windows\System32\PING.EXE (Full Path)
            @{
                FilePath = 'C:\Windows\System32\PING.EXE'
                ArgumentList = @('127.0.0.1', '-n 1')
                OutputEncoding = [System.Text.Encoding]::GetEncoding('shift_jis')
                ExitCode = 0
                WoW64 = $false
            }

            # 1) WSL pwd
            @{
                FilePath = 'WSL'
                ArgumentList = @('pwd')
                OutputEncoding = [System.Text.Encoding]::UTF8
                ExitCode = 0
                WoW64 = $true
            }
        )

		It "invokes process successfully" -TestCases $TestCases {

            # PARAMETER(S)
            Param($FilePath, $ArgumentList, $OutputEncoding, $ExitCode, $WoW64)

            # Inconclusive on Visual Studio
            if ($WoW64 -and ($Host.Name -eq 'PowerShell Tools for Visual Studio Test Adapter')) {

                # SET Test Result "Inconclusive"
                Set-TestInconclusive -Message ("'$FilePath' is invisible from host '" + $Host.Name + "'")
            }


            # ACT: Set Location
            Get-Item -Path $TargetDir | Set-Location

            # ACT
            $actual = Invoke-Process -FilePath $FilePath -ArgumentList $ArgumentList -OutputEncoding $OutputEncoding -PassThru -OutVariable stdout -WarningVariable warning 3> $null

            # OUTPUT (only for DEBUG Build)
            if ($ActiveConfigurationName -eq 'Debug') {

                Write-Host "`t`t`tWARNING: $_"

                $warning | % {
                    Write-Host "`t`t`tWARNING: $_"
                }
                $stdout | % {
                    Write-Host "`t`t`tOUTPUT: $_"
                }
            }

            # ASSERT
            $actual | Should Be $ExitCode
		}
	}
}
#>
