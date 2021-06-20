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


# Sned-MagicPacket
Describe "Sned-MagicPacket" {

	Context 'MagicPacket' {

        $TestCases = @(

            # 1) only MAC Address
            @{
                MacAddress = '00-11-22-AA-BB-CC'
                Port = $null
                Count = $null
                Interval = $null
            }

            # 2)
            @{
                MacAddress = '00:11:22:AA:BB:CC'
                Port = 2304
                Count = 3
                Interval = 100
            }
        )

		It "is sent" -TestCases $TestCases {

            # PARAMETER(S)
            Param($MacAddress, $Port, $Count, $Interval)

            # ARRANGE
            $param = @{ MacAddress = $MacAddress }
            if ($null -ne $Port) { $param += @{ Port = $Port}}
            if ($null -ne $Count) { $param += @{ Count = $Count}}
            if ($null -ne $Interval) { $param += @{ Interval = $Interval}}

            # ACT
            Send-MagicPacket @param #-Verbose

            # ASSERT
            # (None)
		}
	}
}
#>
