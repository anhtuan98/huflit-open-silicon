# HUFLIT Open Silicon — Khởi động LibreLane & Verification

| | |
|---|---|
| **Mã tài liệu** | `OPEN_SILICON_KICKOFF.md` |
| **Phiên bản** | v0.1 (bản thảo đầu tiên) |
| **Ngày** | 2026-09-14 |
| **Chủ sở hữu** | Nguyễn Anh Tuấn — Phó Chủ tịch Hội đồng trường HUFLIT |
| **Trạng thái** | Draft — chờ xác định nhân sự dẫn dắt (xem §11) |
| **Nguồn sự thật** | `PROJECT_INSTRUCTIONS.md` là nguồn sự thật cho các quyết định đang tiến hóa. Tài liệu này là bản chuyên đề. |

---

## 0. Cách dùng tài liệu này

Đây là tài liệu **khởi động**, không phải đề án. Nó tồn tại để:

1. Ghi lại bối cảnh và các dữ kiện đã khảo sát, kèm nguồn, để không phải khảo sát lại.
2. Chốt định vị chiến lược và **những gì không làm**.
3. Đưa ra lộ trình có cổng nghiệm thu (stage gate) — mỗi cổng không qua thì dừng.
4. Ghi các quyết định dưới dạng ADR để người tiếp nhận sau này hiểu *vì sao*, không chỉ *cái gì*.

Mọi con số có gắn ngày tháng đều cần **xác minh lại** trước khi dùng để ra quyết định. Hệ sinh thái này thay đổi nhanh.

---

## 1. Mục tiêu và phi mục tiêu

### 1.1 Mục tiêu

Đưa HUFLIT tham gia **thật** vào chuỗi giá trị vi mạch mã nguồn mở, ở khâu mà lao động trí tuệ chi phí thấp có lợi thế cạnh tranh, với sản phẩm bàn giao **hoàn toàn ở dạng số, chuyển giao qua mạng**.

Thành công trong 24 tháng được định nghĩa là: **tên HUFLIT xuất hiện trong danh sách đóng góp của ít nhất hai dự án quốc tế, và có một quan hệ hợp tác chính thức với một tổ chức trong hệ sinh thái.**

### 1.2 Phi mục tiêu (quan trọng ngang mục tiêu)

Những điều **không** nằm trong phạm vi, và không được phép trở thành mục tiêu vì áp lực thành tích:

- ❌ Mở ngành đào tạo Thiết kế vi mạch.
- ❌ Thành lập trung tâm, phòng thí nghiệm vật lý, hay bất kỳ đơn vị có biên chế nào trong 12 tháng đầu.
- ❌ Mua sắm thiết bị đo đạc (oscilloscope, SMU, trạm rework) — mô hình này thuần phần mềm.
- ❌ Chế tạo chip thương mại, hoặc bất kỳ sản phẩm nào cần ký duyệt ở node tiên tiến.
- ❌ Cạnh tranh trực tiếp với FPT Semiconductor, Viettel, hay các trung tâm FDI trong mảng dịch vụ verification thương mại.
- ❌ Tổ chức lễ ra mắt, thông cáo báo chí, hoặc công bố truyền thông trước khi có bằng chứng kiểm chứng được.

> **Nguyên tắc nền:** không nhầm chuyển động với tiến bộ. Lễ ra mắt là chuyển động. Một pull request được merge là tiến bộ.

---

## 2. Bối cảnh hệ sinh thái (khảo sát 09/2026)

### 2.1 Công cụ

| Thành phần | Trạng thái |
|---|---|
| **LibreLane** | Luồng RTL→GDSII chính. Fork của OpenLane do **FOSSi Foundation** tiếp quản, viết lại trên nền Python, tương thích ngược với config OpenLane. Apache 2.0. |
| **OpenLane** | **Legacy.** Efabless đóng cửa 03/2025; chỉ còn vá lỗi nghiêm trọng, không khuyến nghị cho dự án mới. |
| Yosys / OpenROAD / Magic / KLayout / ngspice | Các công cụ thành phần bên dưới LibreLane. |
| **Verilator, cocotb** | Mô phỏng và testbench. **Đang được dùng trong quy trình thương mại thật.** |
| IIC-OSIC-TOOLS (ĐH Linz, Áo) | Container Docker gói sẵn toàn bộ chuỗi công cụ. **Điểm khởi đầu khuyến nghị.** |

