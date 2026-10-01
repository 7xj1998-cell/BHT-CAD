using System;
using System.Windows.Forms;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Runtime;
using BHT.Bridge;
using AcApp = Autodesk.AutoCAD.ApplicationServices.Application;

namespace BHT.Palette
{
    /// <summary>
    /// 0.4.6-fix3: cua so thong bao loi / canh bao cua BHT (tieu de "BHT", bieu tuong loi / canh bao).
    /// Khong hien trong AutoCAD Core Console (khong co giao dien, kiem thu tu dong khong duoc treo).
    /// Cung mot noi dung trong 3 giay chi hien 1 lan (vd doi ban ve lien tuc khi Lisp khong cung phien ban).
    /// </summary>
    public static class BhtPopup
    {
        public const string Title = "BHT";
        private static string _lastText = "";
        private static DateTime _lastAt = DateTime.MinValue;
        private static bool _showing;

        public static bool CanShow()
        {
            return !PaletteCommands.IsCoreConsole();
        }

        /// <summary>Tra true neu da hien cua so.</summary>
        public static bool Show(string text, bool error)
        {
            if (!CanShow() || _showing) return false;
            text = (text ?? "").Trim();
            if (text.Length == 0) return false;
            if (text == _lastText && (DateTime.Now - _lastAt).TotalSeconds < 3) return false;
            _showing = true;
            try
            {
                IWin32Window owner = null;
                try
                {
                    IntPtr h = AcApp.MainWindow.Handle;
                    if (h != IntPtr.Zero) owner = new Owner(h);
                }
                catch { }
                var icon = error ? MessageBoxIcon.Error : MessageBoxIcon.Warning;
                if (owner != null) MessageBox.Show(owner, text, Title, MessageBoxButtons.OK, icon);
                else MessageBox.Show(text, Title, MessageBoxButtons.OK, icon);
                return true;
            }
            catch { return false; }
            finally
            {
                _lastText = text;
                _lastAt = DateTime.Now;
                _showing = false;
            }
        }

        private sealed class Owner : IWin32Window
        {
            private readonly IntPtr _h;
            public Owner(IntPtr h) { _h = h; }
            public IntPtr Handle { get { return _h; } }
        }
    }

    /// <summary>
    /// (BHTPOPUP "ERROR"|"WARN" "noi dung") - Lisp goi qua bht:popup.
    /// Tra "SHOWN" khi da hien; "SKIP" khi khong hien (Core Console, dang trong lenh goi tu Palette
    /// qua bht:api-*: Palette tu bao loi, hoac noi dung rong / trung lap).
    /// </summary>
    // Lop cu the theo quy uoc CommandClass cua AutoCAD; ham Lisp khong can trang thai instance.
    public sealed class BhtPopupLispFunctions
    {
        [LispFunction("BHTPOPUP")]
        public object Popup(ResultBuffer args)
        {
            string kind = "", text = "";
            int index = 0;
            if (args != null)
                foreach (TypedValue value in args)
                {
                    string s = value.Value == null ? "" : Convert.ToString(value.Value);
                    if (index == 0) kind = s; else if (index == 1) text = s;
                    index++;
                }
            if (AcadDispatcher.InLispApi) return "SKIP";
            bool error = !string.Equals(kind, "WARN", StringComparison.OrdinalIgnoreCase);
            return BhtPopup.Show(text, error) ? "SHOWN" : "SKIP";
        }
    }
}
