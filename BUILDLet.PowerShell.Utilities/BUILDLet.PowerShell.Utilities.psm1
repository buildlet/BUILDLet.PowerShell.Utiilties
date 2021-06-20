<###############################################################################
 The MIT License (MIT)

 Copyright (c) 2015 Daiki Sakamoto

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

################################################################################
Function Get-DateString {
<#

.SYNOPSIS
指定した時刻に対する日付を、指定した書式の文字列として取得します。

.DESCRIPTION
指定した時刻に対する日付に対して、ロケール ID (LCID) および 標準
またはカスタムの日時書式指定文字列を指定して、文字列として取得します。

.INPUTS
System.DateTime

.OUTPUTS
System.String

.EXAMPLE
Get-DateString
今日の日付を文字列として取得します。
書式指定文字列はデフォルトの 'D' なので、日本であれば 'yyyy年M月d日' になります。

.EXAMPLE
Get-DateString -Date 2014/4/29 -LCID en-US -Format m
2014年4月29日 (0:00) に対する日付文字列を、ロケール ID 'en-US'
および書式指定文字列 'm' の文字列として取得します。

.LINK
https://github.com/buildlet/PowerShellUtilities

.LINK
https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-lcid/70feba9f-294e-491e-b6eb-56532684c37f

.LINK
https://docs.microsoft.com/ja-jp/dotnet/standard/base-types/standard-date-and-time-format-strings

.LINK
https://docs.microsoft.com/ja-jp/dotnet/standard/base-types/custom-date-and-time-format-strings

.LINK
https://docs.microsoft.com/ja-jp/dotnet/api/system.datetime.tostring?redirectedfrom=MSDN&view=netframework-4.7.2#System_DateTime_ToString_System_String_System_IFormatProvider_

.LINK
https://docs.microsoft.com/ja-jp/dotnet/api/system.globalization.cultureinfo.-ctor?redirectedfrom=MSDN&view=netframework-4.7.2#System_Globalization_CultureInfo__ctor_System_String_

.LINK
http://www.infoterm.info/standardization/iso_639_1_2002.php

#>
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [System.DateTime]
        # 表示する日付を指定します。
        # 既定では、このコマンドを実行した当日です。
        $Date = (Get-Date),

        [Parameter(Position = 1, ValueFromPipelineByPropertyName = $true)]
        [string]
        # ロケール ID (LCID) を指定します。
        # 省略した場合の既定の設定は、現在のカルチャーの LCID です。
        $LCID = (Get-Culture).ToString(),

        [Parameter(Position = 2)]
        [string]
        # 書式指定文字列を指定します。
        # 省略した場合の既定の設定は 'D' です。
        $Format = 'D'
    )

    # Input Processing Operations
    Process {
        Write-Output ($Date).ToString($Format, (New-Object System.Globalization.CultureInfo($LCID)))
    }
}

################################################################################
Function Get-AuthenticodeSignerName {
<#

.SYNOPSIS
指定されたファイルのデジタル署名の署名者の名前を取得します。

.DESCRIPTION
デジタル署名情報の署名者の名前 (Subject) を、X.509 証明書 (SignerCertificate)
の発行先 (Subject) に含まれる CN (Common Name)　から取得します。

.INPUTS
System.String

.OUTPUTS
System.String

.LINK
https://github.com/buildlet/PowerShellUtilities

.LINK
https://docs.microsoft.com/ja-jp/powershell/module/Microsoft.PowerShell.Security/Get-AuthenticodeSignature

#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]
        # デジタル署名の署名者名を取得するファイルのパスを指定します。
        $FilePath
    )

    # Input Processing Operations
    Process {
        if ($null -ne ($cert = (Get-AuthenticodeSignature -FilePath $FilePath).SignerCertificate)) {
            $cert.Subject -split ',' |
            Where-Object { $_ -like 'CN=*' } |
            ForEach-Object { Write-Output ($_ -split 'CN=')[1] }
        }
    }
}

