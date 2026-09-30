# BHT V5.0 — MASTER TECHNICAL DIRECTION
## Polyline-first / TDT-assisted Route Architecture

Bạn đang tiếp tục phát triển dự án **BHT V5.0**, phần mềm quản lý khảo sát hiện trạng tuyến đường tích hợp AutoCAD.

Mục tiêu của phiên bản này là cải tiến mạnh phần **tuyến tham chiếu, tim TDT, lý trình và phát sinh cọc**, nhưng vẫn giữ toàn bộ nền tảng hiện có về RTK, ảnh TimeMark, hồ sơ đối tượng, Block và báo cáo.

---

# 1. Mục tiêu của BHT V5.0

BHT không phải phần mềm thay thế TDT.

BHT sử dụng dữ liệu hiện có trong AutoCAD/TDT để xây dựng một mô hình tuyến riêng phục vụ:

- xác định lý trình cho điểm RTK;
- xác định phía trái/phải tuyến;
- tính offset;
- đặt biển báo và cọc tiêu;
- quản lý hồ sơ công trình;
- thống kê theo Km;
- phát sinh hoặc quản lý cọc;
- cập nhật tuyến khi dữ liệu nguồn thay đổi.

Nguyên tắc chính:

**TDT là nguồn dữ liệu tuyến. BHT tạo mô hình tuyến riêng để quản lý khảo sát.**

Không sửa trực tiếp đối tượng tuyến gốc của TDT.

---

# 2. Phát hiện quan trọng về cách TDT tạo tuyến

Qua quá trình sử dụng thực tế, hướng hoạt động của TDT có thể là:

```text
Polyline nguồn
      ↓
Chọn điểm đầu tuyến
      ↓
Xác định chiều tuyến
      ↓
TDT tạo Alignment / tim tuyến
      ↓
Phát sinh cọc
      ↓
Lý trình
```

Không nên chỉ tập trung vào `TDTDBALIGNMENT`.

Cần nghiên cứu **Polyline nguồn mà TDT dùng trước khi tạo Alignment**.

Nếu lấy được Polyline nguồn, BHT có thể xây dựng tuyến mà không cần phụ thuộc quá nhiều vào cấu trúc nội bộ của `TDTDBALIGNMENT`.

---

# 3. Hướng kiến trúc mới: POLYLINE-FIRST

BHT V5.0 cần thay đổi tư duy từ:

```text
TDTDBALIGNMENT
→ lấy hình học
→ tạo Polyline BHT
```

sang:

```text
Polyline nguồn
+
điểm đầu
+
chiều tuyến
+
cọc TDT
        ↓
BHT Route Model
```

`TDTDBALIGNMENT` vẫn được hỗ trợ, nhưng không còn là nguồn duy nhất.

---

# 4. Tuyến BHT phải lưu những gì

Mỗi tuyến BHT cần có hồ sơ riêng:

```text
route_id
route_name
source_type
source_handle
source_polyline_handle
source_alignment_handle
closed
start_point
start_parameter
direction
base_station
station_source
max_offset
created_at
updated_at
```

Đặc biệt phải lưu:

```text
start_point
start_parameter
direction
```

Bởi vì đây là những thông tin quyết định chiều lý trình.

---

# 5. Vấn đề Polyline kín

Nếu Polyline nguồn là đường kín (`Closed = Yes`) thì không thể chỉ dựa vào `GetDistAtPoint()` theo cách thông thường.

Ví dụ:

```text
A────B
│    │
D────C
```

Nếu điểm đầu là A:

```text
A → B → C → D
```

Nếu điểm đầu là C:

```text
C → D → A → B
```

Lý trình tại cùng một điểm sẽ khác nhau.

Do đó BHT phải coi:

```text
Polyline + StartPoint + Direction
```

là một tuyến hoàn chỉnh.

Không được coi riêng Polyline là tuyến.

---

# 6. Cách tính khoảng cách tuyến với Polyline kín

BHT nên xây dựng hàm:

```text
RouteDistance(point)
```

Thuật toán:

```text
dPoint = distance tại điểm trên Polyline
dStart = distance tại StartPoint
L = tổng chiều dài Polyline
```

Nếu chiều thuận:

```text
d = dPoint - dStart
nếu d < 0:
    d = d + L
```

Nếu chiều nghịch:

```text
d = dStart - dPoint
nếu d < 0:
    d = d + L
```

Kết quả:

```text
route_distance = d
```

Từ đó mới tính station hoặc nội suy theo các mốc khống chế.

---

# 7. Không giả định lý trình luôn bằng chiều dài hình học

BHT không được mặc định:

```text
1 m hình học = 1 m lý trình
```

