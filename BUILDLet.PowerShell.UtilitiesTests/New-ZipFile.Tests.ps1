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


# Bytes File Name Base
$BinFilenameBase = '0xFFx1024x1024'

# New-ZipFile
Describe "New-ZipFile" {

    BeforeAll {

        # SET $TargetDir
        $TargetDir = $PSScriptRoot | Join-Path -ChildPath 'bin' | Join-Path -ChildPath $ActiveConfigurationName


        # SET Fragment Bytes File(s) Path Base
        $bytes_fragment_filepath_base = $TargetDir | Join-Path -ChildPath $BinFilenameBase

        # Create Fragment Bytes File (ALL 0xFF) [000]
        [System.IO.File]::WriteAllBytes($bytes_fragment_filepath_base + '_000.bin', @(0xFF) * 1024 * 1024)

        # SET Bin File Path Base
        $bytes_in_MB = 512
        $bytes_filepath_base = $TargetDir | Join-Path -ChildPath ($BinFilenameBase + 'x' + $bytes_in_MB.ToString())

        # Create Large Size Binary Base File (if NOT exist)
        if (-not ($bytes_filepath_base + '_0.bin' | Test-Path)) {

            # COPY Fragment Bytes Files [001-]
            for ($i = 1; $i -lt $bytes_in_MB; $i++) {

                # SET Fragment Bytes File Path
                $bytes_fragment_filepath = $bytes_fragment_filepath_base + '_' + $i.ToString('D3') + '.bin'

                # COPY Fragment File (if NOT exist)
                if (-not ($bytes_fragment_filepath | Test-Path)) {
                    cmd /C COPY /B ($bytes_fragment_filepath_base + '_000.bin') $bytes_fragment_filepath
                }
            }

            # Concatenate Fragment Filess (if NOT exist)
            cmd /C COPY /B ($bytes_fragment_filepath_base + '_*.bin') ($bytes_filepath_base + '_0.bin')
        }

        # COPY Large Size Binary Files (x4) (if NOT exist)
        for ($i = 1; $i -lt 4; $i++) {

            # COPY Large Size Binary File (if NOT exist)
            if (-not ($bytes_filepath_base + '_' + $i.ToString() + '.bin' | Test-Path)) {
                cmd /C COPY /B ($bytes_filepath_base + '_0.bin') ($bytes_filepath_base + '_' + $i.ToString() + '.bin')
            }
        }
    }


    AfterAll {

        # SET Fragment File Path(s)
        $bytes_fragment_filepath = $TargetDir | Join-Path -ChildPath ($BinFilenameBase + '_[0-9][0-9][0-9].bin')

        # REMOVE Fragment File (if exists)
        if ($bytes_fragment_filepath | Test-Path) {
            Remove-Item -Path $bytes_fragment_filepath
        }

        # Reset Location
        Set-Location -Path $PSScriptRoot
    }


	Context 'normally' {

        $TestCases = @(

            # zip\Hello\Hello.txt -> .\Zipped_Hello\Hello.zip (-> .\Zipped_Hello\Expand\Hello.txt)
            @{
                Path = $PSScriptRoot | Join-Path -ChildPath zip | Join-Path -ChildPath Hello | Join-Path -ChildPath Hello.txt
                DestinationPath = $TargetDir | Join-Path -ChildPath Zipped_Hello | Join-Path -ChildPath Hello.zip
                ZipFilePath = $TargetDir | Join-Path -ChildPath Zipped_Hello | Join-Path -ChildPath Hello.zip
                Entries = @(
                    [string]($TargetDir | Join-Path -ChildPath Zipped_Hello | Join-Path -ChildPath Expand | Join-Path -ChildPath Hello.txt)
                )
                Original = @(
                    $PSScriptRoot | Join-Path -ChildPath zip | Join-Path -ChildPath Hello | Join-Path -ChildPath Hello.txt
                )
            }

            # zip\Hello2\Hello2\ -> .\Zipped_Hello2\Hello2.zip -> (.\Zipped_Hello2\Expand\Hello2\Hello2.txt)
            @{
                Path = $PSScriptRoot | Join-Path -ChildPath zip | Join-Path -ChildPath Hello2 | Join-Path -ChildPath Hello2
                DestinationPath = $TargetDir | Join-Path -ChildPath Zipped_Hello2 | Join-Path -ChildPath Hello2.zip
                ZipFilePath = $TargetDir | Join-Path -ChildPath Zipped_Hello2 | Join-Path -ChildPath Hello2.zip
                Entries = @(
                    [string]($TargetDir | Join-Path -ChildPath Zipped_Hello2 | Join-Path -ChildPath Expand | Join-Path -ChildPath Hello2 | Join-Path -ChildPath Hello2.txt)
                )
                Original = @(
                    $PSScriptRoot | Join-Path -ChildPath zip | Join-Path -ChildPath Hello2 | Join-Path -ChildPath Hello2 | Join-Path -ChildPath Hello2.txt
                )
            }

            # zip\Hello2\Hello2\ -> .\Hello2.zip (w/o Parameter)
            @{
                Path = $PSScriptRoot | Join-Path -ChildPath zip | Join-Path -ChildPath Hello2 | Join-Path -ChildPath Hello2
                DestinationPath = $null
                ZipFilePath = $TargetDir | Join-Path -ChildPath Hello2.zip
                Entries = @(
                    [string]($TargetDir | Join-Path -ChildPath Expand | Join-Path -ChildPath Hello2 | Join-Path -ChildPath Hello2.txt)
                )
                Original = @(
                    $PSScriptRoot | Join-Path -ChildPath zip | Join-Path -ChildPath Hello2 | Join-Path -ChildPath Hello2 | Join-Path -ChildPath Hello2.txt
                )
            }

            # 0xFFx1024x1024x512_{0,..,3}.bin (x4) -> .\0xFFx1024x1024x512_0.zip (w/o Parameter)
            @{
                Path = $BinFilenameBase + 'x512_[0-9].bin'
                DestinationPath = $null
                ZipFilePath = $TargetDir | Join-Path -ChildPath ($BinFilenameBase + 'x512_0.zip')
                Entries = @(
                    [string]($TargetDir | Join-Path -ChildPath Expand | Join-Path -ChildPath ($BinFilenameBase + 'x512_0.bin'))
                    [string]($TargetDir | Join-Path -ChildPath Expand | Join-Path -ChildPath ($BinFilenameBase + 'x512_1.bin'))
                    [string]($TargetDir | Join-Path -ChildPath Expand | Join-Path -ChildPath ($BinFilenameBase + 'x512_2.bin'))
                    [string]($TargetDir | Join-Path -ChildPath Expand | Join-Path -ChildPath ($BinFilenameBase + 'x512_3.bin'))
                )
                Original = @(
                    [string]($TargetDir | Join-Path -ChildPath ($BinFilenameBase + 'x512_0.bin'))
                    [string]($TargetDir | Join-Path -ChildPath ($BinFilenameBase + 'x512_1.bin'))
                    [string]($TargetDir | Join-Path -ChildPath ($BinFilenameBase + 'x512_2.bin'))
                    [string]($TargetDir | Join-Path -ChildPath ($BinFilenameBase + 'x512_3.bin'))
                )
            }
        )

		It "creates zip file" -TestCases $TestCases {

            # PARAMETER(S)
            Param($Path, $DestinationPath, $ZipFilePath, [string[]]$Entries, [string[]]$Original)


            # ARRANGE (Location)
            Set-Location -Path $TargetDir

            # ARRANGE (Remove old $Entries)
            $Entries | ForEach-Object {
                if ($_ | Test-Path) { Remove-Item -Path $_ -Force }
            }

            # ARRANGE (for $DestinationPath 1)
            if ($ZipFilePath | Test-Path) {

                # REMOVE Target Zip File
                Remove-Item -Path $ZipFilePath -Force
            }

            # ARRANGE (for $DestinationPath 2)
            if (-not ($ZipFilePath | Split-Path -Parent | Test-Path)) {

                # Create Target Directory
                New-Item -Path ($ZipFilePath | Split-Path -Parent) -ItemType Directory -Force
            }


            # ACT
            if ($DestinationPath) {
                # with $DestinationPath parameter
                New-ZipFile -Path $Path -DestinationPath $DestinationPath
            }
            else {
                # w/o $DestinationPath parameter
                New-ZipFile -Path $Path
            }


            # ASSERT (Expand-Archive)
            if ($DestinationPath) {
                # with $DestinationPath parameter
                Expand-Archive -Path $ZipFilePath -DestinationPath ($DestinationPath | Split-Path -Parent | Join-Path -ChildPath Expand)
            }
            else {
                # w/o $DestinationPath parameter
                Expand-Archive -Path $ZipFilePath -DestinationPath ($TargetDir | Join-Path -ChildPath Expand)
            }

            # ASSERT
            for ($i = 0; $i -lt $Entries.Count; $i++) {

                # ASSERT (1: Existence)
                $Entries[$i] | Should Exist

                if ($Entries[$i] | Test-Path -PathType Leaf) {

                    # GET File Hash
                    $expected = Get-FileHash -Path $Original[$i]
                    $actual = Get-FileHash -Path $Entries[$i]

                    # Print Entries (only for DEBUG Build)
                    if ($ActiveConfigurationName -eq 'Debug') {
                        Write-Host ("`t`t`tEntries[$i] Path: `"" + $actual.Path + '"')
                        Write-Host ("`t`t`tEntries[$i] Hash: " + $actual.Hash)
                    }

                    # ASSERT (2: File Hash)
                    $actual.Hash | Should Be $expected.Hash
                }
            }
		}
	}
}
#>
