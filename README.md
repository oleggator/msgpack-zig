# MessagePack for Zig
![Test msgpack-zig](https://github.com/oleggator/msgpack-zig/workflows/Test%20msgpack-zig/badge.svg)

Based on [github.com/tarantool/msgpuck](https://github.com/tarantool/msgpuck).

## Stream API implementation progress
| Type                    |         Encoding        | Decoding |
|-------------------------|:-----------------------:|:--------:|
| generic                 | :ballot_box_with_check: |          |
| int (7-64 bit)          |    :white_check_mark:   |          |
| comptime int (7-64 bit) |    :white_check_mark:   |          |
| float (32, 64 bit)      |    :white_check_mark:   |          |
| comptime float (64 bit) |    :white_check_mark:   |          |
| bool                    |    :white_check_mark:   |          |
| Optional                | :ballot_box_with_check: |          |
| Struct                  | :ballot_box_with_check: |          |
| Pointer                 | :ballot_box_with_check: |          |
| Map                     | :ballot_box_with_check: |          |
| Array                   | :ballot_box_with_check: |          |
| Slice                   | :ballot_box_with_check: |          |
| Many                    | :ballot_box_with_check: |          |
| string                  |    :white_check_mark:   |          |
| binary                  |    :white_check_mark:   |          |
| extension               |    :white_check_mark:   |          |
| nil                     |    :white_check_mark:   |          |

- :white_check_mark: - implemented with unit tests
- :ballot_box_with_check: - implemented without unit tests
