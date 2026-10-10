using System;
using System.IO;
using System.Security.Cryptography;
using Autodesk.AutoCAD.DatabaseServices;

namespace BHT.Bridge
{
    public static class CustomDwgBlock
    {
        public static string LightFolder()
        {
            for(var dir=new DirectoryInfo(Path.GetDirectoryName(typeof(CustomDwgBlock).Assembly.Location));dir!=null;dir=dir.Parent)
                foreach(string path in new[] {Path.Combine(dir.FullName,"LightLibrary"),Path.Combine(dir.FullName,"assets","light-blocks")})
                    if(Directory.Exists(path)) return path;
            return "";
        }
        // Import the model at INSBASE. Content-based names keep existing definitions intact.
        public static string Import(Database target,string path)
        {
            string hash;
            using(var sha=SHA256.Create()) using(var file=File.OpenRead(path))
                hash=BitConverter.ToString(sha.ComputeHash(file)).Replace("-","").Substring(0,12);
            string code=Path.GetFileNameWithoutExtension(path).ToUpperInvariant();
            string[] lights={"DEN_CS_DON_MB","DEN_CS_DOI_MB","DEN_CS_TRANG_TRI_MB","DEN_CS_TRAI_MD","DEN_CS_PHAI_MD","DEN_TIN_HIEU_3_MAU","DEN_CANH_BAO_VANG"};
            string name=Array.IndexOf(lights,code)>=0 ? "BHT_LIGHT_"+code+"_"+hash : "BHT_DWG_"+hash;
            using(var tr=target.TransactionManager.StartOpenCloseTransaction())
            {
                var table=(BlockTable)tr.GetObject(target.BlockTableId,OpenMode.ForRead);
                if(table.Has(name)) return name;
            }
            using(var source=new Database(false,true))
            {
                source.ReadDwgFile(path,FileOpenMode.OpenForReadAndAllShare,true,"");source.CloseInput(true);
                target.Insert(name,source,false);
            }
            return name;
        }
    }
}
