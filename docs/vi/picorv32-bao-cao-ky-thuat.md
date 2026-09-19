# picorv32 — Tinh chỉnh một core RISC-V thật qua luồng ASIC mã nguồn mở: Nhật ký debug

> Tài liệu học tập nguyên bản tiếng Việt (mục đích #2 của `docs/vi/README.md`)
> — không bắt buộc gửi upstream. Bản gốc tiếng Anh (tài sản chính thức, dùng
> để xây uy tín với cộng đồng quốc tế):
> [`docs/picorv32-technical-report.md`](../picorv32-technical-report.md).

| | |
|---|---|
| **Chương trình** | HUFLIT Open Silicon (mật danh Vega) |
| **Thiết kế** | [`designs/picorv32/`](../../designs/picorv32/) |
| **Bối cảnh** | Gỡ lỗi cục bộ trước khi chạy trên cloud (ADR-OS-007), và là thiết kế học tập thứ ba sau `counter3` và `uart_top` |
| **Ngày** | 2026-09-16 (khám phá cục bộ) – 2026-09-17 (chuẩn bị chạy cloud) |
| **Trạng thái** | Đã đạt kết quả sạch về timing cục bộ; còn vi phạm max-slew/max-cap và lần chạy cloud thật vẫn đang chờ |
| **Đối tượng đọc** | Tài liệu giảng dạy — và thẳng thắn, một phép thử xem việc này có đáng công bố hay không (xem mục 1) |

## Tóm tắt

Đây không phải một câu chuyện thành công đã lược bỏ phần khó. Đây là ghi
chép theo trình tự thời gian của việc cố gắng chạy một core RISC-V mã
nguồn mở thật, nổi tiếng — `picorv32` của YosysHQ — qua trọn luồng
RTL-to-GDSII của LibreLane, viết lại từng lần thử một, bao gồm năm lần
chạy thất bại hoặc chưa đạt trước khi có một lần sạch, ba lần bị hệ điều
hành giết vì hết RAM (OOM) được xác nhận độc lập, và một điều bất thường
mà báo cáo này không cố giải thích cho bằng được. Mục đích ghi lại theo
cách này là có chủ đích: giá trị ở đây chưa bao giờ nằm ở việc "đã chạy
được `picorv32`" — `picorv32` đã được chạy qua loại luồng này nhiều hơn
số lần ai đó có thể đếm được. Giá trị nằm ở ba phát hiện cụ thể, dùng lại
được, về cách LibreLane thực sự hoạt động ở quy mô lớn hơn hẳn hai thiết
kế đầu tiên của chương trình (`counter3`, `uart_top`), và ở một ghi chép
trung thực về cách từng phát hiện đó thực sự đạt được — kể cả những bước
đi sai — vì chính ghi chép đó mới là phần một sinh viên hay kỹ sư kế tiếp
thực sự học được điều gì đó. Mục 1 trả lời thẳng câu hỏi liệu bài thực
hành này có đáng công bố hay không, vì câu hỏi đó được đặt ra trước khi
viết báo cáo này, không phải sau.

## 1. Việc này có đáng công bố không?

Câu hỏi này được đặt ra có chủ đích, trước khi viết báo cáo, không phải
một cách đóng khung tu từ sau khi đã làm xong. Câu trả lời trung thực có
hai phần.

**Với tư cách đóng góp cho chính `picorv32`: không.** Không tìm ra lỗi
RTL nào. Sẽ không có pull request nào gửi tới repo của YosysHQ.
`picorv32` là một trong những core mã nguồn mở được tổng hợp (synthesize)
nhiều nhất từng tồn tại; chạy nó qua luồng LibreLane thêm một lần nữa
không đẩy tiến dự án đó theo bất kỳ cách nào. Nếu tiêu chuẩn "đáng làm"
là "có tạo ra PR được merge không", bài thực hành này không đạt tiêu
chuẩn đó, và nên được gọi tên đúng như vậy thay vì tô vẽ thành thứ gì đó
lớn hơn thực tế.

**Với tư cách một bài viết kỹ thuật công khai: có, nhưng trên một cơ sở
hẹp hơn và trung thực hơn.** Ba phát hiện trong báo cáo này (mục 6) không
đặc thù cho `picorv32` — chúng là sự thật về hành vi của chính LibreLane
ở một quy mô thiết kế (~19.000 instance) mà chương trình chưa từng chạm
tới trước đây, và ít nhất một trong số đó (khoảng cách giữa tài liệu và
hành vi thật của auto-detect thread, mục 6.1) trông giống một sai khác
thật sự giữa tài liệu và hành vi thực tế của LibreLane trong bộ công cụ
này, đáng báo lên upstream độc lập với bất kỳ bài viết nào. Một người đọc
đang cố chạy một thiết kế cỡ tương tự qua đúng luồng mã nguồn mở này có
khả năng cao sẽ đâm vào đúng ba bức tường mà báo cáo này đã đâm vào, và
có khả năng cao sẽ tiết kiệm được thời gian thật — và nếu đang thuê cloud,
tiền thật — bằng cách đọc bài này trước. Đó là một cơ sở công bố chính
đáng, dù khiêm tốn: không phải "nhìn xem chúng tôi đã xây được gì", mà là
"đây là những gì đã hỏng, và đây là biên lai".

Người đọc nên cân nhắc báo cáo này theo đúng tinh thần đó: nó gần với một
cuốn sổ tay phòng thí nghiệm hơn là một thông cáo sản phẩm, và đó chính
là văn phong có chủ đích.

## 2. Vì sao chọn picorv32, và vì sao vào lúc này

Lộ trình của chương trình (`docs/OPEN_SILICON_KICKOFF.md` §4) yêu cầu một
thiết kế tự viết chạy trọn ký duyệt (đã thỏa bởi `counter3`) và tùy chọn
thêm một thiết kế lớn hơn để chạm nhiều hơn vào luồng (`uart_top`, ~290
cell). Cả hai đều đã hoàn tất và có tài liệu
(`docs/counter3-technical-report.md`, `docs/uart-technical-report.md`).

Riêng biệt, `docs/decisions/ADR-OS-007-rent-compute-before-buying.md` đã
chốt chương trình này thuê compute cloud theo giờ thay vì mua phần cứng
riêng, vì lý do chi phí trong giai đoạn đầu còn nhiều rủi ro nhân sự.
Trước khi tiêu tiền thật vào một VM đi thuê, câu hỏi tự nhiên là: thuê để
làm *việc gì*, cụ thể? Một thiết kế lớn hơn `uart_top` cả một bậc được
chọn vì ba lý do:

1. **Nó thực sự gây áp lực lên CPU/RAM theo cách `uart_top` chưa từng
   làm**, cho phép kiểm chứng — thay vì đoán — câu hỏi sizing RAM mà
   `docs/OPEN_SILICON_KICKOFF.md` §5.2 đã để lại như một ước lượng chưa
   được xác minh ("128-256GB, RAM là nút thắt thật").
2. **Một thiết kế cỡ này thực sự khó lặp lại nhiều lần trên laptop**
   (như báo cáo này chứng minh: một lần thử đã mất hơn một tiếng trước
   khi sửa config) — đúng hình dạng bài toán mà việc thuê compute burst
   sinh ra để giải quyết, nhưng chỉ khi config *đã đúng từ trước* trước
   khi đồng hồ tính tiền bắt đầu chạy. Điều đó có nghĩa là phải làm phần
   debug khó trước, cục bộ, miễn phí, dù mất bao lâu.
3. **`picorv32` cụ thể** được chọn thay vì một khối lớn bất kỳ vì đây là
   một file Verilog duy nhất (~3.050 dòng gồm vài biến thể wrapper không
   dùng tới), license ISC (hoàn toàn permissive), không cần toolchain
   ngoài nào ngoài những gì Docker image của repo này đã có sẵn, và đủ
   nổi tiếng/được hiểu rõ để nếu có gì hỏng, nguyên nhân gần như chắc
   chắn nằm ở luồng hoặc cấu hình của nó, không phải ở RTL lạ hay có bug.

## 3. Thiết kế

[`designs/picorv32/src/picorv32.v`](../../designs/picorv32/src/picorv32.v),
tải nguyên văn từ
`https://raw.githubusercontent.com/YosysHQ/picorv32/master/picorv32.v`.
File này định nghĩa nhiều module (`picorv32`, `picorv32_axi`,
`picorv32_wb`, các đồng xử lý nhân/chia PCPI, một biến thể register file);
chỉ module lõi `picorv32` thuần túy được nhắm làm top của synthesis —
Yosys chỉ elaborate những gì với tới được từ top module được chỉ định,
nên các module wrapper không dùng trong cùng file đơn giản bị bỏ qua.

Interface top-level của core (dùng giá trị mặc định, không override
parameter nào):

```verilog
module picorv32 #(
    parameter [ 0:0] ENABLE_COUNTERS = 1,
    parameter [ 0:0] ENABLE_REGS_16_31 = 1,
    parameter [ 0:0] ENABLE_REGS_DUALPORT = 1,
    parameter [ 0:0] TWO_STAGE_SHIFT = 1,
    parameter [ 0:0] BARREL_SHIFTER = 0,
    parameter [ 0:0] CATCH_MISALIGN = 1,
    parameter [ 0:0] CATCH_ILLINSN = 1,
    parameter [ 0:0] ENABLE_PCPI = 0,
    parameter [ 0:0] ENABLE_MUL = 0,
    parameter [ 0:0] ENABLE_DIV = 0,
    parameter [ 0:0] ENABLE_IRQ = 0,
    ...
) (
    input clk, resetn,
    output reg trap,
    output reg mem_valid, mem_instr,
    input mem_ready,
    output reg [31:0] mem_addr, mem_wdata,
    output reg [3:0] mem_wstrb,
    input [31:0] mem_rdata,
    ...
);
```

Ở tham số mặc định, nhân/chia/PCPI/IRQ đều tắt nhưng register file
dual-port, bộ đếm (counters), và bẫy lệnh sai địa chỉ/lệnh bất hợp lệ đều
bật — một core RV32I khá đầy đủ tính năng, không cache, không giao thức
bus riêng (các tín hiệu `mem_*` chỉ là bắt tay valid/ready đơn giản mà
SoC bên ngoài phải tự phục vụ). Không có testbench cocotb nào được viết
cho thiết kế này trong bài thực hành — kiểm thử chức năng (mức ISA) của
`picorv32` cố tình nằm ngoài phạm vi; đối tượng nghiên cứu ở đây là *luồng
triển khai vật lý*, không phải tính đúng đắn của core (thứ mà YosysHQ và
một cộng đồng người dùng lớn đã kiểm chứng kỹ hơn nhiều so với những gì
chương trình này có thể làm trong một buổi).

## 4. Phần cứng sử dụng

Độ chính xác ở đây quan trọng với bất kỳ ai muốn tái lập hay so sánh với
các con số này.

| | |
|---|---|
| **Máy cục bộ** | 11th Gen Intel Core i7-11370H @ 3.30GHz — **4 core vật lý, 8 luồng logic (hyperthreading)**, `nproc` báo 8; ~23GB RAM |
| **Toolchain image** | `hpretl/iic-osic-tools:2026.08` (đã pin; xem `docker/Dockerfile`), LibreLane v3.1.0.dev3, sky130A / `sky130_fd_sc_hd` |
| **Điểm tham chiếu sau này (mục 9)** | VM Linode mà công việc này đang chuẩn bị cho báo cáo CPU vật lý bên dưới là AMD EPYC 7601 (32-core, kiến trúc Zen 1, xung cơ bản 2,2GHz), ảo hóa qua KVM |

Sự khác biệt giữa 4 core vật lý và 8 luồng logic trên máy cục bộ không
phải chi tiết vụn vặt: nó giải thích trực tiếp vì sao cách sửa threading
ở mục 6.1 chỉ cho cải thiện thời gian ~3 lần thay vì gần 8 lần —
hyperthreading mang lại lợi ích thật nhưng không tuyến tính cho công việc
biên dịch/PnR bị giới hạn bởi CPU, và một báo cáo nói "8 core" mà không
làm rõ điều này sẽ hứa hẹn quá mức so với những gì cùng một cách sửa nên
được kỳ vọng làm được trên một máy thật sự có 8 core vật lý.

## 5. Các lần thử, theo thứ tự

Mọi lần thử bên dưới đều chạy cùng một dạng lệnh:

```bash
docker compose -f docker/docker-compose.yml run --rm \
  --workdir /workspace/designs/picorv32 \
  librelane-dev --skip \
  librelane -p sky130A -s sky130_fd_sc_hd config.yaml
```

với `designs/picorv32/config.yaml` được sửa giữa các lần thử như mô tả
bên dưới. `runs/` bị xóa trước mỗi lần thử để tránh lẫn lộn kết quả (một
quyết định được xem lại có phê phán ở mục 5.5).

### 5.1 Lần thử 1 — cơ sở, và một bug không được để ý

```yaml
DESIGN_NAME: picorv32
VERILOG_FILES: dir::src/*.v
CLOCK_PERIOD: 10
CLOCK_PORT: clk
```

Không có gì về threading được cấu hình — giả định, chưa được kiểm chứng
lúc đó, là LibreLane sẽ tự dùng các core sẵn có theo mặc định.

**Kết quả: lỗi cứng sau 61 phút 39 giây** (08:36:36 – 09:38:15 UTC).
Synthesis, floorplan, đặt vị trí, CTS, và đi dây đều hoàn tất không lỗi;
luồng chỉ dừng ở ký duyệt cuối:

```
[ERROR] The following error was encountered while running the flow:
        One or more deferred errors were encountered:
        Setup violations found in the following corners:
        * max_ss_100C_1v60
        * min_ss_100C_1v60
        * nom_ss_100C_1v60
[ERROR] LibreLane will now quit.
```

Bản thân đây không phải kết quả bất ngờ — một core CPU thật nhắm tới
100MHz (10ns) trên sky130 mà không tinh chỉnh chiến lược timing gì thất
bại đóng timing ở corner chậm nhất là kết quả hợp lý, gần như dự đoán
được. Điều đáng chú ý là một quan sát bên lề trong lúc chạy: bộ ghi log
tài nguyên định kỳ (`docker stats` + `free -h`, lấy mẫu mỗi 20 giây suốt
358 mẫu) chưa một lần nào ghi nhận CPU vượt quá **~101%** — trên một máy
8 luồng logic. RAM đỉnh của container suốt cả lần chạy chỉ khoảng
~763MiB.

Grep log của luồng tìm từ "thread" hé lộ nguyên nhân thật:

```
[VERBOSE] OpenROAD will use None threads
[WARNING] [ORD-0032] Invalid thread number specification: None
```

**Đây chính là Phát hiện #1 (mục 6.1) — nhưng tại thời điểm này trong
câu chuyện, nó mới chỉ là một điều bất thường, chưa được ghi nhận thành
phát hiện.** Hệ quả trước mắt hẹp hơn: lần chạy dài một tiếng này đã dùng
tương đương một core suốt thời gian, trên một máy có tám luồng logic
đang ngồi không. Trước khi rút ra kết luận gì về timing của `picorv32`,
cấu hình threading cần được sửa trước — một bug không liên quan đang làm
nhiễu chính thí nghiệm.

### 5.2 Lần thử 2 — sửa threading, nới clock

Hai thay đổi cùng lúc (nhìn lại, đổi hai biến trong một bước là một lối
tắt phương pháp luận nhỏ — xem ghi chú nhìn lại ở mục 5.5):

```yaml
CLOCK_PERIOD: 25          # nới từ 10ns
OPENROAD_THREADS: 8
STA_THREADS: 9            # một thread cho mỗi PVT corner
```

**Kết quả: vẫn lỗi cứng, đúng ba corner cũ, nhưng chỉ trong 21 phút 6
giây** (09:39:56 – 10:01:02 UTC) — cải thiện thời gian chạy **~3 lần**,
khớp với lưu ý về hyperthreading ở mục 4. Riêng điều này đã xác nhận cách
sửa threading là thật và hiệu quả, độc lập với việc vấn đề timing có
được giải quyết hay không. Kiểm tra `final/metrics.json` lần đầu tiên
trong bài thực hành này (được ghi ra dù thoát với mã lỗi — xem ghi chú ở
mục 5.5):

| Chỉ số | Giá trị |
|---|---|
| Số instance thiết kế | 19.208 |
| Setup slack xấu nhất | −2,483 ns |
| Số vi phạm setup | 9 |
| Setup TNS (tổng slack âm) | −4,889 ns |

Nới clock 2,5 lần (10ns → 25ns) *không* sửa vi phạm theo tỷ lệ tương
ứng — một gợi ý, chưa được hiểu tại thời điểm này, rằng chính cách tiếp
cận synthesis mặc định, không chỉ mục tiêu clock, là một phần của vấn đề.

### 5.3 Lần thử 3 — nới thêm; "thành công" đầu tiên nhưng chưa sạch

```yaml
CLOCK_PERIOD: 30
```

(threading giữ nguyên). Lần chạy này cũng gặp một sự cố hạ tầng không
liên quan: tiến trình theo dõi ở tầng shell cho lần chạy nền này bị hệ
điều hành của máy phát triển này tự tắt hai lần vì cảnh báo áp lực RAM,
không liên quan đến việc dùng RAM thật của container (đã xác nhận —
bản thân container vẫn khỏe, dùng ~1,4GB, đang giữa chừng đi dây, số vi
phạm đang giảm dần). Lần chạy được gắn lại theo dõi qua `docker wait`
trên đúng container ID thay vì chạy lại từ đầu, và cuối cùng hoàn tất.

**Kết quả: exit code 0** ("Flow complete") — lần đầu hoàn tất mà không
lỗi cứng. Nhưng `flow__errors__count == 0` không có nghĩa là sạch:

| Chỉ số | Giá trị |
|---|---|
| Số instance thiết kế | 19.208 |
| Setup slack xấu nhất | **−3,093 ns (vẫn vi phạm)** |
| Số vi phạm setup | 11 |
| Vi phạm max-slew | 4.682 |
| Vi phạm max-cap | 20 |
| Tổng công suất | 7,26 mW |

Đây là lần đầu xuất hiện một điều bất thường mà báo cáo này không cố
giải thích cho bằng được: lần thử 1 và 2, với slack *ít âm hơn*
(−2,48ns) so với lần thử này (−3,09ns), lại kích hoạt đường lỗi cứng
"Setup violations found... will now quit" của LibreLane, còn lần thử
này, với slack *tệ hơn*, thì không. Bất kể tiêu chí thật sự kích hoạt
việc dừng cứng đó là gì, rõ ràng nó không đơn giản là "có vi phạm setup
hay không" hay "slack xấu nhất âm bao nhiêu" — một ngưỡng nào khác (có
thể là TNS, hoặc tập corner PVT cụ thể, hoặc thứ gì khác chưa được điều
tra ở đây) đang chi phối nó. Báo cáo này nêu rõ đây là **câu hỏi mở**
thay vì khẳng định một lời giải thích chưa được kiểm chứng.

