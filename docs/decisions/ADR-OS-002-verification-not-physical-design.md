# ADR-OS-002 — Ngách chiến lược là verification, không phải physical design

**Trạng thái:** Chấp nhận (2026-09-14)

**Bối cảnh:** Physical design mã nguồn mở cho chất lượng kết quả thấp hơn
công cụ thương mại và bị chặn ở khâu ký duyệt DRC/LVS.

**Quyết định:** Đặt trọng tâm vào verification / mô phỏng / kiểm thử — thuần
phần mềm, nằm trước hàng rào chứng nhận, thâm dụng lao động trí tuệ.

**Hệ quả:** Physical design vẫn được học để hiểu quy trình, nhưng không phải
mảng để xây năng lực cạnh tranh.

Nguồn: `docs/OPEN_SILICON_KICKOFF.md` §3.2, §7.
