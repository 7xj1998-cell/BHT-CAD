using System;
using System.Collections.Generic;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Runtime;
using BHT.Core;
using CoreApp = Autodesk.AutoCAD.ApplicationServices.Core.Application;

namespace BHT.Bridge
{
    /// <summary>
    /// Duong DUY NHAT de .NET goi Lisp BHT: Application.Invoke (acedInvoke) toi cac ham
    /// bht:api-* ma BHT-0.4.4.lsp dang ky bang vl-acad-defun.
    /// BAT BUOC goi trong ngu canh lenh / tai lieu (tu 1 lenh .NET, hoac qua
    /// AcadDispatcher.RunInCommandContext tu palette). Dong bo: tra ve khi Lisp chay xong.
    /// </summary>
    public sealed class LispApi : ILispApi
    {
        public LispReply Call(string function, params string[] args)
        {
            var raw = new List<string>();
            try
            {
                using (var rb = new ResultBuffer())
                {
                    rb.Add(new TypedValue((int)LispDataType.Text, function));
                    if (args != null) foreach (var a in args) rb.Add(new TypedValue((int)LispDataType.Text, a ?? ""));
                    using (var res = CoreApp.Invoke(rb))
                    {
                        if (res == null) return LispReply.FromStrings(null);
                        foreach (TypedValue tv in res)
                        {
                            if (tv.TypeCode == (int)LispDataType.ListBegin || tv.TypeCode == (int)LispDataType.ListEnd
                                || tv.TypeCode == (int)LispDataType.DottedPair) continue;
                            if (tv.TypeCode == (int)LispDataType.Nil) { raw.Add(""); continue; }
                            raw.Add(Convert.ToString(tv.Value, System.Globalization.CultureInfo.InvariantCulture));
                        }
                    }
                }
            }
            catch (System.Exception ex)
            {
                var r = new LispReply();
                r.Error = "không gọi được hàm Lisp " + function + " (" + ex.Message + "). Cần nạp đúng bộ BHT " + BhtVersion.Version + " (hàm bht:api-* đăng ký bằng vl-acad-defun).";
                return r;
            }
            return LispReply.FromStrings(raw);
        }

        /// <summary>Kiem tra dung phien ban Lisp BHT da nap: (bht:api-version) -> ("OK" phien_ban muc_api build).</summary>
        public bool Probe(out string version, out string message)
        {
            version = "";
            var r = Call("bht:api-version");
            if (!r.Ok) { message = r.Error; return false; }
            version = r.Values.Count > 0 ? r.Values[0] : "";
            string lvl = r.Values.Count > 1 ? r.Values[1] : "";
            if (!BhtVersion.LispCompatible(version, lvl))
            {
                message = "BHT Lisp " + version + " (API " + lvl + ") không khớp plugin " + BhtVersion.Version + ". Đóng tất cả AutoCAD rồi cài lại cùng một bộ phát hành.";
                return false;
            }
            message = "BHT Lisp " + version + " đã nạp (API " + lvl + ").";
            return true;
        }
    }
}
