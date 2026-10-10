using System;using System.IO;using System.Linq;using System.Collections.Generic;using Autodesk.AutoCAD.Runtime;using Autodesk.AutoCAD.DatabaseServices;using Autodesk.AutoCAD.Geometry;using Autodesk.AutoCAD.Colors;
public class LightBuild {
 static void Disk(BlockTableRecord model,Transaction tr,double y,short color){var p=new Polyline(2);p.AddVertexAt(0,new Point2d(-.12,y),1,0,0);p.AddVertexAt(1,new Point2d(.12,y),1,0,0);p.Closed=true;p.ConstantWidth=.24;p.ColorIndex=color;model.AppendEntity(p);tr.AddNewlyCreatedDBObject(p,true);}
 static void Line(BlockTableRecord model,Transaction tr,Point3d a,Point3d b){var e=new Line(a,b);e.ColorIndex=0;model.AppendEntity(e);tr.AddNewlyCreatedDBObject(e,true);}
 [CommandMethod("BHTLIGHTBUILD")]public void Run(){
 string dest=Environment.GetEnvironmentVariable("BHT_LIGHT_BUILD_DEST");if(string.IsNullOrEmpty(dest))throw new InvalidOperationException("Set BHT_LIGHT_BUILD_DEST");Directory.CreateDirectory(dest);
 string source=@"C:\Program Files\BZS\ADSCivil NW 2026 For Autocad";
 string[] files={@"3D_RESOURCE\Block 2D\Den chieu sang\Cot den don.dwg",@"3D_RESOURCE\Block 2D\Den chieu sang\Cot den doi.dwg",@"3D_RESOURCE\Block 2D\Den chieu sang\Cot den trang tri.dwg",@"FCode\005.Cot den trai.dwg",@"FCode\006.Cot den phai.dwg"};
 string[] names={"DEN_CS_DON_MB","DEN_CS_DOI_MB","DEN_CS_TRANG_TRI_MB","DEN_CS_TRAI_MD","DEN_CS_PHAI_MD"};
 var report=new List<string>();
 for(int i=0;i<files.Length;i++)using(var db=new Database(false,true)){
 db.ReadDwgFile(Path.Combine(source,files[i]),FileOpenMode.OpenForReadAndAllShare,true,"");db.CloseInput(true);
 using(var tr=db.TransactionManager.StartTransaction()){var model=(BlockTableRecord)tr.GetObject(SymbolUtilityServices.GetBlockModelSpaceId(db),OpenMode.ForRead);foreach(ObjectId id in model){var e=(Entity)tr.GetObject(id,OpenMode.ForWrite);e.Layer="0";e.ColorIndex=0;if(i>=3)e.TransformBy(Matrix3d.Scaling(.12,Point3d.Origin));}tr.Commit();}
 db.Insbase=Point3d.Origin;db.Insunits=UnitsValue.Undefined;db.SaveAs(Path.Combine(dest,names[i]+".dwg"),DwgVersion.AC1027);report.Add(names[i]+" | "+files[i]+" | scale="+(i>=3 ? "0.12":"1"));}
 foreach(bool flash in new[]{false,true})using(var db=new Database(true,true)){
 using(var tr=db.TransactionManager.StartTransaction()){var model=(BlockTableRecord)tr.GetObject(SymbolUtilityServices.GetBlockModelSpaceId(db),OpenMode.ForWrite);Line(model,tr,new Point3d(0,0,0),new Point3d(0,1.4,0));var box=new Polyline(4);double top=flash ? 2.1:3.3;box.AddVertexAt(0,new Point2d(-.4,1.4),0,0,0);box.AddVertexAt(1,new Point2d(.4,1.4),0,0,0);box.AddVertexAt(2,new Point2d(.4,top),0,0,0);box.AddVertexAt(3,new Point2d(-.4,top),0,0,0);box.Closed=true;box.ColorIndex=0;model.AppendEntity(box);tr.AddNewlyCreatedDBObject(box,true);
 if(flash)Disk(model,tr,1.75,2);else{Disk(model,tr,2.95,1);Disk(model,tr,2.35,2);Disk(model,tr,1.75,3);}tr.Commit();}
 db.Insbase=Point3d.Origin;db.Insunits=UnitsValue.Undefined;string name=flash ? "DEN_CANH_BAO_VANG":"DEN_TIN_HIEU_3_MAU";db.SaveAs(Path.Combine(dest,name+".dwg"),DwgVersion.AC1027);report.Add(name+" | BHT native 2D | display symbol, no electrical design");}
 File.WriteAllLines(Path.Combine(dest,"SOURCES.txt"),report);}
}
