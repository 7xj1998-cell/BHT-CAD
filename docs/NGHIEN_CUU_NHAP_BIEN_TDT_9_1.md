# Nghiên cứu nhập biển báo TDT 9.1 và áp dụng cho BHT

Ngày 01/10/2026. Chỉ đọc tài nguyên cài đặt tại `C:/Program Files (x86)/TDT Solution 2022`; không sửa file TDT.

## Bằng chứng trên máy

Tài liệu `A.TÍNH NĂNG MỚI TDT9.1-28-12-2023.docx` xác nhận mô-đun vạch sơn/biển báo và dẫn video chính thức https://www.youtube.com/watch?v=1Ffl8DBb0cw, trang sản phẩm https://tdttech.com.vn/vi/phan-mem/148-vnroad-9-1. Hai URL chưa đọc được do lỗi 429/throttling, không dùng chúng để khẳng định chi tiết giao diện.

Menu `RM.cuix`, phần MenuGroup.cui có lệnh:

| Menu | Lệnh |
|---|---|
| Cài đặt biển báo | CDBB |
| Quản lý Biển báo giao thông | BBGT |
| Cập nhật lý trình biển báo | CNLTBB |
| Thống kê biển báo giao thông | TKBBGT |
| Tạo tuyến biển báo | TTBB |
| Hiệu chỉnh tuyến biển báo | HCTBB |

Chuỗi hộp thoại/prompt trong `RoadSignsUI.arx` có: “Chèn biển báo ATGT”, “Nhóm biển báo”, “Chèn biển theo tim đường”, “Chèn biển tự do”, “Cọc treo biển”, “Vị trí tên biển”, “Hướng quay biển báo với chiều đi”, “Mặt đối diện”. Cài đặt có “Cao chữ”, “Tỉ lệ block biển”, “Kích thước cọc”, “Hiện block cọc”, “Tỉ lệ block cọc”; cọc gồm đơn/đôi/ba và tay vươn. Prompt tuyến có chọn tuyến, vị trí cọc, điểm trung gian và vị trí chèn biển. Cấu trúc quản lý có loại biển, lý trình, vị trí so với tim tuyến, liên kết biển và bảng thống kê.

`Data/Bien bao/Bienbao.xml` tách nhóm `dataSource` DWG và `imgSource` thư mục ảnh CAM/CHI DAN/HIEU LENH/NGUY HIEM/PHU. `bienbao.set` chứa năm DWG mặt biển; `CocTreoBien.dwg` là tài nguyên cọc riêng. BHT đọc được 412 mục; tìm được 292 thumbnail tương ứng. Các mã không có ảnh vẫn chọn được bằng tên/mã.

Đây là bằng chứng về các điều khiển và cấu trúc, không chứng minh thứ tự click hay các giá trị mặc định khi chạy. Đã thử mở TDT cài sẵn qua Computer Use: AutoCAD mở Drawing1 mới nhưng bị hộp lỗi “Exception in ...projectdh.arx ARX Command”; không tiến hành chèn vào bản vẽ người dùng. Vì vậy chưa quay lại hay kiểm thử được toàn bộ luồng TDT trực tiếp.

## Áp dụng và giới hạn

| Hành vi TDT có bằng chứng | BHT |
|---|---|
| Thư viện theo nhóm, có ảnh riêng | Giữ tìm không dấu và bộ lọc; v0.5.2 thêm ảnh chọn lớn, tên/nhóm bên cạnh. |
| Biển và cọc treo là hai tài nguyên riêng | Hồ sơ phân biệt số trụ và số mặt; v0.5.2 sửa nhiều mặt trong cùng một hộp thoại. |
| Theo tim đường hoặc tự do, hướng quay với chiều đi | Dùng Route Model hiện có; có tuyến thì lấy tiếp tuyến, phía đường; chưa có tuyến thì chèn theo tọa độ hiện tại. |
| Lý trình/vị trí/quản lý và thống kê | Giữ quan hệ hồ sơ–RTK–tuyến–ảnh, tránh chỉ lưu block rời. |
| Tỉ lệ biển và cọc, cao chữ riêng | Giữ chuẩn hóa mặt biển 1.8 đơn vị CAD; không bê kích thước biển thật vào bình đồ. |

Nhập tốc độ P.127, giữ mô tả khảo sát và thao tác hủy an toàn là cải tiến của BHT, chưa có bằng chứng TDT hỗ trợ y hệt. Không gán các cải tiến này cho TDT. Các dạng cọc tay vươn, vị trí tên bốn phía, vẽ chồng mọi mặt trên cọc và bố trí hàng loạt theo tuyến chưa được bổ sung trong v0.5.2; cần mô hình hình học và tiêu chí nghiệm thu riêng.

## Phông thực tế

`D:/AutoCAD 2024/Fonts/VNRomancUpdate.shx`: 25.408 byte, SHA256 `B4A515F04E45915E6E2ECA3D19B87C03083EF791F7729E80BE74B311D65993AC`, header unifont 1.0. Có glyph U+00CA/U+00EA/U+1EBE/U+1EC6; không có glyph TCVN 0xA3/0xAA. Phông vnromanc cũ là shapes 1.1. Do đó tên phông mới không thể ghép với bảng mã TCVN3. BHT dùng Unicode NFC cho phông mới và giữ đường chuyển TCVN3 cho kiểu cũ.

## Cập nhật v0.5.3 từ phản hồi người dùng

Người dùng xác nhận: TDT khi chèn tự do cho chọn hướng biển và chọn điểm trung gian. Đây là thông tin từ người dùng, bổ sung cho các prompt trong RoadSignsUI.arx (“Điểm trung gian ... hoặc Xóa điểm (X)/Vị trí chèn biển báo(V)”, “Hướng quay biển báo với chiều đi”). BHT v0.5.3 đã thêm luồng chọn hướng → điểm trung gian → vị trí biển; lưu cấu hình theo hồ sơ và giữ qua đồng bộ. Chi tiết thao tác/kiểm tra nằm trong RELEASE_NOTES_0.5.3.md.
