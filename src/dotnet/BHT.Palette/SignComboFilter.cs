using System;
using System.Collections.Generic;
using System.Linq;
using System.Windows.Forms;
using BHT.Bridge;
using BHT.Core;

namespace BHT.Palette
{
    /// <summary>
    /// 5.0: tim bien khi go cho ComboBox (Mã hiệu, Mã các mặt). Go "di cham", "đi chậm", "245", "w245a"...
    /// -> danh sach loc theo ma + ten (khong dau, khong phan biet hoa; BHT.Core.SignSearch).
    /// multi = true: o "Mã các mặt" nhieu ma cach nhau ';' - chi loc theo ma dang go sau ';' cuoi,
    /// chon muc thi thay ma dang go va giu cac ma truoc.
    /// </summary>
    internal sealed class SignComboFilter
    {
        private readonly ComboBox _c;
        private readonly Func<List<TdtSignEntry>> _source;
        private readonly Func<bool> _enabled;
        private readonly bool _multi;
        private bool _busy;
        public const int MaxItems = 60;

        public SignComboFilter(ComboBox c, Func<List<TdtSignEntry>> source, Func<bool> enabled, bool multi)
        {
            _c = c; _source = source; _enabled = enabled; _multi = multi;
            _c.AutoCompleteMode = AutoCompleteMode.None;
            _c.DropDownStyle = ComboBoxStyle.DropDown;
            _c.TextUpdate += (s, e) => OnTextUpdate();
            _c.DropDown += (s, e) => { if (!_busy) Fill(Query(), false); };
            if (_multi) _c.SelectionChangeCommitted += (s, e) => OnCommitMulti();
        }

        public bool Busy { get { return _busy; } }

        private string Query()
        {
            if (!_multi) return _c.Text ?? "";
            string head; return SignSearch.LastToken(_c.Text, out head);
        }

        private List<TdtSignEntry> Matches(string q)
        {
            if (_enabled != null && !_enabled()) return new List<TdtSignEntry>();
            List<TdtSignEntry> all;
            try { all = _source(); } catch { all = new List<TdtSignEntry>(); }
            var items = all.Select(x => new SignItem(x.Code, x.Description) { Tag = x });
            return SignSearch.Filter(items, q, MaxItems).Select(x => (TdtSignEntry)x.Tag).ToList();
        }

        /// <summary>Nap lai danh sach theo truy van, giu nguyen chu dang go va vi tri con tro.</summary>
        private void Fill(string q, bool drop)
        {
            _busy = true;
            try
            {
                string text = _c.Text; int caret = _c.SelectionStart;
                var hits = Matches(q);
                _c.BeginUpdate();
                try { _c.Items.Clear(); foreach (var h in hits) _c.Items.Add(h); }
                finally { _c.EndUpdate(); }
                if (drop)
                {
                    bool show = hits.Count > 0 && q.Trim() != "";
                    if (_c.DroppedDown != show) _c.DroppedDown = show;
                    if (show) Cursor.Current = Cursors.Default;
                }
                if (_c.Text != text) _c.Text = text;
                _c.SelectionStart = Math.Min(caret, _c.Text.Length); _c.SelectionLength = 0;
            }
            finally { _busy = false; }
        }

        private void OnTextUpdate()
        {
            if (_busy) return;
            Fill(Query(), true);
        }

        private void OnCommitMulti()
        {
            var e = _c.SelectedItem as TdtSignEntry;
            if (e == null) return;
            string before = _c.Tag as string ?? "";
            string next = SignSearch.ReplaceLastToken(before, e.Code);
            // ComboBox dat Text = muc da chon SAU su kien -> doi ve chuoi nhieu ma o vong thong diep ke tiep.
            _c.BeginInvoke((Action)(() =>
            {
                _busy = true;
                try { _c.SelectedIndex = -1; _c.Text = next; _c.SelectionStart = next.Length; _c.SelectionLength = 0; _c.Tag = next; }
                finally { _busy = false; }
            }));
        }

        /// <summary>Goi tu TextChanged cua o nhieu ma de nho chuoi truoc khi ComboBox thay bang muc chon.</summary>
        public void Remember()
        {
            if (!_multi || _busy) return;
            if (_c.SelectedIndex < 0) _c.Tag = _c.Text;
        }
    }
}