Kiến trúc LibreLane theo mô hình **Step → Flow → State**, chụp snapshot cấu hình ở từng bước, mục tiêu: *cùng tool, cùng flow, cùng config → cùng kết quả*. Tính tái lập này là nền tảng cho CI và cho giảng dạy.

### 2.2 PDK

| PDK | Ghi chú |
|---|---|
| SKY130 (Mỹ) | Trưởng thành nhất, nhiều IP đã hardening. |
| GF180MCU | 180nm. |
| **IHP SG13G2 (Đức)** | 130nm BiCMOS — **PDK mở đầu tiên của châu Âu**, làm được cả analog/RF. Trạng thái alpha/preview, chưa dùng cho sản xuất thương mại. IHP tài trợ suất MPW miễn phí cho thiết kế mã nguồn mở phi thương mại dưới 2mm². |

### 2.3 Tổ chức và cộng đồng

- **FOSSi Foundation** — trực tiếp hỗ trợ **cocotb, LibreLane, Embench**. Tổ chức ORConf. Từng là tổ chức bảo trợ Google Summer of Code. Có bản tin **El Correo Libre**.
- **IHP (Leibniz Institute, Đức)** — chủ PDK châu Âu; 07/2026 công bố Open ADK cho chiplet 2.5D.
- **CHIPS Alliance** — 03/2026 lập SV Tools Project cho hạ tầng SystemVerilog/UVM mã nguồn mở.
- **OpenHW Foundation** — 01/2026 công bố Unified RISC-V IP Access Platform.
- **Tiny Tapeout** — kênh tape-out chi phí chia sẻ; hiện dùng LibreLane.

### 2.4 Bối cảnh Việt Nam

- Hơn 40 công ty liên quan đến chip, khoảng **5.600 kỹ sư**; hầu hết là FDI, chỉ Viettel và FPT là doanh nghiệp Việt.
- Cơ cấu: ~10% kiến trúc hệ thống, ~30% front-end, **~40% verification**, ~20% back-end.
- Nhận định của giới chuyên môn: Việt Nam **thiếu kỹ sư trưởng có khả năng thiết kế hoàn chỉnh một con chip**; kỹ sư Việt chủ yếu thực thi theo đặc tả do nước ngoài viết.
- Tin tuyển dụng verification trong nước yêu cầu thành thạo VCS / Incisive / Questa — **toàn công cụ thương mại**.
- ĐH FPT đã mở chuyên ngành thiết kế vi mạch, hợp tác Silvaco, sinh viên thực tập tại FPT và Marvell. TP.HCM có quỹ 5 triệu USD đào tạo 40.000 kỹ sư.

**Kết luận từ dữ liệu trên:** phần đông đúc là *"viết testbench theo kế hoạch người khác lập"*. Phần trống là *"quyết định cần kiểm chứng cái gì"*, và **mảng mã nguồn mở gần như chưa ai chạm tới**.

---

## 3. Định vị chiến lược

### 3.1 Ba bất đối xứng cấu trúc của HUFLIT

**(1) HUFLIT được phép công bố — họ thì không.**

5.600 kỹ sư verification ở Việt Nam làm việc dưới NDA. Năng lực của họ bị nhốt trong công ty chủ quản; cộng đồng quốc tế không nhìn thấy một cái tên Việt Nam nào. **Trường đại học là chủ thể duy nhất ở Việt Nam có thể tích lũy uy tín công khai trong lĩnh vực này.** Đây là lợi thế cạnh tranh cốt lõi, không phải chi phí hay kỹ năng.

**(2) Doanh nghiệp bị ràng buộc bởi nhân lực — đó là đầu ra của trường.**
Quan hệ đúng là **cung cấp và hợp tác**, không phải cạnh tranh.

**(3) Trường chịu được chân trời 3 năm — doanh nghiệp phải có doanh thu quý này.**

### 3.2 Ngách được chọn

> **Verification có AI hỗ trợ, thực hiện trên IP mã nguồn mở.**

Lý do chọn:

