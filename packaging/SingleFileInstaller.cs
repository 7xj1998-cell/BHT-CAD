using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.IO.Compression;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace BHT.Setup
{
    public static class SetupRunner
    {
        public static string Version { get { return Assembly.GetExecutingAssembly().GetName().Version.ToString(3); } }

        internal static void Extract(Stream stream, string directory)
        {
            string root = Path.GetFullPath(directory).TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar;
            var names = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            long size = 0;
            using (var zip = new ZipArchive(stream, ZipArchiveMode.Read, true))
            {
                foreach (var entry in zip.Entries)
                {
                    string name = entry.FullName.Replace('/', Path.DirectorySeparatorChar);
                    if (Path.IsPathRooted(name) || name.IndexOf(':') >= 0)
                        throw new InvalidDataException("Đường dẫn trong bộ cài không hợp lệ.");
                    string target = Path.GetFullPath(Path.Combine(root, name));
                    if (!target.StartsWith(root, StringComparison.OrdinalIgnoreCase) || !names.Add(target))
                        throw new InvalidDataException("Đường dẫn trong bộ cài không hợp lệ.");
                    size += entry.Length;
                    if (size > 256L * 1024 * 1024) throw new InvalidDataException("Bộ cài có dung lượng bất thường.");
                    if (entry.Name.Length == 0) { Directory.CreateDirectory(target); continue; }
                    Directory.CreateDirectory(Path.GetDirectoryName(target));
                    using (var input = entry.Open())
                    using (var output = new FileStream(target, FileMode.CreateNew, FileAccess.Write, FileShare.None)) input.CopyTo(output);
                }
            }
        }

        public static string Execute(bool validateOnly)
        {
            string tempRoot = Path.GetFullPath(Path.GetTempPath()).TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar;
            string directory = Path.Combine(tempRoot, "BHT-setup-" + Guid.NewGuid().ToString("N"));
            string resolved = Path.GetFullPath(directory);
            if (!resolved.StartsWith(tempRoot, StringComparison.OrdinalIgnoreCase)) throw new InvalidOperationException("Thư mục tạm không hợp lệ.");
            Directory.CreateDirectory(directory);
            try
            {
                using (var payload = Assembly.GetExecutingAssembly().GetManifestResourceStream("BHT.Setup.Payload.zip"))
                {
                    if (payload == null) throw new InvalidDataException("Bộ cài thiếu dữ liệu BHT.");
                    using (var hash = SHA256.Create())
                    {
                        string actual = BitConverter.ToString(hash.ComputeHash(payload)).Replace("-", "");
                        if (actual != SetupPayload.Sha256) throw new InvalidDataException("File bộ cài bị thay đổi hoặc tải chưa đầy đủ. Hãy gửi lại file gốc.");
                    }
                    payload.Position = 0; Extract(payload, directory);
                }
                string script = Path.Combine(directory, "INSTALL_BHT.ps1");
                string powershell = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System), "WindowsPowerShell", "v1.0", "powershell.exe");
                if (!File.Exists(powershell)) throw new FileNotFoundException("Máy cần Windows PowerShell để cài BHT.");
                var start = new ProcessStartInfo(powershell, "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File \"" + script + "\"" + (validateOnly ? " -ValidateOnly" : ""))
                {
                    UseShellExecute = false, CreateNoWindow = true, WindowStyle = ProcessWindowStyle.Hidden,
                    RedirectStandardOutput = true, RedirectStandardError = true,
                    StandardOutputEncoding = Encoding.UTF8, StandardErrorEncoding = Encoding.UTF8,
                    WorkingDirectory = directory
                };
                // Use the Windows PowerShell modules even when launched from PowerShell 7.
                start.EnvironmentVariables["PSModulePath"] = Path.Combine(Path.GetDirectoryName(powershell), "Modules");
                using (var process = Process.Start(start))
                {
                    var output = process.StandardOutput.ReadToEndAsync();
                    var error = process.StandardError.ReadToEndAsync();
                    process.WaitForExit();
                    string log = output.Result + error.Result;
                    if (process.ExitCode != 0) throw new InvalidOperationException(log.Trim());
                    return log;
                }
            }
            finally
            {
                // Delete only the unique temporary directory created by this installer.
                if (Directory.Exists(resolved) && resolved.StartsWith(tempRoot, StringComparison.OrdinalIgnoreCase)
                    && Path.GetFileName(resolved).StartsWith("BHT-setup-", StringComparison.Ordinal)
                    && (File.GetAttributes(resolved) & FileAttributes.ReparsePoint) == 0)
                {
                    try { Directory.Delete(resolved, true); } catch (IOException) { } catch (UnauthorizedAccessException) { }
                }
            }
        }
    }

    public sealed class SetupForm : Form
    {
        private readonly Button install = new Button { Text = "Cài đặt BHT", AutoSize = true, MinimumSize = new Size(120, 34), TabIndex = 0 };
        private readonly Button close = new Button { Text = "Đóng", AutoSize = true, MinimumSize = new Size(85, 34), TabIndex = 1 };
        private readonly TextBox log = new TextBox { Multiline = true, ReadOnly = true, ScrollBars = ScrollBars.Vertical, Dock = DockStyle.Fill, BackColor = Color.White, TabStop = false };
        private readonly Label status = new Label { AutoSize = true, Dock = DockStyle.Fill };
        private readonly ProgressBar progress = new ProgressBar { Dock = DockStyle.Fill, Height = 8, Visible = false, Style = ProgressBarStyle.Marquee };
        private readonly Label heading = new Label { AutoSize = true, Font = new Font("Segoe UI", 18f, FontStyle.Bold), ForeColor = Color.Teal, Margin = new Padding(0, 0, 0, 12) };
        private readonly Label intro = new Label { AutoSize = true, MaximumSize = new Size(570, 0), Margin = new Padding(0, 0, 0, 14) };
        private readonly Func<string> runInstaller;
        private bool busy, installed;

        public SetupForm() : this(() => SetupRunner.Execute(false)) { }

        internal SetupForm(Func<string> run)
        {
            if (run == null) throw new ArgumentNullException("run");
            runInstaller = run;
            Text = "Cài đặt BHT " + SetupRunner.Version;
            Font = new Font("Segoe UI", 9f); AutoScaleMode = AutoScaleMode.Dpi;
            ClientSize = new Size(620, 450); MinimumSize = new Size(560, 450);
            StartPosition = FormStartPosition.CenterScreen; MaximizeBox = false;
            var layout = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 1, RowCount = 6, Padding = new Padding(16) };
            layout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
            layout.RowStyles.Add(new RowStyle(SizeType.AutoSize)); layout.RowStyles.Add(new RowStyle(SizeType.AutoSize));
            layout.RowStyles.Add(new RowStyle(SizeType.Percent, 100)); layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 12));
            layout.RowStyles.Add(new RowStyle(SizeType.AutoSize)); layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 42));
            heading.Text = "BHT " + SetupRunner.Version;
            intro.Text = "Quản lý hiện trạng tuyến trong AutoCAD.\r\nĐóng tất cả cửa sổ AutoCAD rồi bấm Cài đặt BHT.\r\n\r\nWindows 64-bit · AutoCAD 2021–2024 (đã kiểm tra trên AutoCAD 2024).\r\nCài cho tài khoản Windows hiện tại, không cần quyền quản trị.";
            layout.Controls.Add(heading, 0, 0); layout.Controls.Add(intro, 0, 1);
            log.Text = "Thư mục cài đặt:\r\n" + Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "Autodesk", "ApplicationPlugins", "BHT.bundle") + "\r\n\r\nBộ cài đã kèm DLL, Lisp và phông chữ. Bản BHT cũ được sao lưu khi cập nhật.";
            layout.Controls.Add(log, 0, 2); layout.Controls.Add(progress, 0, 3);
            status.Text = "Sau khi cài: mở AutoCAD và gõ BHT hoặc BTH."; status.Margin = new Padding(0, 10, 0, 8);
            layout.Controls.Add(status, 0, 4);
            var buttons = new FlowLayoutPanel { Height = 42, FlowDirection = FlowDirection.RightToLeft, Dock = DockStyle.Fill };
            close.Click += (s, e) => Close(); install.Click += Install;
            buttons.Controls.Add(close); buttons.Controls.Add(install); layout.Controls.Add(buttons, 0, 5);
            Controls.Add(layout); AcceptButton = install; CancelButton = close;
            FormClosing += (s, e) => { if (busy) e.Cancel = true; };
        }

        private async void Install(object sender, EventArgs args)
        {
            if (busy || installed) return;
            busy = true; install.Enabled = close.Enabled = false; progress.Visible = true;
            status.Text = "Đang xác minh và cài BHT…";
            status.ForeColor = SystemColors.ControlText;
            try
            {
                log.Text = await Task.Run(runInstaller);
                installed = true;
                Text = heading.Text = "Đã cài đặt BHT " + SetupRunner.Version;
                heading.ForeColor = Color.DarkGreen;
                intro.Text = "Cài đặt thành công.\r\nMở AutoCAD và gõ BHT hoặc BTH để sử dụng.\r\nBấm Hoàn tất để đóng bộ cài.";
                status.Text = "Cài đặt hoàn tất.";
                status.ForeColor = Color.DarkGreen;
                install.Enabled = install.Visible = false;
                close.Text = "Hoàn tất"; AcceptButton = close;
            }
            catch (Exception ex) { log.Text = ex.Message; status.Text = "Chưa cài được. Xem thông báo ở trên rồi thử lại."; status.ForeColor = Color.Firebrick; }
            finally
            {
                busy = false; install.Enabled = !installed; close.Enabled = true; progress.Visible = false;
                if (installed) close.Focus();
            }
        }
    }

    internal static class Program
    {
        [STAThread] private static int Main(string[] args)
        {
            if (args.Length > 0)
            {
                string report = args.Length == 3 && args[1] == "--report" ? args[2] : null;
                if (args[0] != "--validate-only" || (args.Length != 1 && report == null)) return 2;
                try { string text = SetupRunner.Execute(true); if (report != null) File.WriteAllText(report, text, Encoding.UTF8); return 0; }
                catch (Exception ex) { if (report != null) File.WriteAllText(report, "FAIL: " + ex.Message, Encoding.UTF8); return 1; }
            }
            Application.EnableVisualStyles(); Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new SetupForm()); return 0;
        }
    }
}