Cần có hệ thống `Station Control Points`.

Ví dụ:

| Distance | Station |
|---:|---:|
| 0.000 | Km39+000 |
| 503.215 | Km39+500 |
| 1007.423 | Km40+000 |

Sau đó BHT nội suy:

```text
distance → station
```

theo từng đoạn.

Điều này cho phép xử lý nhảy Km, hiệu chỉnh lý trình, tuyến cũ, tuyến thay đổi chiều dài và các đoạn nối khác nhau.

---

# 8. Tận dụng cọc TDT

TDT sau khi tạo tuyến thường phát sinh cọc.

BHT V5.0 phải nghiên cứu cọc TDT như một nguồn dữ liệu quan trọng để tái tạo hệ lý trình.

Mục tiêu xác định được:

- tọa độ cọc;
- tên cọc;
- lý trình;
- loại cọc;
- thứ tự cọc;
- mối quan hệ giữa cọc và tuyến;
- Entity type của cọc;
- XData/XRecord/Attribute nếu có.

Nếu đọc được các dữ liệu này, BHT có thể tạo Station Control tự động.

Ví dụ:

```text
KM39+000 + tọa độ X/Y
→ project lên Polyline
→ geometry_distance = 0.000
→ station = 39000
```

```text
KM39+020
→ geometry_distance = 20.012
→ station = 39020
```

Từ đó xây:

```text
distance → station mapping
```

BHT dùng mapping này để tính lý trình cho điểm RTK, biển báo, cọc tiêu, cột Km, hố ga và công trình ven tuyến.

---

# 9. Nghiên cứu cách nhận diện Polyline nguồn

Agent phải nghiên cứu xem có thể xác định Polyline nguồn tự động không.

Các nguồn cần kiểm tra:

- layer;
- handle/reference;
- XData;
- ExtensionDictionary;
- Reactors;
- đối tượng liên kết với Alignment;
- độ trùng hình học với Alignment;
- vị trí cọc;
- tên tuyến;
- thứ tự tạo đối tượng;
- metadata TDT khác.

Không được tự chọn Polyline nếu độ tin cậy thấp.

Nếu không xác định chắc chắn, yêu cầu người dùng chọn Polyline nguồn và lưu:

```text
source_polyline_handle
start_parameter
direction
```

---

# 10. Hỗ trợ TDTDBALIGNMENT

Giữ nguyên khả năng đọc `TDTDBALIGNMENT` hiện có.

Khi đối tượng có thể đọc trực tiếp, BHT có thể:

- lấy hình học;
- kiểm tra chiều dài;
- so sánh với Polyline nguồn;
- tạo/cập nhật reference polyline;
- nghiên cứu thuộc tính station nếu có.

Không sửa Alignment gốc.

Nếu có Polyline nguồn đáng tin cậy thì ưu tiên Polyline nguồn làm geometry chính.

---

# 11. So sánh Polyline nguồn và Alignment TDT

BHT V5.0 cần kiểm tra:

```text
Source Polyline
vs
TDT Alignment
vs
BHT Route
```

Tính:

- tổng chiều dài;
- số vertex;
- extents;
- hướng tuyến;
- sai lệch vị trí;
- sai lệch cực đại;
- sai lệch trung bình/RMS.

Có thể sample 1 m / 5 m / 10 m tùy chiều dài tuyến.

Không tự coi hai tuyến giống nhau chỉ vì chúng cùng nằm gần nhau.

---

# 12. Tạo Route Wizard trong Palette BTH

Không yêu cầu người dùng nhớ nhiều lệnh.

Tất cả thao tác tuyến phải nằm trong Palette BTH.

Thẻ **TUYẾN** nên có quy trình:

1. Chọn Polyline nguồn.
2. Chọn điểm đầu tuyến.
3. Chọn chiều tăng lý trình.
4. Hiển thị preview mũi tên.
5. Tìm/đọc cọc TDT.
6. Hiển thị danh sách mốc lý trình tìm được.
7. Người dùng kiểm tra.
8. Tạo Route Model BHT.

Không đóng Palette trong quá trình chọn đối tượng.

---

# 13. Preview chiều tuyến

Sau khi chọn StartPoint, BHT phải hiển thị trực quan chiều thuận/nghịch trên CAD.

Có thể dùng transient graphics hoặc đối tượng tạm.

Người dùng chọn:

```text
Đúng chiều
Đảo chiều
```

Sau đó mới lưu route.

---

# 14. Tự phát hiện cọc

Sau khi tạo route, BHT có thể quét vùng quanh tuyến để tìm cọc có khả năng thuộc tuyến đó.

