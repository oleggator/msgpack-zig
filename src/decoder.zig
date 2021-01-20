const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const Int = std.meta.Int;

pub const MsgPackDecodeError = error{
    InvalidCode,
    Overflow,
};

pub fn decodeArrayLen(reader: anytype) !usize {
    const code: u8 = try reader.readIntBig(u8);
    if (code & 0xf0 == 0x90) {
        return code & 0x0f;
    }
    const arr_len: usize = switch (code) {
        0xdc => try reader.readIntBig(u16),
        0xdd => try reader.readIntBig(u32),
        else => return MsgPackDecodeError.InvalidCode,
    };
    return arr_len;
}

test "decode array length" {
    try testDecode(decodeArrayLen, .{}, @as(usize, 0), "\x90");
    try testDecode(decodeArrayLen, .{}, @as(usize, 1), "\x91");
    try testDecode(decodeArrayLen, .{}, @as(usize, 15), "\x9f");
    try testDecode(decodeArrayLen, .{}, @as(usize, 16), "\xdc\x00\x10");
    try testDecode(decodeArrayLen, .{}, @as(usize, 0xfffe), "\xdc\xff\xfe");
    try testDecode(decodeArrayLen, .{}, @as(usize, 0xffff), "\xdc\xff\xff");
    try testDecode(decodeArrayLen, .{}, @as(usize, 0x10000), "\xdd\x00\x01\x00\x00");
    try testDecode(decodeArrayLen, .{}, @as(usize, 0xfffffffe), "\xdd\xff\xff\xff\xfe");
    try testDecode(decodeArrayLen, .{}, @as(usize, 0xffffffff), "\xdd\xff\xff\xff\xff");
}

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

pub fn decodeStrAlloc(allocator: *Allocator, reader: anytype) ![]u8 {
    const str_len: usize = try decodeStrLen(reader);
    const buffer: []u8 = try allocator.alloc(u8, str_len);
    const read_bytes = try reader.readAll(buffer);
    return buffer;
}

fn testDecodeStringAlloc(comptime prefix: []const u8, comptime str_len: usize) !void {
    const source_string: []const u8 = "a" ** str_len;
    const input: []const u8 = prefix ++ source_string;

    var buffer: [input.len]u8 = undefined;
    const allocator = &std.heap.FixedBufferAllocator.init(&buffer).allocator;

    var fbs = std.io.fixedBufferStream(input);
    const reader = fbs.reader();
    const result = try decodeStrAlloc(allocator, reader);

    testing.expectEqualSlices(u8, source_string, result);
}

test "decode string with copy" {
    try testDecodeStringAlloc("\xa0", 0x00);
    try testDecodeStringAlloc("\xa1", 0x01);
    try testDecodeStringAlloc("\xbe", 0x1e);
    try testDecodeStringAlloc("\xbf", 0x1f);

    try testDecodeStringAlloc("\xd9\x20", 0x20);
    try testDecodeStringAlloc("\xd9\xfe", 0xfe);
    try testDecodeStringAlloc("\xd9\xff", 0xff);

    try testDecodeStringAlloc("\xda\x01\x00", 0x0100);
    try testDecodeStringAlloc("\xda\xff\xfe", 0xfffe);
    try testDecodeStringAlloc("\xda\xff\xff", 0xffff);

    try testDecodeStringAlloc("\xdb\x00\x01\x00\x00", 0x00010000);
}

pub fn decodeBool(reader: anytype) !bool {
    const code: u8 = try reader.readIntBig(u8);
    return switch (code) {
        0xc3 => true,
        0xc2 => false,
        else => return MsgPackDecodeError.InvalidCode,
    };
}

test "decode bool" {
    try testDecode(decodeBool, .{}, true, "\xc3");
    try testDecode(decodeBool, .{}, false, "\xc2");
}

pub fn decodeF32(reader: anytype) !f32 {
    const code: u8 = try reader.readIntBig(u8);
    return switch (code) {
        0xca => @bitCast(f32, try reader.readIntBig(u32)),
        else => return MsgPackDecodeError.InvalidCode,
    };
}

