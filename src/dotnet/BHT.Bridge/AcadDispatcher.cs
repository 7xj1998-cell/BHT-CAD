using System;
using System.Threading.Tasks;
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using BHT.Core;
using CoreApp = Autodesk.AutoCAD.ApplicationServices.Core.Application;

namespace BHT.Bridge
{
    /// <summary>
    /// Bo dieu phoi DUY NHAT giua giao dien modeless (palette) va AutoCAD:
    ///  - xac dinh tai lieu dang hoat dong;
    ///  - tu choi khi dang co lenh chay (Document.CommandInProgress) de tranh xung dot;
    ///  - ghi DB truc tiep: Document.LockDocument + Transaction (RunWrite);
    ///  - goi Lisp (acedInvoke): DocumentCollection.ExecuteInCommandContextAsync, moi
    ///    ngoai le duoc bat BEN TRONG callback (RunLisp);
    ///  - gui lenh Lisp tuong tac: SendStringToExecute = "da gui", KHONG phai "thanh cong";
    ///    hoan tat duoc xac nhan qua CommandEnded/LispEnded (CommandWatcher).
    /// Chi tham chieu AcCoreMgd/AcDbMgd (khong AcMgd) nen chay duoc trong Core Console.
    /// </summary>
    public static class AcadDispatcher
    {
        public static Document ActiveDocument
        {
            get
            {
                try { return CoreApp.DocumentManager.MdiActiveDocument; } catch { return null; }
            }
        }

        /// <summary>Lenh dang chay ("" = khong co). Loi -> coi nhu dang ban.</summary>
        public static string ActiveCommands(Document doc)
        {
            try { return doc == null ? "" : (doc.CommandInProgress ?? ""); } catch { return "?"; }
        }

        public static bool IsBusy(Document doc, out string reason)
        {
            reason = null;
            if (doc == null) { reason = "không có bản vẽ đang mở"; return true; }
            string c = ActiveCommands(doc);
            if (c != "") { reason = "AutoCAD đang chạy lệnh " + c + " - hãy kết thúc lệnh (Esc) rồi thử lại"; return true; }
            return false;
        }

        /// <summary>Doc du lieu (khong can khoa). Loi duoc bat va tra ve default.</summary>
        public static T RunRead<T>(Document doc, Func<Database, T> f, T fallback, Action<string> onError)
        {
            if (doc == null) { if (onError != null) onError("không có bản vẽ đang mở"); return fallback; }
            try { return f(doc.Database); }
            catch (Exception ex) { if (onError != null) onError(ex.Message); return fallback; }
        }

        /// <summary>Ghi DB tu giao dien modeless: tu choi neu dang co lenh; khoa tai lieu; bat loi.</summary>
        public static OpResult RunWrite(Document doc, string label, Func<Database, OpResult> f)
        {
            string why;
            if (IsBusy(doc, out why)) return OpResult.Fail(label + ": " + why);
            try
            {
                using (doc.LockDocument(DocumentLockMode.Write, "BHT", label, false))
                {
                    return f(doc.Database);
                }
            }
            catch (Exception ex) { return OpResult.Fail(label + ": " + ex.Message); }
        }

        /// <summary>
        /// Chay 1 hanh dong trong ngu canh lenh cua tai lieu dang hoat dong (can cho acedInvoke).
        /// Tu palette (ngu canh ung dung): ExecuteInCommandContextAsync. Neu da o ngu canh lenh: chay ngay.
        /// done duoc goi dung 1 lan voi ket qua / loi.
        /// </summary>
        public static void RunInCommandContext(string label, Func<OpResult> action, Action<OpResult> done)
        {
            var doc = ActiveDocument;
            string why;
            if (IsBusy(doc, out why)) { Finish(done, OpResult.Fail(label + ": " + why)); return; }
            var dm = CoreApp.DocumentManager;
            if (!dm.IsApplicationContext)
            {
                OpResult r;
                try { r = action(); } catch (Exception ex) { r = OpResult.Fail(label + ": " + ex.Message); }
                Finish(done, r);
                return;
            }
            // done chi duoc goi DUNG 1 LAN (callback hoac loi truoc khi callback chay).
            bool called = false;
            Action<OpResult> once = r => { if (called) return; called = true; Finish(done, r); };
            try
            {
                // AutoCAD 2024: tra ve DocumentCollection.ExecutionResult (awaitable), khong phai Task.
                var er = dm.ExecuteInCommandContextAsync(o =>
                {
                    OpResult r;
                    try { r = action(); }
                    catch (Exception ex) { r = OpResult.Fail(label + ": " + ex.Message); }
                    once(r);
                    return Completed();
                }, null);
                er.OnCompleted(() =>
                {
                    try { er.GetResult(); once(OpResult.Fail(label + ": lệnh không được thực hiện")); }
                    catch (Exception ex) { once(OpResult.Fail(label + ": " + ex.Message)); }
                });
            }
            catch (Exception ex) { once(OpResult.Fail(label + ": " + ex.Message)); }
        }