Không chỉ tìm theo layer.

Dùng kết hợp:

- khoảng cách tới tuyến;
- text Km;
- block name;
- attribute;
- XData;
- thứ tự station;
- hướng tuyến.

Hiển thị danh sách tìm được để người dùng xác nhận.

Không tự động đưa cọc bất thường vào Station Control.

---

# 15. Kiểm tra chuỗi lý trình cọc

Sau khi đọc cọc, BHT phải kiểm tra:

- station tăng đều?
- có cọc trùng station?
- có cọc ngược chiều?
- có khoảng nhảy Km?
- có cọc nằm quá xa tuyến?
- có text Km không đọc được?
- station có khớp thứ tự hình học?

Ví dụ:

```text
0 m  → Km39+000
20 m → Km39+020
40 m → Km39+040
60 m → Km39+300
```

Phải cảnh báo cọc cuối bất thường.

Không tự sửa station.

---

# 16. Hệ lý trình phải hỗ trợ Break

Station Control phải hỗ trợ các đoạn và không nội suy xuyên Station Break chưa được xác nhận.

```text
SEGMENT 1:
d0 → d1
station0 → station1

SEGMENT 2:
d1 → d2
station2 → station3
```

---

# 17. Tính vị trí công trình theo tuyến

Sau khi Route Model hoàn chỉnh, mỗi hồ sơ công trình có thể tính:

```text
nearest_point_on_route
route_distance
station
offset
side
```

Trong đó:

```text
offset = khoảng cách vuông góc tới tuyến
```

`side`:

```text
LEFT
RIGHT
ON_ROUTE
```

Phía trái/phải phải dựa trên chiều tăng lý trình.

---

# 18. Phía trái / phải tuyến

Khi có tangent vector của tuyến và vector từ nearest point tới object, dùng cross product để xác định phía.

Nếu `direction` bị đảo thì `LEFT/RIGHT` cũng phải đảo tương ứng.

Mọi hàm phía đường phải dùng Route Model.

---

# 19. Cọc phát sinh của BHT

BHT có thể tự phát sinh cọc tham chiếu, ví dụ mỗi 20 m hoặc tại Km tròn.

Phải phân biệt:

```text
TDT_STAKE
BHT_GENERATED_STAKE
```

Không ghi đè cọc TDT.

---

# 20. Không thay đổi dữ liệu RTK

Dù tuyến thay đổi, **không được di chuyển điểm RTK**.

Tuyến chỉ dùng để tính thêm:

```text
station
offset
side
```

POINT RTK X/Y/Z vẫn giữ nguyên.

---

# 21. Route Versioning

Tuyến phải có revision:

```text
route_revision = 1
```

Khi thay đổi Polyline, điểm đầu, chiều hoặc Station Control thì tăng revision.

Hồ sơ công trình lưu:

```text
station_route_revision
```

để phát hiện hồ sơ cần tính lại.

---

# 22. Quy trình cập nhật tuyến

Không xóa tuyến rồi tạo lại.

Khi source Polyline thay đổi, phát hiện geometry hash/length thay đổi.

Cho phép:

- cập nhật geometry;
- giữ Station Control nếu còn hợp lệ;
- kiểm tra lại cọc;
- tính lại station/offset.

Không làm mất `route_id`.

---

# 23. Chẩn đoán tuyến

Tạo công cụ:

```text
BHTROUTEDIAG
```

Báo:

```text
Route ID
Source Type
Polyline Handle
Alignment Handle
Closed
Length
Start Parameter
Direction
Station Source
Number of Control Points
Number of TDT stakes
Geometry verified
Last update
```

Có thể Zoom tới start point, mốc bất thường và cọc lỗi.

---

# 24. Giao diện tuyến trong BTH

Bảng Tuyến chia thành:

## THÔNG TIN TUYẾN
- Tên tuyến
- Nguồn hình học
- Chiều dài
- Điểm đầu
- Chiều tuyến

## STATION
- Lý trình đầu
- Số mốc
- Nguồn station

## CỌC
- Số cọc phát hiện
- Số cọc hợp lệ
- Số cảnh báo

## HÀNH ĐỘNG

```text
[Chọn Polyline]
[Chọn điểm đầu]
[Đảo chiều]
[Đọc cọc TDT]
[Kiểm tra tuyến]
[Cập nhật lý trình]
```

---

# 25. Giữ kiến trúc BHT hiện có

Không viết lại toàn bộ phần mềm.

Giữ:

- RTK
- TimeMark
- Photo linking
- Object profile
- Sign/block library
- Palette
- Report
- Segment/package

V5.0 mở rộng mạnh Route Model.