test "decode float" {
    try testDecode(decodeF32, .{}, @as(f32, 1.0), "\xca\x3f\x80\x00\x00");
    try testDecode(decodeF32, .{}, @as(f32, 3.141593), "\xca\x40\x49\x0f\xdc");
    try testDecode(decodeF32, .{}, @as(f32, -1e+38), "\xca\xfe\x96\x76\x99");
}

pub fn decodeF64(reader: anytype) !f64 {
    const code: u8 = try reader.readIntBig(u8);
    return switch (code) {
        0xcb => @bitCast(f64, try reader.readIntBig(u64)),
        else => return MsgPackDecodeError.InvalidCode,
    };
}

test "decode double" {
    try testDecode(decodeF64, .{}, @as(f64, 1.0), "\xcb\x3f\xf0\x00\x00\x00\x00\x00\x00");
    try testDecode(decodeF64, .{}, @as(f64, 3.141592653589793), "\xcb\x40\x09\x21\xfb\x54\x44\x2d\x18");
    try testDecode(decodeF64, .{}, @as(f64, -1e+99), "\xcb\xd4\x7d\x42\xae\xa2\x87\x9f\x2e");
}

pub fn decodeInt(comptime T: type, reader: anytype) !T {
    comptime const dst_bits = switch (@typeInfo(T)) {
        .Int => |intInfo| intInfo.bits,
        .ComptimeInt => 64,
        else => @compileError("Unable to decode type '" ++ @typeName(T) ++ "'"),
    };
    
    const code = try reader.readIntBig(u8);
    if (code & 0xe0 == 0xe0) {
        const truncated_int = @truncate(u6, code);
        return @intCast(T, @bitCast(i6, truncated_int));
    }

    const payload_bits: usize = switch (code) {
        0xd0 => 8,
        0xd1 => 16,
        0xd2 => 32,
        0xd3 => 64,
        else => return MsgPackDecodeError.InvalidCode,
    };
    if (payload_bits > dst_bits) {
        return MsgPackDecodeError.Overflow;
    }

    if (dst_bits <= 8 or payload_bits <= 8) {
        return @intCast(T, try reader.readIntBig(Int(.signed, 8)));
    } else if (dst_bits <= 16 or payload_bits <= 16) {
        return @intCast(T, try reader.readIntBig(Int(.signed, 16)));
    } else if (dst_bits <= 32 or payload_bits <= 32) {
        return @intCast(T, try reader.readIntBig(Int(.signed, 32)));
    } else if (dst_bits <= 64 or payload_bits <= 64) {
        return @intCast(T, try reader.readIntBig(Int(.signed, 64)));
    } else {
       return MsgPackDecodeError.Overflow;
    }
}

test "decode int" {
    try testDecode(decodeInt, .{i6}, @as(i6, -0x01), "\xff");
    try testDecode(decodeInt, .{i6}, @as(i6, -0x1e), "\xe2");
    try testDecode(decodeInt, .{i6}, @as(i6, -0x1f), "\xe1");
    try testDecode(decodeInt, .{i6}, @as(i6, -0x20), "\xe0");

    try testDecode(decodeInt, .{i8}, @as(i8, -0x21), "\xd0\xdf");
    try testDecode(decodeInt, .{i8}, @as(i8, -0x7f), "\xd0\x81");
    try testDecode(decodeInt, .{i8}, @as(i8, -0x80), "\xd0\x80");

    try testDecode(decodeInt, .{i16}, @as(i16, -0x81), "\xd1\xff\x7f");
    try testDecode(decodeInt, .{i16}, @as(i16, -0x7fff), "\xd1\x80\x01");
    try testDecode(decodeInt, .{i16}, @as(i16, -0x8000), "\xd1\x80\x00");

    try testDecode(decodeInt, .{i32}, @as(i32, -0x8001), "\xd2\xff\xff\x7f\xff");
    try testDecode(decodeInt, .{i32}, @as(i32, -0x7fffffff), "\xd2\x80\x00\x00\x01");
    try testDecode(decodeInt, .{i32}, @as(i32, -0x80000000), "\xd2\x80\x00\x00\x00");

    try testDecode(decodeInt, .{i64}, @as(i64, -0x80000001), "\xd3\xff\xff\xff\xff\x7f\xff\xff\xff");
    try testDecode(decodeInt, .{i64}, @as(i64, -0x80000001), "\xd3\xff\xff\xff\xff\x7f\xff\xff\xff");
    try testDecode(decodeInt, .{i64}, @as(i64, -0x7fffffffffffffff), "\xd3\x80\x00\x00\x00\x00\x00\x00\x01");
    try testDecode(decodeInt, .{i64}, @as(i64, -0x8000000000000000), "\xd3\x80\x00\x00\x00\x00\x00\x00\x00");
}

