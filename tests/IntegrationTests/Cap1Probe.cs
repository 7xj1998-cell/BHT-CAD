using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.Runtime;
using BHT.Bridge;
using BHT.Core;
using AcApp=Autodesk.AutoCAD.ApplicationServices.Core.Application;
public class Cap1Probe
{
    static List<string> report=new List<string>();
    static void Check(bool value,string name) { report.Add((value ? "PASS " : "FAIL ")+name); }
    static List<string> Texts(Database db,string name)
    {
        var result=new List<string>(); using(var tr=db.TransactionManager.StartOpenCloseTransaction()) {
            var table=(BlockTable)tr.GetObject(db.BlockTableId,OpenMode.ForRead); Collect(tr,table[name],new HashSet<ObjectId>(),result); }
        return result;
    }
    static void Collect(Transaction tr,ObjectId id,HashSet<ObjectId> seen,List<string> result)
    {
        if(!seen.Add(id)) return;
        foreach(ObjectId e in (BlockTableRecord)tr.GetObject(id,OpenMode.ForRead)) {
            var text=tr.GetObject(e,OpenMode.ForRead) as DBText; if(text!=null) result.Add(text.TextString);
            var b=tr.GetObject(e,OpenMode.ForRead) as BlockReference; if(b!=null) { foreach(ObjectId a in b.AttributeCollection) result.Add(((AttributeReference)tr.GetObject(a,OpenMode.ForRead)).TextString); Collect(tr,b.BlockTableRecord,seen,result); }
        }
    }
    [CommandMethod("BHTCAP1PROBE")]
    public static void Run()
    {
        string folder=Path.GetDirectoryName(typeof(Cap1Probe).Assembly.Location); var db=AcApp.DocumentManager.MdiActiveDocument.Database;
        try {
            var face=TdtSignLibrary.EnsureBlock(db,"R.415a"); var wide=TdtSignLibrary.EnsureBlock(db,"IE.456A-1");
            Check(face.Ok && wide.Ok,"native faces available");
            var fields=SignContentBlocks.Fields("IE.456A-1"); Check(fields.Count>=2,"highway place fields discovered");
            var content=new List<SignContentFace>();
            for(int i=0;i<2;i++) { var c=new SignContentFace {Index=i,Code="IE.456A-1"}; foreach(var f in fields) c.Values[f.Key]=f.Parameter.Kind=="number" ? f.Sample : i==0 ? "THÀNH PHỐ HỒ CHÍ MINH" : "ĐÀ NẴNG"; content.Add(c); }
            string xml=SignContent.Write(content);
            string first=SignContentBlocks.Ensure(db,wide.BlockName,"IE.456A-1",0,xml),second=SignContentBlocks.Ensure(db,wide.BlockName,"IE.456A-1",1,xml);
            Check(first!=second && first!=wide.BlockName,"independent content cache");
            Check(Texts(db,first).Contains("THÀNH PHỐ HỒ CHÍ MINH") && !Texts(db,first).Contains("ĐÀ NẴNG"),"first repeated code retains its own content");
            Check(Texts(db,second).Contains("ĐÀ NẴNG") && !Texts(db,second).Contains("THÀNH PHỐ HỒ CHÍ MINH"),"second repeated code retains its own content");
            Check(!Texts(db,wide.BlockName).Contains("ĐÀ NẴNG"),"catalog template unchanged");
            Check(SignContentBlocks.Ensure(db,wide.BlockName,"IE.456A-1",0,xml)==first,"content cache deterministic");
            var duplicates=SignContentBlocks.Fields("P.127D-1"); Check(duplicates.Select(f=>f.Key).Distinct().Count()==duplicates.Count && duplicates.Count>=3,"duplicate native tags retained");
            var speed=TdtSignLibrary.EnsureBlock(db,"P.127D-1"); var sf=new SignContentFace {Index=0,Code="P.127D-1"};
            for(int i=0;i<duplicates.Count;i++) sf.Values[duplicates[i].Key]=(90-i*10).ToString();
            string speeds=SignContentBlocks.Ensure(db,speed.BlockName,sf.Code,0,SignContent.Write(new[] {sf}));
            Check(Texts(db,speeds).Contains("90") && Texts(db,speeds).Contains("70"),"lane speeds editable separately");
            using(var tr=db.TransactionManager.StartOpenCloseTransaction()) {
                var table=(BlockTable)tr.GetObject(db.BlockTableId,OpenMode.ForRead);
                using(var old=new BlockReference(Point3d.Origin,table[wide.BlockName])) using(var changed=new BlockReference(Point3d.Origin,table[first])) {
                    var a=old.GeometricExtents; var b=changed.GeometricExtents; Check(b.MaxPoint.X-b.MinPoint.X <= (a.MaxPoint.X-a.MinPoint.X)*1.02,"long place names remain within native width");
                }
            }
            int row=0;
            foreach(var spec in SignLayoutSpec.All.Where(s=>s.Code!="LEGACY")) {
                int count=spec.Faces>0 ? spec.Faces : 2;
                string[] names=Enumerable.Range(0,count).Select(i=>spec.Code=="CAP1_9" || spec.Code=="CAP1_10" ? (i==0 ? first : second) : face.BlockName).ToArray();
                string name=SignLayout.Ensure(db,names,spec.Code,.2,.6);
                Check(name==SignLayout.Ensure(db,names,spec.Code,.2,.6),spec.Code+" cache");
                using(var tr=db.TransactionManager.StartTransaction()) {
                    var table=(BlockTable)tr.GetObject(db.BlockTableId,OpenMode.ForRead); var b=(BlockTableRecord)tr.GetObject(table[name],OpenMode.ForRead);
                    var entities=b.Cast<ObjectId>().Select(e=>tr.GetObject(e,OpenMode.ForRead) as Entity).ToList();
                    var plates=entities.OfType<BlockReference>().ToList(); var feet=entities.OfType<Circle>().Where(c=>Math.Abs(c.Center.Y)<1e-6 && c.Radius<=.1).ToList();
                    Check(plates.Count==count && feet.Count==spec.Posts,spec.Code+" face and foot counts");
                    Check(plates.All(p=>p.GeometricExtents.MinPoint.Y>=.6-1e-6),spec.Code+" clearance");
                    bool disjoint=true; for(int i=0;i<plates.Count;i++) for(int j=i+1;j<plates.Count;j++) {var a=plates[i].GeometricExtents;var c=plates[j].GeometricExtents; if(!(a.MaxPoint.X<=c.MinPoint.X || c.MaxPoint.X<=a.MinPoint.X || a.MaxPoint.Y<=c.MinPoint.Y || c.MaxPoint.Y<=a.MinPoint.Y)) disjoint=false;}
                    Check(disjoint,spec.Code+" no overlapping extents");
                    var model=(BlockTableRecord)tr.GetObject(table[BlockTableRecord.ModelSpace],OpenMode.ForWrite);
                    var insert=new BlockReference(new Point3d((row%5)*12,-(row/5)*12,0),table[name]);model.AppendEntity(insert);tr.AddNewlyCreatedDBObject(insert,true);
                    var label=new DBText {TextString=spec.Code,Height=.18,Position=new Point3d((row%5)*12-.5,-(row/5)*12-.4,0)};model.AppendEntity(label);tr.AddNewlyCreatedDBObject(label,true);
                    tr.Commit();row++;
                }
                string outline=TdtSignLibrary.EnsureOutlineBlock(db,name); Check(outline!=name && Texts(db,outline).SequenceEqual(Texts(db,name)),spec.Code+" outline retains text");
            }
            using(var tr=db.TransactionManager.StartTransaction()) {
                BhtStore.Write(tr,db,"OBJ","CAP1-QA",new BhtRecord().Add(ObjFields.Group,"BIEN_BAO").Add(ObjFields.Code,"IE.456A-1").Add(ObjFields.Face,"IE.456A-1").Add(ObjFields.Face,"IE.456A-1").Add(ObjFields.FaceCount,"2").Add(ObjFields.PoleCount,"2").Add(ObjFields.SignLayout,"CAP1_9").Add(ObjFields.SignContent,xml).Add(ObjFields.SignGap,"0.2").Add(ObjFields.SignClearance,"0.6")); tr.Commit();
            }
            db.SaveAs(Path.Combine(folder,"CAP1-0.6.32.dwg"),DwgVersion.AC1032);
            db.DxfOut(Path.Combine(folder,"CAP1-0.6.32.dxf"),16,DwgVersion.AC1032);
        } catch(System.Exception e) {report.Add("FAIL exception "+e);}
        File.WriteAllLines(Path.Combine(folder,"cap1-probe.txt"),report,Encoding.UTF8);
        foreach(string line in report) AcApp.DocumentManager.MdiActiveDocument.Editor.WriteMessage("\n"+line);
    }
}
