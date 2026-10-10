# Kiểm tra 0.6.47
- Core chạy cùng DLL sau Obfuscar: 233 PASS.
- FAS + DLL sau xử lý: SIGN INTEGRATION PASSED với thư viện 467 mẫu; native picker PASS.
- Giao diện sau xử lý: 683 PASS.
- Đèn, nhóm mới và trụ mất biển: PASS, dùng RuntimePath FAS.
- Obfuscar 2.2.50 giữ public API và tên property/event, chỉ xử lý Core/Bridge. Palette giữ nguyên. Mapping/debug không đưa vào gói khách.
- Không tuyên bố sửa crash native hay tăng tốc mọi thao tác. Chưa thử trên tất cả đời AutoCAD, chưa ký số.
