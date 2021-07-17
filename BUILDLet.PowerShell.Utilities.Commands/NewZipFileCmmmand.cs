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
    [Cmdlet(VerbsCommon.New, "ZipFile", SupportsShouldProcess = true)]
    [OutputType(typeof(FileInfo))]
    public class NewZipFileCommand : PSCmdlet
    {
        // ----------------------------------------------------------------------------------------------------
        // PARAMETER(S)
        // ----------------------------------------------------------------------------------------------------

        // .PARAMETER Path
        [Parameter(HelpMessage = PathHelpMessage, Mandatory = true, Position = 0, ValueFromPipeline = true)]
        [Alias("PSPath")]
        public string[] Path { get; set; }
        private const string PathHelpMessage =
@"入力ファイルまたはフォルダーのパスを指定します。";


        // .PARAMETER DestinationPath
        [Parameter(HelpMessage = DestinationHelpMessage, Position = 1)]
        public string DestinationPath { get; set; }
        private const string DestinationHelpMessage =
@"作成する zip ファイルのパスを指定します。
既に存在するディレクトリのパスが指定された場合はエラーになります。 (コマンドレットは zip ファイル名を生成しません。)
既に存在するファイルのパスが指定された場合は、既定ではエラーになります。 (Force パラメーターが指定された場合は、上書きします。)
ただし、省略した場合のみ、入力ファイルまたはディレクトリに、拡張子 '.zip' を付け加えた (または置き換えた) ファイルをカレントディレクトリに作成します。";


        // .PARAMETER Password
        [Parameter(HelpMessage = PasswordHelpMessage)]
        public string Password { get; set; }
        private const string PasswordHelpMessage =
@"パスワードを指定します。";


        // .PARAMETER Encoding
        [Parameter(HelpMessage = EncodingHelpMessage)]
        public Encoding Encoding { get; set; }
        private const string EncodingHelpMessage =
@"エンコーディングを指定します。
既定のエンコーディングは System.Text.Encoding.UTF8 です。";


        // .PARAMETER Force
        [Parameter(Mandatory = false, HelpMessage = ForceHelpMessage)]
        public SwitchParameter Force { get; set; }
        private const string ForceHelpMessage =
@"zip ファイルを作成するパスに、既に同じ名前のファイルが存在していた場合に、そのファイルを上書きします。 (既定では、エラーになります。)
同じ名前のディレクトリが存在していた場合には、上書きしません。 (エラーになります。)";


        // .PARAMETER PathThru
        [Parameter(HelpMessage = PassThruHelpMessage)]
        public SwitchParameter PassThru { get; set; }
        private const string PassThruHelpMessage =
@"作成した zip ファイルをパイプラインに出力します。
既定ではこのコマンドレットによる出力はありません。";


        // .PARAMETER SupressProgress
        [Parameter(HelpMessage = SuppressProgressHelpMessage)]
        public SwitchParameter SuppressProgress { get; set; }
        private const string SuppressProgressHelpMessage =
@"進行状況バーを表示しません。
※ 進行状況バーを表示する場合は、以下の制限に注意してください。
 1. サイズにかかわらず全てのファイル、および、ディレクトリは、同じサイズのエントリとして計算された進捗が表示されます。
    (Verbose オプションを指定すると、各エントリーのサイズに応じた進行状況が表示されます。)
 2. ルート エントリが複数ある場合は、進行状況が正しく表示されません。
    (新しいルート エントリを検出するたびに、全体が更新されます。)";


        // ----------------------------------------------------------------------------------------------------
        // Pre-Processing Operations
        // ----------------------------------------------------------------------------------------------------
        // (None)


        // ----------------------------------------------------------------------------------------------------
        // Input Processing Operations
        // ----------------------------------------------------------------------------------------------------
        protected override void ProcessRecord()
        {
            foreach (var src_paths in this.Path)
            {
                string dest_zipfilepath = null;

                foreach (var src_path in SessionLocation.GetResolvedPath(this.SessionState, src_paths))
                {
                    // SET Destination ZIP File Path
                    if (dest_zipfilepath is null)
                    {
                        // Destination ZIP File Path is not yet set.

                        // SET Destination ZIP File Path
                        dest_zipfilepath = this.DestinationPath is null ?
                            SessionLocation.GetUnresolvedPath(this.SessionState, System.IO.Path.GetFileNameWithoutExtension(src_path)) + ".zip" :
                            SessionLocation.GetUnresolvedPath(this.SessionState, this.DestinationPath);

                        // Validation (Destination Path Existence Check: Directory):
                        if (Directory.Exists(dest_zipfilepath)) { throw new IOException(); }

                        // Validation (Destination Path Existence Check: File):
                        if (File.Exists(dest_zipfilepath))
                        {
                            if (this.Force)
                            {
                                File.Delete(dest_zipfilepath);
                            }
                            else
                            {
                                throw new IOException();
                            }
                        }
                    }

                    // Should Process
                    if (this.ShouldProcess($"Source: '{src_path}', Destination:'{dest_zipfilepath}'", "ファイルの圧縮"))
                    {
                        // using ZipFile
                        using (ZipFile zip = new ZipFile(dest_zipfilepath, this.Encoding ?? Encoding.UTF8))
                        {
                            // SET Password
                            if (!string.IsNullOrEmpty(this.Password)) { zip.Password = this.Password; }

                            // SET ZIP64 extension
                            zip.UseZip64WhenSaving = Zip64Option.AsNecessary;

                            // Workaround of DotNetZip bug
                            zip.ParallelDeflateThreshold = -1;

                            // SET Flag for workaround not to save timestamp
                            zip.EmitTimesInWindowsFormatWhenSaving = false;
                            zip.EmitTimesInUnixFormatWhenSaving = false;

                            // ProgressRecord (Main):
                            ProgressRecord mainProgress = new ProgressRecord(0, $"{this.MyInvocation.MyCommand}: '{src_path}' を圧縮しています", "準備中...");

                            // ProgressRecord (Sub):
                            ProgressRecord subProgress = new ProgressRecord(1, "準備中...", "準備中...") { ParentActivityId = 0 };

                            // Register Event Handler only if needed
                            if (!this.SuppressProgress)
                            {
                                // Count(s)
                                int entryCount = 0;
                                int eventCount = 0;
                                int eventIntervalCount = 150;

                                // ZipFile.ExtractProgress Event Handler
                                zip.SaveProgress += (object sender, SaveProgressEventArgs e) =>
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
                                    this.WriteDebug($"e.{nameof(e.EntriesSaved)} = {e.EntriesSaved}");
#endif

                                    // for ProgressRecord(s)
                                    switch (e.EventType)
                                    {
                                        case ZipProgressEventType.Saving_AfterWriteEntry:
                                            break;
                                        case ZipProgressEventType.Saving_EntryBytesRead:
                                            break;
                                        default:
                                            break;
                                    }

                                    switch (e.EventType)
                                    {
                                        // Before Write Entry
                                        case ZipProgressEventType.Saving_BeforeWriteEntry:

                                            // Increment count of Entry
                                            entryCount++;

                                            mainProgress.Activity = (zip.Count > 1) ?
                                            $"{this.MyInvocation.MyCommand}: '{src_path}' ({entryCount} / {zip.Count}) を圧縮しています" :
                                            $"{this.MyInvocation.MyCommand}: '{src_path}' を圧縮しています";

                                            mainProgress.StatusDescription = $"'{e.CurrentEntry.FileName}' を圧縮中...";
                                            mainProgress.PercentComplete = 100 * (entryCount - 1) / zip.Count;

                                            // Write Progress (Main)
                                            this.WriteProgress(mainProgress);
                                            break;

                                        // Entry Bytes are read
                                        case ZipProgressEventType.Saving_EntryBytesRead:
                                            if (e.TotalBytesToTransfer != 0)
                                            {
                                                // Increment event count
                                                if (++eventCount > eventIntervalCount)
                                                {
                                                    // UPDATE Progress (Main)
                                                    mainProgress.StatusDescription = $"'{e.CurrentEntry.FileName}' ({e.BytesTransferred} / {e.TotalBytesToTransfer} バイト) を圧縮中...";
                                                    mainProgress.PercentComplete = ((100 * (entryCount - 1)) + (int)(100 * e.BytesTransferred / e.TotalBytesToTransfer)) / zip.Count;

                                                    // Write Progress (Main)
                                                    this.WriteProgress(mainProgress);

                                                    // for Sub Progress
                                                    if (this.MyInvocation.BoundParameters.ContainsKey("Verbose"))
                                                    {
                                                        // UPDATE Progress (Sub)
                                                        subProgress.Activity = $"'{e.CurrentEntry}' を圧縮しています";
                                                        subProgress.StatusDescription = $"{e.BytesTransferred} / {e.TotalBytesToTransfer} バイトを圧縮中...";
                                                        subProgress.PercentComplete = (int)(100 * e.BytesTransferred / e.TotalBytesToTransfer);

                                                        // Write Progress (Sub)
                                                        this.WriteProgress(subProgress);
                                                    }

                                                    // Reset event count
                                                    eventCount = 0;
                                                }
                                            }
                                            break;

                                        default:
                                            break;
                                    }
                                    // for ProgressRecord(s)
                                };
                                // ZipFile.ExtractProgress Event Handler
                            }


                            // Add to Zip (Archive)
                            if (File.Exists(src_path))
                            {
                                // File
                                zip.AddFile(src_path, string.Empty);
                            }
                            else if (Directory.Exists(src_path))
                            {
                                // Directory
                                zip.AddDirectory(src_path, new DirectoryInfo(src_path).Name);
                            }
                            else
                            {
                                throw new InvalidDataException();
                            }

                            // Save as file
                            zip.Save();


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


                            // Output (PassThru)
                            if (this.PassThru)
                            {
                                this.WriteObject(new FileInfo(dest_zipfilepath));
                            }
                        }
                        // using ZipFile
                    }
                    // Should Process
                }
            }
        }


        // ----------------------------------------------------------------------------------------------------
        // Post-Processing Operations
        // ----------------------------------------------------------------------------------------------------
        // (None)
    }
}
