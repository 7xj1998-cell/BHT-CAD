using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;

namespace BHT.Core
{
    /// <summary>Toa do 2D thuan tuy, khong phu thuoc AutoCAD.</summary>
    public sealed class RoutePoint
    {
        public double X, Y;
        public RoutePoint() { }
        public RoutePoint(double x, double y) { X = x; Y = y; }
    }

    /// <summary>
    /// Mot moc Station Control. GeometryDistance la khoang cach theo CHIEU TUYEN da chon.
    /// StationBack la ly trinh tai moc khi di toi; StationAhead la ly trinh bat dau sau moc.
    /// Hai gia tri khac nhau bieu dien station break.
    /// </summary>
    public sealed class RouteControlPoint
    {
        public double GeometryDistance;
        public double StationBack;
        public double StationAhead;
        public string Source = "";
        public bool Accepted = true;

        public RouteControlPoint() { }
        public RouteControlPoint(double distance, double station)
        {
            GeometryDistance = distance; StationBack = station; StationAhead = station;
        }
        public RouteControlPoint(double distance, double stationBack, double stationAhead)
        {
            GeometryDistance = distance; StationBack = stationBack; StationAhead = stationAhead;
        }
    }

    public sealed class RouteProjection
    {
        public bool Valid;
        public string Status = "";
        public double RawDistance;
        public double RouteDistance;
        public double Offset;
        public string Side = "CHUA_XAC_DINH";
        public double NearestX, NearestY;
        public int SegmentIndex = -1;
    }

    public sealed class RouteStationResult
    {
        public string Status = "NO_STATION_CONTROL";
        public double? Station;
        public double? Ratio;
        public string Note = "";
    }

    public sealed class RouteIssue
    {
        public string Code = "";
        public int Index = -1;
        public string Message = "";
    }

    /// <summary>
    /// Route Model V5 thuan tuy: Polyline + diem dau + chieu tang ly trinh + Station Control.
    /// Lop nay khong doc/sua RTK va khong phu thuoc geometry proxy TDT.
    /// </summary>
    public static class RouteModelLogic
    {
        public const double Epsilon = 1e-9;

        public static double Length(IList<RoutePoint> points, bool closed)
        {
            if (points == null || points.Count < 2) return 0.0;
            double result = 0.0;
            for (int i = 1; i < points.Count; i++) result += Distance(points[i - 1], points[i]);
            if (closed) result += Distance(points[points.Count - 1], points[0]);
            return result;
        }

        /// <summary>
        /// Doi khoang cach theo thu tu vertex thanh khoang cach tu StartPoint theo direction.
        /// Open polyline: diem nam phia sau diem dau tra ve null. Closed polyline: tu dong wrap.
        /// </summary>
        public static double? ToRouteDistance(double rawDistance, double length, double startDistance, int direction, bool closed)
        {
            if (length < Epsilon) return null;
            direction = direction < 0 ? -1 : 1;
            rawDistance = Clamp(rawDistance, 0.0, length);
            startDistance = Clamp(startDistance, 0.0, length);
            double value = direction > 0 ? rawDistance - startDistance : startDistance - rawDistance;
            if (closed)
            {
                while (value < -Epsilon) value += length;
                while (value >= length - Epsilon) value -= length;
                return Math.Abs(value) < Epsilon ? 0.0 : value;
            }
            return value < -Epsilon ? (double?)null : Math.Max(0.0, value);
        }

        /// <summary>Chieu dai su dung duoc tinh tu diem dau tren Polyline mo.</summary>
        public static double UsableLength(double length, double startDistance, int direction, bool closed)
        {
            if (closed) return Math.Max(0.0, length);
            startDistance = Clamp(startDistance, 0.0, length);
            return direction < 0 ? startDistance : length - startDistance;
        }

