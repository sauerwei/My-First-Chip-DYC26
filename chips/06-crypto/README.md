# 06-cryptographic-chip

**Author:** Tobias Müller, Marius Vodermaier, Maximilian Waidelich

![Logo](./design_data/top-image/images/logo.png)

## Description

Chip that calculates the SHA256 Hash of a Message of arbitrary length. The chip runs at 5kHz and is able to generate 80 hashes per second assuming the message is transferred in 1 clock cycle (which it isn't).

## Pin List

| Pin       | Direction | Description                     |
| --------- | --------- | ------------------------------- |
| `clk`     | Input     | Main clock                      |
| `rst_n`   | Input     | Synchronous reset (active high) |
| `spi_clk` | Input     | SPI clock                       |
| `spi_in`  | Input     | SPI Input lane                  |
| `spi_out` | Output    | SPI Output lane                 |

## Data exchange

The Chip exchanges data over an SPI interface. There are 2 Addresses available:

- `0b00`: Message (Write only)
- `0b10`: Hash (Read only)

To see the SPI frame definition see [./design_data/docs/spi_diag](./design_data/docs/spi_diag)

The SPI clock can be as low as twice the main clock. So if the clock runs at 5kHz, the spi clock can run as 2.5kHz or lower. The SPI clock must a whole fraction of the main clock.

## Documentation

In [./design_data/docs](./design_data/docs) one can find the logic architecture along with the SPI state machine and one example sequence diagram of a hash.

### Constrains

If the message has a length that is a multiple of 512 bits, the user needs to send a 0 length msg chunk

## Build

To build the Chip, first execute `make librelane` inside [./design_data/chip](./design_data/chip). After that execute `make img2gds drc insert_img` inside [./design_data/top-image](./design_data/top-image). The final gds file can be found in [./design_data/top-image/gds](./design_data/top-image/gds) as `final-logo-initials.gds`

## License

Licensed under the MIT License. See [LICENSE](./LICENSE)