1. **Verification chiếm 60–70% công sức** một dự án chip và là công việc phần mềm thuần túy — đúng tiêu chí "digital, thâm dụng lao động trí tuệ".
2. Nó **nằm phía trước hàng rào chứng nhận** (xem §3.4) nên không bị chặn.
3. **Rào cản cấu trúc bảo vệ ngách này:** không thể nghiên cứu AI-assisted verification trên IP thuộc sở hữu khách hàng dưới NDA. Các công ty Việt Nam **không thể** đi trước ở mảng này dù có nhiều kỹ sư hơn. Trên IP mã nguồn mở thì không có rào cản đó.
4. Năng lực AI-assisted engineering là năng lực HUFLIT **đã có thật**, không phải đi vay.
5. Ra được sản phẩm ba lớp cùng lúc: bài báo học thuật, đóng góp mã nguồn công khai, giáo trình bán được.

### 3.3 Phép thử ba câu (dùng mỗi khi phân vân chọn việc)

1. **FPT / Marvell Việt Nam có làm được việc này không?** → Nếu **có**, bỏ. Họ nhiều nguồn lực hơn.
2. **Họ có được phép công bố kết quả không?** → Nếu **không**, đó là ngách của ta.
3. **Nó có tạo ra tài sản công khai mang tên HUFLIT không?** → Nếu **không**, đó là làm thuê, không phải xây vốn.

### 3.4 Cái trần — phải biết để không ảo tưởng

| Khâu | Mã nguồn mở |
|---|---|
| Verification, mô phỏng, kiểm thử | ✅ Dùng được ở mức thương mại **ngay hôm nay** |
| RTL, IP digital, hạ tầng CI | ✅ Dùng được |
| Physical design 130/180nm | ⚠️ Được, chất lượng kết quả kém hơn công cụ thương mại |
| Ký duyệt DRC/LVS cuối cùng | ❌ Cần deck riêng của foundry, phải dùng công cụ thương mại |
| Node tiên tiến (≤7nm) | ❌ Không có cửa |
| Sản phẩm đạt ASIL C/D, DO-254 | ❌ Cần nhà cung cấp chịu trách nhiệm pháp lý |

**Lưu ý quan trọng về "certificate":** hàng rào chứng nhận ràng buộc *khâu ký duyệt* và *sản phẩm cuối*, không ràng buộc toàn chuỗi. Không ai yêu cầu chứng nhận cho một testbench, một RTL, một hạ tầng CI. Trong ISO 26262, công cụ mức TCL1 không cần thẩm định. Hơn nữa, **chứng nhận là một tầng dịch vụ nằm TRÊN mã nguồn mở** (mô hình Red Hat / ELISA), tức là một thị trường chứ không phải một bức tường.

**Về nghề nghiệp sinh viên:** kỹ năng chuyển giao được **nếu dạy khái niệm, không dạy thao tác công cụ**. STA, CDC, metastability, phương pháp verification là độc lập công cụ. Người thạo cocotb/UVM trên Verilator chuyển sang môi trường thương mại trong vài tuần.

---

## 4. Lộ trình và cổng nghiệm thu

### Giai đoạn 0 — 90 ngày: xác thực con người

**Toàn bộ trọng tâm là tìm và thử MỘT người.** Không lập tổ chức, không mua gì, không công bố gì.

Hồ sơ người cần tìm: giảng viên trẻ hoặc sinh viên năm cuối xuất sắc, đọc hiểu tiếng Anh tốt, có tính lì. **Không cần biết gì về vi mạch.**

| Tuần | Nhiệm vụ | Đầu ra bắt buộc |
|---|---|---|
| 1–2 | Cài `IIC-OSIC-TOOLS` bằng Docker, chạy `librelane --smoke-test` | Một file GDSII |
| 3–6 | Thiết kế nhỏ tự viết (bộ đếm / UART), chạy trọn RTL→GDSII với đầy đủ DRC, LVS, timing. **Không nộp shuttle.** | Hiểu được vì sao sign-off là phần khó nhất |
| 7–12 | Chọn một IP mã nguồn mở thiếu verification, viết testbench cocotb, tìm một lỗi thật, gửi PR | **Một PR được merge** |

> **🚦 CỔNG 0 — không qua thì DỪNG.**
> Tiêu chí: có **1 PR được merge** vào một dự án quốc tế trước ngày thứ 90.
> Nếu không qua: đã biết rất rẻ rằng chưa đúng người. Không giải ngân gì thêm. Không đổ lỗi. Ghi lại vào ADR và dừng.

