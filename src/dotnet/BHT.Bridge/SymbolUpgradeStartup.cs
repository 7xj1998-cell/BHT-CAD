using System;
using System.Collections.Generic;
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Runtime;
using BHT.Core;
using AcApp=Autodesk.AutoCAD.ApplicationServices.Core.Application;

namespace BHT.Bridge
{
    public sealed class SymbolUpgradeStartup : IExtensionApplication
    {
        // Loading or activating a drawing must never regenerate its symbols.
        // In particular, do not invoke Lisp/graphics updates from Application.Idle.
        public void Initialize() { }
        public void Terminate() { }
        [LispFunction("BHTSYMBOLUPGRADESCHEDULE")]
        public static int Ready(ResultBuffer args) { return 0; }
        public static bool NeedsUpgrade(Database database)
        {
            using(var tr=database.TransactionManager.StartOpenCloseTransaction())
            {
                if(BhtStore.RootDict(tr,database,false)==null || BhtStore.Keys(tr,database,"OBJ").Count==0) return false;
                Version old;return !Version.TryParse(BhtStore.Meta(tr,database,"symbol_build",""),out old) || old<new Version(BhtVersion.Version);
            }
        }
        public static LispReply RunNow(Document document)
        {
            if(document==null || document!=AcApp.DocumentManager.MdiActiveDocument) return new LispReply {Error="Bản vẽ đang mở đã đổi."};
            var api=new LispApi();var version=api.Call("bht:api-version");
            if(!version.Ok || version.Values.Count<2 || !BhtVersion.LispCompatible(version.Values[0],version.Values[1])) return new LispReply {Error="Chưa nạp đúng phiên bản lõi Lisp BHT."};
            using(document.LockDocument()) return api.Call("bht:api-symbol-upgrade");
        }
    }
}
