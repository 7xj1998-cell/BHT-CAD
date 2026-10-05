using System; using System.Linq; using System.IO; using System.Reflection; using System.Windows.Forms; using Autodesk.AutoCAD.Runtime; using BHT.Core; using BHT.Palette;
public class PaletteEditorProbe {
[CommandMethod("BHTPALETTEEDITORPROBE")] public static void Run(){
var t=typeof(BhtPaletteControl); using(var editor=new BhtPaletteControl()){
t.GetField("_bridgeName",BindingFlags.Instance|BindingFlags.NonPublic).SetValue(editor,"Cầu Nước Mục");t.GetField("_bridgeStation",BindingFlags.Instance|BindingFlags.NonPublic).SetValue(editor,"Km38+580");t.GetField("_roadName",BindingFlags.Instance|BindingFlags.NonPublic).SetValue(editor,"ĐT.830");
var fields=(BhtRecord)t.GetMethod("EditorFields",BindingFlags.Instance|BindingFlags.NonPublic).Invoke(editor,null);
if(fields.Get(ObjFields.BridgeName)!="Cầu Nước Mục" || fields.Get(ObjFields.SignChainage)!="Km38+580" || fields.Get(ObjFields.RoadName)!="ĐT.830") throw new System.Exception("Bridge fields lost");
foreach(var label in Descendants(editor).OfType<Label>()) if(label.Text=="Tên cầu I.439" || label.Text=="Lý trình biển" || label.Text=="Tên đường") throw new System.Exception("Duplicate input remains");
} File.WriteAllText(Environment.GetEnvironmentVariable("BHT_QA_OUTPUT") + "-palette.txt","PASS actual-palette-preserves-bridge-data-and-removes-duplicate-fields");}
static System.Collections.Generic.IEnumerable<Control> Descendants(Control parent){foreach(Control c in parent.Controls){yield return c;foreach(var g in Descendants(c))yield return g;}}
}