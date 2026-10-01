using System;
using System.Collections.Generic;

namespace BHT.Core
{
    /// <summary>Ket qua thao tac: Ok + thong diep (tieng Viet) + cac dong chi tiet.</summary>
    public sealed class OpResult
    {
        public bool Ok;
        public string Message;
        public List<string> Lines = new List<string>();
        public static OpResult Success(string msg) { return new OpResult { Ok = true, Message = msg }; }
        public static OpResult Fail(string msg) { return new OpResult { Ok = false, Message = msg }; }
        public override string ToString() { return (Ok ? "OK: " : "LỖI: ") + Message; }
    }

    public sealed class Overview
    {
        public int RtkPoints, LegacyV01Points, ObjectRecords, ObjectsWithoutPoints;
        public int Photos, PhotosGpsValid, PhotosGpsInvalid, PhotosLinked, PhotosUnlinked, PhotosSuggested, PhotoMarkers;
        public int Routes, Segments, Symbols, Labels;
        public int EntitiesOutsideModel;
        public string LispVersionStored = "";
        public List<string> Warnings = new List<string>();
    }

    public sealed class ObjectSummary
    {
        public string Id, Group, Code, Description, PoleCount, FaceCount, Condition, RoadSide;
        public int PointCount, PhotoCount;
    }

    public sealed class PhotoSummary
    {
        public string Id, Name, Time, GpsState, LinkState;
        public bool GpsValid, HasShotPosition;
        public double E, N;
        public List<string> Objects = new List<string>();
        public List<string> Suggestions = new List<string>();
    }

    /// <summary>
    /// Hop dong du lieu giua palette va ban ve. Ban trien khai: BHT.Bridge.BhtDataService.
    /// Nguon du lieu DUY NHAT: dictionary BHT_V02 / XRecord / XData trong DWG.
    /// Cac thao tac ma Lisp so huu thuat toan (ky hieu, nhan, ky hieu anh, kiem tra,
    /// thu tu hien thi, thong tin kieu BHTINFO) di qua ILispApi (goi ham bht:api-*).
    /// </summary>
    public interface IBhtDataService
    {
        Overview GetOverview();
        List<SurveyPoint> GetPoints();
        SurveyPoint GetPoint(string surveyId);
        SurveyPoint GetPointByHandle(string handle);
        Dictionary<string, BhtRecord> GetObjects();
        BhtRecord GetObject(string objectId);
        Dictionary<string, BhtRecord> GetPhotos();
        BhtRecord GetPhoto(string photoId);
        string ResolvePhotoPath(string photoId);
        string Meta(string key, string def);

        OpResult CreateObject(string objectId, BhtRecord fields, IList<string> pointIds, bool allowShared);
        OpResult UpdateObject(string objectId, BhtRecord fields);
        OpResult AddPoints(string objectId, IList<string> pointIds);
        OpResult RemovePoints(string objectId, IList<string> pointIds);
        OpResult LinkPhoto(string photoId, string objectId, string how);
        OpResult UnlinkPhoto(string photoId, string objectId);
        string NextObjectId();
    }

    /// <summary>Goi ham Lisp bht:api-* (Lisp so huu thuat toan). Moi ham tra ve danh sach chuoi ("OK" ...) / ("LOI" ly_do).</summary>
    public interface ILispApi
    {
        LispReply Call(string function, params string[] args);
    }

    public sealed class LispReply
    {
        public bool Ok;
        public List<string> Values = new List<string>();
        public string Error = "";

        /// <summary>Doc danh sach chuoi do Lisp tra ve (phan tu dau "OK"/"LOI").</summary>
        public static LispReply FromStrings(IList<string> raw)
        {
            var r = new LispReply();
            if (raw == null || raw.Count == 0) { r.Error = "Lisp không trả về giá trị (hàm chưa nạp / chưa đăng ký?)"; return r; }
            if (raw[0] == "OK") { r.Ok = true; for (int i = 1; i < raw.Count; i++) r.Values.Add(raw[i]); }
            else { r.Error = raw.Count > 1 ? raw[1] : raw[0];
                if (string.IsNullOrWhiteSpace(r.Error)) r.Error = "Lisp đã dừng thao tác mà không trả về chi tiết. Kiểm tra bộ BHT đang nạp và dòng lệnh CAD (F2).";
            }
            return r;
        }

        /// <summary>"khoa=gia tri" -> tu dien.</summary>
        public Dictionary<string, string> AsPairs()
        {
            var d = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            foreach (var v in Values) { int i = v.IndexOf('='); if (i > 0) d[v.Substring(0, i)] = v.Substring(i + 1); }
            return d;
        }
    }
}