Các bản vẽ cũ phải tiếp tục đọc được.

Nếu cần schema mới thì migration có kiểm soát.

---

# 26. Liên kết Route với hồ sơ báo hiệu

Mỗi object profile sau V5.0 nên có:

```text
route_id
station
offset
side
route_revision
station_status
```

`station_status`:

```text
VALID
OUT_OF_RANGE
NO_ROUTE
NO_STATION_CONTROL
NEEDS_UPDATE
MANUAL
```

---

# 27. Báo cáo Excel

Báo cáo V5.0 bổ sung:

- Tuyến
- Lý trình
- Offset
- Phía
- Nguồn lý trình
- Trạng thái lý trình
- Route revision

---

# 28. Kiểm thử bắt buộc cho V5.0

Phải kiểm thử:

A. Polyline mở.  
B. Polyline kín.  
C. StartPoint tại vertex.  
D. StartPoint giữa segment.  
E. Chiều forward.  
F. Chiều reverse.  
G. Điểm trước điểm bắt đầu trên closed polyline.  
H. Cọc đều 20 m.  
I. Cọc có một station sai.  
J. Station break.  
K. Cập nhật Polyline nguồn.  
L. Đổi chiều tuyến.  
M. Tính left/right.  
N. Offset.  
O. Bản vẽ cũ chưa có Route Model V5.

---

# 29. Kiểm thử thực tế với TDT

Cần thử trên file thật:

1. Xác định Polyline dùng trước khi tạo tuyến TDT.
2. Ghi lại điểm đầu mà TDT sử dụng.
3. Ghi lại chiều tuyến.
4. Phát sinh cọc trong TDT.
5. Dùng BHT đọc cùng dữ liệu.
6. So sánh lý trình BHT với lý trình TDT.

Kiểm tra tại đầu tuyến, 25%, 50%, 75%, cuối tuyến và các cọc ngẫu nhiên.

Báo sai số.

---

# 30. Không tự nhận đã hiểu TDT

Agent không được giả định cách TDT hoạt động chỉ dựa trên tên file/class.

Phải quan sát dữ liệu thực tế.

Nếu phát hiện workflow khác giả thuyết này, ghi lại phát hiện và điều chỉnh Route Adapter.

---

# 31. Mục tiêu cuối cùng của Route V5.0

Người dùng:

```text
Mở DWG
→ BTH
→ TUYẾN
→ Tạo tuyến
→ chọn Polyline
→ click điểm đầu
→ chọn chiều
→ BHT tìm cọc TDT
→ kiểm tra
→ Xác nhận tuyến
```

Sau đó BHT tự tính:

```text
Km
offset
trái/phải
```

cho các hồ sơ khảo sát.

Người dùng không cần hiểu `TDTDBALIGNMENT`, Handle, RXClass hoặc chi tiết kỹ thuật khác.

---

# 32. Nguyên tắc phiên bản

Phiên bản đang build tiếp theo:

# BHT V5.0

Phải đồng bộ V5.0 trong:

- Lisp
- .NET Core
- Bridge
- Palette
- VERSION
- Palette title
- Bundle
- Installer
- README
- CHANGELOG
- Test Report

Nếu build bản bàn giao mới sau V5.0 thì phải tăng version.

Không phát hành nhiều file khác nhau cùng tên V5.0.

---

# 33. Việc Agent cần làm đầu tiên

Không code ngay từ giả thuyết.

Thực hiện:

1. Audit phần Route hiện tại.
2. Audit `Tdt91Interop` hiện tại.
3. Xác định schema route hiện tại.
4. Thiết kế migration V5.
5. Viết công cụ chẩn đoán Polyline/Alignment/Cọc.
6. Kiểm tra một file TDT thực tế.
7. Xác nhận workflow thực tế.
8. Sau đó mới triển khai Route Model V5.
9. Viết test.
10. Build.
11. Test AutoCAD.
12. Báo cáo sai số so với TDT.

---

# 34. Tóm tắt triết lý thiết kế

BHT V5.0 phải đi theo:

```text
POLYLINE-FIRST
+
START POINT
+
DIRECTION
+
STATION CONTROL
+
TDT STAKES
```

thay vì chỉ:

```text
TDTDBALIGNMENT → EXPLODE
```

Mục tiêu không chỉ là “lấy được tim”, mà là:

```text
lấy đúng hình học
+
đúng điểm đầu
+
đúng chiều
+
đúng hệ lý trình
+
đúng phía trái/phải
+
cập nhật được khi tuyến thay đổi
```

Đó là nền tảng để toàn bộ BHT quản lý biển báo, cọc tiêu và công trình theo lý trình chính xác.
