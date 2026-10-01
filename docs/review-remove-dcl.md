# Review: Xóa giao diện DCL dự phòng khỏi BHT

**File cần sửa:** `src/lisp/BHT-0.5.4.lsp`  
**Phiên bản hiện tại:** 0.5.4  
**Phiên bản sau khi sửa:** 0.5.5 (sửa lỗi / refactor)  
**Lý do:** Người dùng phân phối BHT qua file cài đặt (bundle) — khi đã có Palette .NET không cần DCL dự phòng. Xóa để giảm ~250 dòng code không sử dụng.

---

## Phạm vi xóa

### 1. Xóa toàn bộ section DCL (dòng 6373–6718)

Section này bắt đầu bằng comment:
```lisp
;;; ----------------------------------------------------------------------
;;; Bang dieu khien DCL du phong - tao tam khi go BHTDCL
```
Kết thúc sau `(defun c:BHTUITEST ...)`.

**Các hàm và biến cần xóa — theo thứ tự xuất hiện trong file:**

| Tên | Loại | Ghi chú |
|:----|:-----|:--------|
| `bht:ansi-roundtrip` | defun | Test encoding cho DCL |
| `bht:dcl-unicode-file-p` | defun | Kiểm tra UTF-8 cho file DCL |
| `bht:dcl-escape` | defun | Escape chuỗi nhúng vào DCL |
| `bht:ui-status` | defun | Chuỗi 1 dòng tương thích 0.3.1 — chỉ DCL gọi |
| `*bht-ui-buttons*` | setq | Bảng nút của DCL |
| `bht:ui-captions` | defun | Caption text cho DCL |
| `bht:ui-fill-line` | defun | Điền caption vào template DCL |
| `bht:ui-step-row` | defun | Render hàng nút trong DCL |
| `bht:ui-dcl-template` | defun | Template chuỗi `.dcl` |
| `bht:ui-write-dcl` | defun | Ghi file `.dcl` tạm ra TEMPPREFIX |
| `bht:ui-apply-captions` | defun | Gọi `set_tile` điền caption |
| `bht:ui-bind` | defun | Gọi `action_tile` gán nút |
| `bht:ui-dialog` | defun | Mở/đóng dialog `load_dialog`/`start_dialog` |
| `bht:ui-call` | defun | Gọi lệnh được chọn từ DCL |
| `c:BHTDCL` | defun c: | **Lệnh người dùng — xóa** |
| `bht:ui-validate` | defun | Dùng trong test DCL |
| `c:BHTUITEST` | defun c: | **Lệnh người dùng — xóa** |

> **QUAN TRỌNG — KHÔNG XÓA:**  
> `bht:fold-vi` (nằm trong cùng vùng code, dòng ~6401) **phải giữ lại**.  
> Hàm này bỏ dấu tiếng Việt, được dùng bởi `bht:search-fold` trong module tìm kiếm biển báo (`bht:bb-code-key`, `bht:bb-search`).  
> Nếu cần, dời `bht:fold-vi` lên trước section biển báo (khoảng dòng 4700) để tránh nhầm lẫn.

> **QUAN TRỌNG — KHÔNG XÓA:**  
> `bht:status-data`, `bht:status-notes`, `bht:status-lines` — được dùng bởi `c:BHTTRANGTHAI`. Các hàm này nằm xen kẽ trong section DCL (dòng ~6438–6482) nhưng **không phải code DCL**, phải giữ nguyên.

---

### 2. Sửa 2 chuỗi trong `c:BHTLOAD` (dòng ~6917–6925)

**Hiện tại:**
```lisp
(defun c:BHTLOAD ()
  (if (bht:palette-load)
    (bht:msg "BHT: Palette đã sẵn sàng. Gõ BTH hoặc BHT để mở bảng.")
    (progn
      (bht:warn "BHT: không nạp được Palette.")
      (bht:msg (strcat "  Kiểm tra BHT.Palette.dll, BHT.Bridge.dll và BHT.Core.dll nằm cạnh BHT-" *bht-version* ".lsp."))
      (bht:msg "  Có thể dùng bảng dự phòng bằng lệnh BHTDCL.")))  ; <-- XÓA DÒNG NÀY
  (princ)
)
```