pub fn decodeUint(comptime T: type, reader: anytype) !T {
    comptime const dst_bits = switch (@typeInfo(T)) {
        .Int => |intInfo| intInfo.bits,
        .ComptimeInt => 64,
        else => @compileError("Unable to decode type '" ++ @typeName(T) ++ "'"),
    };

    const code = try reader.readIntBig(u8);
    if (code & 0x80 == 0) { // u7
        return @intCast(T, code);
    }

    const payload_bits: usize = switch (code) {
        0xcc => 8,
        0xcd => 16,
        0xce => 32,
        0xcf => 64,
        else => return MsgPackDecodeError.InvalidCode,
    };
    if (payload_bits > dst_bits) {
        return MsgPackDecodeError.Overflow;
    }

    if (dst_bits <= 8 or payload_bits <= 8) {
       return @intCast(T, try reader.readIntBig(Int(.unsigned, 8)));
    } else if (dst_bits <= 16 or payload_bits <= 16) {
        return @intCast(T, try reader.readIntBig(Int(.unsigned, 16)));
    } else if (dst_bits <= 32 or payload_bits <= 32) {
        return @intCast(T, try reader.readIntBig(Int(.unsigned, 32)));
    } else if (dst_bits <= 64 or payload_bits <= 64) {
        return @intCast(T, try reader.readIntBig(Int(.unsigned, 64)));
    } else {
       return MsgPackDecodeError.Overflow;
    }
}

test "decode uint" {
    try testDecode(decodeUint, .{u7}, @as(u7, 0), "\x00");
    try testDecode(decodeUint, .{u7}, @as(u7, 1), "\x01");
    try testDecode(decodeUint, .{u7}, @as(u7, 0x7e), "\x7e");
    try testDecode(decodeUint, .{u7}, @as(u7, 0x7f), "\x7f");

    try testDecode(decodeUint, .{u16}, @as(u16, 0x80), "\xcc\x80");
    try testDecode(decodeUint, .{u16}, @as(u16, 0xfe), "\xcc\xfe");
    try testDecode(decodeUint, .{u16}, @as(u16, 0xff), "\xcc\xff");

    try testDecode(decodeUint, .{u32}, @as(u32, 0xfffe), "\xcd\xff\xfe");
    try testDecode(decodeUint, .{u32}, @as(u32, 0xffff), "\xcd\xff\xff");

    try testDecode(decodeUint, .{u64}, @as(u64, 0x10000), "\xce\x00\x01\x00\x00");
    try testDecode(decodeUint, .{u64}, @as(u64, 0xfffffffe), "\xce\xff\xff\xff\xfe");
    try testDecode(decodeUint, .{u64}, @as(u64, 0xffffffff), "\xce\xff\xff\xff\xff");
}

fn testDecode(func: anytype, func_args: anytype, expected: anytype, input: []const u8) !void {
    var fbs = std.io.fixedBufferStream(input);
    const reader = fbs.reader();

    const args = func_args ++ .{reader};
    const result = try @call(.{}, func, args);
    testing.expectEqual(expected, result);
}
