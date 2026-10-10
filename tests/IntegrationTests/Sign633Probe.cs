using System;using System.Collections.Generic;using System.Globalization;using System.IO;using System.Linq;using System.Text;
using Autodesk.AutoCAD.DatabaseServices;using Autodesk.AutoCAD.Geometry;using Autodesk.AutoCAD.Runtime;using BHT.Bridge;using BHT.Core;
using AcApp=Autodesk.AutoCAD.ApplicationServices.Core.Application;
public class Sign633Probe
{
 static readonly List<string> report=new List<string>(),audit=new List<string>();
 static void Check(bool ok,string name){report.Add((ok ? "PASS " : "FAIL ")+name);File.AppendAllText(Path.Combine(Path.GetDirectoryName(typeof(Sign633Probe).Assembly.Location),"print-live.txt"),report.Last()+"\n");}
 static List<Entity> Fills(Transaction tr,ObjectId id,HashSet<ObjectId> seen){var result=new List<Entity>();if(!seen.Add(id))return result;foreach(ObjectId c in (BlockTableRecord)tr.GetObject(id,OpenMode.ForRead)){var e=tr.GetObject(c,OpenMode.ForRead) as Entity;if(e==null)continue;if(e is Hatch || e is Solid)result.Add(e);var b=e as BlockReference;if(b!=null)result.AddRange(Fills(tr,b.BlockTableRecord,seen));}return result;}
 static string Shape(Entity e){var h=e as Hatch;string area="unavailable";if(h!=null)try{area=Math.Round(h.Area,7).ToString(CultureInfo.InvariantCulture);}catch(Autodesk.AutoCAD.Runtime.Exception){}return e.GetType().Name+"|"+SignPrintPresentation.Role(e)+"|"+e.GeometricExtents+"|"+(h==null ? "" : h.NumberOfLoops+"|"+area);}
 [CommandMethod("BHTSIGN633PROBE")] public static void Run(){string folder=Path.GetDirectoryName(typeof(Sign633Probe).Assembly.Location);var db=AcApp.DocumentManager.MdiActiveDocument.Database;int row=0;try {
  foreach(var entry in TdtSignLibrary.GetCatalog().Where(e=>e.Provider=="BHT")) {
   try {
    File.AppendAllText(Path.Combine(folder,"print-progress.txt"),entry.Code+" import\n");
    var imported=TdtSignLibrary.EnsureBlock(db,entry.Code);Check(imported.Ok,entry.Code+" import "+imported.Error);if(!imported.Ok)continue;
    File.AppendAllText(Path.Combine(folder,"print-progress.txt"),entry.Code+" print\n");
    string print=TdtSignLibrary.EnsureOutlineBlock(db,imported.BlockName);
    File.AppendAllText(Path.Combine(folder,"print-progress.txt"),entry.Code+" check\n");
    using(var tr=db.TransactionManager.StartTransaction()) {
     var table=(BlockTable)tr.GetObject(db.BlockTableId,OpenMode.ForRead);var original=Fills(tr,table[imported.BlockName],new HashSet<ObjectId>());var output=Fills(tr,table[print],new HashSet<ObjectId>());
     int bg=original.Count(e=>SignPrintPresentation.Role(e)==SignPrintPresentation.Background),ink=original.Count-bg;
     Check(output.Count(e=>e.Visible && SignPrintPresentation.Role(e)==SignPrintPresentation.Background)==0,entry.Code+" background hidden");
     Check(original.Where(e=>e.Visible && SignPrintPresentation.Role(e)!=SignPrintPresentation.Background).Select(Shape).OrderBy(s=>s).SequenceEqual(output.Where(e=>e.Visible && SignPrintPresentation.Role(e)!=SignPrintPresentation.DerivedInk && SignPrintPresentation.Role(e)!=SignPrintPresentation.Frame && !(e is Solid && SignPrintPresentation.Role(e)==SignPrintPresentation.Paper)).Select(Shape).OrderBy(s=>s)),entry.Code+" all pictogram fills retained");
     Check(original.All(e=>e.Visible),entry.Code+" colored source unchanged");
     var rims=output.OfType<Hatch>().Where(e=>SignPrintPresentation.Role(e)==SignPrintPresentation.Frame).ToList();
     if(rims.Count>0)Check(rims.All(h=>h.Area/((h.GeometricExtents.MaxPoint.X-h.GeometricExtents.MinPoint.X)*(h.GeometricExtents.MaxPoint.Y-h.GeometricExtents.MinPoint.Y))<.45),entry.Code+" border leaves the interior clear");
     if(entry.Code=="W.207a") Check(bg==2 && ink==1 && output.Count(e=>e.Visible && SignPrintPresentation.Role(e)==SignPrintPresentation.Ink)==1 && output.Count(e=>e.Visible && SignPrintPresentation.Role(e)==SignPrintPresentation.Frame)==1,"W207 junction keeps filled branches and complete triangular border");
     if(new[]{"W.201a","W.239a","W.207a","P.127","P.115","IE.457a"}.Contains(entry.Code))Check(output.Any(e=>e is Hatch && e.Visible && SignPrintPresentation.Role(e)==SignPrintPresentation.Frame && ((Hatch)e).NumberOfLoops==2),entry.Code+" native outer/inner contours form a complete filled rim");
     if(entry.Code=="R.415a")Check(bg==1 && ink==12,"R415 keeps six vehicles and lane symbols");
     if(entry.Code=="P.102")Check(bg==0 && output.Count(e=>e.Visible && SignPrintPresentation.Role(e)==SignPrintPresentation.Void)==1,"P102 keeps disk and white horizontal opening");
     if(entry.Code=="R.415b")Check(bg==1 && ink==12 && original.Count(e=>SignPrintPresentation.Role(e)==SignPrintPresentation.Void)==0,"R415b cancellation stripe does not turn vehicles into white holes");
     if(new[]{"P.103a","I.448","P.127D-1","P.127D","R.310"}.Contains(entry.Code))Check(bg>0 && ink>0,entry.Code+" indexed and multi-loop background removed while pictogram remains");
     if(entry.Code=="I.448")Check(output.Count(e=>SignPrintPresentation.Role(e)==SignPrintPresentation.Paper)==1 && output.Count(e=>SignPrintPresentation.Role(e)==SignPrintPresentation.Void)==1,"I448 checkered panel keeps all white holes below preserved red tiles");
     if(new[]{"IE.457a","IE.461a","IE.463b","IE.474"}.Contains(entry.Code))Check(original.Where(e=>e.ColorIndex==114).All(e=>SignPrintPresentation.Role(e)==SignPrintPresentation.Background),entry.Code+" every green text/distance panel is background");
     if(new[]{"IE.464A-1","IE.464A-2"}.Contains(entry.Code))Check(original.Any(e=>e.ColorIndex==40) && original.Where(e=>e.ColorIndex==40).All(e=>SignPrintPresentation.Role(e)==SignPrintPresentation.Background),entry.Code+" yellow road-code panel does not hide black code");
     if(new[]{"I.437","I.445a","I.445f"}.Contains(entry.Code))Check(original.Any(e=>e is Hatch && ((Hatch)e).NumberOfLoops>=5 && SignPrintPresentation.Role(e)==SignPrintPresentation.Ink),entry.Code+" multi-loop white pictogram remains ink");
     if(new[]{"IE.453c","IE.452a"}.Contains(entry.Code))Check(original.Any(e=>e is Hatch && ((Hatch)e).NumberOfLoops==5 && SignPrintPresentation.Role(e)==SignPrintPresentation.Ink),entry.Code+" motorway pictogram remains filled");
     if(new[]{"IE.452b","IE.452c"}.Contains(entry.Code))Check(original.Where(e=>e is Hatch && Math.Abs(((Hatch)e).Area-.17670158837313593)<1e-8).All(e=>SignPrintPresentation.Role(e)==SignPrintPresentation.Ink),entry.Code+" both lane arrows remain foreground");
     if(new[]{"W.243a","W.243b"}.Contains(entry.Code))Check(original.Where(e=>e.ColorIndex==1).All(e=>SignPrintPresentation.Role(e)==SignPrintPresentation.Ink),entry.Code+" railway distance stripes remain filled");
     if(new[]{"P.131a","P.131b","P.131c","R.E9a","R.E9b","R.E,9A","R.E,9B","R.E10a","R.E10b","R.E,10A","R.E,10B","R.310","R.310b"}.Contains(entry.Code))Check(original.Where(e=>e.ColorIndex==142).All(e=>SignPrintPresentation.Role(e)==SignPrintPresentation.Background),entry.Code+" blue disk is removed instead of merging with slash/arrow");
     if(entry.Code=="R.310b")Check(output.Count(e=>e is Hatch && e.Visible && SignPrintPresentation.Role(e)==SignPrintPresentation.DerivedInk)==1,"R310b native arrow cutout becomes filled foreground ink");
     if(new[]{"I.442","I.443"}.Contains(entry.Code))Check(original.Where(e=>e.ColorIndex==2).All(e=>SignPrintPresentation.Role(e)==SignPrintPresentation.Ink),entry.Code+" yellow triangular pictogram remains filled");
     if(new[]{"IE.467a","IE.467b"}.Contains(entry.Code))Check(original.Count(e=>SignPrintPresentation.Role(e)==SignPrintPresentation.Paper)==1 && output.Count(e=>SignPrintPresentation.Role(e)==SignPrintPresentation.Paper && e.Visible && e.Color.Red==255)==1,entry.Code+" road backing stays white beneath filled lane arrows");
     if(entry.Code=="DP.127b")Check(original.Count(e=>SignPrintPresentation.Role(e)==SignPrintPresentation.Backing)==3 && output.Count(e=>SignPrintPresentation.Role(e)==SignPrintPresentation.Backing && e.Visible && e.Color.Red==255)==3,"DP127b three speed disks protect values from lane arrows");
     if(new[]{"P.127a","R.E9d","R.E,9D","P.127D-2"}.Contains(entry.Code))Check(output.Any(e=>SignPrintPresentation.Role(e)==SignPrintPresentation.Void && e.Visible && e.Color.Red==255),entry.Code+" speed values retain white inner backing");
     if(entry.Code=="I.418")Check(output.Count(e=>SignPrintPresentation.Role(e)==SignPrintPresentation.Ink)==1 && output.Count(e=>SignPrintPresentation.Role(e)==SignPrintPresentation.Void)==1,"I418 route arrow contrasts against filled road path");
     audit.Add(entry.Code+"\t"+bg+"\t"+ink+"\t"+original.Count(e=>SignPrintPresentation.Role(e)==SignPrintPresentation.Void));
     var model=(BlockTableRecord)tr.GetObject(table[BlockTableRecord.ModelSpace],OpenMode.ForWrite);
     for(int i=0;i<2;i++){var br=new BlockReference(new Point3d(i*12,-row*4,0),table[i==0 ? imported.BlockName : print]);model.AppendEntity(br);tr.AddNewlyCreatedDBObject(br,true);}
     var text=new DBText{TextString=entry.Code,Height=.25,Position=new Point3d(-2,-row*4-.6,0)};model.AppendEntity(text);tr.AddNewlyCreatedDBObject(text,true);
     tr.Commit();row++;
    }
   }catch(System.Exception ex){Check(false,entry.Code+" "+ex);}
  }
  db.SaveAs(Path.Combine(folder,"print-gallery-0.6.33.dwg"),DwgVersion.AC1032);db.DxfOut(Path.Combine(folder,"print-gallery-0.6.33.dxf"),16,DwgVersion.AC1032);
 } catch(System.Exception ex){Check(false,"exception "+ex);}
 File.WriteAllLines(Path.Combine(folder,"print-audit.tsv"),audit,Encoding.UTF8);File.WriteAllLines(Path.Combine(folder,"print-probe.txt"),report,Encoding.UTF8);
 AcApp.DocumentManager.MdiActiveDocument.Editor.WriteMessage("\nPRINT633-COMPLETE "+report.Count(r=>r.StartsWith("PASS"))+" PASS / "+report.Count(r=>r.StartsWith("FAIL"))+" FAIL");
 }
}
