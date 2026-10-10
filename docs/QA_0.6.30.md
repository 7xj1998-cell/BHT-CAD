# Kiểm tra BHT 0.6.30

- Build DLL x64 bằng .NET Framework 4.8 với tham chiếu AutoCAD 2024; Core: 178 PASS.
- Giao diện WinForms trong Core Console: 149 PASS, gồm nút xóa bị khóa khi tạo mới/đang chạy, được bật cho hồ sơ đã lưu và đặt ngoài vùng cuộn; hồi quy vị trí cuộn, chọn biển modeless và tỷ lệ RTK.
- CAD/thư viện: tô màu tắt/bật ở năm nhóm; bản chỉ nét không có hatch/solid hiển thị, nền MText hoặc bề rộng polyline. Bản màu gốc không bị sửa.
- Cập nhật: thay block cũ giả lập mang tên V0627 bằng V0630; giữ transform không đồng nhất, góc xoay, XData TU_DONG/TAY, toàn bộ hồ sơ và RTK; giữ lựa chọn không tô màu. Không tạo ký hiệu của hồ sơ chưa đặt. Gọi qua acedInvoke giống đường chạy khi tự nạp; dấu hiện tại không cập nhật lặp, dấu phiên bản tương lai không bị hạ.
- Xóa: ID thường/hoa hoạt động; xóa hồ sơ và toàn bộ ký hiệu/nhãn/đường nối, giữ RTK/hồ sơ khác/ảnh gốc, gỡ đúng liên kết ngược của ảnh. ID rỗng/đã xóa trả lỗi và không đổi dữ liệu.
- Hồi quy các biển tham số, Unicode, G/T, đặt theo tuyến, nhiều mặt, hai trụ/hai chân, nhãn đèn bên dưới và IE.472a/b. Kiểm tra không có TDT vẫn dùng mẫu native; kiểm tra trọng lượng S.505a trong thư viện đầy đủ.
- Bộ cài: kiểm tra manifest/SHA-256, đường dẫn thoát gói, sao lưu và rollback trên fixture riêng; kiểm tra bộ cài một file và khóa nút cài sau thành công.
- Hình R.415 xuất qua DWG To PDF, render bằng MuPDF; đối chiếu sáu hình xe và đường cong ở cả hai chế độ. Đã chỉnh lại việc khớp cung qua các góc thẳng trước khi chấp nhận mẫu.

Giới hạn: chưa cài lên bundle đang dùng, chưa chạy sự kiện Idle trong AutoCAD giao diện đầy đủ. Kịch bản Core Console gọi trực tiếp cùng bộ điều phối cập nhật, không mô phỏng toàn bộ thứ tự sự kiện mở DWG. Không chỉnh sửa bản vẽ khảo sát thật; các kiểm tra CAD dùng bản vẽ trống và profile riêng. AutoCAD 2021–2023 chưa được chạy kiểm thử.