### Giai đoạn 1 — tháng 4–12: từ một người thành một nhóm nhỏ

Hình thức: **CLB / seminar hằng tuần**, 5–8 sinh viên. Không phải môn học, không phải trung tâm. Người ở GĐ0 trở thành người dẫn.

Hai luồng đầu ra song song:

- **Kỹ thuật:** thêm 3–5 PR được merge vào cocotb, LibreLane, IHP hoặc PULP.
- **Bản địa hóa:** dịch một tài liệu cốt lõi sang tiếng Việt chuẩn mực, **gửi ngược lại dự án gốc**. Đây là việc không trường kỹ thuật nào ở Việt Nam làm tốt bằng HUFLIT.

> **🚦 CỔNG 1.** Tiêu chí cuối tháng 12: 5 PR merge + 1 tài liệu tiếng Việt được dự án gốc chấp nhận + 3 bài viết kỹ thuật công khai bằng tiếng Anh.

### Giai đoạn 2 — năm thứ hai: thể chế hóa cái đã chứng minh

Chỉ đến lúc này mới bàn tới học phần tự chọn — và nó được xây từ **giáo trình đã tích lũy 12 tháng**, không phải từ đề cương viết trên giấy.

Song song: mở quan hệ chính thức với **IHP** và **FOSSi Foundation**. Lúc đó HUFLIT đến với một danh sách đóng góp tra cứu được, không phải một bản đề án.

---

## 5. Hạ tầng kỹ thuật tối thiểu

### 5.1 Giai đoạn 0: không mua gì

Laptop cá nhân + Docker + GitHub + internet. Đủ.

### 5.2 Khi cần máy chủ regression (không sớm hơn GĐ1)

| Thành phần | Khuyến nghị | Lý do |
|---|---|---|
| CPU | 16–32 nhân | Regression là bài toán song song hoàn hảo; mỗi test là một tiến trình đơn luồng |
| RAM | 128–256GB | **Nút thắt thật.** Verilator biên dịch ngốn RAM |
| Ổ đĩa | NVMe ≥2TB | Build artifact và waveform sinh ra rất nhiều |
| **GPU** | **Không** | Luồng LibreLane là CPU-bound. GPU acceleration (DREAMPlace, DG-RePlAce, OpenDRC) hiện vẫn ở mức nghiên cứu, chưa nằm trong luồng mặc định |

**Về RAM ECC:** ECC đáng giá khi máy chạy nhiều giờ liên tục dưới áp lực bộ nhớ cao — một bit lật giữa lần chạy 12 tiếng không gây crash mà cho ra **kết quả sai không báo gì** (đúng loại silent error mà công việc của ta là săn tìm). Nhưng nếu ngân sách hạn chế:

- Ưu tiên **dung lượng lớn** hơn ECC: 256GB non-ECC hữu ích hơn 128GB ECC.
- Nếu mua nền tảng server cũ → bắt buộc **RDIMM**, và đây là cách rẻ nhất tính trên mỗi GB.
- Nếu Ryzen mới → chỉ dùng được **UDIMM ECC**; nhớ **kiểm chứng ECC thực sự bật** bằng `edac-util -v` và `rasdaemon`, vì rất nhiều máy chạy nhiều năm mà ECC chưa từng kích hoạt.
- **ECC của người nghèo:** chạy cùng một thiết kế hai lần và so hash của GDS đầu ra. Khác nhau ⇒ có gì đó sai. Đưa vào CI như một job hằng tuần. Cách này còn bắt được cả lỗi phần mềm.
- Không bật XMP/EXPO. Chạy memtest86+ 24 giờ trước khi đưa vào vận hành. Giữ mức chiếm dụng RAM dưới 80%.

### 5.3 FPGA — chỉ để dạy front-end

FPGA dạy RTL, FSM, testbench, CDC. FPGA **không** dạy floorplan, PDN, CTS, DRC/LVS, GDSII — phần đó chỉ LibreLane dạy được, và **không cần phần cứng nào cả**.

