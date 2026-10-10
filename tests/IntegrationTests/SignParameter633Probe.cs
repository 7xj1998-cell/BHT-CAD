using System;using System.Collections.Generic;using System.IO;using System.Linq;using System.Text;
using Autodesk.AutoCAD.DatabaseServices;using Autodesk.AutoCAD.Runtime;using BHT.Bridge;using BHT.Core;
using AcApp=Autodesk.AutoCAD.ApplicationServices.Core.Application;
public class SignParameter633Probe
{
 static readonly List<string> report=new List<string>(),audit=new List<string>();
 static void Check(bool ok,string name){report.Add((ok ? "PASS " : "FAIL ")+name);}
 static List<string> Texts(Transaction tr,ObjectId id,HashSet<ObjectId> path){var list=new List<string>();if(!path.Add(id))return list;foreach(ObjectId c in (BlockTableRecord)tr.GetObject(id,OpenMode.ForRead)){var e=tr.GetObject(c,OpenMode.ForRead) as Entity;var t=e as DBText;var m=e as MText;if(t!=null)list.Add(t.TextString);if(m!=null)list.Add(m.Text);var r=e as BlockReference;if(r!=null){foreach(ObjectId a in r.AttributeCollection)list.Add(((AttributeReference)tr.GetObject(a,OpenMode.ForRead)).TextString);list.AddRange(Texts(tr,r.BlockTableRecord,path));}}path.Remove(id);return list;}
 [CommandMethod("BHTPARAM633PROBE")] public static void Run(){string folder=Path.GetDirectoryName(typeof(SignParameter633Probe).Assembly.Location);var db=AcApp.DocumentManager.MdiActiveDocument.Database;
 foreach(var entry in TdtSignLibrary.GetCatalog().Where(e=>e.Provider=="BHT"))try{
  var fields=SignContentBlocks.Fields(entry.Code);Check(fields.Select(f=>f.Key).Distinct().Count()==fields.Count,entry.Code+" unique field keys");
  foreach(var f in fields)audit.Add(entry.Code+"\t"+f.Key+"\t"+f.Parameter.Kind+"\t"+f.Parameter.Unit+"\t"+f.Sample);
  if(fields.Count==0)continue;
  var imported=TdtSignLibrary.EnsureBlock(db,entry.Code);Check(imported.Ok,entry.Code+" import");if(!imported.Ok)continue;
  var face=new SignContentFace{Index=0,Code=entry.Code};foreach(var f in fields)face.Values[f.Key]=f.Parameter.Normalize(f.Parameter.Kind=="number" ? f.Parameter.Integer ? f.Parameter.Maximum==9 ? "8" : "75" : "17,25" : f.Parameter.Kind=="time" ? "23:15-05:45" : "NỘI DUNG HỒ SƠ 0633");
  string xml=SignContent.Write(new[]{face}),edited=SignContentBlocks.Ensure(db,imported.BlockName,entry.Code,0,xml);
  using(var tr=db.TransactionManager.StartOpenCloseTransaction()) {var table=(BlockTable)tr.GetObject(db.BlockTableId,OpenMode.ForRead);var values=Texts(tr,table[edited],new HashSet<ObjectId>());Check(face.Values.Values.All(v=>values.Contains(v)),entry.Code+" all actual values applied");Check(!Texts(tr,table[imported.BlockName],new HashSet<ObjectId>()).Contains("NỘI DUNG HỒ SƠ 0633"),entry.Code+" template unchanged");}
  Check(SignContent.ForFace(xml,0,entry.Code).Count==fields.Count,entry.Code+" persisted field count");
 }catch(System.Exception e){Check(false,entry.Code+" "+e);}
 foreach(string code in new[]{"I.441a","I.441b","I.441c","IE.450a","IE.451a","IE.453a","IE.454","IE.456a1","IE.456a2","IE.457a","IE.459a","IE.461a","IE.462","IE.463a","IE.467b","IE.475A","IE.475B","IE.475C","IE.475D"})Check(SignContentBlocks.Fields(code).Any(f=>f.Key.StartsWith("TEXT#") || f.Key.StartsWith("MTEXT#")),code+" native numeric CAD text editable");
 foreach(string code in new[]{"P.127a","R.307","R.E9d","R.E,9B","S.508a","S.508b","P.106b","P.115","P.116","P.121","W.219","W.220","S.H,3B"})Check(SignContentBlocks.Fields(code).Count>0,code+" numeric or time attributes editable");
 var zero=SignParameter.Describe("IE.475A","TEXT","0 M");Check(zero.Normalize("0")=="0 M","zero distance retains unit");
 var overnight=SignParameter.Describe("P.127a","TIME","22:00");Check(overnight.Normalize("22:00-5:00")=="22:00-05:00","overnight hours allowed");
 foreach(string bad in new[]{"24:00","12:60","abc"})try{overnight.Normalize(bad);Check(false,"reject invalid hour "+bad);}catch(ArgumentException){Check(true,"reject invalid hour "+bad);}
 foreach(string bad in new[]{"-1","NaN","Infinity","2 km"})try{zero.Normalize(bad);Check(false,"reject invalid number/unit "+bad);}catch(ArgumentException){Check(true,"reject invalid number/unit "+bad);}
 foreach(string code in new[]{"S.509a","S.509a@5","S.509a@4.75"}) {
  var fields=SignContentBlocks.Fields(code);
  var first=fields.Single(f=>f.Tag.Equals("DESC_1",StringComparison.OrdinalIgnoreCase));
  var second=fields.Single(f=>f.Tag.Equals("DESC_2",StringComparison.OrdinalIgnoreCase));
  var distance=fields.Single(f=>f.Tag.Equals("DESC_3",StringComparison.OrdinalIgnoreCase));
  Check(first.Sample=="CHIỀU CAO" && second.Sample=="AN TOÀN",code+" reference captions");
  Check(SignContentBlocks.ResolveContentValue(code,first.Tag,"")=="CHIỀU CAO",code+" editor restores legacy blank");
  var imported=TdtSignLibrary.EnsureBlock(db,code);
  var face=new SignContentFace{Index=1,Code=code};
  face.Values[first.Key]="";face.Values[second.Key]=" ";face.Values[distance.Key]="4.75 m";
  string edited=SignContentBlocks.Ensure(db,imported.BlockName,code,1,SignContent.Write(new[]{face}));
  Check(edited.StartsWith("BHT_SIGN_CONTENT_V0643_"),code+" bypass stale content cache");
  foreach(string block in new[]{edited,TdtSignLibrary.EnsureOutlineBlock(db,edited)}) {
   using(var tr=db.TransactionManager.StartOpenCloseTransaction()) {
    var bt=(BlockTable)tr.GetObject(db.BlockTableId,OpenMode.ForRead);
    var text=Texts(tr,bt[block],new HashSet<ObjectId>());
    Check(text.Contains("CHIỀU CAO") && text.Contains("AN TOÀN") && text.Contains("4.75 m"),code+" restores captions and retains actual distance "+block);
   }
  }
  face.Values[first.Key]="CHIỀU CAO THỰC TẾ";face.Values[second.Key]="AN TOÀN RIÊNG";
  edited=SignContentBlocks.Ensure(db,imported.BlockName,code,1,SignContent.Write(new[]{face}));
  using(var tr=db.TransactionManager.StartOpenCloseTransaction()){
   var bt=(BlockTable)tr.GetObject(db.BlockTableId,OpenMode.ForRead);
   var text=Texts(tr,bt[edited],new HashSet<ObjectId>());
   Check(text.Contains("CHIỀU CAO THỰC TẾ") && text.Contains("AN TOÀN RIÊNG"),code+" retains custom nonempty captions");
  }
 }
 Check(SignContentBlocks.ResolveContentValue("I.449","NAME","")=="" && SignContentBlocks.ResolveContentValue("S.509b","DESC_1","")=="","other blank fields unchanged");
 File.WriteAllLines(Path.Combine(folder,"parameter-audit.tsv"),audit,Encoding.UTF8);File.WriteAllLines(Path.Combine(folder,"parameter-probe.txt"),report,Encoding.UTF8);
 AcApp.DocumentManager.MdiActiveDocument.Editor.WriteMessage("\nPARAM633-COMPLETE "+report.Count(r=>r.StartsWith("PASS"))+" PASS / "+report.Count(r=>r.StartsWith("FAIL"))+" FAIL");
 }
}
