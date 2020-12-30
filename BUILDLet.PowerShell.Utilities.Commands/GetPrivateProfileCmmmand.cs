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

using BUILDLet.Standard.Utilities; // for PrivateProfile

namespace BUILDLet.PowerShell.Utilities.Commands
{
    [CmdletBinding(HelpUri = "https://github.com/buildlet/BUILDLet.PowerShell.Utilities")]
    [Cmdlet(VerbsCommon.Get, "PrivateProfile", SupportsShouldProcess = true, DefaultParameterSetName = "Path")]
    [OutputType(typeof(string), typeof(Dictionary<string, string>), typeof(Dictionary<string, Dictionary<string, string>>))]
    public class GetPrivateProfileCmmmand : PSCmdlet
    {
        // ----------------------------------------------------------------------------------------------------
        // PARAMETER(S)
        // ----------------------------------------------------------------------------------------------------

        // .PARAMETER Path
        [Parameter(HelpMessage = PathHelpMessage, Mandatory = true, ParameterSetName = "Path", Position = 0, ValueFromPipeline = true)]
        [Alias("PSPath")]
        public string Path { get; set; }
        private const string PathHelpMessage =
@"INI ファイルのパスを指定します。";


        // .PARAMETER InputObject
        [Parameter(HelpMessage = InputObjectHelpMessage, Mandatory = true, ParameterSetName = "InputObject", Position = 0, ValueFromPipelineByPropertyName = true)]
        public string InputObject { get; set; }
        private const string InputObjectHelpMessage =
@"INI ファイルのコンテンツを指定します。";


        // .PARAMETER Section
        [Parameter(HelpMessage = SectionHelpMessage, Position = 1)]
        public string Section { get; set; }
        private const string SectionHelpMessage =
@"取得するエントリのセクションを指定します。
省略した場合は、ファイル全体に含まれる全てのエントリーを取得します。";


        // .PARAMETER Key
        [Parameter(HelpMessage = KeyHelpMessage, Position = 2)]
        public string Key { get; set; }
        private const string KeyHelpMessage =
@"取得するエントリのキーを指定します。
省略した場合は、指定したセクションに含まれる全てのエントリを取得します。";


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

                    // Open INI File Stream by READ-ONLY Mode
                    using (var profile = new PrivateProfile(filepath))
                    {
                        // OUTPUT Profile (according parameter)
                        WriteProfile(profile, $"ファイル '{filepath}'");
                    }
                }
            }
            else if (this.ParameterSetName == "InputObject")
            {
                // NEW PrivateProfile
                var profile = new PrivateProfile();

                // IMPORT content from InputObject
                profile.Import(this.InputObject);

                // OUTPUT Profile (according parameter)
                WriteProfile(profile, $"パラメーター '{nameof(InputObject)}'");
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

        // Write Profile according parameter
        private void WriteProfile(PrivateProfile profile, string target)
        {
            if (this.Section is null)
            {
                // ALL (FILE):

                // Should Process
                if (this.ShouldProcess(target, "全てのエントリーの取得"))
                {
                    // GET Sections
                    var sections = GetPrivateProfileSections(profile);

                    // OUTPUT Sections
                    this.WriteObject(sections);
                }
            }
            else
            {
                // Validation (SECTION Existence Check):
                if (!profile.Contains(this.Section)) { throw new KeyNotFoundException(); }

                // UPDATE SECTION
                this.Section = (from section_name in profile.Sections.Keys where string.Compare(section_name, this.Section, true) == 0 select section_name).First();

                if (this.Key is null)
                {
                    // SECTION:

                    // Should Process
                    if (this.ShouldProcess(target, $"セクション '{this.Section}' に含まれる全てのエントリーの取得"))
                    {
                        // GET Entries
                        var entries = GetPrivateProfileEntries(profile.Sections[this.Section]);

                        // OUTPUT Entries
                        this.WriteObject(entries);
                    }
                }
                else
                {
                    // ENTRY:

                    // Validation (KEY Existence Check):
                    if (!profile.Sections[this.Section].Entries.ContainsKey(this.Key)) { throw new KeyNotFoundException(); }

                    // UPDATE KEY
                    this.Key = (from key in profile.Sections[this.Section].Entries.Keys where string.Compare(key, this.Key, true) == 0 select key).First();

                    // Should Process
                    if (this.ShouldProcess(target, $"セクション '{this.Section}' に含まれるキー '{this.Key}' の値の取得"))
                    {
                        // OUTPUT Entry
                        this.WriteObject(profile.GetValue(this.Section, this.Key));
                    }
                }
            }
        }

        // GET Sections
        private Dictionary<string, Dictionary<string, string>> GetPrivateProfileSections(PrivateProfile profile)
        {
            // NEW Dictionary (Sections)
            Dictionary<string, Dictionary<string, string>> sections = new Dictionary<string, Dictionary<string, string>>(StringComparer.OrdinalIgnoreCase);

            // for Sections
            foreach (var section_name in profile.Sections.Keys)
            {
                // GET Entries
                var entries = this.GetPrivateProfileEntries(profile.Sections[section_name]);

                // ADD Section
                sections.Add(section_name, entries);
            }

            // RETURN Sections
            return sections;
        }

        // GET Entries
        private Dictionary<string, string> GetPrivateProfileEntries(PrivateProfileSection section)
        {
            // NEW Dictionary (Entries)
            Dictionary<string, string> entries = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

            // for Entries
            foreach (var key in section.Entries.Keys)
            {
                // ADD Entry
                entries.Add(key, section.Entries[key]);
            }

            // RETURN Entries
            return entries;
        }
    }
}