        /// <summary>Chieu diem len polyline thuan (doan thang), sau do quy ve diem dau/chieu V5.</summary>
        public static RouteProjection Project(IList<RoutePoint> points, bool closed, double startDistance, int direction, double x, double y)
        {
            var result = new RouteProjection { Status = "INVALID_GEOMETRY" };
            if (points == null || points.Count < 2) return result;
            double best2 = double.MaxValue, rawAtStart = 0.0, cumulative = 0.0;
            double bestCross = 0.0, bestX = 0.0, bestY = 0.0, bestRaw = 0.0;
            int bestSegment = -1;
            int count = points.Count - 1 + (closed ? 1 : 0);
            for (int i = 0; i < count; i++)
            {
                RoutePoint a = points[i], b = points[(i + 1) % points.Count];
                double dx = b.X - a.X, dy = b.Y - a.Y, seg2 = dx * dx + dy * dy;
                if (seg2 < Epsilon) continue;
                double t = ((x - a.X) * dx + (y - a.Y) * dy) / seg2;
                t = Clamp(t, 0.0, 1.0);
                double qx = a.X + t * dx, qy = a.Y + t * dy;
                double ex = x - qx, ey = y - qy, d2 = ex * ex + ey * ey;
                if (d2 < best2)
                {
                    best2 = d2; bestX = qx; bestY = qy; bestSegment = i;
                    bestRaw = cumulative + Math.Sqrt(seg2) * t;
                    bestCross = dx * (y - qy) - dy * (x - qx);
                }
                cumulative += Math.Sqrt(seg2);
            }
            if (bestSegment < 0) return result;
            rawAtStart = bestRaw;
            double? routeDistance = ToRouteDistance(rawAtStart, cumulative, startDistance, direction, closed);
            result.RawDistance = rawAtStart;
            result.RouteDistance = routeDistance ?? 0.0;
            result.Offset = Math.Sqrt(best2);
            result.NearestX = bestX; result.NearestY = bestY; result.SegmentIndex = bestSegment;
            result.Side = result.Offset < 0.005 ? "ON_ROUTE" : ((bestCross * (direction < 0 ? -1.0 : 1.0)) > 0.0 ? "LEFT" : "RIGHT");
            result.Valid = routeDistance.HasValue;
            result.Status = result.Valid ? "VALID" : "BEFORE_START";
            return result;
        }

        /// <summary>Ngoai suy/noi suy Station Control, khong noi suy xuyen station break.</summary>
        public static RouteStationResult Station(IList<RouteControlPoint> source, double routeDistance, double extrapolation)
        {
            var marks = (source ?? new RouteControlPoint[0]).Where(x => x != null && x.Accepted)
                .OrderBy(x => x.GeometryDistance).ToList();
            if (marks.Count == 0) return new RouteStationResult { Status = "NO_STATION_CONTROL", Note = "Tuyến chưa có mốc lý trình đã xác nhận." };
            if (marks.Count == 1)
            {
                double delta = routeDistance - marks[0].GeometryDistance;
                if (Math.Abs(delta) > Math.Max(0.0, extrapolation)) return new RouteStationResult { Status = "OUT_OF_RANGE", Note = "Ngoài phạm vi một mốc." };
                double basis = delta < 0.0 ? marks[0].StationBack : marks[0].StationAhead;
                return new RouteStationResult { Status = "VALID", Station = basis + delta, Ratio = 1.0, Note = "Tính từ một mốc." };
            }
            for (int i = 0; i < marks.Count - 1; i++)
            {
                RouteControlPoint a = marks[i], b = marks[i + 1];
                if (routeDistance + Epsilon < a.GeometryDistance || routeDistance - Epsilon > b.GeometryDistance) continue;
                double span = b.GeometryDistance - a.GeometryDistance;
                if (span < Epsilon) return new RouteStationResult { Status = "INVALID_CONTROL", Note = "Hai mốc trùng vị trí hình học." };
                double ratio = (b.StationBack - a.StationAhead) / span;
                double station = a.StationAhead + (routeDistance - a.GeometryDistance) * ratio;
                if (Math.Abs(routeDistance - b.GeometryDistance) < Epsilon) station = b.StationBack;
                return new RouteStationResult { Status = Math.Abs(Math.Abs(ratio) - 1.0) > 0.03 ? "CHECK" : "VALID", Station = station, Ratio = ratio,
                    Note = "Nội suy Station Control " + i.ToString(CultureInfo.InvariantCulture) + "." };
            }
            RouteControlPoint edge = routeDistance < marks[0].GeometryDistance ? marks[0] : marks[marks.Count - 1];
            double outside = Math.Abs(routeDistance - edge.GeometryDistance);
            if (outside > Math.Max(0.0, extrapolation)) return new RouteStationResult { Status = "OUT_OF_RANGE", Note = "Ngoài phạm vi Station Control." };
            bool before = routeDistance < marks[0].GeometryDistance;
            double stationEdge = before ? edge.StationBack : edge.StationAhead;
            double edgeRatio = EdgeRatio(marks, before);
            return new RouteStationResult { Status = "VALID", Station = stationEdge + (routeDistance - edge.GeometryDistance) * edgeRatio,
                Ratio = edgeRatio, Note = "Ngoại suy trong giới hạn cho phép." };
        }