| Board | Toolchain FOSS | Ghi chú |
|---|---|---|
| Sipeed Tang Nano 9K/20K | ✅ Apicula | Nhập môn, rẻ, dễ mua ở VN |
| **ULX3S 85F (ECP5)** | ✅ Trellis + nextpnr | **Khuyến nghị.** 84K LUT, chạy được SoC RISC-V, phần cứng mã nguồn mở |
| Tang Mega 138K | ❌ GW5AST buộc dùng Gowin IDE thương mại | **Không mua** — phá vỡ nguyên tắc FOSS-first |
| Xilinx Artix-7 | ❌ prjxray còn thử nghiệm | Không dùng cho dạy học |

---

## 6. Quy ước repo và tài liệu

Kế thừa từ `dev-op-skill` (DevSecOps baseline của HUFLIT):

```
huflit-open-silicon/
├── README.md                  # Bằng tiếng Anh — đây là mặt tiền quốc tế
├── PROJECT_INSTRUCTIONS.md    # Nguồn sự thật cho quyết định đang tiến hóa
├── docs/
│   ├── OPEN_SILICON_KICKOFF.md   # Tài liệu này
│   ├── RUNBOOK.md                # Cách chạy môi trường, chạy regression
│   ├── decisions/                # ADR-OS-xxx.md
│   └── vi/                       # Bản dịch tiếng Việt (tài sản riêng của HUFLIT)
├── designs/                   # Thiết kế học tập (hello_huflit, v.v.)
├── verification/              # Testbench cocotb — sản phẩm chính
├── docker/                    # Dockerfile, compose cho môi trường tái lập
├── .github/workflows/         # CI: lint → sim → LibreLane → so hash
├── .env.example               # KHÔNG BAO GIỜ commit .env thật
└── CHANGELOG.md
```

**Nguyên tắc bắt buộc:**

1. **README bằng tiếng Anh.** Đây là thứ người nước ngoài đọc đầu tiên.
2. **Mọi thứ tái lập được từ Git** — Dockerfile, config, CI đều trong version control.
3. **Conventional Commits**, trunk-based, `main` luôn ở trạng thái chạy được.
4. **Không secret trong Git.**
5. **Ghi ADR cho mọi quyết định có đánh đổi.** Người tiếp nhận sau này cần hiểu *vì sao*.
6. **Repo công khai ngay từ ngày đầu.** Uy tín chỉ tích lũy được khi công khai. Repo private không tạo ra tài sản nào.

---

## 7. ADR khởi đầu

### ADR-OS-001 — Chọn LibreLane, không dùng OpenLane
**Bối cảnh:** Efabless đóng cửa 03/2025; OpenLane chuyển sang chế độ legacy.
**Quyết định:** dùng LibreLane (FOSSi Foundation) cho mọi công việc mới.
**Hệ quả:** tương thích ngược với config OpenLane nên tài liệu cũ vẫn tham khảo được; cần theo dõi upstream của FOSSi.

### ADR-OS-002 — Ngách chiến lược là verification, không phải physical design
**Bối cảnh:** physical design mã nguồn mở cho chất lượng kết quả thấp hơn công cụ thương mại và bị chặn ở khâu ký duyệt.
**Quyết định:** đặt trọng tâm vào verification / mô phỏng / kiểm thử — thuần phần mềm, nằm trước hàng rào chứng nhận, thâm dụng lao động trí tuệ.
**Hệ quả:** physical design vẫn được học để hiểu quy trình, nhưng không phải mảng để xây năng lực cạnh tranh.

### ADR-OS-003 — Không tape-out trong 12 tháng đầu
**Bối cảnh:** chạy hết RTL→GDSII với đầy đủ sign-off cho ~90% giá trị học tập với chi phí bằng không; tape-out mất 9–14 tháng chờ và tốn phí.
**Quyết định:** giữ "Hello HUFLIT" ở dạng GDSII, không nộp shuttle.
**Hệ quả:** tiết kiệm tiền và hơn một năm. Xét lại khi có một IP thật cần chứng minh trên silicon.

### ADR-OS-004 — Repo công khai, tiếng Anh, ngay từ ngày đầu
**Bối cảnh:** lợi thế cạnh tranh cốt lõi của HUFLIT là *quyền được công bố* — thứ các doanh nghiệp dưới NDA không có.
**Quyết định:** mọi sản phẩm công khai mặc định; README và commit message bằng tiếng Anh; bản dịch tiếng Việt nằm trong `docs/vi/`.
**Hệ quả:** không được đưa vào repo bất cứ thứ gì ràng buộc bảo mật.