################################################################################
Function Get-FileVersionInfo {
<#

.SYNOPSIS
ディスク上の物理ファイルのバージョン情報を取得します。

.DESCRIPTION
指定したファイルのバージョン情報を System.Diagnostics.FileVersionInfo として取得します。

.INPUTS
System.String

.OUTPUTS
System.Diagnostics.FileVersionInfo

.EXAMPLE
Get-FileVersion -Path .\setup.exe
カレントディレクトリにある setup.exe のバージョン情報を取得します。

.LINK
https://github.com/buildlet/PowerShellUtilities

.LINK
http://msdn.microsoft.com/ja-jp/library/system.diagnostics.fileversioninfo

#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]
        # ファイルバージョンを取得するファイルのパスを指定します。
        $FilePath
    )

    # Input Processing Operations
    Process {
        Write-Output (Get-Item -Path $FilePath).VersionInfo
    }
}

################################################################################
Function Get-FileVersion {
<#

.SYNOPSIS
ディスク上の物理ファイルのファイルバージョンを取得します。

.DESCRIPTION
指定したファイルのファイルバージョン (System.Diagnostics.FileVersionInfo.FileVersion) を
文字列として取得します。

.INPUTS
System.String

.OUTPUTS
System.String

.LINK
https://github.com/buildlet/PowerShellUtilities

.LINK
http://msdn.microsoft.com/ja-jp/library/system.diagnostics.fileversioninfo.fileversion.aspx

#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]
        # ファイルバージョンを取得するファイルのパスを指定します。
        $FilePath
    )

    # Input Processing Operations
    Process {
        Write-Output (Get-Item -Path $FilePath).VersionInfo.FileVersion
    }
}

################################################################################
Function Get-ProductVersion {
<#

.SYNOPSIS
ディスク上の物理ファイルの製品バージョンを取得します。

.DESCRIPTION
指定したファイルの製品バージョン (System.Diagnostics.FileVersionInfo.ProductVersion) を
文字列として取得します。

.INPUTS
System.String

.OUTPUTS
System.String

.LINK
https://github.com/buildlet/PowerShellUtilities

.LINK
http://msdn.microsoft.com/ja-jp/library/system.diagnostics.fileversioninfo.productversion.aspx

#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]
        # 製品バージョンを取得するファイルのパスを指定します。
        $FilePath
    )

    # Input Processing Operations
    Process {
        Write-Output (Get-Item -Path $FilePath).VersionInfo.ProductVersion
    }
}

################################################################################
Function Get-ProductName {
<#

.SYNOPSIS
ディスク上の物理ファイルの製品名を取得します。

.DESCRIPTION
指定したファイルの製品名 (System.Diagnostics.FileVersionInfo) を文字列として取得します。

.INPUTS
System.String

.OUTPUTS
System.String

.LINK
https://github.com/buildlet/PowerShellUtilities

.LINK
http://msdn.microsoft.com/ja-jp/library/system.diagnostics.fileversioninfo.productname.aspx

#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]
        # 製品名を取得するファイルのパスを指定します。
        $FilePath
    )

    # Input Processing Operations
    Process {
        Write-Output (Get-Item -Path $FilePath).VersionInfo.ProductName
    }
}

################################################################################
Function Get-FileDescription {
<#

.SYNOPSIS
ディスク上の物理ファイルの説明を取得します。

.DESCRIPTION
指定したファイルの説明 (System.Diagnostics.FileVersionInfo.FileDescription) を
文字列として取得します。

.INPUTS
System.String

.OUTPUTS
System.String

.LINK
https://github.com/buildlet/PowerShellUtilities

.LINK
http://msdn.microsoft.com/ja-jp/library/system.diagnostics.fileversioninfo.filedescription.aspx

#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]
        # ファイルの説明を取得するファイルのパスを指定します。
        $FilePath
    )

    # Input Processing Operations
    Process {
        Write-Output (Get-Item -Path $FilePath).VersionInfo.FileDescription
    }
}

