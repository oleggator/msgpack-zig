const std = @import("std");
const testing = std.testing;

pub const MsgPackDecodeError = error{
    InvalidCode,
    Overflow,
};

pub fn decodeStrLen(reader: anytype) !usize {
    const code: u8 = try reader.readIntBig(u8);
    if (code & 0xe0 == 0xa0) {
        return code & 0x1f;
    }

    const str_len: usize = switch (code) {
        0xd9 => try reader.readIntBig(u8),
        0xda => try reader.readIntBig(u16),
        0xdb => try reader.readIntBig(u32),
        else => return MsgPackDecodeError.InvalidCode,
    };
    return str_len;
}

test "decode string length" {
    try testDecode(decodeStrLen, .{}, @as(usize, 0x00), "\xa0");
    try testDecode(decodeStrLen, .{}, @as(usize, 0x01), "\xa1");
    try testDecode(decodeStrLen, .{}, @as(usize, 0x1e), "\xbe");
    try testDecode(decodeStrLen, .{}, @as(usize, 0x1f), "\xbf");

    try testDecode(decodeStrLen, .{}, @as(usize, 0x20), "\xd9\x20");
    try testDecode(decodeStrLen, .{}, @as(usize, 0xfe), "\xd9\xfe");
    try testDecode(decodeStrLen, .{}, @as(usize, 0xff), "\xd9\xff");

    try testDecode(decodeStrLen, .{}, @as(usize, 0x0100), "\xda\x01\x00");
    try testDecode(decodeStrLen, .{}, @as(usize, 0xfffe), "\xda\xff\xfe");
    try testDecode(decodeStrLen, .{}, @as(usize, 0xffff), "\xda\xff\xff");

    try testDecode(decodeStrLen, .{}, @as(usize, 0x00010000), "\xdb\x00\x01\x00\x00");
    try testDecode(decodeStrLen, .{}, @as(usize, 0xfffffffe), "\xdb\xff\xff\xff\xfe");
    try testDecode(decodeStrLen, .{}, @as(usize, 0xffffffff), "\xdb\xff\xff\xff\xff");
}


fn testDecode(func: anytype, func_args: anytype, expected: anytype, input: []const u8) !void {
    var fbs = std.io.fixedBufferStream(input);
    const reader = fbs.reader();

    const args = func_args ++ .{reader};
    const result = try @call(.{}, func, args);
    testing.expectEqual(expected, result);
}