**Sau khi sửa:** Xóa dòng `(bht:msg "  Có thể dùng bảng dự phòng bằng lệnh BHTDCL.")`.

---

### 3. Sửa chuỗi thông báo lúc nạp (dòng ~6936)

**Hiện tại:**
```lisp
(if *bht-palette-loaded*
  (princ "\nGõ BTH hoặc BHT để mở Palette bên trái; BHTHELP để xem danh sách lệnh.")
  (princ "\nCHƯA nạp được Palette. Gõ BHTLOAD để thử lại hoặc BHTDCL để mở bảng dự phòng."))
```

**Sau khi sửa:**
```lisp
(if *bht-palette-loaded*
  (princ "\nGõ BTH hoặc BHT để mở Palette bên trái; BHTHELP để xem danh sách lệnh.")
  (princ "\nCHƯA nạp được Palette. Gõ BHTLOAD để thử lại; kiểm tra DLL nằm cạnh file Lisp."))
```

---

### 4. Sửa chuỗi trong `bht:help-text` (dòng ~6365)

**Hiện tại:**
```lisp
"  BHTDCL       Bảng DCL dự phòng   BHTLOAD  Kiểm tra / nạp lại Palette"
```

**Sau khi sửa:** Xóa phần `BHTDCL`, giữ `BHTLOAD`:
```lisp
"  BHTLOAD  Kiểm tra / nạp lại Palette"
```

---

### 5. Sửa comment header (dòng 11)

**Hiện tại:**
```lisp
;;;  - bang dieu khien DCL (v0.3).
```

**Sau khi sửa:** Xóa dòng này hoặc đổi thành:
```lisp
;;;  - giao dien .NET Palette (v0.4.3+); DCL da bị loại bỏ từ 0.5.5.
```

---

## Kiểm tra sau khi sửa

Chạy lại bộ test để xác nhận không có regression:

```
tests/IntegrationTests/test_V5.lsp
tests/IntegrationTests/test_SIGN.lsp
tests/IntegrationTests/test_TCVN.lsp
tests/IntegrationTests/test_TX.lsp
```

Kết quả mong đợi:
- `c:BHTDCL` → không còn tồn tại → test nào đang gọi BHTDCL phải được cập nhật hoặc xóa
- `c:BHTUITEST` → không còn tồn tại → tương tự
- `bht:fold-vi` → vẫn hoạt động bình thường (test tìm kiếm biển báo)
- `c:BHTTRANGTHAI` → vẫn hiển thị đầy đủ trạng thái (dùng `bht:status-data`)
- `c:BHTLOAD` → không còn in ra "BHTDCL"

---

## Ghi CHANGELOG

Thêm entry mới vào `CHANGELOG.md`:

```markdown
## 0.5.5 (YYYY-MM-DD)

- Loại bỏ giao diện DCL dự phòng (`BHTDCL`, `BHTUITEST`, `bht:ui-*`, `bht:dcl-*`,
  `bht:ansi-roundtrip`, `*bht-ui-buttons*`): không cần thiết khi phân phối
  qua Application Bundle kèm Palette .NET. Giảm ~250 dòng code.
- Giữ `bht:fold-vi`, `bht:status-data`, `bht:status-lines`, `bht:status-notes`,
  `c:BHTTRANGTHAI` — không liên quan đến DCL.
- Cập nhật thông báo `BHTLOAD` và thông báo lúc nạp Lisp.
```

---

## Tóm tắt thay đổi

| Hạng mục | Trước | Sau |
|:---------|------:|----:|
| Tổng dòng | 6.939 | ~6.690 |
| Lệnh người dùng (`c:BHT*`) | 69 | **67** (bỏ `BHTDCL`, `BHTUITEST`) |
| Hàm nội bộ (`bht:*`) | 411 | ~397 |
