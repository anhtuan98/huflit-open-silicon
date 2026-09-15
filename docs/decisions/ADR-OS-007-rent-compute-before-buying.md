# ADR-OS-007 — Thuê compute theo giờ trước khi mua server thật

**Trạng thái:** Chấp nhận (2026-09-16)

**Bối cảnh:** Kickoff doc §5.2 đã ước lượng cấu hình một máy chủ regression
tương lai (16-32 nhân, 128-256GB RAM) nhưng chưa chốt *khi nào* mua, chỉ
ghi "không sớm hơn GĐ1". ADR-OS-006 đã phân bổ ~20% ngân sách cho compute
nhưng chưa nói rõ compute đó đến từ đâu. Nhu cầu tính toán nặng thật sự đã
xuất hiện ngay trong Giai đoạn 0 (chạy `picorv32` trọn LibreLane + kiểm
tra determinism — xem `docs/picorv32-cloud-burst-plan.md`), trong khi
nhân sự và tài chính chương trình còn chưa ổn định (rủi ro "người dẫn
nghỉ việc" đã ghi trong kickoff doc §10).

**Quyết định:** Trong Giai đoạn 0-1, thuê VM cloud theo giờ (ví dụ Linode
Dedicated CPU) cho các tác vụ tính toán nặng, thay vì mua server vật lý
ngay. Chỉ cân nhắc mua/tự vận hành máy chủ riêng khi chương trình **tự
nuôi sống được về tài chính** — mốc cụ thể chưa xác định, sẽ ghi bổ sung
vào đây khi tới lúc.

**Hệ quả:** Tiết kiệm vốn đầu tư ban đầu và chi phí bảo trì phần cứng
(điện, làm mát, không gian, thay linh kiện) trong giai đoạn còn nhiều rủi
ro nhân sự/tài chính. Đánh đổi: phát sinh chi phí thuê lặp lại theo mỗi
lần dùng, và bắt buộc phải thiết kế kỹ quy trình mỗi lần thuê — cấu hình
nhanh, rút dữ liệu nhanh, giải phóng tài nguyên ngay — để không lãng phí
tiền thuê vào thời gian chờ/debug (xem `docker/cloud-burst/` và
`docs/picorv32-cloud-burst-plan.md` cho quy trình đang áp dụng). Không
kiểm soát được phần cứng vật lý, nhưng chấp nhận được vì đây là workload
tính toán theo lô (batch), không phải dịch vụ cần zero-downtime.

Nguồn: `docs/OPEN_SILICON_KICKOFF.md` §5.2, `docs/decisions/ADR-OS-006-no-lab-equipment.md`.