        /// <summary>Kiem tra chuoi coc; khong tu sua hay chap nhan coc bat thuong.</summary>
        public static List<RouteIssue> DiagnoseControls(IList<RouteControlPoint> source, double expectedStep, double distanceTolerance, double stationTolerance)
        {
            var controls = (source ?? new RouteControlPoint[0]).Where(x => x != null).OrderBy(x => x.GeometryDistance).ToList();
            var issues = new List<RouteIssue>();
            for (int i = 0; i < controls.Count; i++)
            {
                if (!controls[i].Accepted) issues.Add(new RouteIssue { Code = "NOT_ACCEPTED", Index = i, Message = "Mốc chưa được xác nhận." });
                if (i == 0) continue;
                double dd = controls[i].GeometryDistance - controls[i - 1].GeometryDistance;
                double ds = controls[i].StationBack - controls[i - 1].StationAhead;
                if (Math.Abs(dd) < Epsilon) issues.Add(new RouteIssue { Code = "DUPLICATE_DISTANCE", Index = i, Message = "Hai cọc trùng vị trí hình học." });
                if (Math.Abs(ds) < Epsilon) issues.Add(new RouteIssue { Code = "DUPLICATE_STATION", Index = i, Message = "Hai cọc trùng lý trình." });
                if (ds < -stationTolerance) issues.Add(new RouteIssue { Code = "REVERSED_STATION", Index = i, Message = "Lý trình giảm ngược chiều tuyến." });
                if (expectedStep > Epsilon && Math.Abs(dd - expectedStep) <= distanceTolerance && Math.Abs(ds - expectedStep) > stationTolerance)
                    issues.Add(new RouteIssue { Code = "STATION_JUMP", Index = i, Message = "Khoảng hình học đều nhưng lý trình nhảy bất thường." });
            }
            return issues;
        }

        /// <summary>Hash on dinh cho hinh hoc; dung phat hien Polyline nguon thay doi.</summary>
        public static string GeometryHash(IList<RoutePoint> points, bool closed)
        {
            ulong hash = 1469598103934665603UL;
            Action<string> add = s => { foreach (byte b in Encoding.UTF8.GetBytes(s)) { hash ^= b; hash *= 1099511628211UL; } };
            add(closed ? "C|" : "O|");
            foreach (RoutePoint p in points ?? new RoutePoint[0])
                add(p.X.ToString("R", CultureInfo.InvariantCulture) + "," + p.Y.ToString("R", CultureInfo.InvariantCulture) + "|");
            return hash.ToString("X16", CultureInfo.InvariantCulture);
        }

        public static int NextRevision(int currentRevision, string oldSignature, string newSignature)
        {
            int value = currentRevision < 1 ? 1 : currentRevision;
            return string.Equals(oldSignature ?? "", newSignature ?? "", StringComparison.Ordinal) ? value : value + 1;
        }

        /// <summary>Gia tri mac dinh khi doc Route schema cu.</summary>
        public static int LegacyDirection(string value) { return (value ?? "").Trim() == "-1" ? -1 : 1; }
        public static int LegacyRevision(string value)
        {
            int revision; return int.TryParse((value ?? "").Trim(), NumberStyles.Integer, CultureInfo.InvariantCulture, out revision) && revision > 0 ? revision : 1;
        }

        private static double EdgeRatio(IList<RouteControlPoint> marks, bool before)
        {
            RouteControlPoint a = before ? marks[0] : marks[marks.Count - 2];
            RouteControlPoint b = before ? marks[1] : marks[marks.Count - 1];
            double span = b.GeometryDistance - a.GeometryDistance;
            if (Math.Abs(span) < Epsilon) return 1.0;
            return (b.StationBack - a.StationAhead) / span;
        }

        private static double Distance(RoutePoint a, RoutePoint b)
        {
            double dx = b.X - a.X, dy = b.Y - a.Y; return Math.Sqrt(dx * dx + dy * dy);
        }

        private static double Clamp(double value, double min, double max) { return Math.Max(min, Math.Min(max, value)); }
    }
}