### ADR-OS-005 — Kiến trúc không phụ thuộc một nhà cung cấp AI
**Bối cảnh:** quy trình của nhóm dựa nhiều vào AI. Rủi ro gián đoạn là thật — đã có tiền lệ: Anthropic tạm ngưng truy cập Fable/Mythos 12–30/06/2026 để tuân thủ kiểm soát xuất khẩu, khôi phục 01/07/2026.
**Quyết định:** (a) dùng lớp API tương thích OpenAI để đổi nhà cung cấp chỉ là sửa biến môi trường; (b) toàn bộ prompt và quy ước lưu dạng Markdown trong Git; (c) xây bộ eval riêng 10–20 bài toán thật; (d) **diễn tập một tuần không dùng AI mỗi quý** và ghi lại mức sụt năng suất.
**Hệ quả:** kịch bản xấu nhất là "AI yếu hơn và phải tự chạy" (model open-weight như Qwen3.8-27B Apache 2.0 chạy được trên một GPU 24GB), không phải "không có AI".
**Rủi ro lớn hơn cần theo dõi:** phụ thuộc nhận thức. Nếu sau 12 tháng nhóm không tự đọc được file Liberty, không tự gỡ được lỗi timing, thì AI đang là *nạng* chứ không phải *người thầy* — và đó là vấn đề nghiêm trọng hơn nhiều so với việc nhà cung cấp biến mất.

### ADR-OS-006 — Không mua thiết bị đo đạc
**Bối cảnh:** định vị là sản phẩm số chuyển giao qua mạng.
**Quyết định:** ngân sách phân bổ ~20% compute, ~65% con người, ~15% hiện diện cộng đồng. Không oscilloscope, không SMU, không trạm rework.
**Hệ quả:** không tự đo đạc hậu silicon được. Chấp nhận — đó là mô hình khác.

---

## 8. Chỉ số đo lường

**Chỉ đo bằng những con số người ngoài kiểm chứng được.**

| Mốc | Chỉ số |
|---|---|
| Tháng 3 | 1 PR được merge vào một dự án quốc tế |
| Tháng 6 | 3 bài viết kỹ thuật tiếng Anh công khai |
| Tháng 12 | 5 PR merge + 1 tài liệu tiếng Việt được dự án gốc chấp nhận |
| Tháng 24 | Tên HUFLIT trong danh sách đóng góp của ≥2 dự án; 1 quan hệ hợp tác với IHP hoặc FOSSi |

**Không đo bằng:** số buổi seminar, số sinh viên tham gia, số trang đề án, số tin bài truyền thông.

---

## 9. Lịch hiện diện cộng đồng

| Kênh | Ghi chú | Thời điểm |
|---|---|---|
| **Google Summer of Code** | FOSSi Foundation từng là tổ chức bảo trợ. **Google trả tiền cho sinh viên**, người hướng dẫn là lãnh đạo kỹ thuật của hệ sinh thái. Tỷ lệ lợi ích/chi phí tốt nhất cho một trường. | Đơn mở ~tháng 2–3 hằng năm |
| **ORConf** (FOSSi) | **Miễn phí tham dự**, đóng góp tùy tâm. Kỳ 2026: 11–13/09/2026 tại Ghent, Bỉ. Hạn nộp bài 16/08/2026. | Mục tiêu: nộp bài ~08/2027 |
| **FSiC** (Free Silicon Conference) | Kỳ 2026: 06–08/07/2026 tại ĐH Ljubljana, Slovenia. Bao gồm cả analog lẫn digital. | Mục tiêu: ~07/2027 |
| **El Correo Libre** | Bản tin của FOSSi. Được nhắc tên = phát hành miễn phí tới đúng tệp độc giả. | Liên tục |
| **DVCon / WOSET** | Kênh học thuật — HUFLIT có lợi thế thể chế sẵn, dễ xin kinh phí, bài báo trích dẫn được vĩnh viễn. | Theo lịch hội nghị |

**Bài nói có xác suất được nhận cao nhất:** *"Đưa silicon mã nguồn mở vào tiếng Việt — bài học từ một nước 100 triệu dân"*. Cộng đồng này rất quan tâm mở rộng địa lý, và không ai khác kể được câu chuyện đó.

