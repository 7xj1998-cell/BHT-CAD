using System;
using System.Collections.Generic;
using System.Linq;
using Autodesk.AutoCAD.DatabaseServices;
using BHT.Core;

namespace BHT.Bridge
{
    /// <summary>
    /// Dem thay doi cua 1 Database (ObjectAppended / ObjectModified / ObjectErased).
    /// Moi bo nho dem trong plugin gan voi Version; khi Version doi -> doc lai tu DWG.
    /// </summary>
    public sealed class ChangeTracker : IDisposable
    {
        private Database _db;
        private long _version;
        public long Version { get { return System.Threading.Interlocked.Read(ref _version); } }

        public ChangeTracker(Database db)
        {
            _db = db;
            _db.ObjectAppended += OnChange;
            _db.ObjectModified += OnChange;
            _db.ObjectErased += OnErased;
        }

        private void OnChange(object s, ObjectEventArgs e) { System.Threading.Interlocked.Increment(ref _version); }
        private void OnErased(object s, ObjectErasedEventArgs e) { System.Threading.Interlocked.Increment(ref _version); }

        public void Dispose()
        {
            if (_db == null) return;
            try
            {
                _db.ObjectAppended -= OnChange;
                _db.ObjectModified -= OnChange;
                _db.ObjectErased -= OnErased;
            }
            catch { }
            _db = null;
        }
    }

    /// <summary>
    /// Trien khai IBhtDataService tren 1 Database. Doc: tu mo Transaction.
    /// Ghi: nguoi goi PHAI dang giu khoa tai lieu (lenh AutoCAD thuong, hoac
    /// AcadDispatcher.RunWrite tu palette). Moi thao tac ghi nam tron trong 1 Transaction.
    /// </summary>
    public sealed class BhtDataService : IBhtDataService, IDisposable
    {
        private readonly Database _db;
        private readonly Func<string> _dwgPrefix;
        private readonly ChangeTracker _tracker;
        private long _ptVersion = -1;
        private List<SurveyPoint> _ptCache;

        public BhtDataService(Database db, Func<string> dwgPrefix, bool trackChanges)
        {
            _db = db;
            _dwgPrefix = dwgPrefix ?? (() => "");
            if (trackChanges) _tracker = new ChangeTracker(db);
        }

        public Database Database { get { return _db; } }

        public void Dispose() { if (_tracker != null) _tracker.Dispose(); }

        private T Read<T>(Func<Transaction, T> f)
        {
            using (var tr = _db.TransactionManager.StartTransaction())
            {
                var r = f(tr);
                tr.Commit();
                return r;
            }
        }

        private OpResult Write(Func<Transaction, OpResult> f)
        {
            using (var tr = _db.TransactionManager.StartTransaction())
            {
                OpResult r;
                try { r = f(tr); }
                catch (Exception ex) { tr.Abort(); return OpResult.Fail("lỗi ghi dữ liệu (đã hủy, dữ liệu cũ giữ nguyên): " + ex.Message); }
                if (r.Ok) tr.Commit(); else tr.Abort();
                return r;
            }
        }

        // ------------------------------------------------------------ doc

        public List<SurveyPoint> GetPoints()
        {
            if (_tracker != null && _ptCache != null && _ptVersion == _tracker.Version) return _ptCache;
            long v = _tracker == null ? 0 : _tracker.Version;
            var l = Read(tr => BhtStore.Points(tr, _db));
            _ptCache = l; _ptVersion = v;
            return l;
        }

        public Dictionary<string, SurveyPoint> PointIndex()
        {
            var d = new Dictionary<string, SurveyPoint>(StringComparer.Ordinal);
            foreach (var p in GetPoints()) { var k = p.IdUpper; if (!d.ContainsKey(k)) d[k] = p; }
            return d;
        }

        public SurveyPoint GetPoint(string surveyId)
        {
            SurveyPoint p;
            return PointIndex().TryGetValue((surveyId ?? "").ToUpperInvariant(), out p) ? p : null;
        }

        public SurveyPoint GetPointByHandle(string handle)
        {
            foreach (var p in GetPoints()) if (string.Equals(p.Handle, handle, StringComparison.OrdinalIgnoreCase)) return p;
            return null;
        }

        private Dictionary<string, BhtRecord> Dict(string sub)
        {
            return Read(tr =>
            {
                var d = new Dictionary<string, BhtRecord>(StringComparer.OrdinalIgnoreCase);
                foreach (var kv in BhtStore.All(tr, _db, sub)) d[kv.Key] = kv.Value;
                return d;
            });
        }

        /// <summary>Danh sach ban ghi theo DUNG thu tu dictionary.</summary>
        public List<KeyValuePair<string, BhtRecord>> Ordered(string sub) { return Read(tr => BhtStore.All(tr, _db, sub)); }