        private static void Finish(Action<OpResult> done, OpResult r)
        {
            if (done == null) return;
            try { done(r); } catch { }
        }

        private static Task Completed()
        {
            var tcs = new TaskCompletionSource<object>();
            tcs.SetResult(null);
            return tcs.Task;
        }

        /// <summary>Goi ham Lisp bht:api-* qua ngu canh lenh.</summary>
        public static void RunLisp(string function, string[] args, Action<LispReply> done)
        {
            LispReply reply = null;
            RunInCommandContext("Lisp " + function, () =>
            {
                reply = new LispApi().Call(function, args);
                return reply.Ok ? OpResult.Success(function) : OpResult.Fail(reply.Error);
            }, r =>
            {
                if (reply == null) { reply = new LispReply(); reply.Error = r.Message; }
                if (done != null) done(reply);
            });
        }

        /// <summary>
        /// Gui 1 lenh tuong tac (vd "BHTXUAT") - fire-and-forget. Tra ve OpResult "da gui"; ket qua that
        /// duoc bao qua CommandWatcher (CommandEnded / Cancelled / Failed) va doc lai du lieu.
        /// </summary>
        public static OpResult SendCommand(Document doc, string command, CommandWatcher watcher)
        {
            string why;
            if (IsBusy(doc, out why)) return OpResult.Fail(command + ": " + why);
            try
            {
                if (watcher != null) watcher.Expect(doc, command);
                doc.SendStringToExecute("_" + command + " ", true, false, true);
                return OpResult.Success("đã gửi lệnh " + command + " - đang chờ AutoCAD thực hiện");
            }
            catch (Exception ex) { return OpResult.Fail(command + ": " + ex.Message); }
        }
    }

    /// <summary>
    /// Theo doi ket thuc lenh da gui de xac nhan va lam moi du lieu. Lenh ARX/.NET/noi tai:
    /// CommandEnded/Cancelled/Failed. Lenh Lisp (c:BHT...): LispWillStart (dong dau chua "C:LENH")
    /// roi LispEnded / LispCancelled.
    /// </summary>
    public sealed class CommandWatcher
    {
        private Document _doc;
        private string _cmd;
        private bool _lispArmed;
        public event Action<string, string> Finished; // (lenh, trang thai: KET_THUC / HUY / LOI)

        public void Expect(Document doc, string command)
        {
            Detach();
            _doc = doc; _cmd = command.ToUpperInvariant();
            _doc.CommandEnded += OnEnded;
            _doc.CommandCancelled += OnCancelled;
            _doc.CommandFailed += OnFailed;
            _doc.LispWillStart += OnLispStart;
            _doc.LispEnded += OnLispEnded;
            _doc.LispCancelled += OnLispCancelled;
            _lispArmed = false;
        }

        private void OnLispStart(object s, LispWillStartEventArgs e)
        {
            if (_cmd != null && e.FirstLine != null && e.FirstLine.ToUpperInvariant().Contains("C:" + _cmd)) _lispArmed = true;
        }
        private void OnLispEnded(object s, EventArgs e) { if (_lispArmed) Done("KET_THUC"); }
        private void OnLispCancelled(object s, EventArgs e) { if (_lispArmed) Done("HUY"); }

        private bool Match(CommandEventArgs e)
        {
            return _cmd != null && string.Equals(e.GlobalCommandName, _cmd, StringComparison.OrdinalIgnoreCase);
        }

        private void OnEnded(object s, CommandEventArgs e) { if (Match(e)) Done("KET_THUC"); }
        private void OnCancelled(object s, CommandEventArgs e) { if (Match(e)) Done("HUY"); }
        private void OnFailed(object s, CommandEventArgs e) { if (Match(e)) Done("LOI"); }

        private void Done(string state)
        {
            string c = _cmd;
            Detach();
            var h = Finished;
            if (h != null) { try { h(c, state); } catch { } }
        }

        public void Detach()
        {
            if (_doc != null)
            {
                try
                {
                    _doc.CommandEnded -= OnEnded;
                    _doc.CommandCancelled -= OnCancelled;
                    _doc.CommandFailed -= OnFailed;
                    _doc.LispWillStart -= OnLispStart;
                    _doc.LispEnded -= OnLispEnded;
                    _doc.LispCancelled -= OnLispCancelled;
                }
                catch { }
            }
            _doc = null; _cmd = null; _lispArmed = false;
        }
    }
}
