using System;
using System.Collections.Generic;
using System.Text;

namespace BHT.Core
{
    /// <summary>
    /// Ban ghi BHT = danh sach cap (khoa, gia tri) CO THU TU, cho phep khoa lap
    /// (vd nhieu "pt", "anh"). Tuong duong danh sach assoc cua Lisp
    /// (bht:get / bht:get-all / bht:set / bht:set-all).
    /// </summary>
    public sealed class BhtRecord
    {
        private readonly List<KeyValuePair<string, string>> _pairs = new List<KeyValuePair<string, string>>();

        public BhtRecord() { }

        public BhtRecord(IEnumerable<KeyValuePair<string, string>> pairs)
        {
            if (pairs != null) foreach (var p in pairs) _pairs.Add(new KeyValuePair<string, string>(p.Key, p.Value ?? ""));
        }

        public IList<KeyValuePair<string, string>> Pairs { get { return _pairs.AsReadOnly(); } }
        public int Count { get { return _pairs.Count; } }

        /// <summary>bht:get - gia tri dau tien cua khoa, "" neu khong co (phan biet hoa thuong nhu assoc).</summary>
        public string Get(string key)
        {
            foreach (var p in _pairs) if (p.Key == key) return p.Value;
            return "";
        }

        public bool Has(string key)
        {
            foreach (var p in _pairs) if (p.Key == key) return true;
            return false;
        }

        /// <summary>bht:get-all - moi gia tri cua khoa theo thu tu.</summary>
        public List<string> GetAll(string key)
        {
            var o = new List<string>();
            foreach (var p in _pairs) if (p.Key == key) o.Add(p.Value);
            return o;
        }

        /// <summary>bht:set - thay gia tri o vi tri cap dau tien; bo cac cap trung sau; them cuoi neu chua co.</summary>
        public BhtRecord Set(string key, string value)
        {
            value = value ?? "";
            var o = new List<KeyValuePair<string, string>>();
            bool done = false;
            foreach (var p in _pairs)
            {
                if (p.Key == key)
                {
                    if (!done) { o.Add(new KeyValuePair<string, string>(key, value)); done = true; }
                }
                else o.Add(p);
            }
            if (!done) o.Add(new KeyValuePair<string, string>(key, value));
            _pairs.Clear(); _pairs.AddRange(o);
            return this;
        }

        /// <summary>bht:set-all - bo moi cap cua khoa, them cac gia tri moi o CUOI.</summary>
        public BhtRecord SetAll(string key, IEnumerable<string> values)
        {
            _pairs.RemoveAll(p => p.Key == key);
            if (values != null) foreach (var v in values) _pairs.Add(new KeyValuePair<string, string>(key, v ?? ""));
            return this;
        }

        public BhtRecord Add(string key, string value)
        {
            _pairs.Add(new KeyValuePair<string, string>(key, value ?? ""));
            return this;
        }

        public BhtRecord Clone() { return new BhtRecord(_pairs); }

        /// <summary>Chuoi chuan de so sanh ban ghi (moi cap 1 dong "khoa=gia tri").</summary>
        public string ToCanonical()
        {
            var sb = new StringBuilder();
            foreach (var p in _pairs) sb.Append(p.Key).Append('=').Append(p.Value).Append('\n');
            return sb.ToString();
        }
    }

    /// <summary>
    /// Ma hoa XRECORD giong bht:rec-encode / bht:rec-decode (BHT-0.3.x/0.4.0):
    /// moi truong la ma DXF 1 "khoa=gia tri"; gia tri dai hon 200 ky tu duoc
    /// chia doan, doan tiep theo la "khoa+=phan tiep".
    /// </summary>
    public static class RecordCodec
    {
        public const int ChunkSize = 200;

        /// <summary>bht:chunks - chia chuoi thanh cac doan &lt;= n ky tu (chuoi rong -> 1 doan rong).</summary>
        public static List<string> Chunks(string s, int n)
        {
            var o = new List<string>();
            s = s ?? "";
            while (s.Length > n) { o.Add(s.Substring(0, n)); s = s.Substring(n); }
            o.Add(s);
            return o;
        }

        public static List<string> Encode(BhtRecord rec)
        {
            var o = new List<string>();
            foreach (var p in rec.Pairs)
            {
                bool first = true;
                foreach (var part in Chunks(p.Value, ChunkSize))
                {
                    o.Add(p.Key + (first ? "=" : "+=") + part);
                    first = false;
                }
            }
            return o;
        }

        /// <summary>Giai ma cac chuoi ma DXF 1 theo dung thu tu. Chuoi khong co "=" bi bo qua (nhu Lisp).</summary>
        public static BhtRecord Decode(IEnumerable<string> group1Strings)
        {
            var o = new List<KeyValuePair<string, string>>();
            foreach (var s in group1Strings)
            {
                if (s == null) continue;
                int pos = s.IndexOf('=');
                if (pos < 0) continue;
                string k = s.Substring(0, pos), v = s.Substring(pos + 1);
                if (k.Length > 1 && k[k.Length - 1] == '+' && o.Count > 0)
                {
                    var last = o[o.Count - 1];
                    o[o.Count - 1] = new KeyValuePair<string, string>(last.Key, last.Value + v);
                }
                else o.Add(new KeyValuePair<string, string>(k, v));
            }
            return new BhtRecord(o);
        }
    }
}
