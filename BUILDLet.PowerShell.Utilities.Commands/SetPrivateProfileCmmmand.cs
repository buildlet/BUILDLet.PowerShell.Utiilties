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
using System.Linq;

using BUILDLet.Standard.Utilities; // for PrivateProfile

namespace BUILDLet.PowerShell.Utilities.Commands
{
    [CmdletBinding(HelpUri = "https://github.com/buildlet/BUILDLet.PowerShell.Utilities")]
    [Cmdlet(VerbsCommon.Set, "PrivateProfile", SupportsShouldProcess = true)]
    public class SetPrivateProfileCmmmand : PSCmdlet
    {
        // ----------------------------------------------------------------------------------------------------
        // PARAMETER(S)
        // ----------------------------------------------------------------------------------------------------

        // .PARAMETER Path
        [Parameter(HelpMessage = PathHelpMessage, Mandatory = true, Position = 0, ValueFromPipeline = true)]
        [Alias("PSPath")]
        public string Path { get; set; }
        private const string PathHelpMessage =
@"INI ファイルのパスを指定します。";


        // .PARAMETER Section
        [Parameter(HelpMessage = SectionHelpMessage, Mandatory = true, Position = 1)]
        public string Section { get; set; }
        private const string SectionHelpMessage =
@"設定するエントリのセクションを指定します。";


        // .PARAMETER Key
        [Parameter(HelpMessage = KeyHelpMessage, Mandatory = true, Position = 2)]
        public string Key { get; set; }
        private const string KeyHelpMessage =
@"設定するエントリのキーを指定します。";


        // .PARAMETER Value
        [Parameter(HelpMessage = ValueHelpMessage, Mandatory = true, Position = 3)]
        public string Value { get; set; }
        private const string ValueHelpMessage =
@"設定するエントリの値を指定します。";


        // ----------------------------------------------------------------------------------------------------
        // Pre-Processing Operations
        // ----------------------------------------------------------------------------------------------------
        // (None)


        // ----------------------------------------------------------------------------------------------------
        // Input Processing Operations
        // ----------------------------------------------------------------------------------------------------
        protected override void ProcessRecord()
        {
            foreach (var filepath in SessionLocation.GetResolvedPath(this.SessionState, this.Path))
            {
                // Validation (File Existence Check):
                if (!File.Exists(filepath)) { throw new FileNotFoundException(); }

                // Open INI File Stream by READ-WRITE Mode
                using (var profile = new PrivateProfile(filepath, false))
                {
                    // SECTION Existence Check:
                    if (profile.Contains(this.Section))
                    {
                        // UPDATE SECTION
                        this.Section = (from section_name in profile.Sections.Keys where string.Compare(section_name, this.Section, true) == 0 select section_name).First();

                        // KEY Existence Check)
                        if (profile.Sections[this.Section].Entries.ContainsKey(this.Key))
                        {
                            // UPDATE KEY
                            this.Key = (from key in profile.Sections[this.Section].Entries.Keys where string.Compare(key, this.Key, true) == 0 select key).First();
                        }
                    }

                    // Should Process
                    if (this.ShouldProcess($"ファイル '{filepath}'", $"セクション '{this.Section}' に含まれるキー '{this.Key}' の値の設定"))
                    {
                        // SET & Write VALUE
                        profile.SetValue(this.Section, this.Key, this.Value).Write();
                    }
                }
            }
        }

        // ----------------------------------------------------------------------------------------------------
        // Post-Processing Operations
        // ----------------------------------------------------------------------------------------------------
        // (None)
    }
}