################################################################################
Function ConvertTo-WslPath {
<#

.SYNOPSIS
Windows path を WSL path に変換します。

.DESCRIPTION
通常の Windows パス文字列を WSL パス文字列に変換します。

.INPUTS
System.String

.OUTPUTS
System.String

.LINK
https://github.com/buildlet/PowerShellUtilities

#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]
        # 変換する Windows パスを指定します。
        $Path
    )

    # Input Processing Operations
    Process {

        # Absolute Path:
        if ([System.IO.Path]::IsPathRooted($Path)) {
            $Path = '/mnt/' + [char]::ToLower($Path[0]) + $Path.Substring(2)
        }

        # Replace Directory Separator ('\' -> '/') and Output it
        $Path.Replace([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) | Write-Output
    }
}

################################################################################
Function Send-MagicPacket {
<#

.SYNOPSIS
マジックパケットを送信します。

.DESCRIPTION
マジックパケット (AMD Magic Packet Format) を UDP で送信します。

.INPUTS
System.String

.OUTPUTS
None

.LINK
https://github.com/buildlet/PowerShellUtilities

#>
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]
        # 起動対象のコンピューターの MAC アドレスを指定します。
        $MacAddress,

        [Parameter(Position = 1, ValueFromPipelineByPropertyName = $true)]
        [string]
        # ポート番号を指定します。
        # 既定のポート番号は 2304 です。
        $Port = 2304,

        [Parameter(Position = 2, ValueFromPipelineByPropertyName = $true)]
        [string]
        # 送信回数を指定します。
        # 既定のポート送信回数は 1 回です。
        $Count = 1,

        [Parameter(Position = 3, ValueFromPipelineByPropertyName = $true)]
        [string]
        # 送信間隔をミリ秒で指定します。
        # 既定の送信間隔は 0 ミリ秒です。
        $Interval = 0
    )


    # Pre-Processing Operations
    # Begin { }


    # Input Processing Operations
    Process {

        if ($PSCmdlet.ShouldProcess("MAC Address = '$MacAddress', Port = $Port, Count = $Count, Interval = $Interval", "マジックパケットの送信"))
        {
            $sent = [BUILDLet.Standard.Utilities.Network.MagicPacket]::Send($MacAddress, $Port, $Count, $Interval)

            # for Output
            for ($i = 0; $i -lt $sent.Length; $i++) {

                # Verbose Output
                Write-Verbose -Message ("Source IP Address[$i] = " + $sent[$i])
            }
        }
    }


    # Post-Processing Operations
    # End { }
}

################################################################################
Function Get-StringReplacedBy {
<#
.SYNOPSIS
入力文字列を置換します。

.DESCRIPTION
入力文字列に対して、置換対象文字列セットの文字列を検索・置換して出力します。

.INPUTS
System.String

.OUTPUTS
System.String

.EXAMPLE
Get-Content -Path './Readme.txt' | Get-StringReplacedBy -SubstitutionTable @{ '__DATE__' = 'December 19, 2020', '__VERSION__' = '1.00' }
Readme.txt 内にある文字列 '__DATE__' および '__VERSION__' を、それぞれ 'December 19, 2020' および '1.00' に置換します。

#>
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]
        # 入力文字列を指定します。
        $InputObject,

        [Parameter(Mandatory = $true, Position = 1)]
        [hashtable]
        # 置換対象の文字列セットを指定します。
        $SubstitutionTable
    )


    # Pre-Processing Operations
    # Begin { }


    # Input Processing Operations
    Process {

        # Replace string(s) in $SubstitutionTable
        $SubstitutionTable.Keys | ForEach-Object {

            # GET substitution strings (bofore & after)
            $before = $_
            $after = $SubstitutionTable.$_

            # Replace the string
            $InputObject = $InputObject -replace $before, $after
        }

        # OUTPT
        $InputObject | Write-Output
    }


    # Post-Processing Operations
    # End { }
}
################################################################################
Export-ModuleMember -Function *
