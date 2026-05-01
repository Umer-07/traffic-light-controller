# Traffic Light Controller

A SystemVerilog finite state machine (FSM) that controls a traffic light sequence with pedestrian crossing logic.

---

## State machine

```
         reset
           │
           ▼
  ┌──────────────┐   timer done    ┌──────────────┐
  │     RED      │ ──────────────► │    GREEN     │
  └──────────────┘                 └──────────────┘
          ▲                               │ timer done
          │                               ▼
          │                        ┌──────────────┐
          │   timer done, no btn   │    YELLOW    │
          │ ◄────────────────────── └──────────────┘
          │                               │ timer done
          │                               │ + ped_btn latched
          │                               ▼
          │   walk timer done      ┌──────────────┐
          └──────────────────────── │     WALK     │
                                   └──────────────┘
```

Pedestrian flow:
1. Car traffic gets GREEN.
2. Pedestrian presses button — the request is latched.
3. GREEN timer expires → YELLOW.
4. YELLOW timer expires → WALK (cars stay RED, walk signal on).
5. WALK timer expires → back to normal RED → GREEN cycle.

---

## Project structure

```
traffic-light-controller/
├── rtl/
│   └── traffic_light.sv        Main FSM design
├── tb/
│   └── traffic_light_tb.sv     Self-checking testbench
├── screenshots/
│   └── waveform.png            GTKWave screenshot (add after sim)
└── README.md
```

---

## How to run (Icarus Verilog)

### Install

```bash
# macOS
brew install icarus-verilog gtkwave

# Ubuntu / WSL
sudo apt install iverilog gtkwave
```

### Compile and simulate

```bash
iverilog -g2012 -o sim \
  rtl/traffic_light.sv \
  tb/traffic_light_tb.sv

vvp sim
```

You should see PASS lines in the terminal and a `traffic_light.vcd` file created.

### View waveform

```bash
gtkwave traffic_light.vcd
```

In GTKWave:
1. Expand `traffic_light_tb` in the left panel.
2. Drag `clk`, `rst_n`, `ped_btn`, `red`, `yellow`, `green`, `walk` into the signal view.
3. Press **Ctrl+Shift+F** to zoom to fit.
4. Take a screenshot and save it to `screenshots/waveform.png`.

### Run on EDA Playground (no install)

1. Go to https://edaplayground.com
2. Paste `traffic_light.sv` into the left (Design) panel.
3. Paste `traffic_light_tb.sv` into the right (Testbench) panel.
4. Select **Icarus Verilog 12.0** as the simulator, tick **Open EPWave**.
5. Click **Run**.

---

## Skills demonstrated

- FSM design (Moore machine, 4 states)
- Sequential logic with `always_ff`
- Combinational output and next-state logic with `always_comb`
- Timer / counter implementation
- Pedestrian request latch (sticky button)
- Self-checking testbench with `$display` pass/fail
- VCD waveform generation for GTKWave

---

## Extending the project (ideas)

| Idea | What you learn |
|---|---|
| Add a second road (4-way intersection) | More states, interlock logic |
| Parameterise timer lengths | SystemVerilog parameters |
| Add a 7-segment countdown display | Output encoding |
| Implement in hardware (FPGA) | Synthesis, timing constraints |
