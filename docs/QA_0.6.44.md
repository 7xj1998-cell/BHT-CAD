# Kiểm tra 0.6.44

- Core: 233 PASS.
- Thay đổi bỏ đăng ký DocumentCreated, DocumentActivated và Idle của bộ nâng cấp ký hiệu; hàm tương thích BHTSYMBOLUPGRADESCHEDULE trả về 0.
- Kiểm tra hồi quy đo ObjectModified/ObjectAppended khi Initialize, Ready và Terminate trên bản vẽ có dữ liệu phiên bản cũ; sau đó kiểm tra cập nhật chủ động.
- Crash gốc được sao lưu tại D:lispBHTcrash-20261010-1805. Phân tích chỉ xác định module/hàm native và quét các địa chỉ stack, không phải kết luận nguyên nhân từ stack managed.
- Kiểm thử CoreConsole không thay thế thử mở CAD đồ họa thực tế. Chưa xác nhận crash gốc hết trên cùng bản vẽ và môi trường plugin của người dùng.
- Đạt: startup-does-not-modify-old-drawing, explicit-acedInvoke-upgrade, current-drawing-no-repeat-upgrade và future-drawing-not-downgraded. Kiểm tra tích hợp thư viện 467 mẫu: SIGN INTEGRATION PASSED.