        public Dictionary<string, BhtRecord> GetObjects() { return Dict("OBJ"); }
        public BhtRecord GetObject(string id) { return Read(tr => BhtStore.Read(tr, _db, "OBJ", id)); }
        public Dictionary<string, BhtRecord> GetPhotos() { return Dict("PHOTO"); }
        public BhtRecord GetPhoto(string id) { return Read(tr => BhtStore.Read(tr, _db, "PHOTO", id)); }
        public string Meta(string key, string def) { return Read(tr => BhtStore.Meta(tr, _db, key, def)); }

        public string ResolvePhotoPath(string photoId)
        {
            var rec = GetPhoto(photoId);
            if (rec == null) return null;
            return PhotoLogic.Resolve(rec, Meta("thu_muc_anh", ""), _dwgPrefix(), PhotoLogic.FileOk);
        }

        public string NextObjectId()
        {
            return Read(tr => ObjectLogic.NextId(BhtStore.Keys(tr, _db, "OBJ"), BhtStore.Meta(tr, _db, "obj_seq", "0")));
        }

        public Overview GetOverview()
        {
            var ov = new Overview();
            var pts = GetPoints();
            ov.RtkPoints = pts.Count;
            var objs = GetObjects();
            var photos = GetPhotos();
            var idx = PointIndex();
            Read(tr =>
            {
                ov.LegacyV01Points = BhtStore.LegacyPointCount(tr, _db);
                ov.Routes = BhtStore.Keys(tr, _db, "ROUTE").Count;
                ov.Segments = BhtStore.Keys(tr, _db, "SEG").Count;
                ov.PhotoMarkers = BhtStore.Tagged(tr, _db, "INSERT", "BHT_ANHPT").Count;
                ov.Symbols = BhtStore.Tagged(tr, _db, "INSERT", "BHT_KH").Count;
                ov.Labels = BhtStore.Tagged(tr, _db, "TEXT", "BHT_NHAN").Count;
                return 0;
            });
            ov.ObjectRecords = objs.Count;
            foreach (var o in objs.Values)
                if (!o.GetAll(ObjFields.Point).Any(p => idx.ContainsKey(p.ToUpperInvariant()))) ov.ObjectsWithoutPoints++;
            ov.Photos = photos.Count;
            foreach (var p in photos.Values)
            {
                if (PhotoLogic.GpsValid(p)) ov.PhotosGpsValid++; else ov.PhotosGpsInvalid++;
                if (p.GetAll(PhotoFields.Objects).Count > 0) ov.PhotosLinked++; else ov.PhotosUnlinked++;
                var st = p.Get(PhotoFields.State);
                if (st == "DE_XUAT" || st == "MO_HO") ov.PhotosSuggested++;
            }
            ov.EntitiesOutsideModel = pts.Count(p => p.Space != "Model");
            if (ov.LegacyV01Points > 0) ov.Warnings.Add(ov.LegacyV01Points + " điểm BHT 0.1 chưa có ID - dùng BHTNANGCAP (mục Bảo trì dữ liệu cũ).");
            if (ov.ObjectsWithoutPoints > 0) ov.Warnings.Add(ov.ObjectsWithoutPoints + " hồ sơ không còn điểm RTK hợp lệ.");
            if (ov.EntitiesOutsideModel > 0) ov.Warnings.Add(ov.EntitiesOutsideModel + " điểm RTK nằm trong Layout - dùng BHTVEMODEL.");
            if (ov.PhotosGpsValid > ov.PhotoMarkers) ov.Warnings.Add((ov.PhotosGpsValid - ov.PhotoMarkers) + " ảnh GPS hợp lệ chưa có ký hiệu - Đồng bộ ký hiệu ảnh.");
            var dup = pts.GroupBy(p => p.IdUpper).Where(g => g.Count() > 1).Count();
            if (dup > 0) ov.Warnings.Add(dup + " ID điểm bị trùng - chạy BHTKT.");
            return ov;
        }

        // ------------------------------------------------------------ ghi

        public OpResult CreateObject(string objectId, BhtRecord fields, IList<string> pointIds, bool allowShared)
        {
            var ptIds = new HashSet<string>(GetPoints().Select(p => p.IdUpper), StringComparer.Ordinal);
            return Write(tr =>
            {
                var objs = new Dictionary<string, BhtRecord>(StringComparer.OrdinalIgnoreCase);
                foreach (var kv in BhtStore.All(tr, _db, "OBJ")) objs[kv.Key] = kv.Value;
                string id = string.IsNullOrWhiteSpace(objectId)
                    ? ObjectLogic.NextId(objs.Keys, BhtStore.Meta(tr, _db, "obj_seq", "0"))
                    : objectId.Trim().ToUpperInvariant();
                BhtRecord rec;
                string why = ObjectLogic.BuildNew(id, fields ?? new BhtRecord(), pointIds, allowShared, ptIds, objs, BhtTime.Now(), out rec);
                if (why != null) return OpResult.Fail("không tạo được đối tượng: " + why);
                BhtStore.Write(tr, _db, "OBJ", id, rec);
                int seq = ObjectLogic.SeqNum(id);
                if (seq > 0 && seq > ObjectLogic.ParseIntLikeLisp(BhtStore.Meta(tr, _db, "obj_seq", "0")))
                    BhtStore.MetaSet(tr, _db, "obj_seq", seq.ToString(System.Globalization.CultureInfo.InvariantCulture));
                var r = OpResult.Success(id);
                r.Lines.Add("đã tạo đối tượng " + id + " với " + pointIds.Count + " điểm RTK.");
                return r;
            });
        }

