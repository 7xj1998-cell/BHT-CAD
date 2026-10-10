using System;
using System.IO;
using Autodesk.AutoCAD.Runtime;
using Autodesk.AutoCAD.ApplicationServices.Core;
using BHT.Bridge;
using BHT.Core;
[assembly: CommandClass(typeof(RuntimeBootstrapProbe))]
public class RuntimeBootstrapProbe
{
    private static LispRuntimeLoader request; private static string mode { get { return File.ReadAllText(Path.Combine(dir, "mode.txt")).Trim(); } }
    private static string dir { get { return Path.GetDirectoryName(typeof(RuntimeBootstrapProbe).Assembly.Location); } }
    private static void Report(string s) { File.AppendAllText(Path.Combine(dir,"bootstrap.txt"), s + Environment.NewLine); }
    [CommandMethod("BHTBOOTTEST")]
    public void Begin()
    {
        var initial = new LispApi().Call("bht:api-version");
        Report(!initial.Ok ? "PASS missing-before-load" : "FAIL runtime-already-loaded");
        request = new LispRuntimeLoader(Application.DocumentManager.MdiActiveDocument, error =>
        {
            if (mode == "broken")
            {
                Report(!string.IsNullOrEmpty(error) ? "PASS load-error-reported" : "FAIL missing-load-error");
                Report("DONE"); return;
            }
            Report(string.IsNullOrEmpty(error) ? "PASS load-completion" : "FAIL load: " + error);
            Application.DocumentManager.MdiActiveDocument.SendStringToExecute("BHTBOOTVERIFY\n",false,false,false);
        });
        try { request.Start(); }
        catch (System.Exception ex) { Report(mode == "missing" && ex is FileNotFoundException ? "PASS missing-file-reported" : "FAIL start: " + ex.Message); Report("DONE"); }
    }
    [CommandMethod("BHTBOOTVERIFY")]
    public void Verify()
    {
        var reply = new LispApi().Call("bht:api-version");
        if (mode == "mismatch")
        {
            Report(reply.Ok && reply.Values.Count > 1 && !BhtVersion.LispCompatible(reply.Values[0],reply.Values[1])
                ? "PASS real-version-mismatch" : "FAIL mismatch-not-detected");
            Report("DONE"); return;
        }
        Report(reply.Ok && reply.Values.Count>1 && BhtVersion.LispCompatible(reply.Values[0],reply.Values[1])
            ? "PASS api-after-queue" : "FAIL api-after-queue: " + reply.Error);
        Report("DONE");
    }
}
