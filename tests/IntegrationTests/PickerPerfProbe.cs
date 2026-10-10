using System;using System.Linq;using System.IO;using System.Drawing;using System.Reflection;using System.Diagnostics;using System.Windows.Forms;using Autodesk.AutoCAD.Runtime;using BHT.Palette;
public class PickerPerfProbe {
 [CommandMethod("BHTPICKERPERF")]public void Run(){
 var folder=Environment.GetEnvironmentVariable("BHT_PICKER_PERF_FOLDER");Directory.CreateDirectory(folder);var report=new System.Collections.Generic.List<string>();
 Application.EnableVisualStyles();
 Application.SetUnhandledExceptionMode(UnhandledExceptionMode.CatchException);
 System.Threading.ThreadExceptionEventHandler handler=(sender,args)=>report.Add("FAIL UI exception: "+args.Exception);
 Application.ThreadException+=handler;
 for(int i=0;i<3;i++){
  var watch=Stopwatch.StartNew();using(var picker=new SignPickerForm("W.207a","","")){
   var ctor=watch.ElapsedMilliseconds;picker.StartPosition=FormStartPosition.Manual;picker.Location=new Point(-2500,-2500);picker.Show();Application.DoEvents();var shown=watch.ElapsedMilliseconds;
   var flags=BindingFlags.Instance|BindingFlags.NonPublic;var images=(System.Collections.Generic.List<Image>)typeof(SignPickerForm).GetField("images",flags).GetValue(picker);
   report.Add("open="+i+" ctor_ms="+ctor+" shown_ms="+shown+" images="+images.Count+" pixel_bytes="+images.Sum(x=>(long)x.Width*x.Height*4));
   var search=(TextBox)typeof(SignPickerForm).GetField("search",flags).GetValue(picker);watch.Restart();search.Text="R";search.Text="R.";search.Text="R.415";Application.DoEvents();report.Add("search_burst_ms="+watch.ElapsedMilliseconds);
   var filter=typeof(SignPickerForm).GetMethod("Filter",flags);
   search.Text="";filter.Invoke(picker,null);
   var next=(Button)typeof(SignPickerForm).GetField("nextPage",flags).GetValue(picker);
   next.PerformClick();picker.Size=new Size(1000,700);Application.DoEvents();
   search.Text="NO-MATCH-XYZ";filter.Invoke(picker,null);Application.DoEvents();
   search.Text="";filter.Invoke(picker,null);Application.DoEvents();
   if(i%2==0) picker.Dispose(); else picker.Close();
   Application.DoEvents();picker.Dispose();
   report.Add("PASS lifecycle resize-page-empty-filter-"+i);
  }
 }
 Application.ThreadException-=handler;
 File.WriteAllLines(Path.Combine(folder,"picker-perf.txt"),report);}
}