        public OpResult UpdateObject(string objectId, BhtRecord fields)
        {
            return Write(tr =>
            {
                var rec = BhtStore.Read(tr, _db, "OBJ", objectId);
                if (rec == null) return OpResult.Fail("không có hồ sơ " + objectId);
                foreach (var p in fields.Pairs)
                    if (p.Key == ObjFields.Id || p.Key == ObjFields.Point || p.Key == ObjFields.Photo || p.Key == ObjFields.CreatedAt)
                        return OpResult.Fail("không sửa trực tiếp trường " + p.Key + " (dùng thêm/gỡ điểm, gắn ảnh)");
                BhtStore.Write(tr, _db, "OBJ", objectId, ObjectLogic.ApplyEdit(rec, fields, BhtTime.Now()));
                return OpResult.Success("đã cập nhật " + objectId.ToUpperInvariant());
            });
        }

        public OpResult AddPoints(string objectId, IList<string> pointIds)
        {
            var ptIds = new HashSet<string>(GetPoints().Select(p => p.IdUpper), StringComparer.Ordinal);
            return Write(tr =>
            {
                var rec = BhtStore.Read(tr, _db, "OBJ", objectId);
                if (rec == null) return OpResult.Fail("không có hồ sơ " + objectId);
                var bad = pointIds.Where(p => !ptIds.Contains(p.ToUpperInvariant())).ToList();
                if (bad.Count > 0) return OpResult.Fail("không tìm thấy điểm: " + string.Join(", ", bad));
                var n = ObjectLogic.AddPoints(rec, pointIds, BhtTime.Now());
                BhtStore.Write(tr, _db, "OBJ", objectId, n);
                return OpResult.Success(objectId.ToUpperInvariant() + " có " + n.GetAll(ObjFields.Point).Count + " điểm");
            });
        }

        public OpResult RemovePoints(string objectId, IList<string> pointIds)
        {
            return Write(tr =>
            {
                var rec = BhtStore.Read(tr, _db, "OBJ", objectId);
                if (rec == null) return OpResult.Fail("không có hồ sơ " + objectId);
                var n = ObjectLogic.RemovePoints(rec, pointIds, BhtTime.Now());
                BhtStore.Write(tr, _db, "OBJ", objectId, n);
                return OpResult.Success(objectId.ToUpperInvariant() + " còn " + n.GetAll(ObjFields.Point).Count + " điểm");
            });
        }

        public OpResult LinkPhoto(string photoId, string objectId, string how)
        {
            return Write(tr =>
            {
                var prec = BhtStore.Read(tr, _db, "PHOTO", photoId);
                var orec = BhtStore.Read(tr, _db, "OBJ", objectId);
                if (prec == null) return OpResult.Fail("không có ảnh " + photoId.ToUpperInvariant());
                if (orec == null) return OpResult.Fail("không có đối tượng " + objectId.ToUpperInvariant());
                BhtRecord no, np;
                ObjectLogic.LinkPhoto(photoId, objectId, string.IsNullOrEmpty(how) ? "THU_CONG" : how, orec, prec, BhtTime.Now(), out no, out np);
                BhtStore.Write(tr, _db, "OBJ", objectId, no);
                BhtStore.Write(tr, _db, "PHOTO", photoId, np);
                return OpResult.Success("đã gắn ảnh " + photoId.ToUpperInvariant() + " -> " + objectId.ToUpperInvariant());
            });
        }

        public OpResult UnlinkPhoto(string photoId, string objectId)
        {
            return Write(tr =>
            {
                var prec = BhtStore.Read(tr, _db, "PHOTO", photoId);
                var orec = BhtStore.Read(tr, _db, "OBJ", objectId);
                BhtRecord no, np;
                ObjectLogic.UnlinkPhoto(photoId, objectId, orec, prec, BhtTime.Now(), out no, out np);
                if (no != null) BhtStore.Write(tr, _db, "OBJ", objectId, no);
                if (np != null) BhtStore.Write(tr, _db, "PHOTO", photoId, np);
                return OpResult.Success("đã bỏ gắn ảnh " + photoId.ToUpperInvariant() + " - " + objectId.ToUpperInvariant());
            });
        }
    }
}
