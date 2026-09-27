using System;
using System.Drawing;
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.Runtime;
using Autodesk.AutoCAD.Windows;
using AcApp = Autodesk.AutoCAD.ApplicationServices.Application;

[assembly: ExtensionApplication(typeof(BHT.Palette.BhtPlugin))]
[assembly: CommandClass(typeof(BHT.Palette.PaletteCommands))]

namespace BHT.Palette
{
    /// <summary>Nap / go plugin: khong lam viec nang khi nap; go su kien khi AutoCAD dong.</summary>
    public class BhtPlugin : IExtensionApplication
    {
        public void Initialize()
        {
            try
            {
                var doc = AcApp.DocumentManager.MdiActiveDocument;
                if (doc != null) doc.Editor.WriteMessage("\nBHT " + BHT.Core.BhtVersion.Version + " đã sẵn sàng. Gõ BTH hoặc BHT để mở Palette.");
            }
            catch { }
        }

        public void Terminate() { PaletteHost.Shutdown(); }
    }

    public class PaletteCommands
    {
        internal static bool IsCoreConsole()
        {
            try { return string.Equals(System.Diagnostics.Process.GetCurrentProcess().ProcessName, "accoreconsole", StringComparison.OrdinalIgnoreCase); }
            catch { return false; }
        }

        [CommandMethod("BTH", CommandFlags.Session)]
        public void ShowBth() { ShowPalette("BTH"); }

        [CommandMethod("BHT", CommandFlags.Session)]
        public void ShowBht() { ShowPalette("BHT"); }

        [CommandMethod("BHTSHOW", CommandFlags.Session)]
        public void ShowInternal() { ShowPalette("BHTSHOW"); }

        [CommandMethod("BHTPALETTE", CommandFlags.Session)]
        public void ShowLegacy() { ShowPalette("BHTPALETTE"); }

        private static void ShowPalette(string command)
        {
            if (IsCoreConsole())
            {
                // AutoCAD Core Console khong co giao dien: tao PaletteSet se lam tien trinh dung dot ngot
                // (kiem chung bang Core Console) -> chi bao, khong tao palette.
                var d0 = AcApp.DocumentManager.MdiActiveDocument;
                if (d0 != null) d0.Editor.WriteMessage("\n" + command + ": cần AutoCAD đầy đủ (Core Console không có giao diện) - không mở Palette.");
                return;
            }
            try { PaletteHost.Show(); }
            catch (System.Exception ex)
            {
                var doc = AcApp.DocumentManager.MdiActiveDocument;
                if (doc != null) doc.Editor.WriteMessage("\nBHT: không mở được palette: " + ex.Message);
            }
        }
    }

    /// <summary>
    /// PaletteSet GUID CO DINH (AutoCAD luu vi tri / dock / kich thuoc theo GUID).
    /// Lan dau: dock trai. Theo doi DocumentActivated / DocumentToBeDestroyed de gan lai du lieu.
    /// </summary>
    public static class PaletteHost
    {
        public static readonly Guid PaletteGuid = new Guid("B4A7E0C2-5D31-4F0B-9C6E-0BD7A1F40410");
        public static string Title { get { return "BHT " + BHT.Core.BhtVersion.Version + " — QUẢN LÝ HIỆN TRẠNG TUYẾN"; } }
        private static PaletteSet _ps;
        private static BhtPaletteControl _ctl;
        private static bool _initialLayoutApplied;
        private static bool _docEvents;

        [System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.NoInlining)]
        public static void Show()
        {
            if (_ps == null)
            {
                _ps = new PaletteSet(Title, "BTH", PaletteGuid);
                // AutoCAD co the khoi phuc ten da luu theo GUID tu ban cu; ep lai ten hien tai.
                _ps.Name = Title;
                _ps.Text = Title;
                _ps.Load += OnLoad;
                _ps.Save += OnSave;
                _ps.Style = PaletteSetStyles.ShowCloseButton | PaletteSetStyles.ShowAutoHideButton
                          | PaletteSetStyles.ShowPropertiesMenu | PaletteSetStyles.Snappable;
                _ps.MinimumSize = new Size(340, 420);
                _ps.DockEnabled = DockSides.Left | DockSides.Right;
                _ps.KeepFocus = false;
                _ctl = new BhtPaletteControl();
                _ps.Add("BHT", _ctl);
                HookDocEvents();
            }
            _ps.Name = Title;
            _ps.Text = Title;
            _ps.Visible = true;
            if (!_initialLayoutApplied)
            {
                // Moi phien AutoCAD bat dau voi bo cuc de doc: dock trai, rong 430 px.
                // Cau hinh cu tung lam cac hang dau bieu mau bi cat va de lai "chu mo coi".
                _initialLayoutApplied = true;
                try { _ps.Dock = DockSides.Left; _ps.Size = new Size(430, 820); } catch { }
            }
            _ctl.BindTo(AcApp.DocumentManager.MdiActiveDocument);
            _ctl.RefreshAll();
        }

        private static void OnLoad(object sender, PalettePersistEventArgs e)
        {
            // AutoCAD da doc cau hinh cu. Show() se chuan hoa bo cuc mot lan cho phien nay.
        }

        private static void OnSave(object sender, PalettePersistEventArgs e)
        {
            try { e.ConfigurationSection.WriteProperty("BHT_Version", BHT.Core.BhtVersion.Version); } catch { }
        }

        private static void HookDocEvents()
        {
            if (_docEvents) return;
            var dm = AcApp.DocumentManager;
            dm.DocumentActivated += OnDocActivated;
            dm.DocumentToBeDestroyed += OnDocToBeDestroyed;
            _docEvents = true;
        }

        private static void OnDocActivated(object sender, DocumentCollectionEventArgs e)
        {
            if (_ctl != null && _ps != null && _ps.Visible) _ctl.BindTo(e.Document);
        }

        private static void OnDocToBeDestroyed(object sender, DocumentCollectionEventArgs e)
        {
            if (_ctl != null) _ctl.DocumentClosing(e.Document);
        }

        public static void Shutdown()
        {
            try
            {
                if (_docEvents)
                {
                    var dm = AcApp.DocumentManager;
                    dm.DocumentActivated -= OnDocActivated;
                    dm.DocumentToBeDestroyed -= OnDocToBeDestroyed;
                    _docEvents = false;
                }
                if (_ctl != null) _ctl.Unbind();
            }
            catch { }
        }
    }
}
