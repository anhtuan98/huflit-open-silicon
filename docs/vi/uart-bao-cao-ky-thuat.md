# uart_top — Thiết kế RTL-to-GDSII thứ hai: Báo cáo kỹ thuật

> Tài liệu học tập nguyên bản tiếng Việt (mục đích #2 của `docs/vi/README.md`)
> — không bắt buộc gửi upstream. Bản gốc tiếng Anh:
> [`docs/uart-technical-report.md`](../uart-technical-report.md).

| | |
|---|---|
| **Chương trình** | HUFLIT Open Silicon (mật danh Vega) |
| **Thiết kế** | [`designs/uart/`](../../designs/uart/) |
| **Mốc** | Giai đoạn 0, tuần 3-6 (`docs/OPEN_SILICON_KICKOFF.md` §4) — thiết kế học tập thứ hai, tùy chọn |
| **Ngày chạy** | 2026-09-15 |
| **Trạng thái** | Hoàn tất ký duyệt đầy đủ DRC/LVS/timing. Không nộp shuttle (ADR-OS-003) |
| **Đối tượng đọc** | Tài liệu giảng dạy — bài đi kèm [`docs/vi/counter3-bao-cao-ky-thuat.md`](counter3-bao-cao-ky-thuat.md), ví dụ thực hành đầu tiên của chương trình |

## Tóm tắt

Tài liệu này ghi lại `uart_top`, thiết kế thứ hai chạy trọn luồng
RTL-to-GDSII trong chương trình HUFLIT Open Silicon: một cặp UART
transmitter (TX) và receiver (RX) theo chuẩn 8N1. Nếu `counter3` (thiết
kế đầu tiên) cố tình rất đơn giản, thì `uart_top` được chọn chính vì nó
**không** đơn giản — có máy trạng thái (FSM) thật ở cả hai phía TX và RX,
một bộ đếm định thời bit, và một input bên ngoài không có clock cần được
đồng bộ hóa trước khi dùng. Kết quả tạo ra một sự đối lập thú vị với
`counter3` ở phần triển khai vật lý: thiết kế này sizing floorplan mặc
định chạy được luôn, không cần tinh chỉnh thủ công gì cả — ngược hẳn với
trải nghiệm của `counter3`, và chính điều này là bài học trọng tâm của
báo cáo: khi nào thật sự cần "vá" cho thiết kế tí hon, khi nào không. Một
vấn đề ký duyệt mới — vi phạm max-slew sau khi đi dây chi tiết, chỉ xuất
hiện ở một PVT corner — cũng được ghi lại đầy đủ, kèm một cạm bẫy khi đọc
log của chính luồng LibreLane.

## 1. Mục đích và bối cảnh

Theo `docs/OPEN_SILICON_KICKOFF.md` §4, tuần 3-6 của Giai đoạn 0 chỉ yêu
cầu **một** thiết kế tự viết chạy trọn ký duyệt — `counter3` đã tự thỏa
mãn cổng đó rồi (xem `docs/vi/counter3-bao-cao-ky-thuat.md`). `uart_top`
được làm thêm sau đó như một thiết kế thứ hai, hoàn toàn tùy chọn, vì hai
lý do đã nêu khi quyết định làm:

1. **Chạm nhiều hơn vào luồng.** `counter3` chỉ là ba flip-flop và một bộ
   cộng; việc triển khai vật lý của nó cần tinh chỉnh thủ công **chính vì**
   nó nhỏ đến mức đó (mục 5.1 báo cáo counter3). Một thiết kế có FSM thật,
   nhiều thanh ghi hơn, và một input trông như bất đồng bộ từ bên ngoài sẽ
   kiểm tra xem việc tinh chỉnh đó có áp dụng chung được hay chỉ là hiện
   tượng riêng của một thiết kế cực nhỏ.
2. **Diễn tập cho mục tiêu Cổng 0 thật.** Mốc tiếp theo của chương trình
   (tuần 7-12) là đóng góp một testbench cocotb cho một IP mã nguồn mở
   thật — cụ thể là `obi_uart` (`pulp-platform/obi_peripherals`, chọn sau
   khi rà soát shortlist — xem `backlog.md`). Tự viết testbench UART của
   riêng mình trước — đóng khung byte, kiểm tra bit start/data/stop, lái
   một input serial từ bên ngoài — chính là diễn tập trực tiếp cho phần
   kiểm tra đóng khung byte mà testbench kia cũng cần, trước khi thêm vào
   giao thức bus riêng của `obi_uart`.

## 2. Thiết kế RTL

Thiết kế tách thành hai module độc lập cộng một wrapper top-level chỉ để
khởi tạo cả hai:
[`designs/uart/src/uart_tx.v`](../../designs/uart/src/uart_tx.v),
[`designs/uart/src/uart_rx.v`](../../designs/uart/src/uart_rx.v),
[`designs/uart/src/uart_top.v`](../../designs/uart/src/uart_top.v).

```verilog
module uart_top #(
    parameter CLKS_PER_BIT = 4
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       tx_start,
    input  wire [7:0] tx_data,
    output wire       tx_serial,
    output wire       tx_busy,
    input  wire       rx_serial,
    output wire [7:0] rx_data,
    output wire       rx_done
);
```

`tx_serial` và `rx_serial` là hai cổng top-level tách biệt — không có gì
bên trong thiết kế này nối TX với RX. Loopback (cần để kiểm tra hai nửa
đối chiếu nhau) là việc của testbench hoặc của board, không phải của
RTL. Đây là lựa chọn interface có chủ đích: mô phỏng đúng cách một UART
peripheral thật trong một SoC lớn hơn sẽ đưa ra hai chân độc lập cho thế
giới bên ngoài.

### 2.1 Transmitter: FSM 4 trạng thái trên một bộ đếm định thời bit

`uart_tx` đóng khung một byte thành 1 bit start (0) + 8 bit dữ liệu
(LSB trước) + 1 bit stop (1), dùng FSM 4 trạng thái
(`IDLE → START → DATA → STOP → IDLE`). Mỗi trạng thái giữ trong
`CLKS_PER_BIT` chu kỳ clock trước khi chuyển tiếp — không có miền clock
baud rate riêng, chỉ là một tín hiệu enable chậm hơn được tạo ra bằng
cách đếm cạnh `clk`. `tx_busy` được bật trong suốt thời gian gửi một
khung, cho phía gọi (hoặc trong bài này, testbench) một tín hiệu rõ ràng
về thời điểm có thể bắt đầu byte tiếp theo.

### 2.2 Receiver: lấy mẫu giữa bit, phía sau một bộ đồng bộ hóa

`uart_rx` mô phỏng lại khung của transmitter với FSM 5 trạng thái (thêm
trạng thái `CLEANUP` sau `STOP_BIT` để tạo xung `rx_done` đúng một chu
kỳ). Hai lựa chọn thiết kế đáng nêu tường minh:

- **Lấy mẫu giữa bit (mid-bit sampling).** Receiver đợi
  `(CLKS_PER_BIT - 1) / 2` chu kỳ vào bit start trước khi kiểm tra lại
  nó, và lấy mẫu mỗi bit dữ liệu ở cùng độ lệch đó vào chu kỳ bit của nó.
  Đây là kỹ thuật thu UART chuẩn: lấy mẫu gần **giữa** một bit, thay vì
  ở cạnh của nó, giúp chịu được sai lệch thời gian nhỏ giữa clock của
  transmitter bên ngoài và clock của chính receiver — hai bên không được
  giả định là đồng pha.
- **Bộ đồng bộ hóa hai tầng flip-flop trên `rx_serial`.** Theo định
  nghĩa, `rx_serial` được điều khiển bởi thứ gì đó nằm ngoài miền clock
  của thiết kế này (một transmitter bên ngoài, hoặc trong test loopback
  của chính thiết kế — xem mục 3 — chính là `tx_serial` của module này).
  Trước khi FSM thu nhìn vào nó, `rx_serial` đi qua hai flip-flop liên
  tiếp (`rx_sync`, rồi `rx_serial_sync`). Đây là biện pháp giảm thiểu
  metastability chuẩn cho một input bất đồng bộ đi vào một thiết kế có
  clock — đúng khái niệm "CDC" (clock domain crossing) mà kickoff doc
  §5.3 nhắc tới cho track dạy FPGA, ở đây được áp dụng phòng ngừa dù bài
  thực hành này chỉ có một miền clock vật lý.

## 3. Kiểm thử (Verification)

[`designs/uart/verify/test_uart.py`](../../designs/uart/verify/test_uart.py)
dùng cùng luồng Makefile cổ điển của cocotb như `counter3`, chạy trên
Verilator. Ba test:

1. **`test_tx_frames_byte`** — bắt đầu gửi `0xA5` (chọn vì không phải
   toàn 0 hay toàn 1, nên bắt được lỗi thứ tự bit mà một byte toàn giá
   trị giống nhau sẽ che giấu) và lấy mẫu `tx_serial` mỗi chu kỳ bit một
   lần, kiểm tra trọn khung 10 bit: bit start, 8 bit dữ liệu đúng thứ tự,
   bit stop.
2. **`test_rx_decodes_byte`** — lái một khung 8N1 lý tưởng từ bên ngoài
   (`0x5A`) trực tiếp lên `rx_serial`, kiểm tra `rx_data` khi `rx_done`
   phát xung.
3. **`test_tx_rx_loopback`** — liên tục copy `tx_serial` sang `rx_serial`
   (dây loopback bằng phần mềm) và gửi 5 byte chọn để phủ các trường hợp
   biên (`0x00`, `0xFF`, `0xA5`, `0x3C`, `0x81`), kiểm tra từng byte nhận
   về không đổi.

Cả ba đều pass (3/3). Một điểm phương pháp luận kế thừa trực tiếp từ cạm
bẫy cocotb của `counter3` (xem mục 4.1 báo cáo đó): hàm hỗ trợ bắt đầu
gửi **không** giả định một số chu kỳ cố định cho việc gửi một khung mất
bao lâu. Nó đợi trên chính các lần chuyển trạng thái của tín hiệu
`tx_busy`:

```python
async def start_tx(dut, byte):
    dut.tx_data.value = byte
    dut.tx_start.value = 1
    await RisingEdge(dut.clk)
    dut.tx_start.value = 0
    while int(dut.tx_busy.value) == 0:
        await RisingEdge(dut.clk)
    while int(dut.tx_busy.value) == 1:
        await RisingEdge(dut.clk)
```

Đây là cùng một bài học được tổng quát hóa: ưu tiên đợi trên một tín hiệu
quan sát được thay vì giả định một quan hệ thời gian cố định, ngay cả khi
số chu kỳ cố định đó về nguyên tắc có thể tính ra được.

## 4. Triển khai vật lý (LibreLane)

[`designs/uart/config.yaml`](../../designs/uart/config.yaml), toàn bộ:

```yaml
# Basics
DESIGN_NAME: uart_top
VERILOG_FILES: dir::src/*.v
CLOCK_PERIOD: 10
CLOCK_PORT: clk

# Timing repair
DESIGN_REPAIR_MAX_SLEW_PCT: 25
GRT_DESIGN_REPAIR_MAX_SLEW_PCT: 15

# Technology-Specific Configs
pdk::sky130*:
  CLOCK_PERIOD: 10.0
```

Hai điểm nổi bật khi so với config của `counter3`, và cả hai chính là lý
do để làm thiết kế thứ hai này.

### 4.1 Không cần tinh chỉnh floorplan/PDN — và đó chính là phát hiện

Config của `counter3` cần `FP_SIZING: absolute`, một `DIE_AREA` tường
minh được đặt dư dả, và mẫu strap PDN được nới rộng, vì sizing floorplan
mặc định (theo phần trăm) của nó tính ra một die quá nhỏ một khi strap
PDN và buffer sửa hold cần chỗ (xem mục 5.1 báo cáo đó). Không có gì như
vậy ở đây cả. `uart_top` — với 50 sequential cell và khoảng 290 standard
cell tổng cộng, so với 3 và ~22 của `counter3` — ký duyệt sạch với sizing
**mặc định** của LibreLane, tự đạt 75,3% utilization mà không cần can
thiệp thủ công gì.

Đây không phải là mâu thuẫn với phát hiện trước đó; nó xác nhận đúng
phạm vi áp dụng của phát hiện đó. Vấn đề floorplan cho thiết kế tí hon
chỉ xảy ra với thiết kế nhỏ đến mức chi phí PDN và đi dây buffer chiếm áp
đảo diện tích die — một nhúm flip-flop, không phải năm mươi. Quy tắc
thực tiễn mà cặp thiết kế này thiết lập: **thử config tối giản, mặc định
trước; chỉ dùng tới khối `FP_SIZING: absolute` / tuning PDN khi
`PDN-0185` hoặc `DPL-0036` thật sự xuất hiện, hoặc khi
`design__instance__utilization` ở lần thử đầu ra một con số phi lý cao.**
Copy `DIE_AREA` của `counter3` lên mọi thiết kế mới bất kể kích thước là
đang áp dụng máy móc một cách sửa cho một vấn đề có thể không tồn tại.
Bài viết đầy đủ:
[`wiki/uart-signoff-sizing-and-slew-margin.md`](../../wiki/uart-signoff-sizing-and-slew-margin.md).

### 4.2 Một vấn đề ký duyệt mới: max-slew sau đi dây, chỉ một corner

Lần chạy đầu tiên của luồng cho thiết kế này hoàn tất với **4 vi phạm
max-slew** — tất cả chỉ ở corner tiến trình `ss` (chậm), tất cả trên cùng
một net có fanout 3, mỗi cái chỉ vượt giới hạn 0,75 ns khoảng 7%. Nguyên
nhân gốc: các bước sửa thiết kế (resizer) của LibreLane chạy **trước**
khi đi dây chi tiết, nên chúng tối ưu dựa trên ký sinh (parasitics) ước
lượng từ đặt vị trí và đi dây toàn cục, chứ không phải ký sinh cuối cùng
trích xuất từ đi dây chi tiết. Một khoảng chênh nhỏ giữa hai bên có thể
tồn tại đến tận phân tích thời gian tĩnh (STA) sau đi dây cuối cùng, mà
không còn bước nào phía sau để sửa nó.

**Cách sửa:** nới rộng biên sửa slew của chính resizer, để nó nhắm tới
một mức slew khắt khe hơn mức cần thiết trong lúc sửa thiết kế, chừa dư
địa hấp thụ phần suy giảm về sau:

```yaml
DESIGN_REPAIR_MAX_SLEW_PCT: 25       # mặc định 20
GRT_DESIGN_REPAIR_MAX_SLEW_PCT: 15   # mặc định 10
```

Điều này đưa số vi phạm từ 4 về 0 ở lần chạy lại, không cần thay đổi gì
khác.

**Một cạm bẫy khi debug đáng nói riêng:** ở lần chạy bị lỗi, chính bước
`Checker.MaxSlewViolations` của luồng in ra một khối `WARNING` nêu tên
các corner vi phạm, **ngay sau đó** là một dòng `VERBOSE` ghi *"No max
slew violations found"* — từ cùng một bước, trong cùng một lần chạy, và
luồng vẫn thoát với mã 0 ("Flow complete") dù thế nào. **Không thể tin
cậy vào bất kỳ dòng log nào trong hai dòng đó làm kết luận cuối cùng.**
Nguồn đáng tin duy nhất là `design__max_slew_violation__count` trong
`final/metrics.json`, hoặc file `checks.rpt` theo từng corner dưới thư
mục `*-openroad-stapostpnr`, nơi nêu đúng tên pin vi phạm và biên độ.
Log cuối cùng, sạch (sau khi sửa) của lần chạy này ghi rõ ràng, không mơ
hồ: `No max slew violations found` — khớp đúng với chỉ số.

## 5. Kết quả

Các số liệu bên dưới lấy trực tiếp từ
`designs/uart/runs/RUN_2026-09-15_07-44-22/final/metrics.json` (không
commit — tái tạo bằng cách chạy lại luồng theo mục 6).

### 5.1 Số lượng cell và diện tích

| Chỉ số | Giá trị |
|---|---|
| Số bước hoàn tất | 76 / 76, 0 lỗi |
| Standard cell (`design__instance__count__stdcell`) | 290 |
| Sequential cell | 50 |
| Combinational cell | 105 |
| Clock buffer | 16 |
| Hold-fix buffer | 36 |
| Timing-repair buffer (gồm cả phần sửa slew mục 4.2) | 69 |
| Inverter | 2 |
| Fill cell | 207 |
| Tap/endcap cell | 48 |
| Tổng instance được đặt | 497 (= 290 stdcell + 207 fill, cùng cách tính như `counter3` — xem [`wiki/librelane-metrics-json.md`](../../wiki/librelane-metrics-json.md)) |
| Diện tích die | 72,265 µm × 82,985 µm (5.996,91 µm²) |
| Diện tích core | 3.661,01 µm² |
| Độ lấp đầy (utilization) của core | 75,3% |

Ở mức utilization 75,3% so với 5,24% của `counter3`, die của thiết kế
này đang thật sự làm việc — hệ quả vật lý trực tiếp của phát hiện ở mục
4.1.

### 5.2 Timing và công suất

| Chỉ số | Giá trị |
|---|---|
| Chu kỳ clock mục tiêu | 10 ns (100 MHz) |
| Setup slack xấu nhất (trên mọi PVT corner) | +2,52 ns (đạt) |
| Hold slack xấu nhất (trên mọi PVT corner) | +0,12 ns (đạt) |
| Vi phạm setup / hold | 0 / 0 |
| Vi phạm max slew / max cap / max fanout | 0 / 0 / 0 (xem mục 4.2 về cách đưa về 0) |
| Tổng công suất (corner danh định, 25 °C, 1,8 V) | ≈ 566,8 nW |
| — công suất internal | ≈ 457,0 nW |
| — công suất switching | ≈ 109,7 nW |
| — công suất leakage | ≈ 3,5 pW (không đáng kể) |

Cả hai dư địa xấu nhất đều hẹp hơn rõ rệt so với `counter3` (+4,96 ns
setup, +0,41 ns hold) — điều dự tính trước, vì thiết kế này làm việc
thật nhiều hơn theo tỷ lệ trên mỗi chu kỳ clock và có cây clock cao hơn,
fanout lớn hơn (16 clock buffer so với 4). Cả hai vẫn dương thoải mái ở
cùng mục tiêu bảo thủ 100 MHz.

### 5.3 Đi dây và ký duyệt

| Kiểm tra | Kết quả |
|---|---|
| Wirelength / via (global route) | 6.679 / 1.500 |
| Wirelength / via (detailed route) | 3.777 / 1.540 |
| Lỗi Magic DRC | 0 |
| Lỗi KLayout DRC | 0 |
| Lỗi chồng lấn (illegal overlap) Magic | 0 |
| Khác biệt XOR (GDS so với layout) | 0 |
| Lỗi LVS (schematic so với layout) | 0 |
| Vi phạm antenna | 0 |

Mọi bộ kiểm tra trong log của luồng đều báo sạch, theo đúng thứ tự: Lint
sạch → kiểm tra Yosys sạch → power-grid sạch → DRC đi dây sạch → pin mất
kết nối sạch → XOR sạch → Magic DRC sạch → KLayout DRC sạch →
illegal-overlap sạch → LVS sạch → không vi phạm setup → không vi phạm
hold → không vi phạm max slew → không vi phạm max cap. File GDSII cuối
cùng
(`designs/uart/runs/RUN_2026-09-15_07-44-22/final/gds/uart_top.gds`,
~607 KB) chỉ được giữ làm bằng chứng cục bộ — bị gitignore, không phải
tài sản nộp shuttle (ADR-OS-003).

## 6. Tái lập kết quả

```bash
# 1. Build image toolchain (chung với counter3, một lần)
docker compose -f docker/docker-compose.yml build

# 2. Chạy testbench cocotb
docker compose -f docker/docker-compose.yml run --rm \
  --workdir /workspace/designs/uart/verify \
  librelane-dev --skip make

# 3. Chạy trọn luồng LibreLane (PDK phải tường minh -- xem mục 2 báo cáo
#    counter3 để biết lý do)
docker compose -f docker/docker-compose.yml run --rm \
  --workdir /workspace/designs/uart \
  librelane-dev --skip \
  librelane -p sky130A -s sky130_fd_sc_hd config.yaml

# 4. Kiểm tra kết quả
ls designs/uart/runs/RUN_*/final/gds/
cat designs/uart/runs/RUN_*/final/metrics.json
```

## 7. Liên hệ với lộ trình chương trình

Thiết kế này là phần thêm tùy chọn trên một cổng tuần 3-6 đã thỏa mãn
rồi (`counter3` một mình đã đủ). Mục đích của nó từ giờ trở đi là lý do
thứ hai ở mục 1: diễn tập cho việc Cổng 0 thật. Bước kế tiếp cụ thể (theo
dõi trong `backlog.md`) là thăm dò maintainer của
`pulp-platform/obi_peripherals` — xác nhận họ có nhận testbench dựa trên
cocotb không, và register interface của họ (PR #9, đang mở tại thời điểm
viết bài) đã đủ ổn định để nhắm tới chưa — trước khi đầu tư viết
testbench đó, tái sử dụng các mẫu test đóng khung byte của thiết kế này
làm điểm khởi đầu.

## Bảng thuật ngữ Anh-Việt bổ sung (EDA / verification)

Bảng thuật ngữ chung đã có ở
[`docs/vi/counter3-bao-cao-ky-thuat.md`](counter3-bao-cao-ky-thuat.md);
dưới đây chỉ thêm các thuật ngữ mới xuất hiện trong báo cáo này.

| Tiếng Anh | Tiếng Việt / giải thích ngắn |
|---|---|
| finite-state machine (FSM) | máy trạng thái hữu hạn |
| synchronizer (2-flop) | bộ đồng bộ hóa (2 tầng flip-flop) — mạch chống metastability cho tín hiệu bất đồng bộ |
| metastability | siêu ổn định (trạng thái không xác định) — hiện tượng flip-flop rơi vào trạng thái không ổn định khi vi phạm setup/hold |
| clock domain crossing (CDC) | vượt miền clock — tín hiệu đi từ một miền clock sang miền clock khác |
| mid-bit sampling | lấy mẫu giữa bit — kỹ thuật thu UART chuẩn |
| max slew | độ dốc tín hiệu tối đa — tốc độ chuyển mức của tín hiệu, có giới hạn trên |
| resizer | bộ sửa kích thước cell — công cụ tối ưu timing bằng cách đổi kích thước/chèn buffer |
| parasitics | ký sinh (điện trở/điện dung ký sinh) — ảnh hưởng vật lý của dây dẫn lên tín hiệu |
| fanout | số tải — số chân input mà một cổng/net phải điều khiển |

## Changelog

| Phiên bản | Ngày | Thay đổi |
|---|---|---|
| v1.0 | 2026-09-15 | Bản đầu tiên, viết sau lần chạy ngày 2026-09-15, phỏng theo bản tiếng Anh `docs/uart-technical-report.md`. |