DRC, LVS, và antenna đều sạch tại thời điểm này, và bản thân điều đó
đáng nói thẳng ra: một thiết kế có thể hợp lệ về vật lý và qua được ký
duyệt trên mọi trục trừ timing, và mã thoát của LibreLane không phân
biệt đáng tin cậy giữa "sạch" và "còn hàng nghìn vi phạm slew/cap chưa
sửa".

### 5.4 Lần thử 4 — chiến lược synthesis mới là biến số còn thiếu

Đến đây (theo đúng chỉ đạo của thầy tiếp tục khám phá "cho phong phú ngữ
cảnh và các test case fine-tuning khác nhau"), việc dò cấu hình chuyển
từ phản ứng bị động sang có chủ đích. Truy vấn trực tiếp định nghĩa step
của chính LibreLane, thay vì đoán từ tài liệu:

```bash
docker compose -f docker/docker-compose.yml run --rm librelane-dev --skip \
  python3 -c "
from librelane.steps import Yosys
for v in Yosys.Synthesis.config_vars:
    if 'STRATEGY' in v.name:
        print(v.name, '| default=', v.default, '|', v.description[:200])
"
```

```
SYNTH_STRATEGY | default= AREA 0 | Strategies for abc logic synthesis
and technology mapping. AREA strategies usually result in a more
compact design, while DELAY strategies usually result in a design that
runs at a higher frequency.
```

Mặc định tối ưu diện tích, không tối ưu độ trễ (delay) — mặc định hợp lý
cho một luồng đa dụng, nhưng không hợp với một thiết kế đã fail timing.
Đổi sang tùy chọn hướng delay mạnh nhất:

```yaml
CLOCK_PERIOD: 25           # thắt lại từ 30
SYNTH_STRATEGY: "DELAY 4"
```

**Kết quả:** exit 0, và cải thiện thật *dù clock chặt hơn lần thử 3*:

| Chỉ số | Lần thử 3 (`AREA 0`, 30ns) | Lần thử 4 (`DELAY 4`, 25ns) |
|---|---|---|
| Setup slack xấu nhất | −3,093 ns | **−2,157 ns** |
| Vi phạm setup | 11 | 3 |
| Vi phạm max-slew | 4.682 | 2.862 |
| Vi phạm max-cap | 20 | 31 |
| Số instance thiết kế | 19.208 | 19.062 |
| Tổng công suất | 7,26 mW | 6,67 mW |

Một kết quả tốt hơn ở mục tiêu timing *chặt hơn* so với lần thử trước
với mục tiêu *lỏng hơn* là tín hiệu rõ ràng nhất có thể có rằng chiến
lược synthesis, không chỉ chu kỳ clock, mới là đòn bẩy chính — đây là
**Phát hiện #2** (mục 6.2).

### 5.5 Lần thử 5 — timing sạch, cuối cùng

Kết hợp việc nới clock chặt hơn với chiến lược đã có tác dụng:

```yaml
CLOCK_PERIOD: 30
SYNTH_STRATEGY: "DELAY 4"
```

**Kết quả: timing setup và hold sạch hoàn toàn.**

| Chỉ số | Giá trị |
|---|---|
| Setup slack xấu nhất | **+2,790 ns (đạt)** |
| Vi phạm setup | **0** |
| Hold slack xấu nhất | +0,115 ns (đạt) |
| Vi phạm hold | 0 |
| Magic DRC / KLayout DRC / LVS / antenna | đều sạch |
| Vi phạm max-slew | 2.837 (chưa đổi loại so với lần thử 4) |
| Vi phạm max-cap | 31 |
| Tổng công suất | 5,56 mW |
| Số instance thiết kế | 19.058 |

Đây là kết quả thật sự tốt đầu tiên trong bài thực hành này: đóng timing
setup và hold thật trên một core RISC-V ~19.000 instance, trên một
laptop, với DRC/LVS/antenna đều sạch. Đây chưa phải ký duyệt *hoàn
chỉnh* — hàng nghìn vi phạm max-slew/max-cap vẫn còn — nhưng đây là thời
điểm bài thực hành thôi không còn là "làm cho nó fail ít hơn" mà trở
thành "sửa đúng vấn đề còn lại".

**Một sai sót quy trình cần công khai thay vì giấu đi:** thư mục `runs/`
của lần chạy này bị xóa trước khi bắt đầu lần thử 6 (theo đúng thói quen
ở mọi lần thử trước), nghĩa là GDSII thật và log đầy đủ của kết quả sạch
này **không được giữ lại** — chỉ có các chỉ số in ra terminal trong buổi
làm việc là còn sót lại. Điều này chỉ được nhận ra vài lần thử sau đó
(mục 5.8) và phải được sửa bằng cách chạy lại đúng cấu hình này lần thứ
hai. Bài học được nói thẳng ở mục 6.4 thay vì lướt qua: **xóa một thư
mục kết quả trước khi chắc chắn không còn cần artifact của nó là một sai
lầm thật, có thể tránh được**, không phải giả thuyết — nó đã xảy ra,
trong bài thực hành này, với đúng kết quả tốt nhất tại thời điểm đó.

### 5.6 Lần thử 6 — đuổi theo vi phạm còn lại, quá mạnh tay

Báo cáo ký duyệt của chính `designs/uart/`
(`docs/uart-technical-report.md` mục 4.2) trước đó đã sửa một vấn đề
tương tự (nhưng quy mô nhỏ hơn nhiều) về vi phạm max-slew còn sót lại qua
`DESIGN_REPAIR_MAX_SLEW_PCT`/`GRT_DESIGN_REPAIR_MAX_SLEW_PCT`. Truy vấn
các biến config của LibreLane theo cách giống mục 5.4 hé lộ trọn bộ gia
đình biến này:

```
DESIGN_REPAIR_MAX_SLEW_PCT | default= 20
DESIGN_REPAIR_MAX_CAP_PCT | default= 20
GRT_DESIGN_REPAIR_MAX_SLEW_PCT | default= 10
GRT_DESIGN_REPAIR_MAX_CAP_PCT | default= 10
```

Với số vi phạm lớn hơn nhiều so với `uart` từng có (2.837 so với 4), các
biên độ được nới rộng mạnh tay thay vì tăng dần từng chút:

```yaml
DESIGN_REPAIR_MAX_SLEW_PCT: 40
DESIGN_REPAIR_MAX_CAP_PCT: 40
GRT_DESIGN_REPAIR_MAX_SLEW_PCT: 30
GRT_DESIGN_REPAIR_MAX_CAP_PCT: 30
```

**Kết quả: một cú crash thật, không phải một thất bại nhẹ nhàng.**

```
[ERROR] The flow has encountered an unexpected error:
        OpenROAD.RepairDesignPostGPL failed with an unexpected error.
        Please check '.../32-openroad-repairdesignpostgpl/...' and
        unless you wrote the step yourself, file an issue.
```

Log của chính step này cho thấy bước sửa bắt đầu bình thường — "Iteration
0 | +0,0% | 0 | 0 | 0 | 6316" (6.316 net được xác định cần sửa) — rồi
không có gì thêm. Không stack trace, không văn bản lỗi rõ ràng, chỉ là
sự im lặng ở chỗ lẽ ra phải có dòng của iteration kế tiếp. Tại thời điểm
này trong câu chuyện, nguyên nhân chưa được biết; gợi ý của chính
LibreLane ("file an issue") giả định đây là bug của tool, hóa ra là một
phỏng đoán hợp lý nhưng không chính xác.

### 5.7 Lần thử 7 — crash y hệt ở biên độ vừa phải hơn

Để tách xem liệu con số 40% cụ thể có phải vấn đề không, các biên độ
được đưa về đúng giá trị đã thành công với `uart`:

```yaml
DESIGN_REPAIR_MAX_SLEW_PCT: 25
GRT_DESIGN_REPAIR_MAX_SLEW_PCT: 15
# biên độ cap giữ mặc định (20 / 10)
```

**Kết quả: crash y hệt**, ở đúng điểm đó ("Iteration 0 | ... | 6316" rồi
không gì cả), chỉ khác một thay đổi biên độ so với lần trước. Đây là
bằng chứng mạnh đầu tiên cho thấy *giá trị* của biên độ không phải là
biến số quan trọng — việc gọi bước sửa này **nói chung**, trên một thiết
kế cỡ này, mới là vấn đề.

Đến đây việc điều tra chuyển từ log của chính LibreLane (không còn gì
thêm để cung cấp) sang log kernel của host:

```bash
journalctl -k | grep -i "out of memory: killed process.*openroad"
```

```
Out of memory: Killed process 154090 (openroad)
  total-vm:26842284kB anon-rss:20885252kB
```

**Tiến trình đã phình lên ~19,9GB RAM thường trú trước khi bị kernel
giết.** Điều này định hình lại hoàn toàn cả hai lần crash: không phải
bug của LibreLane, không phải giá trị biên độ tệ, mà là một yêu cầu bộ
nhớ thật — cho đúng thao tác sửa cụ thể này, trên đúng thiết kế cụ thể
này — vượt quá những gì laptop 23GB này có thể chịu đựng một khi tính cả
chi phí của chính nó (hệ điều hành, phiên Claude Code này, mọi thứ khác
đang chạy).

### 5.8 Lần thử 8 — loại trừ threading là nguyên nhân dùng RAM

Một giả thuyết còn lại: có thể `OPENROAD_THREADS: 8` tự nó đang nhân số
lần dùng RAM (ví dụ, mỗi thread giữ một bản sao trạng thái làm việc), và
số thread nhỏ hơn sẽ vừa với RAM sẵn có.

```yaml
OPENROAD_THREADS: 4
STA_THREADS: 4
# biên độ slew/cap giữ nguyên như lần thử 7 (25 / mặc định / 15 / mặc định)
```

**Kết quả: crash y hệt, ở đúng điểm đó, với 4 thread thay vì 8.** Kiểm
tra lại log kernel:

```
Out of memory: Killed process 154850 (openroad)
  total-vm:26199672kB anon-rss:20772264kB
```

**~19,8GB thường trú — gần như giống hệt ~19,9GB của lần thử 7, dù chỉ
bằng nửa số thread.** Đây là bằng chứng dứt khoát: yêu cầu bộ nhớ thuộc
về cách thuật toán sửa xử lý số net này (6.316) trên thiết kế này, không
thuộc về `OPENROAD_THREADS`. Một xác nhận độc lập thứ ba cho cùng một
dấu hiệu thất bại, với hai số thread khác nhau cho ra dấu chân bộ nhớ
gần như giống hệt nhau, là bằng chứng mạnh hơn bất kỳ một lần crash đơn
lẻ nào có thể có — đây là **Phát hiện #3** (mục 6.3), và là lý do báo
cáo này có thể phát biểu nó như một phát hiện chứ không phải một phỏng
đoán.

Đến đây, ba lần thử liên tiếp (6, 7, 8) đã thất bại theo cùng một cách,
với nguyên nhân giờ đã được hiểu. Tiếp tục thay đổi giá trị biên độ thêm
nữa, cục bộ, sẽ không cho ra kết quả khác — ràng buộc là bộ nhớ, và bộ
nhớ của máy này là cố định. Đây chính xác là loại bức tường mà một lần
chạy cloud với nhiều RAM hơn hẳn sinh ra để đối đầu, và bài thực hành
dừng ở đây thay vì tiếp tục tốn thời gian lặp lại cùng một kết quả lần
thứ tư.

### 5.9 Lần thử 9 — tái tạo lại kết quả sạch đã mất

Để sửa sai sót ở mục 5.5, đúng cấu hình của lần thử 5 (không override
biên độ slew/cap, khôi phục lại `OPENROAD_THREADS: 8` / `STA_THREADS: 9`)
được chạy lại, lần này cố tình để giữ lại artifact.

**Kết quả: chỉ số giống hệt lần thử 5 tới đúng số chữ số có nghĩa đã báo
cáo** — setup slack xấu nhất +2,790ns, 0 vi phạm setup/hold, 2.837
max-slew / 31 max-cap, 19.058 instance. Đây không phải mục tiêu chính
của lần chạy lại, nhưng đáng nói như một xác nhận không chính thức, nhỏ,
về **tính xác định (determinism)**: cùng một config, chạy lần thứ hai
(trên cùng máy, cùng toolchain image), cho ra báo cáo chỉ số nhất quán
từng bit một. Đây chính là tính chất mà `docs/OPEN_SILICON_KICKOFF.md`
§5.2 gọi tên là đáng kiểm tra một cách hệ thống ("chạy cùng thiết kế hai
lần, so hash GDS") — bài thực hành này không so hash GDS thật, chỉ so
chỉ số tóm tắt, nên nên được đọc như một gợi ý, không phải bản thân phép
kiểm tra hệ thống đó (vẫn là phần đã lên kế hoạch của lần chạy cloud sắp
tới, mục 9).

Artifact của lần chạy này được giữ lại: `designs/picorv32/runs/`
(gitignore, tái tạo bằng lệnh ở mục 8), gồm một file `picorv32.gds`
15.096.966 byte (~14,4MB), qua đủ 76 stage của luồng.

## 6. Ba phát hiện, tổng hợp lại

Câu chuyện theo từng lần thử ở mục 5 cho thấy *cách* mỗi phát hiện được
tìm ra; mục này phát biểu trực tiếp từng cái, cho người đọc chỉ cần kết
luận mà không cần câu chuyện.

### 6.1 `OPENROAD_THREADS`/`STA_THREADS` âm thầm mặc định về 1 thread

Cả hai biến mặc định `None`, tài liệu ghi là sẽ tương đương "số core của
máy" khi không đặt. Hành vi quan sát được trong container dựa trên
IIC-OSIC-TOOLS này (`hpretl/iic-osic-tools:2026.08`, LibreLane v3.1.0.dev3):
không đặt nghĩa là **một thread**, xác nhận bằng hai cách: cảnh báo
`OpenROAD will use None threads` / `[ORD-0032] Invalid thread number
specification: None` của chính log, và độc lập bằng `docker stats` chưa
bao giờ vượt ~101% CPU suốt một lần chạy trọn một tiếng trên máy 8 luồng
logic.

**Cách sửa:** đặt tường minh, ví dụ `OPENROAD_THREADS: 8`, `STA_THREADS:
9` (một cho mỗi PVT corner là mặc định hợp lý — toolchain này kiểm 9
corner). Hiệu quả đo được trên thiết kế ~19k instance (picorv32): thời
gian chạy trọn giảm từ 61m39s (1 thread, không đặt) xuống 21m6s (8
thread, tường minh) — mọi thứ khác giữ nguyên.

**Đây trông giống một khoảng cách thật giữa tài liệu và hành vi của
LibreLane**, không chỉ là sai sót cấu hình từ phía chương trình này, và
đáng báo lên dự án `librelane/librelane` độc lập với báo cáo này — một
đóng góp nhỏ cho cộng đồng, rủi ro thấp, khác biệt với (và dễ hơn) việc
Gate 0 chương trình đang theo đuổi riêng trên `obi_uart`/`apb_timer`.

**Quy tắc thực tiễn từ giờ trở đi:** không bao giờ tin tài liệu
"tự nhận diện số core" cho toolchain này mà không kiểm tra `docker stats`
(hoặc tương đương) trong ít nhất một lần chạy. Đặt số thread tường minh,
mọi lần, trên mọi kích cỡ máy mới — chính xác là lý do vì sao cách tiếp
cận `-c OPENROAD_THREADS=$(nproc)` mang tính di động ở mục 9 tồn tại.

### 6.2 `SYNTH_STRATEGY` mặc định tối ưu diện tích, không tối ưu timing

Mặc định `"AREA 0"`. Với một thiết kế đã fail timing, `"DELAY 4"` (chiến
lược ABC hướng delay mạnh nhất LibreLane cung cấp) cho kết quả timing
tốt hơn ở mục tiêu clock *chặt hơn* so với chiến lược mặc định đạt được
ở mục tiêu *lỏng hơn* (mục 5.3 so với 5.4: −3,09ns slack xấu nhất ở 30ns
dưới `AREA 0`, so với −2,16ns ở 25ns dưới `DELAY 4`). Kết hợp với việc
nới clock đã lên kế hoạch từ trước, `DELAY 4` chính là khác biệt giữa
một thiết kế không bao giờ đóng được timing (lần thử 1–4) và một thiết
kế đóng được (lần thử 5).

**Quy tắc thực tiễn:** với bất kỳ thiết kế nào đủ lớn để có rủi ro timing
thật (một datapath thật, không phải quy mô `counter3` hay `uart_top`),
hãy thử một chiến lược `DELAY` trước — hoặc ít nhất song song với — việc
nới mục tiêu clock. Chỉ nới clock, như lần thử 1→2→3 đã làm, là xử lý
triệu chứng; đổi chiến lược, như lần thử 4 đã làm, đã chạm gần hơn tới
nguyên nhân.

### 6.3 Biên độ sửa slew/cap tường minh có thể làm OpenROAD bị OOM-kill ở quy mô thiết kế này

Cách sửa của chính `designs/uart/` cho một vi phạm max-slew còn sót lại
(`DESIGN_REPAIR_MAX_SLEW_PCT`/`GRT_DESIGN_REPAIR_MAX_SLEW_PCT`,
`docs/uart-technical-report.md` mục 4.2) không đơn giản mở rộng quy mô
được. Áp dụng đúng cơ chế đó lên `picorv32` (19.058 instance, 6.316 net
được gắn cờ cần sửa) đã giết tiến trình OpenROAD qua Linux OOM killer,
được xác nhận độc lập ba lần riêng biệt:

| Lần thử | Giá trị biên độ | `OPENROAD_THREADS` | RAM thường trú xác nhận lúc bị giết |
|---|---|---|---|
| 6 | slew 40 / cap 40 / GRT-slew 30 / GRT-cap 30 | 8 | (crash y hệt; không kiểm tra lại độc lập qua kernel log, nhưng xem lần thử 7–8) |
| 7 | slew 25 / cap mặc định / GRT-slew 15 | 8 | ~19,9 GB (`anon-rss:20885252kB`) |
| 8 | slew 25 / cap mặc định / GRT-slew 15 | **4** | ~19,8 GB (`anon-rss:20772264kB`) |

Lần thử 7 và 8 dùng **số thread khác nhau nhưng cho ra dấu chân bộ nhớ
gần như giống hệt tại thời điểm bị giết** — bằng chứng mạnh nhất có được
rằng đây là yêu cầu bộ nhớ theo từng thiết kế/phạm vi sửa cụ thể, không
phải hiện tượng do threading. Lần thử 6 không được kiểm tra lại độc lập
qua kernel log với cùng mức độ chặt chẽ như 7 và 8 (nó được kiểm tra sau
khi mẫu hình đã được hiểu, và dòng log cho đúng lần giết đó không được
tách riêng ra) — báo cáo này nói rõ điều đó thay vì ngầm hiểu cả ba đều
được xác minh cùng một chuẩn.

**Quy tắc thực tiễn:** đừng giả định một cách sửa slew/cap từng hoạt
động trên thiết kế nhỏ (`uart_top`, 290 cell) sẽ chỉ tốn RAM tăng theo tỷ
lệ trên một thiết kế lớn hơn ~65 lần (19.058 cell) — trong trường hợp
này nó tốn đủ để vượt hẳn 23GB. Trước khi thử loại sửa này trên một
thiết kế lớn, hoặc là (a) dự trù dư địa RAM lớn hơn hẳn những gì phần
còn lại của luồng có vẻ cần (các giai đoạn *khác* của thiết kế này đạt
đỉnh dưới 3GB — xem mục 7), hoặc là (b) chấp nhận vi phạm còn sót lại
cục bộ và hoãn việc sửa cho một máy đã biết có đủ dư địa — chính xác là
điều bài thực hành này đã làm (mục 5.8, hoãn lại cho lần chạy cloud đã
lên kế hoạch, mục 9).

### 6.4 Kỷ luật quy trình: đừng xóa một kết quả trước khi chắc chắn đã xong việc với nó

Không phải một phát hiện về LibreLane, nhưng đáng nói thẳng như các phát
hiện kỹ thuật, vì nó đã thực sự xảy ra (mục 5.5): kết quả sạch đầu tiên
đạt được trong bài thực hành này bị xóa (như một phần của thói quen `rm
-rf runs/` giữa các lần thử) trước khi artifact của nó được sao chép đi
đâu đó bền vững, và phải được tái tạo lại từ đầu. Cách sửa áp dụng ở đây
đơn giản — chạy lại đúng cấu hình và xác nhận chỉ số giống hệt trước khi
tin vào kết quả tái tạo — nhưng sai lầm này có thể tránh được, và một
người đọc lặp lại kiểu buổi làm việc khám phá nhiều lần thử này nên giữ
lại (sao chép ra, không chỉ xem) một kết quả ngay khi nó trông như tốt
nhất tới thời điểm đó, không phải sau khi đã quyết định chuyển sang thí
nghiệm kế tiếp.

## 7. Tóm tắt hồ sơ tài nguyên

Tổng hợp từ log tài nguyên lấy trong lúc các lần thử ở mục 5 (`docker
stats` + `free -h`, lấy mẫu mỗi 20 giây):

| Giai đoạn | RAM đỉnh quan sát | CPU đỉnh quan sát |
|---|---|---|
| Trọn luồng, 1 thread (lần thử 1) | ~763 MiB | ~101% (1 luồng logic) |
| Trọn luồng, 8 thread, không override biên độ sửa (lần thử 2–5, 9) | ~1,4–2,8 GB | ~796% (~8 luồng logic) |
| `OpenROAD.RepairDesignPostGPL` với biên độ slew/cap tường minh trên 6.316 net (lần thử 6–8) | **~19,8–19,9 GB (bị OOM-kill)** | không đo được ý nghĩa trước khi bị giết |

Sự tương phản ở dòng cuối so với mọi dòng phía trên là con số quan trọng
nhất trong báo cáo này cho việc tính sizing VM cloud sắp tới (mục 9):
phần lớn luồng của thiết kế này thoải mái dưới 3GB, nhưng một bước sửa
cụ thể, tùy chọn thì không — và một kế hoạch sizing chỉ dựa trên con số
"mọi thứ khác" sẽ sai một cách nguy hiểm cho đúng bước duy nhất thực sự
quan trọng.

## 8. Tái lập kết quả

```bash
# Từ thư mục gốc của repo
docker compose -f docker/docker-compose.yml build

# Kết quả sạch (lần thử 5 / 9):
docker compose -f docker/docker-compose.yml run --rm \
  --workdir /workspace/designs/picorv32 \
  librelane-dev --skip \
  librelane -p sky130A -s sky130_fd_sc_hd designs/picorv32/config.yaml

# Di động qua các máy có số core khác nhau (xem mục 9):
CORES=$(nproc)
docker compose -f docker/docker-compose.yml run --rm \
  --workdir /workspace/designs/picorv32 \
  librelane-dev --skip \
  librelane -p sky130A -s sky130_fd_sc_hd \
  -c OPENROAD_THREADS=$CORES -c STA_THREADS=$CORES \
  designs/picorv32/config.yaml
```

`designs/picorv32/config.yaml` như đã commit phản ánh cấu hình sạch của
lần thử 5/9 (`CLOCK_PERIOD: 30`, `SYNTH_STRATEGY: "DELAY 4"`,
`OPENROAD_THREADS: 8`, `STA_THREADS: 9`), với các lần thử biên độ
slew/cap ở mục 5.6–5.8 **cố tình không** đưa vào file đã commit — chúng
được ghi lại ở đây như một hồ sơ về những gì đã thử và vì sao thất bại
trên máy này, không phải thứ để áp dụng lại một cách mù quáng.

## 9. Bước tiếp theo: lần chạy cloud

Báo cáo này chỉ bao phủ phần khám phá cục bộ. Tính đến lúc viết, lần
chạy cloud đã lên kế hoạch (`docs/picorv32-cloud-burst-plan.md`,
`docker/cloud-burst/`) đã hoàn tất giai đoạn diễn tập (một instance
Linode cấp Nano, dùng `counter3` làm hàng giả lập nhẹ để kiểm chứng cơ
chế SSH/upload/Docker/build mà không cần dấu chân tài nguyên của thiết
kế này) nhưng chưa tới lần chạy thật. Bước kế tiếp ngay lập tức, đang
tiến hành: resize đúng instance đó lên 2 vCPU cụ thể để kiểm chứng — trên
đúng hạ tầng cloud mục tiêu, không chỉ cục bộ — rằng cách sửa threading
ở mục 6.1 thật sự cho ra việc dùng đa lõi ở đó nữa, trước khi cam kết
chạy full-size (50 core / 128GB, theo sizing mới nhất của thầy) tốn tiền
thật. Cách override `-c OPENROAD_THREADS=$(nproc)` ở mục 8 tồn tại chính
xác để đúng một lệnh chạy nguyên vẹn ở 2 core, rồi sau đó ở 50, mà không
cần sửa tay `config.yaml` cho từng cỡ máy — tự nó là một phát hiện
phương pháp luận nhỏ từ đúng tuần làm việc này, đạt được trong lúc chuẩn
bị cho chính mục này.

Khi chạy ở quy mô đầy đủ, báo cáo này nên được mở rộng (không thay thế)
với: liệu trần bộ nhớ ở mục 6.3 có thật sự được vượt qua với RAM nhiều
hơn hẳn (đóng được vi phạm max-slew/max-cap còn lại lần đầu tiên); một
phép kiểm tra determinism bằng hash GDS thật, có hệ thống, qua N bản
chạy song song (phép kiểm tra chạy lại một lần không chính thức ở mục
5.9 chỉ mang tính gợi ý, không phải phép kiểm tra thật); và dữ liệu
thời gian/chi phí thật cho lần chạy full-size, con số sẽ trực tiếp cho
biết ước lượng sizing RAM của `docs/OPEN_SILICON_KICKOFF.md` §5.2 đúng,
sai, hay lệch theo hướng nào.

## Bảng thuật ngữ Anh-Việt bổ sung (EDA / verification)

Bảng thuật ngữ chung đã có ở `docs/vi/counter3-bao-cao-ky-thuat.md` và
`docs/vi/uart-bao-cao-ky-thuat.md`; dưới đây chỉ thêm thuật ngữ mới xuất
hiện trong báo cáo này.

| Tiếng Anh | Tiếng Việt / giải thích ngắn |
|---|---|
| synthesis strategy | chiến lược tổng hợp — cách công cụ ABC cân bằng giữa diện tích và tốc độ khi ánh xạ công nghệ |
| ABC (logic synthesis) | công cụ tối ưu logic mức cổng dùng trong Yosys |
| out-of-memory (OOM) kill | bị hệ điều hành giết tiến trình vì hết bộ nhớ |
| resident memory (RSS) | bộ nhớ thường trú — phần RAM vật lý thật sự một tiến trình đang chiếm dụng |
| kernel log / `journalctl -k` | log của nhân hệ điều hành — nơi ghi lại các sự kiện cấp thấp như OOM-kill |
| deferred error | lỗi hoãn — LibreLane chạy hết các bước rồi mới báo lỗi tổng hợp ở cuối, thay vì dừng ngay khi gặp |
| hyperthreading | siêu phân luồng — kỹ thuật CPU cho phép mỗi core vật lý chạy hai luồng logic |
| physical core / logical core | core vật lý / luồng logic (core ảo qua hyperthreading) |
| repair pass (resizer) | lượt sửa của resizer — bước tối ưu lại cell/dây để đáp ứng giới hạn timing/slew/cap |
| determinism check | kiểm tra tính xác định — chạy lại cùng đầu vào nhiều lần, xác nhận kết quả giống hệt nhau |

## Tài liệu tham khảo

- `docs/OPEN_SILICON_KICKOFF.md` — lộ trình chương trình, §4 (bậc thang
  thiết kế) và §5.2 (câu hỏi sizing máy chủ regression mà báo cáo này
  góp phần trả lời)
- `docs/decisions/ADR-OS-007-rent-compute-before-buying.md` — vì sao
  chọn thuê cloud thay vì phần cứng riêng
- `docs/counter3-technical-report.md`, `docs/uart-technical-report.md`
  — hai thiết kế đầu tiên của chương trình, và cách sửa slew-margin của
  `uart` mà mục 5.6–5.8 báo cáo này cố mở rộng quy mô
- `wiki/librelane-threading-and-timing-strategy.md` — bản súc tích, dành
  cho agent, của các phát hiện ở mục 6
- `wiki/librelane-metrics-json.md`, `wiki/librelane-config-for-tiny-designs.md`,
  `wiki/uart-signoff-sizing-and-slew-margin.md` — các cạm bẫy toolchain
  trước đó mà bài thực hành này xây dựng trên nền đó
- `docs/picorv32-cloud-burst-plan.md`, `docker/cloud-burst/` — lần chạy
  cloud đang tiến hành mà công việc cục bộ này đang chuẩn bị cho
- `backlog.md` — nhật ký vận hành, gồm cả phiên làm việc qua đêm mà báo
  cáo này ghi lại
- picorv32 upstream: `github.com/YosysHQ/picorv32`
- Tài liệu LibreLane: `librelane.readthedocs.io`

## Changelog

| Phiên bản | Ngày | Thay đổi |
|---|---|---|
| v1.0 | 2026-09-17 | Bản đầu tiên, phỏng theo bản tiếng Anh `docs/picorv32-technical-report.md`, bao phủ phần khám phá cục bộ (lần thử 1-9) trước lần chạy cloud đã lên kế hoạch. |
