/***************************************************************************************************
The MIT License (MIT)

Copyright 2020 Daiki Sakamoto

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and 
associated documentation files (the "Software"), to deal in the Software without restriction, 
including without limitation the rights to use, copy, modify, merge, publish, distribute, 
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is 
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or 
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT 
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, 
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
***************************************************************************************************/
using System;
using System.Collections.Generic;
using System.IO;
using System.Management.Automation;
using System.Collections.ObjectModel; // for ReadOnlyDictionary
using System.Linq;
using System.Text;         // for Encoding
using System.Diagnostics;  // for Debug

using BUILDLet.Standard.Utilities;    // for HtmlSyntaxParser
using BUILDLet.Standard.Diagnostics;  // for DebugInfo

namespace BUILDLet.PowerShell.Utilities.Commands
{
    [CmdletBinding(HelpUri = "https://github.com/buildlet/BUILDLet.PowerShell.Utilities")]
    [Cmdlet(VerbsCommon.Get, "HtmlContent", SupportsShouldProcess = true, DefaultParameterSetName = "Path")]
    [OutputType(typeof(string), typeof(HtmlContentCollection))]
    public class GetHtmlContentCmmmand : PSCmdlet
    {
        // ----------------------------------------------------------------------------------------------------
        // PARAMETER(S)
        // ----------------------------------------------------------------------------------------------------

        // .PARAMETER Path
        [Parameter(HelpMessage = PathHelpMessage, Mandatory = true, ParameterSetName = "Path", Position = 0, ValueFromPipeline = true)]
        [Alias("PSPath")]
        public string Path { get; set; }
        private const string PathHelpMessage =
@"入力ファイルのパスを指定します。";


        // .PARAMETER InputObject
        [Parameter(HelpMessage = InputObjectHelpMessage, Mandatory = true, ParameterSetName = "InputObject", Position = 0, ValueFromPipeline = true)]
        public string InputObject { get; set; }
        private const string InputObjectHelpMessage =
@"入力文字列を指定します。";


        // .PARAMETER Section
        [Parameter(HelpMessage = NodeHelpMessage, Position = 1)]
        public string Node { get; set; }
        private const string NodeHelpMessage =
@"任意のノードのコンテンツを文字列として取得する場合に、取得する HTML コンテンツのノードを XPath で指定します。
このパラメーターを省略した場合は、入力ファイル または 入力文字列全体を構文解析した結果を取得します。";


        // .PARAMETER Encoding
        [Parameter(HelpMessage = EncodingHelpMessage)]
        public Encoding Encoding { get; set; } = Encoding.UTF8;
        private const string EncodingHelpMessage =
@"エンコーディングを指定します。
既定のエンコーディングは System.Text.Encoding.UTF8 です。";


        // ----------------------------------------------------------------------------------------------------
        // Pre-Processing Operations
        // ----------------------------------------------------------------------------------------------------
        // (None)


        // ----------------------------------------------------------------------------------------------------
        // Input Processing Operations
        // ----------------------------------------------------------------------------------------------------
        protected override void ProcessRecord()
        {
            if (this.ParameterSetName == "Path")
            {
                foreach (var filepath in SessionLocation.GetResolvedPath(this.SessionState, this.Path))
                {
                    // Validation (File Existence Check):
                    if (!File.Exists(filepath)) { throw new FileNotFoundException(); }

                    // Should Process
                    if (this.ShouldProcess($"ファイル '{filepath}'", "HTML コンテンツの構文解析"))
                    {
                        // GET Parsed HTML Contents
                        var contents = HtmlSyntaxParser.Read(filepath, this.Encoding);

                        // OUTPUT HTML Contents
                        this.WriteContents(contents);
                    }
                }
            }
            else if (this.ParameterSetName == "InputObject")
            {
                // Should Process
                if (this.ShouldProcess($"入力文字列", "HTML コンテンツの構文解析"))
                {
                    // GET Parsed HTML Contents
                    var contents = HtmlSyntaxParser.Parse(this.InputObject);

                    // OUTPUT HTML Contents
                    this.WriteContents(contents);
                }
            }
            else
            {
                throw new InvalidOperationException();
            }
        }


        // ----------------------------------------------------------------------------------------------------
        // Post-Processing Operations
        // ----------------------------------------------------------------------------------------------------
        // (None)


        // ----------------------------------------------------------------------------------------------------
        // Private Method(s)
        // ----------------------------------------------------------------------------------------------------

        // Write Output according parameter
        private void WriteContents(HtmlContentCollection contents)
        {
            // Check Node Parameter
            if (!string.IsNullOrEmpty(this.Node))
            {
                // Node Parameter is specified.

                // GET Nodes
                var nodes = contents.GetNodes(this.Node);

                // OUTPUT Node Texts
                nodes.ToList().ConvertAll(node => node.Contents?.Text).ForEach(text => this.WriteObject(text));
            }
            else
            {
                // Node Parameter is NOT specified.

                // OUTPUT Contents
                this.WriteObject(contents);
            }
        }
    }
}
