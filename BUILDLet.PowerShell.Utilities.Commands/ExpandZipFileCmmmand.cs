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
using System.Text;  // for Encoding
using System.Linq;

using Ionic.Zip;   // for Zip

namespace BUILDLet.PowerShell.Utilities.Commands
{
    [CmdletBinding(HelpUri = "https://github.com/buildlet/BUILDLet.PowerShell.Utilities")]
    [Cmdlet(VerbsData.Expand, "ZipFile", SupportsShouldProcess = true)]
    [OutputType(typeof(FileInfo), typeof(DirectoryInfo), typeof(object[]))]
    public class ExpandZipFileCommand : PSCmdlet
    {
        // ----------------------------------------------------------------------------------------------------
        // PARAMETER(S)
        // ----------------------------------------------------------------------------------------------------

        // .PARAMETER Path
        [Parameter(HelpMessage = PathHelpMessage, Mandatory = true, Position = 0, ValueFromPipeline = true)]
        [Alias("PSPath")]
        public string Path { get; set; }
        private const string PathHelpMessage =
@"展開する zip ファイルのパスを指定します。";


        // .PARAMETER DestinationPath
        [Parameter(HelpMessage = DestinationHelpMessage, Position = 1)]
        public string DestinationPath { get; set; }
        private const string DestinationHelpMessage =
@"展開されたエントリを保存するディレクトリのパスを指定します。
存在しないパスが指定された場合や、同じ名前のファイルが存在する場合は、エラーになります。(コマンドレットはディレクトリを作成しません。)
ただし、省略した場合のみ、入力ファイルから拡張子を除いた名前のディレクトリをカレントディレクトリに作成します。";


        // .PARAMETER Password
        [Parameter(HelpMessage = PasswordHelpMessage)]
        public string Password { get; set; }
        private const string PasswordHelpMessage =
@"パスワードを指定します。";


        // .PARAMETER Encoding
        [Parameter(HelpMessage = EncodingHelpMessage)]
        public Encoding Encoding { get; set; }
        protected const string EncodingHelpMessage =
@"エンコーディングを指定します。
既定のエンコーディングは System.Text.Encoding.UTF8 です。";


        // .PARAMETER Force
        [Parameter(HelpMessage = ForceHelpMessage)]
        public SwitchParameter Force { get; set; }
        private const string ForceHelpMessage =
@"ファイルの展開先に同じ名前のファイルやディレクトリが既に存在していた場合に、そのファイルを上書きします。
既定の設定では、上書きしません。
(このパラメーターを指定すると、Ionic.Zip.ZipEntry.Extract メソッドに指定する extractExistingFile パラメーターに
 Ionic.Zip.ExtractExistingFileAction.OverwriteSilently が指定されます。
 既定では Ionic.Zip.ExtractExistingFileAction.DoNotOverwrite です。)";


        // .PARAMETER PathThru
        [Parameter(HelpMessage = PassThruHelpMessage)]
        public SwitchParameter PassThru { get; set; }
        private const string PassThruHelpMessage =
@"展開した全ての Ionic.Zip.ZipEntry をパイプラインに出力します。
既定では、ルート エントリ (ファイルまたはディレクトリ) のみをパイプラインに出力します。";


        // .PARAMETER SupressProgress
        [Parameter(HelpMessage = SuppressProgressHelpMessage)]
        public SwitchParameter SuppressProgress { get; set; }
        private const string SuppressProgressHelpMessage =
@"進行状況バーを表示しません。
(進行状況バーを表示する場合、Verbose オプションを指定すると、全体の進行状況に加えて、各エントリーの進行状況が表示されます。)";


        [Parameter(HelpMessage = SuppressOutputHelpMessage)]
        public SwitchParameter SuppressOutput { get; set; }
        private const string SuppressOutputHelpMessage =
@"このコマンドレットの出力を抑制します。
Source に含まれるエントリーが多く、パフォーマンスに影響がある場合に、このパラメーターを指定してください。
進行状況バーも非表示にする場合は SupressProgress パラメーターを指定してください。
PassThru パラメーターと同時に指定された場合は、PassThru パラメーターが優先されます。";


        // ----------------------------------------------------------------------------------------------------
        // Pre-Processing Operations
        // ----------------------------------------------------------------------------------------------------
        // (None)


