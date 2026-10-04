# Kiểm tra BHT 0.6.11

Ngày kiểm tra: 2026-10-05. Môi trường: AutoCAD Core Console 2024, .NET Framework 4.8, Windows.

| Phạm vi | Kết quả |
|---|---|
| BHT.CoreTests | 154 PASS, 0 FAIL |
| Hình học và nội dung biển/cọc trong AutoCAD | 39 PASS, 0 FAIL |
| Thư viện WinForms | 378 ảnh thật, 0 ảnh thiếu; chọn biển, nội dung I.439, nhập mét và chọn góc đạt |
| Lisp ký hiệu và đặt tự do | SIGN-TEST-FAIL=0, FREE-INPUT-FAIL=0 |
| Unicode và SHX | TCVN-TEST-FAIL=0 |
| Khôi phục sau mở DWG | SIGN0610-REOPEN-FAIL=0 |
| Bộ cài trên bộ dữ liệu thử riêng | 7 PASS |

## Các tình huống kiểm tra

- Đặt cọc tiêu, chọn hướng lên/xuống/trái/phải: đầu đỏ theo đúng hướng chọn. Kiểm tra UCS xoay 30°, ANGBASE khác 0 và ANGDIR=1. Chọn hướng trùng điểm chèn hủy thao tác, hồ sơ giữ nguyên.
- Mặt biển mặc định nằm theo hướng chọn. Block tùy chỉnh giữ quy ước trục X của block.
- Cọc Km có hoặc không ghi số dùng tâm thanh đuôi làm điểm chèn. Kiểm tra tâm này với các góc 0°, 90°, 180°, -90° và tỷ lệ 2,5.
- Nhãn H9/39 vẫn hiện ngang cạnh đầu cọc. Cọc tiêu chưa có lý trình và mọi cọc Km không tạo nhãn ngoài; nhãn BHT cũ thuộc các trường hợp này được xóa.
- Nhập Km 46/H 1 tự ghi Km46+100 khi tạo/lưu hồ sơ; thay H cập nhật lý trình. Tắt số Km chỉ xóa lý trình do các ô Km/H tạo ra. Liên kết RTK, ảnh và tuyến được giữ.
- I.439 giữ ba đường viền hình mẫu, phông giaothong1.ttf, nền xanh và chân trụ. Hai dòng chữ nằm trong biển, nội dung Unicode được giữ và viền/chữ trắng đúng màu khi xuất PDF bằng bộ in AutoCAD.
- R.415a/b, W.239a/b, W.205c và W.207a giữ đúng hình đã sửa; tô màu/không tô màu, nhiều mặt cùng trụ, nhập tốc độ và giá trị mét đạt.

Bản sao mới từ 15doan.dwg được dùng để test. SHA256 bản gốc trước và sau:
`22697AE97EF4A7781A5CDAB8BD2DC43DE8258DCED2BB230ADDE9068C8CA825F3`.

DLL kiểm tra trong AutoCAD được đối chiếu SHA256 với DLL đưa vào gói. Gói không chứa bản vẽ khảo sát, ảnh hiện trường hay DLL Autodesk.

Các bài kiểm tra CAD chạy bằng AutoCAD Core Console, có các lượt chọn điểm qua lời nhắc lệnh và xuất PDF bằng bộ in AutoCAD. Các kiểm tra WinForms chạy riêng. Chưa thay DLL trong phiên AutoCAD đang mở của người dùng; cần đóng CAD và cài gói mới.