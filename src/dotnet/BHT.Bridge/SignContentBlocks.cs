using System;
using System.Collections.Generic;
using System.Linq;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Runtime;
using BHT.Core;
using AcApp = Autodesk.AutoCAD.ApplicationServices.Core.Application;
namespace BHT.Bridge
{
    public sealed class SignContentField
    {
        public string Key, Tag, Sample;
        public SignParameter Parameter;
        public string Label { get { return Tag.StartsWith("MTEXT ") || Tag.StartsWith("TEXT ") ? Parameter.Label+" / "+Tag.Split(' ').Last() : Parameter.Label+" — "+Tag; } }
    }
    public static class SignContentBlocks
    {
        // Older content dialogs saved these required captions as empty native defaults.
        // Keep custom captions and all measured values intact.
        public static string ResolveContentValue(string code,string tag,string value)
        {
            if(SignPresentation.BaseCode(code).Equals("S.509a",StringComparison.OrdinalIgnoreCase)
                && string.IsNullOrWhiteSpace(value)
                && (string.Equals(tag,"DESC_1",StringComparison.OrdinalIgnoreCase) || string.Equals(tag,"DESC_2",StringComparison.OrdinalIgnoreCase)))
                return TdtSignLibrary.AttributeValue(code,value,tag,true);
            return value;
        }
        private static bool Editable(string code, AttributeDefinition d)
        {
            string tag=d.Tag.Trim('[',']').ToUpperInvariant();
            if (d.Invisible || tag=="CODE") return false;
            if (code.Equals("I.439",StringComparison.OrdinalIgnoreCase) || (tag=="V" && SignPresentation.SpeedBase(code)!="")) return false;
            if (SignPresentation.HasZoneTime(code) && tag=="TIME") return false;
            if (SignPresentation.HasWeight(code) && tag=="W") return false;
            if (SignPresentation.MetreDefault(code)!="" && new[] { "H", "H,", "WI", "WI,", "L", "DISTANCE", "KHOANG_CACH", "DESC3" }.Contains(tag)) return false;
            return true;
        }
        private static bool EditableText(string code,string text)
        {
            if(!SignParameter.IsQuantity(text))return false;
            // The existing per-sign control owns this value; avoid a second override.
            return SignPresentation.MetreDefault(code)=="" && SignPresentation.SpeedBase(code)=="";
        }
        // One logical field per definition; reference values and duplicate tags stay paired.
        private static void Visit(Transaction tr,ObjectId id,BlockReference instance,string code,Dictionary<string,int> counts,HashSet<ObjectId> path,Action<string,string,string,Entity,AttributeReference> action)
        {
            if (!path.Add(id)) throw new InvalidOperationException("Block biển có tham chiếu vòng.");
            var b=(BlockTableRecord)tr.GetObject(id,OpenMode.ForRead);
            var references=new List<AttributeReference>();
            if(instance!=null) foreach(ObjectId a in instance.AttributeCollection) references.Add((AttributeReference)tr.GetObject(a,OpenMode.ForRead));
            var order=(DrawOrderTable)tr.GetObject(b.DrawOrderTableId,OpenMode.ForRead);
            foreach(ObjectId e in order.GetFullDrawOrder(0))
            {
                var d=tr.GetObject(e,OpenMode.ForRead) as AttributeDefinition;
                if(d!=null && Editable(code,d))
                {
                    int n; counts.TryGetValue(d.Tag,out n); counts[d.Tag]=n+1;
                    var a=references.Where(attr=>attr.Tag==d.Tag).OrderBy(attr=>attr.Position.DistanceTo(d.Position.TransformBy(instance.BlockTransform))).FirstOrDefault(); if(a!=null) references.Remove(a);
                    string attributeSample=a==null ? d.TextString : a.TextString;
                    // Keep the 0.6.32 DESC_3 key so existing saved face content stays editable.
                    if(SignPresentation.BaseCode(code).Equals("S.509a",StringComparison.OrdinalIgnoreCase)) attributeSample=TdtSignLibrary.AttributeValue(code,attributeSample,d.Tag,true);
                    if(SignPresentation.HasZoneTime(code) && SignPresentation.ZoneTime(code)!="" && d.Tag.Equals("THOI_GIAN",StringComparison.OrdinalIgnoreCase) && n<2)attributeSample=SignPresentation.ZoneTime(code).Split('-')[n];
                    action(d.Tag+"#"+n,d.Tag,attributeSample,d,a);
                }
                var entity=tr.GetObject(e,OpenMode.ForRead) as Entity;
                var text=entity as DBText;var mtext=entity as MText;
                string sample=mtext!=null ? mtext.Text : text!=null && d==null ? text.TextString : "";
                if(entity!=null && entity.Visible && EditableText(code,sample)) {
                    string type=mtext!=null ? "MTEXT" : "TEXT";int n;counts.TryGetValue(type,out n);counts[type]=n+1;
                    action(type+"#"+n,type+" "+(n+1),sample,entity,null);
                }
                var r=tr.GetObject(e,OpenMode.ForRead) as BlockReference;
                if(r!=null) Visit(tr,r.BlockTableRecord,r,code,counts,path,action);
            }
            path.Remove(id);
        }
        public static List<SignContentField> Fields(string code)
        {
            var result=new List<SignContentField>(); var entry=BhtSignLibrary.Find(code);
            if(entry==null) return result;
            using(var db=new Database(false,true))
            {
                db.ReadDwgFile(entry.SourceDrawing,FileOpenMode.OpenForReadAndAllShare,false,""); db.CloseInput(true);
                using(var tr=db.TransactionManager.StartOpenCloseTransaction())
                {
                    var table=(BlockTable)tr.GetObject(db.BlockTableId,OpenMode.ForRead);
                    Visit(tr,table[BlockTableRecord.ModelSpace],null,code,new Dictionary<string,int>(),new HashSet<ObjectId>(),(key,tag,sample,e,a)=>result.Add(new SignContentField { Key=key,Tag=tag,Sample=sample,Parameter=SignParameter.Describe(code,tag,sample) }));
                }
            }
            return result;
        }
        public static string Ensure(Database db,string source,string code,int index,string content)
        {
            var values=SignContent.ForFace(content,index,code); if(values.Count==0) return source;
            if(SignPresentation.BaseCode(code).Equals("I.449",StringComparison.OrdinalIgnoreCase) && values.ContainsKey("NAME#0")) return SignCorrections.StreetName(db,source,values["NAME#0"]);
            string name=(SignPresentation.BaseCode(code).Equals("S.509a",StringComparison.OrdinalIgnoreCase) ? "BHT_SIGN_CONTENT_V0643_" : "BHT_SIGN_CONTENT_V0633_")+SignLayout.Hash(source+"|"+SignContent.Write(new[] { new SignContentFaceCopy(index,code,values).Face }));
            ObjectId sourceId;
            using(var tr=db.TransactionManager.StartOpenCloseTransaction())
            { var table=(BlockTable)tr.GetObject(db.BlockTableId,OpenMode.ForRead); if(table.Has(name)) return name; sourceId=table[source]; }
            var working=HostApplicationServices.WorkingDatabase;
            try
            {
                using(var scratch=new Database(true,true))
                {
                    var map=new IdMapping(); db.WblockCloneObjects(new ObjectIdCollection(new[] { sourceId }),scratch.BlockTableId,map,DuplicateRecordCloning.MangleName,false);
                    ObjectId clone=map[sourceId].Value; HostApplicationServices.WorkingDatabase=scratch;
                    using(var native=db.TransactionManager.StartOpenCloseTransaction())
                    using(var tr=scratch.TransactionManager.StartTransaction())
                    {
                        BhtSignLibrary.RestoreDrawOrder(native,tr,sourceId,clone,map,new HashSet<ObjectId>());
                        ((BlockTableRecord)tr.GetObject(clone,OpenMode.ForWrite)).Name=name;
                        var used=new HashSet<string>();
                        Visit(tr,clone,null,code,new Dictionary<string,int>(),new HashSet<ObjectId>(),(key,tag,sample,e,a)=> {
                            string value; if(!values.TryGetValue(key,out value)) return; used.Add(key);
                            value=SignParameter.Describe(code,tag,sample).Normalize(ResolveContentValue(code,tag,value));
                            var text=e as DBText;if(text!=null)SetText(text,value,scratch);else SetMText((MText)e,value);
                            if(a!=null) SetText(a,value,scratch);
                        });
                        if(values.Keys.Any(k=>!used.Contains(k))) throw new ArgumentException("Nội dung không khớp các trường của mặt biển "+code+".");
                        tr.Commit();
                    }
                    map=new IdMapping(); scratch.WblockCloneObjects(new ObjectIdCollection(new[] { clone }),db.BlockTableId,map,DuplicateRecordCloning.MangleName,false);
                    using(var native=scratch.TransactionManager.StartOpenCloseTransaction())
                    using(var tr=db.TransactionManager.StartTransaction())
                    { BhtSignLibrary.RestoreDrawOrder(native,tr,clone,map[clone].Value,map,new HashSet<ObjectId>()); ((BlockTableRecord)tr.GetObject(map[clone].Value,OpenMode.ForWrite)).Name=name; tr.Commit(); }
                }
            }
            finally { HostApplicationServices.WorkingDatabase=working; }
            return name;
        }
        private static void SetText(DBText text,string value,Database db)
        {
            double width=0; try { var b=text.GeometricExtents; width=b.MaxPoint.X-b.MinPoint.X; } catch(Autodesk.AutoCAD.Runtime.Exception) { }
            text.UpgradeOpen(); text.TextString=value; text.AdjustAlignment(db);
            if(width>1e-8 && value!="") try {
                var b=text.GeometricExtents; double next=b.MaxPoint.X-b.MinPoint.X;
                if(next>width) { text.WidthFactor=Math.Max(.01,text.WidthFactor*width/next); text.AdjustAlignment(db); }
            } catch(Autodesk.AutoCAD.Runtime.Exception) { }
        }
        private static void SetMText(MText text,string value)
        {
            double width=text.ActualWidth; text.UpgradeOpen();
            // Preserve inline font/height formatting from the native face.
            string old=text.Text;int start=text.Contents.IndexOf(old,StringComparison.Ordinal);
            text.Contents=start<0 ? value : text.Contents.Substring(0,start)+value+text.Contents.Substring(start+old.Length);
            if(width>1e-8 && text.ActualWidth>width)text.TextHeight*=width/text.ActualWidth;
        }
        private sealed class SignContentFaceCopy
        {
            public SignContentFace Face;
            public SignContentFaceCopy(int index,string code,Dictionary<string,string> values) { Face=new SignContentFace { Index=index,Code=code }; foreach(var p in values) Face.Values.Add(p.Key,p.Value); }
        }
    }
    public sealed class SignContentFunctions
    {
        [LispFunction("BHTSIGNCONTENT")]
        public static string Build(ResultBuffer args)
        {
            if(args==null || args.AsArray().Length!=4) throw new ArgumentException("Cần block, mã, chỉ số mặt và nội dung biển.");
            var v=args.AsArray(); return SignContentBlocks.Ensure(AcApp.DocumentManager.MdiActiveDocument.Database,Convert.ToString(v[0].Value),Convert.ToString(v[1].Value),Convert.ToInt32(v[2].Value),Convert.ToString(v[3].Value));
        }
    }
}
