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


# Get-HtmlContent
Describe "Get-HtmlContent" {

    # SET $TargetDir
    $TargetDir = $PSScriptRoot | Join-Path -ChildPath 'bin' | Join-Path -ChildPath $ActiveConfigurationName


    # HtmlContentTest1
    $HtmlContentTestText1 = @"
<!DOCTYPE html>
<html>
    <head>
        <title>Hello</title>
    </head>
    <body>
        <p>Hello, world.
    </body>
</html>
"@

    # HtmlContentTest2: A basic HTML document (WHATWG) + modified
    $HtmlContentTestText2 = @"
<!DOCTYPE html>
<html lang="en">
 <head>
  <title>Sample page</title>
 </head>
 <body>
  <h1>Sample page</h1>
  <p>This is a <a href="demo.html">simple</a> sample.</p>
  <!-- this is a comment -->
  <!-- The following sentences were added for tests. -->
  <!-- [START] -->
  <p>This is a <a href="demo1.html">1st simple</a> sample.</p>
  <p>This is a <a href="demo2.html">2nd simple</a> sample.</p>
  <p>This is a <a href="demo3.html">3rd simple</a> sample.</p>
  <!-- [END] -->
 </body>
</html>
"@

    # HtmlContentTest3
    $HtmlContentTestText3 = @"
<!DOCTYPE HTML PUBLIC `"-//W3C//DTD HTML 4.01 Transitional//EN`" `"http://www.w3.org/TR/html4/loose.dtd`">
<html>
    <head>
        <title>Test</title>
        <meta http-equiv=`"Content-Type`" content=`"text/html; charset=utf-8`" />
    </head>
    <body>
        <h1>Test</h1>
        
        <div class=`"section`">
            <p>Hello, world.
        </div>
        
    </body>
</html>
"@

    # TestCases
    $TestCases = @(

        # Get-HtmlContentTest1.html
        @{
            InputText = $HtmlContentTestText1
            Path = $TargetDir | Join-Path -ChildPath Get-HtmlContentTest1.html
            Node = '/html/head/title'
            Expected = 'Hello'
        }

        # Get-HtmlContentTest2.html
        @{
            InputText = $HtmlContentTestText2
            Path = $TargetDir | Join-Path -ChildPath Get-HtmlContentTest2.html
            Node = '/html/body/p/a[@href="demo2.html"]'
            Expected = '2nd simple'
        }

        # Get-HtmlContentTest3.html (1)
        @{
            InputText = $HtmlContentTestText3
            Path = $TargetDir | Join-Path -ChildPath Get-HtmlContentTest3.html
            Node = '/html/head/!DOCTYPE'
            Expected = $null
        }

        # Get-HtmlContentTest3.html (2)
        @{
            InputText = $HtmlContentTestText3
            Path = $TargetDir | Join-Path -ChildPath Get-HtmlContentTest3.html
            Node = '/html/body/div[@class="section"]/p'
            Expected = 'Hello, world.'
        }

        # Get-HtmlContentTest3.html (3)
        @{
            InputText = $HtmlContentTestText3
            Path = $TargetDir | Join-Path -ChildPath Get-HtmlContentTest3.html
            Node = '/html/head/meta[@http-equiv="Content-Type"]'
            Expected = $null
        }

        # Get-HtmlContentTest3.html (4)
        @{
            InputText = $HtmlContentTestText3
            Path = $TargetDir | Join-Path -ChildPath Get-HtmlContentTest3.html
            Node = '/html/head/meta[@content="text/html; charset=utf-8"]'
            Expected = $null
        }
    )


    # with $Node Parameter
	Context 'with parameter $Node' {

        # Parse string from $InputObject
		It 'returns Node retrieved from $InputObject' -TestCases $TestCases {

            # PARAMETER(S)
            Param($InputText, $Node, $Expected)

            # ARRANGE
            # (None)

            # ACT
            $actual = Get-HtmlContent -InputObject $InputText -Node $Node

            # ASSERT
            $actual | Should Be $Expected
		}


        # Parse string read from file $Path
		It 'returns Node read from file $Path' -TestCases $TestCases {

            # PARAMETER(S)
            Param($InputText, $Path, $Node, $Expected)

            # ARRANGE (Create File)
            $InputText | Out-File -FilePath $Path -Force

            # ACT
            $actual = Get-HtmlContent -Path $Path -Node $Node

            # ASSERT
            $actual | Should Be $Expected
		}
	}


    # w/o $Node Parameter
	Context 'w/o parameter $Node' {

        # Parse string from $InputObject
		It 'returns Node retrieved from $InputObject' -TestCases $TestCases {

            # PARAMETER(S)
            Param($InputText, $Node, $Expected)

            # ARRANGE
            # (None)

            # ACT
            $actual = Get-HtmlContent -InputObject $InputText

            # ASSERT
            ([BUILDLet.Standard.Utilities.HtmlContentCollection]$actual).GetNodes($Node).Contents.Text | Should Be $Expected
		}


        # Parse string read from file $Path
		It 'returns Node read from file $Path' -TestCases $TestCases {

            # PARAMETER(S)
            Param($InputText, $Path, $Node, $Expected)

            # ARRANGE (Create File)
            $InputText | Out-File -FilePath $Path -Force

            # ACT
            $actual = Get-HtmlContent -Path $Path

            # ASSERT
            ([BUILDLet.Standard.Utilities.HtmlContentCollection]$actual).GetNodes($Node).Contents.Text | Should Be $Expected
		}
	}
}
#>