        // ----------------------------------------------------------------------------------------------------
        // Input Processing Operations
        // ----------------------------------------------------------------------------------------------------
        protected override void ProcessRecord()
        {
            foreach (var src_zipfilepath in SessionLocation.GetResolvedPath(this.SessionState, this.Path))
            {
                // Validation (Source File Existence Check):
                if (!File.Exists(src_zipfilepath)) { throw new FileNotFoundException(); }

                // SET Destination Directory Path
                var dest_dirpath = this.DestinationPath is null ?
                    Directory.CreateDirectory(SessionLocation.GetUnresolvedPath(this.SessionState, System.IO.Path.GetFileNameWithoutExtension(src_zipfilepath))).FullName :
                    SessionLocation.GetUnresolvedPath(this.SessionState, this.DestinationPath);

                // Validation (Destination Directory Existence Check):
                if (!Directory.Exists(dest_dirpath)) { throw new DirectoryNotFoundException(); }

                // Should Process
                if (this.ShouldProcess($"Source: '{src_zipfilepath}', Destination:'{dest_dirpath}'", "ファイルの展開"))
                {
                    // using ZipFile
                    using (ZipFile zip = ZipFile.Read(src_zipfilepath, new ReadOptions() { Encoding = this.Encoding ?? Encoding.UTF8 }))
                    {
                        // Set FileAction (Overwirte or NOT)
                        ExtractExistingFileAction fileAction = this.Force ? ExtractExistingFileAction.OverwriteSilently : ExtractExistingFileAction.DoNotOverwrite;

                        // ProgressRecord (Main):
                        ProgressRecord mainProgress = new ProgressRecord(0, $"{this.MyInvocation.MyCommand}: '{src_zipfilepath}' を展開しています", "準備中...");

                        // ProgressRecord (Sub):
                        ProgressRecord subProgress = new ProgressRecord(1, "準備中...", "準備中...") { ParentActivityId = 0 };

                        // Register Event Handler only if needed
                        if (!this.SuppressProgress || !this.SuppressOutput || this.PassThru)
                        {
                            // Root Entries for Output
                            List<string> outputEntryRoots = new List<string>();

                            // Count(s)
                            int entryCount = 0;
                            int eventCount = 0;
                            int eventIntervalCount = 150;

                            // ZipFile.ExtractProgress Event Handler
                            zip.ExtractProgress += (object sender, ExtractProgressEventArgs e) =>
                            {
#if DEBUG
                                // DEBUG Output
                                this.WriteDebug("");
                                this.WriteDebug($"e.{nameof(e.EventType)} = {e.EventType}");
                                this.WriteDebug($"e.{nameof(e.ArchiveName)} = {e.ArchiveName}");
                                this.WriteDebug($"e.{nameof(e.BytesTransferred)} = {e.BytesTransferred}");
                                this.WriteDebug($"e.{nameof(e.TotalBytesToTransfer)} = {e.TotalBytesToTransfer}");
                                this.WriteDebug($"e.{nameof(e.EntriesTotal)} = {e.EntriesTotal}");
                                this.WriteDebug($"e.{nameof(e.CurrentEntry)} = {e.CurrentEntry}");
                                this.WriteDebug($"e.{nameof(e.EntriesExtracted)} = {e.EntriesExtracted}");
#endif

                                // for ProgressRecord(s)
                                if (!this.SuppressProgress)
                                {
                                    switch (e.EventType)
                                    {
                                        // Before Extracting Entry
                                        case ZipProgressEventType.Extracting_BeforeExtractEntry:

                                            // Increment count of Entry
                                            entryCount++;

                                            mainProgress.Activity = (zip.Count > 1) ?
                                            $"{this.MyInvocation.MyCommand}: '{src_zipfilepath}' ({entryCount} / {zip.Count}) を展開しています" :
                                            $"{this.MyInvocation.MyCommand}: '{src_zipfilepath}' を展開しています";

                                            mainProgress.StatusDescription = $"'{e.CurrentEntry.FileName}' を展開中...";
                                            mainProgress.PercentComplete = 100 * (entryCount - 1) / zip.Count;

                                            // Write Progress (Main)
                                            this.WriteProgress(mainProgress);
                                            break;

                                        // Entry Bytes are written
                                        case ZipProgressEventType.Extracting_EntryBytesWritten:

                                            // Increment event count
                                            if (++eventCount > eventIntervalCount)
                                            {
                                                // UPDATE Progress (Main)
                                                mainProgress.StatusDescription = $"'{e.CurrentEntry.FileName}' ({e.BytesTransferred} / {e.TotalBytesToTransfer} バイト) を展開中...";
                                                mainProgress.PercentComplete = ((100 * (entryCount - 1)) + (int)(100 * e.BytesTransferred / e.TotalBytesToTransfer)) / zip.Count;

                                                // Write Progress (Main)
                                                this.WriteProgress(mainProgress);

                                                // for Sub Progress
                                                if (this.MyInvocation.BoundParameters.ContainsKey("Verbose"))
                                                {
                                                    // UPDATE Progress (Sub)
                                                    subProgress.Activity = $"'{e.CurrentEntry}' を展開しています";
                                                    subProgress.StatusDescription = $"{e.BytesTransferred} / {e.TotalBytesToTransfer} バイトを展開中...";
                                                    subProgress.PercentComplete = (int)(100 * e.BytesTransferred / e.TotalBytesToTransfer);

                                                    // Write Progress (Sub)
                                                    this.WriteProgress(subProgress);
                                                }

                                                // Reset event count
                                                eventCount = 0;
                                            }
                                            break;

                                        default:
                                            break;
                                    }
                                }
                                // for ProgressRecord(s)

                                // for Entry Output
                                if (e.EventType == ZipProgressEventType.Extracting_AfterExtractEntry)
                                {
                                    if (this.PassThru)
                                    {
                                        // PassThru:

                                        // Convert '/' -> '\' (System.IO.Path.DirectorySeparatorChar)
                                        string filename = e.CurrentEntry.FileName.Replace('/', System.IO.Path.DirectorySeparatorChar);

                                        // Output
                                        if (e.CurrentEntry.IsDirectory)
                                        {
                                            // Directory:
                                            this.WriteObject(new DirectoryInfo(System.IO.Path.Combine(e.ExtractLocation, filename)));
                                        }
                                        else
                                        {
                                            // File:
                                            this.WriteObject(new FileInfo(System.IO.Path.Combine(e.ExtractLocation, filename)));
                                        }
                                    }
                                    else
                                    {
                                        // NOT PassThru:
                                        if (!this.SuppressOutput)
                                        {
                                            // NOT PassThru & NOT SuppressOutput:

                                            string[] separated = e.CurrentEntry.FileName.Split(new char[] { '/' });
                                            string root = separated[0];

                                            if (!outputEntryRoots.Contains(root))
                                            {
                                                // Add File Name of Root Entry 
                                                outputEntryRoots.Add(root);

                                                // Output
                                                if (e.CurrentEntry.IsDirectory || (separated.Length > 1))
                                                {
                                                    // Directory:
                                                    this.WriteObject(new DirectoryInfo(System.IO.Path.Combine(dest_dirpath, root)));
                                                }
                                                else
                                                {
                                                    // File:
                                                    this.WriteObject(new FileInfo(System.IO.Path.Combine(dest_dirpath, root)));
                                                }
                                            }
                                        }
                                    }
                                }
                                // for Entry Output
                            };
                            // ZipFile.ExtractProgress Event Handler
                        }


                        // UnZip (Extract)
                        foreach (var entry in zip)
                        {
                            // Extract each Zip entries
                            if (string.IsNullOrEmpty(this.Password))
                            {
                                // w/o Password
                                entry.Extract(dest_dirpath, fileAction);
                            }
                            else
                            {
                                // with Password
                                entry.ExtractWithPassword(dest_dirpath, fileAction, this.Password);
                            }
                        }


                        // Completion of ProgressRecord(s):
                        foreach (var progress in new ProgressRecord[] { subProgress, mainProgress })
                        {
                            if (progress != null)
                            {
                                // Complete the Progress
                                progress.PercentComplete = 100;
                                progress.RecordType = ProgressRecordType.Completed;

                                // Write Progress
                                this.WriteProgress(progress);
                            }
                        }
                    }
                    // using ZipFile
                }
                // Should Process
            }
        }


        // ----------------------------------------------------------------------------------------------------
        // Post-Processing Operations
        // ----------------------------------------------------------------------------------------------------
        // (None)
    }
}
