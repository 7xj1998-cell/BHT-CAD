using System;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using System.Security.Cryptography;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.Runtime;
using BHT.Bridge;
using AcApp=Autodesk.AutoCAD.ApplicationServices.Core.Application;

public class LightLibraryProbe
{
    static string Hash(string path){using(var sha=SHA256.Create())using(var f=File.OpenRead(path))return BitConverter.ToString(sha.ComputeHash(f));}
    [CommandMethod("BHTLIGHTPROBE")] public void Run()
    {
        var report=new List<string>();int checks=0;
        Action<string,bool> check=(name,ok)=>{report.Add((ok ? "PASS ":"FAIL ")+name);checks++;};
        try
        {
            var db=AcApp.DocumentManager.MdiActiveDocument.Database;
            var folder=CustomDwgBlock.LightFolder();var files=Directory.GetFiles(folder,"*.dwg");
            check("seven-native-light-blocks",files.Length==7);
            foreach(var file in files)
            {
                string before=Hash(file),name=CustomDwgBlock.Import(db,file);
                check(Path.GetFileName(file)+" imported-once",name==CustomDwgBlock.Import(db,file));
                check(Path.GetFileName(file)+" source-unchanged",before==Hash(file));
                using(var tr=db.TransactionManager.StartOpenCloseTransaction())
                {
                    var table=(BlockTable)tr.GetObject(db.BlockTableId,OpenMode.ForRead);
                    var block=(BlockTableRecord)tr.GetObject(table[name],OpenMode.ForRead);
                    check(Path.GetFileName(file)+" anchor-at-survey-origin",block.Origin.IsEqualTo(Point3d.Origin));
                    check(Path.GetFileName(file)+" native-2D-no-proxy",block.Cast<ObjectId>().All(id=>tr.GetObject(id,OpenMode.ForRead) is Curve || tr.GetObject(id,OpenMode.ForRead) is Hatch));
                    if(file.EndsWith("DEN_TIN_HIEU_3_MAU.dwg",StringComparison.OrdinalIgnoreCase))
                        check("traffic-three-distinct-filled-colors",block.Cast<ObjectId>().Select(id=>tr.GetObject(id,OpenMode.ForRead)).OfType<Polyline>().Count(p=>p.Closed && p.NumberOfVertices==2 && p.ConstantWidth>0 && new int[]{1,2,3}.Contains(p.ColorIndex))==3);
                    if(file.EndsWith("DEN_CS_TRANG_TRI_MB.dwg",StringComparison.OrdinalIgnoreCase))
                        // Decorative fixture legitimately contains native solid hatches.
                        check("decorative-hatch-retained",block.Cast<ObjectId>().Any(id=>tr.GetObject(id,OpenMode.ForRead) is Hatch));
                }
            }
        }
        catch(System.Exception ex){check("exception "+ex,false);}
        File.WriteAllLines(Path.Combine(Path.GetDirectoryName(typeof(LightLibraryProbe).Assembly.Location),"light-probe.txt"),report);
    }
}