**Tuyệt đối không làm:** email chào hàng lạnh; thông cáo báo chí; website tiếng Anh có chữ "world-class" mà không có link tới repo nào; xin gặp lãnh đạo FOSSi/IHP khi chưa có PR nào được merge. Trong cộng đồng này, **tuyên bố không có bằng chứng bị trừ điểm, không phải hòa vốn**.

---

## 10. Rủi ro và giảm thiểu

| Rủi ro | Mức | Giảm thiểu |
|---|---|---|
| **Không tìm được người phù hợp** | Cao | Đây là nút thắt thật, không phải tiền. Cổng 0 phát hiện sớm trong 90 ngày với chi phí ~0 |
| **Áp lực thể chế đòi thành tích sớm** | Cao | Không công bố gì trong 12 tháng đầu. Thầy che chắn nhóm khỏi yêu cầu báo cáo. Không gắn nhãn Hội đồng trường quá sớm |
| **Phụ thuộc nhận thức vào AI** | Cao | Xem ADR-OS-005. Tiêu chí nghiệm thu là PR được cộng đồng merge — maintainer sẽ hỏi "vì sao anh làm thế này", và không AI nào trả lời thay được |
| Gián đoạn nhà cung cấp AI | Trung bình | ADR-OS-005 |
| PDK IHP còn alpha | Trung bình | Không dùng cho bất cứ cam kết sản xuất nào; chỉ dùng học tập và đóng góp |
| Cạnh tranh từ các trường khác | Thấp | Ngách được bảo vệ bởi rào cản NDA (§3.2) — không phải bởi tốc độ |
| Người dẫn nghỉ việc | Cao | Mọi thứ công khai trong Git từ ngày đầu; tri thức không nằm trong đầu một người |

---

## 11. Việc cần làm tiếp / câu hỏi mở

- [ ] **Xác định người dẫn giai đoạn 0.** Đây là việc chặn tất cả những việc khác.
- [ ] Xác định cơ chế bảo vệ thời gian cho người đó (giảm giờ giảng, hoặc thù lao).
- [ ] Xác minh lại trạng thái shuttle, giá và lịch nếu/khi xét lại ADR-OS-003.
- [ ] Chọn danh sách 10 IP mã nguồn mở ứng viên cho PR đầu tiên.
- [ ] Kiểm tra EULA của Efinix trước khi công bố bất cứ phát hiện nào về công cụ của họ.
- [ ] Quyết định host repo: GitHub (mặc định cho dự án công khai/giáo dục) — cần có mặt ở nơi cộng đồng đang ở.

---

## 12. Nguồn tham khảo

| Chủ đề | Nguồn |
|---|---|
| LibreLane | `librelane.readthedocs.io` · `github.com/librelane/librelane` |
| FOSSi Foundation, ORConf | `fossi-foundation.org` · `orconf.org` |
| FSiC | `wiki.f-si.org` |
| IHP Open PDK | `github.com/IHP-GmbH/IHP-Open-PDK` |
| Tiny Tapeout | `tinytapeout.com` |
| Container công cụ | IIC-OSIC-TOOLS (JKU Linz) |
| Mô hình tham chiếu | Antmicro (Ba Lan/Thụy Điển, thành lập 2009, ~86–122 người, gần như không gọi vốn mạo hiểm; Renode mã nguồn mở là kênh marketing, không phải sản phẩm bán) |
| Gián đoạn AI 06/2026 | `anthropic.com/news/fable-mythos-access` |
| Bối cảnh nhân lực VN | Hội thảo Bộ KH-CN; số liệu ĐH Bách khoa TP.HCM |

---

## 13. Changelog

| Phiên bản | Ngày | Thay đổi |
|---|---|---|
| v0.1 | 2026-09-14 | Bản thảo đầu tiên. Tổng hợp từ khảo sát hệ sinh thái tháng 09/2026. Chốt định vị (§3), lộ trình có cổng nghiệm thu (§4), sáu ADR khởi đầu (§7). |

---

> **Nhắc lại nguyên tắc vận hành:**
> Mỗi khi cân nhắc một việc, hỏi: *Việc này tạo ra tài sản công khai mang tên HUFLIT, hay chỉ tạo ra chuyển động?*
> Nếu là chuyển động — dừng lại.
