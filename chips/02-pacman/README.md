# 02-pacman

**Authors:** 
- Maria Krumm
- Johannes Jäger
- Max Kreutzer
- Illia Spasonov

## Description


This chip manages a Pacman implementation by integrating player movement, ghost ai logic and game state transitions. It tracks level progress, scoring and item consumption while coordinating interactions between other game elements. We display the game screen with a vga out signal with 640 x 480 resolution and 25.175 MHz.

## Pin List

| Pin | Direction | Description |
|---|---|---|
| `clk_PAD` | Input | Main clock |
| `rst_n_PAD` | Input | Synchronous reset (active high) |
| `button_up_PAD` | Input | Button for game controls |
| `button_down_PAD` | Input | Button for game controls |
| `button_left_PAD` | Input | Button for game controls |
| `button_right_PAD` | Input | Button for game controls |
| `uo_out_PAD[0]` | Output | VGA Output red higher order bit |
| `uo_out_PAD[1]` | Output | VGA Output green higher order bit |
| `uo_out_PAD[2]` | Output | VGA Output blue higher order bit |
| `uo_out_PAD[3]` | Output | VGA Output VSync |
| `uo_out_PAD[4]` | Output | VGA Output red lower order bit |
| `uo_out_PAD[5]` | Output | VGA Output green lower order bit |
| `uo_out_PAD[6]` | Output | VGA Output blue lower order bit |
| `uo_out_PAD[7]` | Output | VGA Output HSync |