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
using System.Text;         // for System.Text.Encoding
using System.Diagnostics;  // for System.Diagnostics.ProcessStartInfo
using System.Threading;    // for System.Threading.Thread
using System.Collections.Concurrent;  // for ConcurrentQueue
using Microsoft.Win32.SafeHandles;

namespace BUILDLet.PowerShell.Utilities.Commands
{
    [CmdletBinding(HelpUri = "https://github.com/buildlet/BUILDLet.PowerShell.Utilities")]
    [Cmdlet(VerbsLifecycle.Invoke, "Process", SupportsShouldProcess = true)]
    public class InvokeProcessCmmmand : PSCmdlet
    {
        // ----------------------------------------------------------------------------------------------------
        // PARAMETER(S)
        // ----------------------------------------------------------------------------------------------------

        // .PARAMETER FilePath
        [Parameter(HelpMessage = PathHelpMessage, Mandatory = true, Position = 0, ValueFromPipeline = true)]
        public string FilePath { get; set; }
        private const string PathHelpMessage =
@"プロセスで実行するアプリケーション ファイルのパスを指定します。";


        // .PARAMETER ArgumentList
        [Parameter(HelpMessage = ArgumentListHelpMessage)]
        public string[] ArgumentList { get; set; }
        private const string ArgumentListHelpMessage =
@"プロセスを起動するときに渡すコマンド ライン引数を指定します。";


        [Parameter(HelpMessage = OutputEncodingHelpMessage)]
        public Encoding OutputEncoding { get; set; } = System.Text.Encoding.UTF8;
        private const string OutputEncodingHelpMessage =
@"アプリケーションの標準出力ストリームおよび標準エラー ストリームへの出力のエンコードを指定します。
既定のエンコーディングは System.Text.Encoding.UTF8 です。";


        [Parameter(HelpMessage = PassThruHelpMessage)]
        public SwitchParameter PassThru { get; set; }
        private const string PassThruHelpMessage =
@"アプリケーションの終了コードを返します。
このとき、アプリケーションの標準出力ストリームへの出力は、警告メッセージ ストリームへリダイレクトされます。

既定では、アプリケーションの標準出力ストリームへの出力はパイプラインへ出力され、標準エラー ストリームへの出力は
警告メッセージ ストリームへリダイレクトされるので、PassThru パラメーターを指定すると、
警告メッセージ ストリームには、アプリケーションの標準出力ストリームへの出力と標準エラー ストリームへの出力が混在することになります。";


        [Parameter(HelpMessage = RetryCountHelpMessage)]
        public int RetryCount { get; set; } = 0;
        private const string RetryCountHelpMessage =
@"プロセスの終了コードが 0 以外だった場合にリトライする回数を指定します。
既定のリトライ回数は 0 回です。";


        [Parameter(HelpMessage = RetrySecondHelpMessage)]
        public int RetrySecond { get; set; } = 0;
        private const string RetrySecondHelpMessage =
@"リトライする間隔を秒数で指定します。
既定のリトライ間隔は 0 秒です。";


        // ----------------------------------------------------------------------------------------------------
        // Pre-Processing Operations
        // ----------------------------------------------------------------------------------------------------
        // (None)


