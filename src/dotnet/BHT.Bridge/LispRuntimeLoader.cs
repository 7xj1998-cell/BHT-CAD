using System;
using System.Collections.Generic;
using System.IO;
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Runtime;
using BHT.Core;
using CoreApp = Autodesk.AutoCAD.ApplicationServices.Core.Application;

[assembly: CommandClass(typeof(BHT.Bridge.LispRuntimeLoader))]
namespace BHT.Bridge
{
    // Completion of LOAD is followed by a separate API/version probe.
    public sealed class LispRuntimeLoader : IDisposable
    {
        private static readonly Dictionary<string, LispRuntimeLoader> Pending = new Dictionary<string, LispRuntimeLoader>();
        private readonly string token = Guid.NewGuid().ToString("N");
        private readonly Document document;
        private readonly Action<string> completed;
        public LispRuntimeLoader(Document doc, Action<string> done) { document = doc; completed = done; }

        public static string RuntimePath()
        {
            string dir = Path.GetDirectoryName(typeof(LispRuntimeLoader).Assembly.Location);
            string stem = Path.Combine(dir, "BHT-" + BhtVersion.Version);
            if (File.Exists(stem + ".fas")) return stem + ".fas";
            if (File.Exists(stem + ".lsp")) return stem + ".lsp";
            throw new FileNotFoundException("Không tìm thấy lõi BHT đi kèm plugin: " + stem + ".fas");
        }

        public static string LoadExpression(string path, string requestToken)
        {
            Func<string, string> quote = s => "\"" + s.Replace("\\", "/").Replace("\"", "\\\"") + "\"";
            return "(progn (vl-load-com) ((lambda (r) (BHTRUNTIMELOADED " + quote(requestToken) +
                " (if (vl-catch-all-error-p r) (vl-catch-all-error-message r) \"\"))) " +
                "(vl-catch-all-apply 'load (list " + quote(path) + "))) (princ))\n";
        }

        public void Start()
        {
            if (document == null || document != CoreApp.DocumentManager.MdiActiveDocument)
                throw new InvalidOperationException("Bản vẽ đang mở đã đổi.");
            string path = RuntimePath();
            Pending.Add(token, this);
            try { document.SendStringToExecute(LoadExpression(path, token), false, false, false); }
            catch { Dispose(); throw; }
        }

        [LispFunction("BHTRUNTIMELOADED")]
        public static string Loaded(ResultBuffer args)
        {
            var values = args == null ? new TypedValue[0] : args.AsArray();
            if (values.Length != 2) return "INVALID";
            string id = Convert.ToString(values[0].Value), error = Convert.ToString(values[1].Value);
            LispRuntimeLoader request;
            if (!Pending.TryGetValue(id, out request)) return error;
            if (request.document != CoreApp.DocumentManager.MdiActiveDocument) return "STALE";
            request.Dispose();
            if (request.completed != null) request.completed(error);
            return error;
        }

        public void Dispose() { Pending.Remove(token); }
    }
}
