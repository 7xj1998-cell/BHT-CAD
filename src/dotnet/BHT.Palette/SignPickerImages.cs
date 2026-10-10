using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.IO;
using System.Linq;
using System.Windows.Forms;
using BHT.Core;
using BHT.Bridge;

namespace BHT.Palette
{
    public sealed partial class SignPickerForm
    {
        private readonly Timer searchTimer = new Timer();
        private readonly Dictionary<string,string> previewPaths = new Dictionary<string,string>(StringComparer.OrdinalIgnoreCase);
        private static readonly Dictionary<string,string> previewResources = typeof(SignPickerForm).Assembly.GetManifestResourceNames()
            .Where(n=>n.StartsWith("BHT.SignPreviews.",StringComparison.Ordinal))
            .GroupBy(n=>SignSearch.CodeKey(n.Substring("BHT.SignPreviews.".Length).Replace(".png","")))
            .ToDictionary(g=>g.Key,g=>g.First(),StringComparer.OrdinalIgnoreCase);
        private bool loadingPreviews, tearingDown, changingPage;
        private const int PageSize=60;
        private int pageIndex;
        private readonly List<Panel> filteredCards=new List<Panel>();
        private readonly Label pageLabel=new Label {AutoSize=true,Padding=new Padding(8,5,8,0)};
        private Button previousPage,nextPage;

        private Control BuildPageNavigation()
        {
            var row=new FlowLayoutPanel {Dock=DockStyle.Bottom,Height=36,Padding=new Padding(8,2,0,0)};
            previousPage=new Button {Text="← Trang trước",AutoSize=true};
            nextPage=new Button {Text="Trang sau →",AutoSize=true};
            previousPage.Click+=(s,e)=> {pageIndex--;ShowPage();};
            nextPage.Click+=(s,e)=> {pageIndex++;ShowPage();};
            row.Controls.AddRange(new Control[] {previousPage,pageLabel,nextPage});
            return row;
        }
        private void ShowPage()
        {
            if(tearingDown || IsDisposed || Disposing) return;
            changingPage=true;
            int pages=Math.Max(1,(filteredCards.Count+PageSize-1)/PageSize);
            pageIndex=Math.Max(0,Math.Min(pageIndex,pages-1));
            grid.SuspendLayout();
            try
            {
                grid.Controls.Clear();
                grid.Controls.AddRange(filteredCards.Skip(pageIndex*PageSize).Take(PageSize).Cast<Control>().ToArray());
                grid.AutoScrollPosition=Point.Empty;
            }
            finally {grid.ResumeLayout(); changingPage=false;}
            pageLabel.Text="Trang "+(pageIndex+1)+" / "+pages+" · "+filteredCards.Count+" biển";
            previousPage.Enabled=pageIndex>0;nextPage.Enabled=pageIndex+1<pages;
            if(IsHandleCreated) LoadVisiblePreviews();
        }

        private static Bitmap Thumbnail(Image original)
        {
            double scale = Math.Min(1.0,Math.Min(320.0/original.Width,216.0/original.Height));
            var result = new Bitmap(Math.Max(1,(int)(original.Width*scale)),Math.Max(1,(int)(original.Height*scale)));
            using(var g=Graphics.FromImage(result))
            {
                g.Clear(Color.White); g.InterpolationMode=InterpolationMode.HighQualityBicubic;
                g.DrawImage(original,new Rectangle(0,0,result.Width,result.Height));
            }
            return result;
        }
        private static Image FilePreview(string path)
        {
            if(string.IsNullOrWhiteSpace(path)) return null;
            try { using(var original=Image.FromFile(path)) return Thumbnail(original); }
            catch(ArgumentException) { return null; } catch(IOException) { return null; }
        }
        private void EnsureCardPreview(Panel card)
        {
            if(tearingDown || card.IsDisposed || card.Disposing) return;
            var picture=card.Controls.OfType<PictureBox>().FirstOrDefault();
            if(picture==null || picture.IsDisposed) return;
            if(picture.Image!=null) return;
            var sign=(TdtSignEntry)card.Tag;
            Image loaded=FilePreview(sign.PreviewPath) ?? BundledPreview(sign.Code) ?? BundledPreview(sign.NameFrom);
            string path;
            if(loaded==null && (previewPaths.TryGetValue(SignSearch.CodeKey(sign.Code),out path) ||
                previewPaths.TryGetValue(SignSearch.CodeKey(sign.NameFrom ?? ""),out path))) loaded=FilePreview(path);
            if(loaded==null) { picture.Tag="UNAVAILABLE"; loaded=CodePreview(sign); }
            picture.Image=loaded; images.Add(loaded);
        }
        private void LoadVisiblePreviews()
        {
            if(tearingDown || changingPage || loadingPreviews || !grid.IsHandleCreated || IsDisposed || Disposing) return;
            loadingPreviews=true;
            try
            {
                var viewport=grid.ClientRectangle;
                foreach(var card in cards)
                {
                    if(card.IsDisposed || card.Disposing) continue;
                    var picture=card.Controls.OfType<PictureBox>().FirstOrDefault();
                    if(picture==null || picture.IsDisposed) continue;
                    if(card.Parent==grid) EnsureCardPreview(card);
                    else if(picture.Image!=null && ((TdtSignEntry)card.Tag)!=SelectedSign)
                    {
                        var previous=picture.Image;picture.Image=null;images.Remove(previous);previous.Dispose();
                    }
                }
            }
            finally { loadingPreviews=false; }
        }
    }
}
