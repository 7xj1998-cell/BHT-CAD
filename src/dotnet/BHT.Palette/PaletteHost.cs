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
                if (doc != null) doc.Editor.WriteMessage("\nBHT.Palette " + BHT.Core.BhtVersion.FileVersion + " đã nạp. Gõ BHTPALETTE để mở bảng (cần APPLOAD BHT-0.4.0.lsp cho các chức năng Lisp).");
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

        [CommandMethod("BHTPALETTE", CommandFlags.Session)]
        public void ShowPalette()
        {
            if (IsCoreConsole())
            {
                // AutoCAD Core Console khong co giao dien: tao PaletteSet se lam tien trinh dung dot ngot
                // (kiem chung 0.4.0-rc) -> chi bao, khong tao palette.
                var d0 = AcApp.DocumentManager.MdiActiveDocument;
                if (d0 != null) d0.Editor.WriteMessage("\nBHTPALETTE: cần AutoCAD đầy đủ (Core Console không có giao diện) - không mở palette.");
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
        public static readonly Guid PaletteGuid = new Guid("B4A7E0C2-5D31-4F0B-9C6E-0BD7A1F40400");
        public const string Title = "BHT — QUẢN LÝ HIỆN TRẠNG TUYẾN";
        private static PaletteSet _ps;
        private static BhtPaletteControl _ctl;
        private static bool _restored;
        private static bool _docEvents;

        [System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.NoInlining)]
        public static void Show()
        {
            if (_ps == null)
            {
                _ps = new PaletteSet(Title, "BHTPALETTE", PaletteGuid);
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
            _ps.Visible = true;
            if (!_restored)
            {
                // Chua co cau hinh luu (lan dau): dock trai, rong vua du.
                _restored = true;
                try { _ps.Dock = DockSides.Left; _ps.Size = new Size(420, 760); } catch { }
            }
            _ctl.BindTo(AcApp.DocumentManager.MdiActiveDocument);
        }

        private static void OnLoad(object sender, PalettePersistEventArgs e)
        {
            // AutoCAD da khoi phuc cau hinh cua PaletteSet theo GUID -> khong ep dock lai.
            _restored = true;
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
