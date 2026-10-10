using System;
using System.Drawing;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading;
using System.Windows.Forms;

public static class SingleFileInstallerProbe
{
    static int checks;
    static void Check(string name, bool value) { if (!value) throw new Exception(name); checks++; Console.WriteLine("PASS " + name); }
    static object Field(Form form, string name) { return form.GetType().GetField(name, BindingFlags.Instance | BindingFlags.NonPublic).GetValue(form); }
    static void PumpUntil(Func<bool> ready)
    {
        var limit = DateTime.UtcNow.AddSeconds(5);
        while (!ready()) { if (DateTime.UtcNow >= limit) throw new Exception("Installer UI timed out"); Application.DoEvents(); Thread.Sleep(10); }
        Application.DoEvents();
    }
    static Form TestForm(Assembly assembly, Func<string> run)
    {
        var constructor = assembly.GetType("BHT.Setup.SetupForm").GetConstructor(BindingFlags.Instance | BindingFlags.NonPublic, null, new[] { typeof(Func<string>) }, null);
        var form = (Form)constructor.Invoke(new object[] { run });
        form.StartPosition = FormStartPosition.Manual; form.Location = new Point(-3000, -3000); form.Show(); Application.DoEvents(); return form;
    }
    static System.Collections.Generic.IEnumerable<Control> Children(Control parent)
    { foreach (Control c in parent.Controls) { yield return c; foreach (var nested in Children(c)) yield return nested; } }
    static MemoryStream Zip(params string[] names)
    {
        var stream = new MemoryStream();
        using (var zip = new ZipArchive(stream, ZipArchiveMode.Create, true))
            foreach (string name in names) using (var writer = new StreamWriter(zip.CreateEntry(name).Open(), Encoding.UTF8)) writer.Write("Nội dung thử");
        stream.Position = 0; return stream;
    }
    [STAThread] static int Main(string[] args)
    {
        try
        {
            string output = Path.GetFullPath(args[1]); Directory.CreateDirectory(output);
            var assembly = Assembly.LoadFrom(args[0]);
            var runner = assembly.GetType("BHT.Setup.SetupRunner");
            var extract = runner.GetMethod("Extract", BindingFlags.NonPublic | BindingFlags.Static);
            using (var zip = Zip("Thư mục/kiểm tra.txt")) extract.Invoke(null, new object[] { zip, Path.Combine(output, "valid") });
            Check("unicode-path-extraction", File.ReadAllText(Path.Combine(output, "valid", "Thư mục", "kiểm tra.txt")).Contains("Nội dung thử"));
            foreach (var names in new[] { new[] { "../outside.txt" }, new[] { "C:/outside.txt" }, new[] { "/outside.txt" }, new[] { "same.txt", "SAME.txt" }, new[] { "stream:alternate.txt" } })
            {
                bool rejected = false;
                using (var zip = Zip(names))
                    try { extract.Invoke(null, new object[] { zip, Path.Combine(output, "reject-" + checks) }); }
                    catch (TargetInvocationException ex) { rejected = ex.InnerException is InvalidDataException; }
                Check("reject-unsafe-zip-" + checks, rejected);
            }
            Check("no-file-escaped-extraction", !File.Exists(Path.Combine(output, "outside.txt")));
            Application.EnableVisualStyles();
            Exception uiError = null;
            using (var uiContext = new ApplicationContext())
            using (var uiStart = new System.Windows.Forms.Timer { Interval = 1 })
            {
                uiStart.Tick += (sender, eventArgs) => {
                    uiStart.Stop();
                    try
                    {
            using (var form = (Form)Activator.CreateInstance(assembly.GetType("BHT.Setup.SetupForm")))
            {
                form.StartPosition = FormStartPosition.Manual; form.Location = new Point(-3000, -3000); form.Show(); Application.DoEvents();
                Check("installer-version-title", form.Text == "Cài đặt BHT " + assembly.GetName().Version.ToString(3));
                Check("installer-target-current-account", Children(form).OfType<TextBox>().Single().Text.Contains(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData)));
                foreach (var size in new[] { new Size(620, 450), new Size(560, 450) })
                {
                    form.Size = size; Application.DoEvents();
                    foreach (var control in Children(form).Where(c => c is Button || c is TextBox || c is Label))
                        Check("installer-layout-" + size.Width + "-" + control.GetType().Name, control.Width > 0 && control.Height >= 14 && form.ClientRectangle.Contains(form.PointToClient(control.PointToScreen(new Point(control.Width - 1, control.Height - 1)))));
                }
                form.ClientSize = new Size(620, 450); Application.DoEvents();
                using (var bitmap = new Bitmap(form.Width, form.Height)) { form.DrawToBitmap(bitmap, new Rectangle(Point.Empty, form.Size)); bitmap.Save(Path.Combine(output, "installer.png")); }
                Children(form).OfType<Button>().Single(b => b.Text == "Đóng").PerformClick();
                Check("close-does-not-install", !form.Visible);
            }
            int installs = 0;
            using (var gate = new ManualResetEvent(false))
            using (var form = TestForm(assembly, () => { Interlocked.Increment(ref installs); if (!gate.WaitOne(4000)) throw new Exception("Test gate timeout"); return "Đã cài BHT thành công."; }))
            {
                var install = (Button)Field(form, "install"); var close = (Button)Field(form, "close");
                var click = form.GetType().GetMethod("Install", BindingFlags.Instance | BindingFlags.NonPublic);
                install.PerformClick(); PumpUntil(() => installs == 1);
                Check("running-install-locks-actions", !install.Enabled && !close.Enabled && ((ProgressBar)Field(form, "progress")).Visible);
                click.Invoke(form, new object[] { install, EventArgs.Empty });
                Check("running-install-rejects-second-click", installs == 1);
                form.Close(); Check("running-install-keeps-window-open", form.Visible);
                gate.Set(); PumpUntil(() => !(bool)Field(form, "busy"));
                Check("success-announcement-visible", ((Label)Field(form, "heading")).Text.StartsWith("Đã cài đặt BHT") && ((Label)Field(form, "status")).Text == "Cài đặt hoàn tất.");
                Check("success-hides-and-disables-install", !install.Visible && !install.Enabled);
                Check("success-only-finish-action", Children(form).OfType<Button>().Count(b => b.Visible && b.Enabled) == 1 && close.Text == "Hoàn tất" && close.Enabled);
                Check("success-enter-and-escape-close", form.AcceptButton == close && form.CancelButton == close);
                Check("success-help-replaces-install-instructions", ((Label)Field(form, "intro")).Text.Contains("Mở AutoCAD") && !((Label)Field(form, "intro")).Text.Contains("bấm Cài đặt"));
                click.Invoke(form, new object[] { install, EventArgs.Empty }); Application.DoEvents();
                Check("success-rejects-programmatic-reinstall", installs == 1 && !(bool)Field(form, "busy"));
                foreach (int width in new[] { 620, 560 })
                {
                    try
                    {
                        form.Size = new Size(width, 450); Application.DoEvents();
                        bool fits = true;
                        foreach (var control in Children(form).Where(c => c.Visible && (c is Button || c is Label || c is TextBox)))
                        {
                            bool visible = control.Height >= 14 && form.ClientRectangle.Contains(form.PointToClient(control.PointToScreen(new Point(control.Width - 1, control.Height - 1))));
                            if (!visible) Console.WriteLine("Clipped: " + control.GetType().Name + " " + control.Text + " " + control.Bounds + " / " + form.ClientSize);
                            fits &= visible;
                        }
                        Check("success-layout-" + width, fits);
                    }
                    catch (Exception ex) { Console.WriteLine("Layout exception: " + ex); throw; }
                }
                form.ClientSize = new Size(620, 450); Application.DoEvents();
                using (var bitmap = new Bitmap(form.Width, form.Height)) { form.DrawToBitmap(bitmap, new Rectangle(Point.Empty, form.Size)); bitmap.Save(Path.Combine(output, "installer-completed.png")); }
                close.PerformClick(); Check("finish-closes-without-reinstall", !form.Visible && installs == 1);
            }
            int attempts = 0;
            using (var form = TestForm(assembly, () => { if (Interlocked.Increment(ref attempts) == 1) throw new Exception("Lỗi thử nghiệm"); return "Đã cài thành công sau thử lại."; }))
            {
                var install = (Button)Field(form, "install"); install.PerformClick(); PumpUntil(() => !(bool)Field(form, "busy"));
                Check("failure-keeps-install-for-retry", install.Visible && install.Enabled && !(bool)Field(form, "installed"));
                Check("failure-displays-real-error", ((TextBox)Field(form, "log")).Text.Contains("Lỗi thử nghiệm") && ((Label)Field(form, "status")).Text.Contains("Chưa cài được"));
                install.PerformClick(); PumpUntil(() => !(bool)Field(form, "busy"));
                Check("retry-success-locks-reinstall", attempts == 2 && (bool)Field(form, "installed") && !install.Visible && !install.Enabled && ((Button)Field(form, "close")).Text == "Hoàn tất");
            }
                    }
                    catch (Exception ex) { uiError = ex; }
                    finally { uiContext.ExitThread(); }
                };
                uiStart.Start(); Application.Run(uiContext);
            }
            if (uiError != null) throw uiError;
            // Change a byte inside the embedded ZIP, keeping the executable structure valid.
            byte[] prefix = new byte[64];
            using (var payload = assembly.GetManifestResourceStream("BHT.Setup.Payload.zip")) payload.Read(prefix, 0, prefix.Length);
            byte[] exe = File.ReadAllBytes(args[0]); int match = -1;
            Check("installer-does-not-request-elevation", Encoding.UTF8.GetString(exe).Contains("asInvoker"));
            for (int index = 0; index <= exe.Length - prefix.Length; index++)
            {
                if (exe[index] != prefix[0]) continue;
                bool equal = true;
                for (int n = 1; n < prefix.Length; n++) if (exe[index + n] != prefix[n]) { equal = false; break; }
                if (equal) { match = index; break; }
            }
            Check("embedded-payload-found", match >= 0);
            exe[match + 40] ^= 1;
            File.WriteAllBytes(Path.Combine(output, "tampered.exe"), exe);
            Console.WriteLine("INSTALLER PROBE PASSED: " + checks); return 0;
        }
        catch (Exception ex) { Console.WriteLine("FAIL " + ex); return 1; }
    }
}
