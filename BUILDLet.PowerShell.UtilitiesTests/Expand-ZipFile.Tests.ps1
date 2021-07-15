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


# Size in MB
$BinFileSizeInMB = @(512, 1024)

# Bytes File Name Base
$BinFilenameBase = '0xFFx1024x1024'

# Expand-ZipFile
Describe "Expand-ZipFile" {

    BeforeAll {

        # SET $TargetDir
        $TargetDir = $PSScriptRoot | Join-Path -ChildPath 'bin' | Join-Path -ChildPath $ActiveConfigurationName


        # SET Fragment Bytes File(s) Path Base
        $bytes_fragment_filepath_base = $TargetDir | Join-Path -ChildPath $BinFilenameBase

        # Create Fragment Bytes File (ALL 0xFF) [000] (, and [099] for ASSERT)
        [System.IO.File]::WriteAllBytes($bytes_fragment_filepath_base + '_000.bin', @(0xFF) * 1024 * 1024)
        [System.IO.File]::WriteAllBytes($bytes_fragment_filepath_base + '_099.bin', @(0xFF) * 1024 * 1024)

        # Create Zip File(s) including Large Size Binary File(s)
        $BinFileSizeInMB | ForEach-Object {

            # SET Bin File Path Base
            $bytes_in_MB = $_
            $bytes_filepath_base = $TargetDir | Join-Path -ChildPath ($BinFilenameBase + 'x' + $bytes_in_MB.ToString())

            # Do if both BIN and ZIP files do NOT exist
            if ((-not ($bytes_filepath_base + '.bin' | Test-Path)) -or (-not ($bytes_filepath_base + '.zip' | Test-Path))) {

                # COPY Fragment Bytes Files [001-]
                for ($i = 1; $i -lt $bytes_in_MB; $i++) {

                    # SET Fragment Bytes File Path
                    $bytes_fragment_filepath = $bytes_fragment_filepath_base + '_' + $i.ToString('D3') + '.bin'

                    # COPY Fragment Bytes File (if NOT exist)
                    if (-not ($bytes_fragment_filepath | Test-Path)) {
                        cmd /C COPY /B ($bytes_fragment_filepath_base + '_000.bin') $bytes_fragment_filepath
                    }
                }

                # Concatenate Fragment Bytes Files (if NOT exist)
                if (-not ($bytes_filepath_base + '.bin' | Test-Path)) {
                    cmd /C COPY /B ($bytes_fragment_filepath_base + '_*.bin') ($bytes_filepath_base + '.bin')
                }

                # Zip the file (if NOT exist)
                if (-not ($bytes_filepath_base + '.zip' | Test-Path)) {
                    Compress-Archive -Path ($bytes_filepath_base + '.bin') -DestinationPath ($bytes_filepath_base + '.zip')
                }
            }
        }

        # Create Zip File(s) including Multiple Large Size Binary (x100) Files (if BIN and ZIP files do NOT exist)
        if (-not ($bytes_fragment_filepath_base + 'x100Files.zip' | Test-Path)) {

            # COPY Fragment Bytes Files (x100)
            for ($i = 0; $i -lt 100; $i++) {

                # SET Fragment Bytes File Path
                $bytes_fragment_filepath = $bytes_fragment_filepath_base + '_' + $i.ToString('D3') + '.bin'

                # COPY Fragment (x100) File from Original BIN File (if NOT exist)
                if (-not ($bytes_fragment_filepath | Test-Path)) {
                    cmd /C COPY /B ($bytes_fragment_filepath_base + '_000.bin') $bytes_fragment_filepath
                }
            }

            # Zip Bytes Files (if NOT exist)
            if (-not ($bytes_fragment_filepath_base + 'x100Files.zip' | Test-Path)) {
                Compress-Archive -Path ($bytes_fragment_filepath_base + '_0[0-9][0-9].bin') -DestinationPath ($bytes_fragment_filepath_base + 'x100Files.zip')
            }
        }
    }



    AfterAll {

        # SET Fragment File Path(s)
        $bytes_fragment_filepath = $TargetDir | Join-Path -ChildPath ($BinFilenameBase + '_[0-9][0-9]*.bin')

        # REMOVE Fragment File (if exists)
        if ($bytes_fragment_filepath | Test-Path) {
            Remove-Item -Path $bytes_fragment_filepath
        }

        # Reset Location
        Set-Location -Path $PSScriptRoot
    }


	Context 'normally' {

        $TestCases = @(

            # zip\Hello.zip (zip\Hello\Hello.txt) -> .\Expand_Hello\Hello.txt
            @{
                Path = $PSScriptRoot | Join-Path -ChildPath zip | Join-Path -ChildPath Hello.zip
                DestinationPath = $TargetDir | Join-Path -ChildPath Expand_Hello
                Entries = @(
                    [string]($TargetDir | Join-Path -ChildPath Expand_Hello | Join-Path -ChildPath Hello.txt)
                )
                Original = @(
                    [string]($PSScriptRoot | Join-Path -ChildPath zip | Join-Path -ChildPath Hello | Join-Path -ChildPath Hello.txt)
                )
            }

            # zip\Hello2.zip (zip\Hello2\Hello2\Hello2.txt) -> .\Expand_Hello2\Hello2\Hello2.txt
            @{
                Path = $PSScriptRoot | Join-Path -ChildPath zip | Join-Path -ChildPath Hello2.zip
                DestinationPath = $TargetDir | Join-Path -ChildPath Expand_Hello2
                Entries = @(
                    [string]($TargetDir | Join-Path -ChildPath Expand_Hello2 | Join-Path -ChildPath Hello2 | Join-Path -ChildPath Hello2.txt)
                )
                Original = @(
                    [string]($PSScriptRoot | Join-Path -ChildPath zip | Join-Path -ChildPath Hello2 | Join-Path -ChildPath Hello2 | Join-Path -ChildPath Hello2.txt)
                )
            }

            # zip\Hello.zip (zip\Hello\Hello.txt) -> .\Hello\Hello.txt (w/o Parameter)
            @{
                Path = $PSScriptRoot | Join-Path -ChildPath zip | Join-Path -ChildPath Hello.zip
                DestinationPath = $null
                Entries = @(
                    [string]($TargetDir | Join-Path -ChildPath Hello | Join-Path -ChildPath Hello.txt)
                )
                Original = @(
                    [string]($PSScriptRoot | Join-Path -ChildPath zip | Join-Path -ChildPath Hello | Join-Path -ChildPath Hello.txt)
                )
            }

            # 0xFFx1024x1024x512.zip -> .\Expand_0xFFx1024x1024x512\0xFFx1024x1024x512.bin
            @{
                Path = $TargetDir | Join-Path -ChildPath ($BinFilenameBase + 'x512.zip')
                DestinationPath =  ('Expand_' + $BinFilenameBase + 'x512')
                Entries = @(
                    [string]($TargetDir | Join-Path -ChildPath ('Expand_' + $BinFilenameBase + 'x512') | Join-Path -ChildPath ($BinFilenameBase + 'x512.bin'))
                )
                Original = @(
                    [string]($TargetDir | Join-Path -ChildPath ($BinFilenameBase + 'x512.bin'))
                )
            }

            # 0xFFx1024x1024x1024.zip -> .\Expand_0xFFx1024x1024x1024\0xFFx1024x1024x1024.bin
            @{
                Path = $TargetDir | Join-Path -ChildPath ($BinFilenameBase + 'x1024.zip')
                DestinationPath =  ('Expand_' + $BinFilenameBase + 'x1024')
                Entries = @(
                    [string]($TargetDir | Join-Path -ChildPath ('Expand_' + $BinFilenameBase + 'x1024') | Join-Path -ChildPath ($BinFilenameBase + 'x1024.bin'))
                )
                Original = @(
                    [string]($TargetDir | Join-Path -ChildPath ($BinFilenameBase + 'x1024.bin'))
                )
            }

            # 0xFFx1024x1024x100Files.zip -> .\Expand_0xFFx1024x1024x100Files\0xFFx1024x1024x100_[000-099].bin
            @{
                Path = $TargetDir | Join-Path -ChildPath ($BinFilenameBase + 'x100Files.zip')
                DestinationPath =  ('Expand_' + $BinFilenameBase + 'x100Files')
                Entries = @(
                    [string]($TargetDir | Join-Path -ChildPath ('Expand_' + $BinFilenameBase + 'x100Files') | Join-Path -ChildPath ($BinFilenameBase + '_000.bin'))
                    # Omit from *_001.bin to *_098.bin
                    [string]($TargetDir | Join-Path -ChildPath ('Expand_' + $BinFilenameBase + 'x100Files') | Join-Path -ChildPath ($BinFilenameBase + '_099.bin'))
                )
                Original = @(
                    [string]($TargetDir | Join-Path -ChildPath ($BinFilenameBase + '_000.bin'))
                    # Omit from *_001.bin to *_098.bin
                    [string]($TargetDir | Join-Path -ChildPath ($BinFilenameBase + '_099.bin'))
                )
            }
        )

		It "expands zip file" -TestCases $TestCases {

            # PARAMETER(S)
            Param($Path, $DestinationPath, [string[]]$Entries, [string[]]$Original)


            # ARRANGE (Location)
            Set-Location -Path $TargetDir

            # ARRANGE (Remove old $Entries)
            $Entries | ForEach-Object {
                if ($_ | Test-Path) { Remove-Item -Path $_ -Force }
            }

            # ARRANGE (for $DestinationPath)
            if ($DestinationPath -ne $null) {

                # SET Destination Directory Path
                $dest_dirpath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($DestinationPath)

                # Check Existence of $DestinationPath
                if ($dest_dirpath | Test-Path) {

                    # REMOVE contents of $DestinationPath
                    $dest_dirpath | Get-ChildItem | ForEach-Object {
                        Remove-Item -Path $_.FullName -Recurse -Force
                    }
                }
                else {
                    # NEW $DestinationPath
                    New-Item -Path $dest_dirpath -ItemType Directory -Force
                }
            }


            # ACT
            if ($DestinationPath -ne $null) {
                # with $DestinationPath parameter
                Expand-ZipFile -Path $Path -DestinationPath $DestinationPath
            }
            else {
                # w/o $DestinationPath parameter
                Expand-ZipFile -Path $Path
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
