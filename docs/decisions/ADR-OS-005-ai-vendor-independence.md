# ADR-OS-005 — Kiến trúc không phụ thuộc một nhà cung cấp AI

**Trạng thái:** Chấp nhận (2026-09-14)

**Bối cảnh:** Quy trình của nhóm dựa nhiều vào AI. Rủi ro gián đoạn là thật —
đã có tiền lệ: Anthropic tạm ngưng truy cập Fable/Mythos 12–30/06/2026 để
tuân thủ kiểm soát xuất khẩu, khôi phục 01/07/2026.

**Quyết định:**
(a) Dùng lớp API tương thích OpenAI để đổi nhà cung cấp chỉ là sửa biến môi
trường (xem `.env.example`);
(b) Toàn bộ prompt và quy ước lưu dạng Markdown trong Git;
(c) Xây bộ eval riêng 10–20 bài toán thật;
(d) Diễn tập một tuần không dùng AI mỗi quý và ghi lại mức sụt năng suất.

**Hệ quả:** Kịch bản xấu nhất là "AI yếu hơn và phải tự chạy" (model
open-weight như Qwen3.8-27B Apache 2.0 chạy được trên một GPU 24GB), không
phải "không có AI".

**Rủi ro lớn hơn cần theo dõi:** phụ thuộc nhận thức. Nếu sau 12 tháng nhóm
không tự đọc được file Liberty, không tự gỡ được lỗi timing, thì AI đang là
*nạng* chứ không phải *người thầy*.

Nguồn: `docs/OPEN_SILICON_KICKOFF.md` §7, §10.