        // ----------------------------------------------------------------------------------------------------
        // Input Processing Operations
        // ----------------------------------------------------------------------------------------------------
        protected override void ProcessRecord()
        {
            string filepath = null;
            string testpath = null;

            // WARNING:
            // 64 bit application program file in C:\Windows\System32 folder (e.g., wsl.exe)
            // cannot be found by Visual Studio, because Visal Studio itself is 32 bit application.

            // SET filepath
            if (Path.IsPathRooted(this.FilePath))
            {
                // Absolute Path:

                // PRIORITY 1.1: Full Path is specified.
                if (File.Exists(testpath = this.FilePath))
                {
                    filepath = testpath;
                }
                else
                {
                    // PRIORITY 1.2: Full Path + ".exe"
                    if (Path.GetExtension(testpath) == "" && File.Exists(testpath += ".exe"))
                    {
                        filepath = testpath;
                    }
                }
            }
            else
            {
                // Relative Path:

                // PRIORITY 2.1: Serch Current Directory
                if (File.Exists(testpath = Path.Combine(this.SessionState.Path.CurrentFileSystemLocation.ProviderPath, this.FilePath)))
                {
                    filepath = testpath;
                }
                else
                {
                    // PRIORITY 2.2: Current Directory + ".exe"
                    if (Path.GetExtension(testpath) == "" && File.Exists(testpath += ".exe"))
                    {
                        filepath = testpath;
                    }
                    else
                    {
                        // PRIORITY 3: Search from PATH environment variable
                        foreach (var envpath in Environment.GetEnvironmentVariable("PATH").Split(';'))
                        {
                            // PRIORITY 3.1
                            if (File.Exists(testpath = Path.Combine(envpath, this.FilePath)))
                            {
                                filepath = testpath;
                            }
                            else
                            {
                                // PRIORITY 3.2: PATH environment variable + ".exe"
                                if (Path.GetExtension(testpath) == "" && File.Exists(testpath += ".exe"))
                                {
                                    filepath = testpath;
                                }
                            }
                        }
                    }
                }
            }


            // Using Process
            using (var p = new Process())
            {
                // SET StartInfo
                p.StartInfo.FileName = filepath;
                p.StartInfo.WorkingDirectory = this.SessionState.Path.CurrentFileSystemLocation.ProviderPath;
                p.StartInfo.CreateNoWindow = true;
                p.StartInfo.ErrorDialog = false;
                p.StartInfo.UseShellExecute = false;
                p.StartInfo.RedirectStandardOutput = true;
                p.StartInfo.RedirectStandardError = true;
                p.StartInfo.StandardOutputEncoding = this.OutputEncoding;
                p.StartInfo.StandardErrorEncoding = this.OutputEncoding;

                // NEW arguments
                StringBuilder arguments = new StringBuilder();

                // for ArgumentList
                if (this.ArgumentList != null)
                {
                    // Construct arguments
                    for (int i = 0; i < this.ArgumentList.Length; i++)
                    {
                        arguments.Append(" " + this.ArgumentList[i]);
                    }

                    // SET arguments -> StartInfo.Arguments
                    p.StartInfo.Arguments = arguments.ToString().Trim();
                }

                // GET Command line
                var commandline = filepath + (this.ArgumentList is null ? "" : arguments.ToString());


                // NEW ConcurrentQueue (for Standard Output)
                ConcurrentQueue<string> stdout = new ConcurrentQueue<string>();

                // for OutputDataReceived Event (Standard Output)
                p.OutputDataReceived += (object sender, DataReceivedEventArgs e) =>
                {
                    if (e.Data != null)
                    {
                        // Enque (Standard Output)
                        stdout.Enqueue(e.Data);
                    }
                };

                // NEW ConcurrentQueue (for Standard Error)
                ConcurrentQueue<string> stderr = new ConcurrentQueue<string>();

                // for ErrorDataReceived Event (Standard Error)
                p.ErrorDataReceived += (object sender, DataReceivedEventArgs e) =>
                {
                    if (e.Data != null)
                    {
                        // Enque (Standard Error)
                        stderr.Enqueue(e.Data);
                    }
                };


                // Retry Loop
                int count = 0;
                do
                {
                    // Should Process
                    if (this.ShouldProcess(commandline, $"コマンドラインの実行 ({count + 1} 回目)"))
                    {
                        // START Process
                        p.Start();

                        // START Reading Stream(s)
                        p.BeginOutputReadLine();
                        p.BeginErrorReadLine();


                        // Main Loop
                        bool nextExit = false;
                        while (true)
                        {
                            // Check if Exited
                            if (p.HasExited)
                            {
                                // Wait for Exit
                                p.WaitForExit();

                                // SET Flag
                                nextExit = true;
                            }

                            // Check ConcurrentQueue (Standard Output)
                            while (!stdout.IsEmpty)
                            {
                                if (stdout.TryDequeue(out var line))
                                {
                                    if (this.PassThru)
                                    {
                                        // REDIRECT Standard Output to (3) Warning Stream
                                        this.WriteWarning(line);
                                    }
                                    else
                                    {
                                        // OUTPUT (1) Standard Output
                                        this.WriteObject(line);
                                    }
                                }
                            }

                            // Check ConcurrentQueue (Standard Error)
                            while (!stderr.IsEmpty)
                            {
                                if (stderr.TryDequeue(out var line))
                                {
                                    // REDIRECT Standard Error to (3) Warning Stream
                                    this.WriteWarning(line);
                                }
                            }

                            // Break
                            if (nextExit) { break; }
                        }
                        // Main Loop


                        // STOP Reading Stream(s)
                        p.CancelOutputRead();
                        p.CancelErrorRead();

                        // Check Exit Code
                        if (p.ExitCode == 0)
                        {
                            // EXIT
                            break;
                        }
                        else
                        {
                            // Write Error
                            this.WriteError(new ErrorRecord(new ApplicationFailedException(), "NonZeroExitCode", ErrorCategory.InvalidResult, filepath));

                            // Wait for Retry
                            if (count < this.RetryCount)
                            {
                                // Wait for $RetrySecond
                                for (int second = 0; second < this.RetrySecond; second++)
                                {
                                    // OUTPUT Message
                                    this.WriteWarning($"Wait for {this.RetrySecond - second} seconds to retry ({count} / {this.RetryCount})...");

                                    // Wait for a second
                                    Thread.Sleep(1000);
                                }
                            }
                        }
                    }
                    // Should Process

                } while (count++ < this.RetryCount);
                // Retry Loop


                // OUTPUT
                if (this.PassThru)
                {
                    // OUTPUT Process
                    this.WriteObject(p.ExitCode);
                }
            }
            // Using Process
        }


        // ----------------------------------------------------------------------------------------------------
        // Post-Processing Operations
        // ----------------------------------------------------------------------------------------------------
        // (None)
    }
}
