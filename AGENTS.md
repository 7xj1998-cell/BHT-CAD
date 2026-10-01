# Quy tắc làm việc với BHT

- Mỗi lần thay đổi chức năng, sửa lỗi hoặc tạo bản phát hành mới phải tăng phiên bản `major.minor.patch`; sửa lỗi tăng `patch` tối thiểu. Một đợt sửa và kiểm tra cùng yêu cầu dùng một phiên bản mới.
- Phiên bản hiện tại lấy từ `VERSION`. Dùng `scripts/set-version.ps1 -Version <phiên-bản-mới>` để đồng bộ Lisp, DLL, bundle và bộ cài; không phát hành mã đã thay đổi dưới số phiên bản cũ.
- Ghi thay đổi vào CHANGELOG và kiểm tra `scripts/check-version.ps1` trước khi build/phát hành. `scripts/package.ps1` kiểm tra phiên bản DLL và chặn tái phát hành cùng số phiên bản nếu nội dung đã đổi, dựa trên RELEASE_STATE.json.
- Chữ CAD mặc định: `VNRomancUpdate.shx`, bảng mã Unicode NFC. Kiểu tùy chỉnh cũ dùng `vnromanc.shx` vẫn chuyển TCVN3 tại lớp hiển thị TEXT; hồ sơ/XRecord/XData, Palette, tìm kiếm và báo cáo giữ Unicode.
- Giữ các sửa đổi và tài liệu trước đó của người dùng. Không sửa tài nguyên TDT gốc.
