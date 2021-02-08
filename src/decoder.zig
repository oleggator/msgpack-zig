const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const Int = std.meta.Int;

pub const MsgPackDecodeError = error{
    InvalidCode,
    Overflow,
    InvalidContentSize,
};

pub fn decodeArrayLen(reader: anytype) !usize {
    const code: u8 = try reader.readIntBig(u8);
    if (code & 0xf0 == 0x90) {
        return code & 0x0f;
    }
    return switch (code) {
        0xdc => try reader.readIntBig(u16),
        0xdd => try reader.readIntBig(u32),
        else => MsgPackDecodeError.InvalidCode,
    };
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
    return switch (code) {
        0xd9 => try reader.readIntBig(u8),
        0xda => try reader.readIntBig(u16),
        0xdb => try reader.readIntBig(u32),
        else => MsgPackDecodeError.InvalidCode,
    };
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

pub fn decodeStrAlloc(comptime T: type, allocator: *Allocator, reader: anytype) !T {
    switch (@typeInfo(T)) {
        .Array => |array_info| {
            if (array_info.child != u8) {
                @compileError("Unable to decode type '" ++ @typeName(T) ++ "' to string");
            }
            const str_len = try decodeStrLen(reader);
            if (array_info.len < str_len) {
                return MsgPackDecodeError.InvalidContentSize;
            }
            return try reader.readBytesNoEof(array_info.len);
        },
        .Pointer => |array_info| {
            if (array_info.child != u8) {
                @compileError("Unable to decode type '" ++ @typeName(T) ++ "' to string");
            }

            const str_len = try decodeStrLen(reader);

            const buffer = try allocator.alloc(u8, str_len);
            errdefer allocator.free(buffer);

            const read_bytes = try reader.read(buffer);
            if (read_bytes != str_len) {
                return MsgPackDecodeError.InvalidContentSize;
            }

            return buffer;
        },
        else => @compileError("Unable to decode type '" ++ @typeName(T) ++ "' to string"),
    }
}

test "decode string with copy" {
    try testDecodeWithCopy(decodeStrAlloc, "\xa0", 0x00);
    try testDecodeWithCopy(decodeStrAlloc, "\xa1", 0x01);
    try testDecodeWithCopy(decodeStrAlloc, "\xbe", 0x1e);
    try testDecodeWithCopy(decodeStrAlloc, "\xbf", 0x1f);

    try testDecodeWithCopy(decodeStrAlloc, "\xd9\x20", 0x20);
    try testDecodeWithCopy(decodeStrAlloc, "\xd9\xfe", 0xfe);
    try testDecodeWithCopy(decodeStrAlloc, "\xd9\xff", 0xff);

    try testDecodeWithCopy(decodeStrAlloc, "\xda\x01\x00", 0x0100);
    try testDecodeWithCopy(decodeStrAlloc, "\xda\xff\xfe", 0xfffe);
    try testDecodeWithCopy(decodeStrAlloc, "\xda\xff\xff", 0xffff);

    try testDecodeWithCopy(decodeStrAlloc, "\xdb\x00\x01\x00\x00", 0x00010000);
}

pub fn decodeBinLen(reader: anytype) !usize {
    const code: u8 = try reader.readIntBig(u8);
    return switch (code) {
        0xc4 => try reader.readIntBig(u8),
        0xc5 => try reader.readIntBig(u16),
        0xc6 => try reader.readIntBig(u32),
        else => MsgPackDecodeError.InvalidCode,
    };
}

test "decode bin length" {
    try testDecode(decodeBinLen, .{}, @as(usize, 0x00), "\xc4\x00");
    try testDecode(decodeBinLen, .{}, @as(usize, 0x01), "\xc4\x01");
    try testDecode(decodeBinLen, .{}, @as(usize, 0x1e), "\xc4\x1e");
    try testDecode(decodeBinLen, .{}, @as(usize, 0x1f), "\xc4\x1f");
    try testDecode(decodeBinLen, .{}, @as(usize, 0x20), "\xc4\x20");
    try testDecode(decodeBinLen, .{}, @as(usize, 0xfe), "\xc4\xfe");
    try testDecode(decodeBinLen, .{}, @as(usize, 0xff), "\xc4\xff");

    try testDecode(decodeBinLen, .{}, @as(usize, 0x0100), "\xc5\x01\x00");
    try testDecode(decodeBinLen, .{}, @as(usize, 0xfffe), "\xc5\xff\xfe");
    try testDecode(decodeBinLen, .{}, @as(usize, 0xffff), "\xc5\xff\xff");

    try testDecode(decodeBinLen, .{}, @as(usize, 0x00010000), "\xc6\x00\x01\x00\x00");
    try testDecode(decodeBinLen, .{}, @as(usize, 0xfffffffe), "\xc6\xff\xff\xff\xfe");
    try testDecode(decodeBinLen, .{}, @as(usize, 0xffffffff), "\xc6\xff\xff\xff\xff");
}

pub fn decodeBinAlloc(comptime T: type, allocator: *Allocator, reader: anytype) !T {
    switch (@typeInfo(T)) {
        .Array => |array_info| {
            if (array_info.child != u8) {
                @compileError("Unable to decode type '" ++ @typeName(T) ++ "' from binary");
            }
            const bin_len = try decodeBinLen(reader);
            if (array_info.len < bin_len) {
                return MsgPackDecodeError.InvalidContentSize;
            }
            return try reader.readBytesNoEof(array_info.len);
        },
        .Pointer => |array_info| {
            if (array_info.child != u8) {
                @compileError("Unable to decode type '" ++ @typeName(T) ++ "' from binary");
            }

            const bin_len = try decodeBinLen(reader);

            const buffer = try allocator.alloc(u8, bin_len);
            errdefer allocator.free(buffer);

            const read_bytes = try reader.read(buffer);
            if (read_bytes != bin_len) {
                return MsgPackDecodeError.InvalidContentSize;
            }

            return buffer;
        },
        else => @compileError("Unable to decode type '" ++ @typeName(T) ++ "' from binary"),
    }
}

test "decode bin with copy" {
    try testDecodeWithCopy(decodeBinAlloc, "\xc4\x00", 0x00);
    try testDecodeWithCopy(decodeBinAlloc, "\xc4\x01", 0x01);
    try testDecodeWithCopy(decodeBinAlloc, "\xc4\x1e", 0x1e);
    try testDecodeWithCopy(decodeBinAlloc, "\xc4\x1f", 0x1f);
    try testDecodeWithCopy(decodeBinAlloc, "\xc4\x20", 0x20);
    try testDecodeWithCopy(decodeBinAlloc, "\xc4\xfe", 0xfe);
    try testDecodeWithCopy(decodeBinAlloc, "\xc4\xff", 0xff);

    try testDecodeWithCopy(decodeBinAlloc, "\xc5\x01\x00", 0x0100);
    try testDecodeWithCopy(decodeBinAlloc, "\xc5\xff\xfe", 0xfffe);
    try testDecodeWithCopy(decodeBinAlloc, "\xc5\xff\xff", 0xffff);

    try testDecodeWithCopy(decodeBinAlloc, "\xc6\x00\x01\x00\x00", 0x00010000);
}

pub fn decodeBool(reader: anytype) !bool {
    const code: u8 = try reader.readIntBig(u8);
    return switch (code) {
        0xc3 => true,
        0xc2 => false,
        else => MsgPackDecodeError.InvalidCode,
    };
}

test "decode bool" {
    try testDecode(decodeBool, .{}, true, "\xc3");
    try testDecode(decodeBool, .{}, false, "\xc2");
}

pub fn decodeFloat(comptime T: type, reader: anytype) !T {
    comptime const dst_bits = switch (@typeInfo(T)) {
        .Float => |floatInfo| floatInfo.bits,
        .ComptimeFloat => 64,
        else => @compileError("Unable to decode type '" ++ @typeName(T) ++ "'"),
    };

    const code: u8 = try reader.readIntBig(u8);
    const payload_bits: usize = switch (code) {
        0xca => 32,
        0xcb => 64,
        else => return MsgPackDecodeError.InvalidCode,
    };
    if (payload_bits > dst_bits) {
        return MsgPackDecodeError.Overflow;
    }

    if (dst_bits <= 32 or payload_bits <= 32) {
        return @bitCast(f32, try reader.readIntBig(u32));
    } else if (dst_bits <= 64 or payload_bits <= 64) {
        return @bitCast(f64, try reader.readIntBig(u64));
    } else {
        return MsgPackDecodeError.Overflow;
    }
}

test "decode float" {
    try testDecode(decodeFloat, .{f32}, @as(f32, 1.0), "\xca\x3f\x80\x00\x00");
    try testDecode(decodeFloat, .{f32}, @as(f32, 3.141593), "\xca\x40\x49\x0f\xdc");
    try testDecode(decodeFloat, .{f32}, @as(f32, -1e+38), "\xca\xfe\x96\x76\x99");

    try testDecode(decodeFloat, .{f64}, @as(f64, 1.0), "\xcb\x3f\xf0\x00\x00\x00\x00\x00\x00");
    try testDecode(decodeFloat, .{f64}, @as(f64, 3.141592653589793), "\xcb\x40\x09\x21\xfb\x54\x44\x2d\x18");
    try testDecode(decodeFloat, .{f64}, @as(f64, -1e+99), "\xcb\xd4\x7d\x42\xae\xa2\x87\x9f\x2e");

    try testDecode(decodeFloat, .{f128}, @as(f128, 1.0), "\xcb\x3f\xf0\x00\x00\x00\x00\x00\x00");
}

pub fn decodeInt(comptime T: type, reader: anytype) !T {
    const DstTypeTag = enum {
        signed,
        unsigned,
    };
    const DstType = union(DstTypeTag) {
        signed: comptime_int,
        unsigned: comptime_int,
    };
    comptime const dst_type = switch (@typeInfo(T)) {
        .Int => |intInfo| if (intInfo.is_signed)
            DstType{ .signed = intInfo.bits }
        else
            DstType{ .unsigned = intInfo.bits },
        .ComptimeInt => DstType{ .signed = 64 },
        else => @compileError("Unable to decode type '" ++ @typeName(T) ++ "'"),
    };

    const code = try reader.readIntBig(u8);
    switch (dst_type) {
        .signed => |dst_bits| {
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
        },
        .unsigned => |dst_bits| {
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
        },
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

    try testDecode(decodeInt, .{u7}, @as(u7, 0), "\x00");
    try testDecode(decodeInt, .{u7}, @as(u7, 1), "\x01");
    try testDecode(decodeInt, .{u7}, @as(u7, 0x7e), "\x7e");
    try testDecode(decodeInt, .{u7}, @as(u7, 0x7f), "\x7f");

    try testDecode(decodeInt, .{u16}, @as(u16, 0x80), "\xcc\x80");
    try testDecode(decodeInt, .{u16}, @as(u16, 0xfe), "\xcc\xfe");
    try testDecode(decodeInt, .{u16}, @as(u16, 0xff), "\xcc\xff");

    try testDecode(decodeInt, .{u32}, @as(u32, 0xfffe), "\xcd\xff\xfe");
    try testDecode(decodeInt, .{u32}, @as(u32, 0xffff), "\xcd\xff\xff");

    try testDecode(decodeInt, .{u64}, @as(u64, 0x10000), "\xce\x00\x01\x00\x00");
    try testDecode(decodeInt, .{u64}, @as(u64, 0xfffffffe), "\xce\xff\xff\xff\xfe");
    try testDecode(decodeInt, .{u64}, @as(u64, 0xffffffff), "\xce\xff\xff\xff\xff");
}

pub fn decodeNull(reader: anytype) !void {
    const code: u8 = try reader.readIntBig(u8);
    if (code != 0xc0) {
        return MsgPackDecodeError.InvalidCode;
    }
}

test "decode null" {
    try testDecode(decodeNull, .{}, @as(void, undefined), "\xc0");
}

pub fn decodeArrayAlloc(
    comptime T: type,
    allocator: *Allocator,
    opts: DecoodingOptions,
    reader: anytype,
) !T {
    switch (@typeInfo(T)) {
        .Array => |array_info| {
            const array_len = try decodeArrayLen(reader);
            var array: T = undefined;
            if (array_len != array_info.len) {
                return MsgPackDecodeError.InvalidContentSize;
            }
            for (array) |_, i| {
                array[i] = try decodeAlloc(array_info.child, allocator, opts, reader);
            }
            return array;
        },
        .Pointer => |array_info| {
            const array_len = try decodeArrayLen(reader);
            var array = try allocator.alloc(array_info.child, array_len);
            for (array) |_, i| {
                array[i] = try decodeAlloc(array_info.child, allocator, opts, reader);
            }
            return array;
        },
        else => @compileError("Unable to decode type '" ++ @typeName(T) ++ "'"),
    }
}

test "decode array" {
    const test_array = [4]u32{ 1, 2, 3, 4 };
    const test_slice: []const u32 = test_array[0..test_array.len];

    const allocator = std.testing.allocator;

    try testDecode(decodeArrayAlloc, .{ @TypeOf(test_array), allocator, .{} }, test_array, "\x94\x01\x02\x03\x04");
    try testDecodeSlice(decodeArrayAlloc, .{.{}}, test_slice, "\x94\x01\x02\x03\x04");
}

pub fn decodeStruct(
    comptime T: type,
    allocator: *Allocator,
    opts: DecoodingOptions,
    reader: anytype,
) !T {
    const code = try reader.readIntBig(u8);

    const SrcTypeTag = enum {
        array,
        // map,
    };
    const SrcType = union(SrcTypeTag) {
        array: usize,
        // map: usize,
    };
    const array_len: usize = switch (code) {
        // 0x80...0x8F => SrcType{ .map = code & 0x00F },
        0x90...0x9F => code & 0x0F,
        0xDC => try reader.readIntBig(u16),
        0xDD => try reader.readIntBig(u32),
        // 0xDE => SrcType{ .map = try reader.readIntBig(u16) },
        // 0xDF => SrcType{ .map = try reader.readIntBig(u32) },
        else => return MsgPackDecodeError.InvalidCode,
    };

    comptime const fields = @typeInfo(T).Struct.fields;

    var structure = T{};
    if (array_len != fields.len) {
        return MsgPackDecodeError.InvalidContentSize;
    }
    inline for (fields) |Field| {
        @field(structure, Field.name) = try decodeAlloc(Field.field_type, allocator, opts, reader);
    }

    return structure;
}

test "decode struct" {
    const SomeStruct = struct {
        int: u32 = 0,
        float: f64 = 0,
        boolean: bool = false,
        nil: ?bool = null,
        string: [6]u8 = undefined,
        array: [4]u16 = undefined,
    };
    const str = [6]u8{ 's', 't', 'r', 'i', 'n', 'g' };
    const someStruct = SomeStruct{
        .int = @as(u32, 65534),
        .float = @as(f64, 3.141592653589793),
        .boolean = true,
        .nil = null,
        .string = str,
        .array = @as([4]u16, .{ 11, 22, 33, 44 }),
    };
    const allocator = std.testing.allocator;
    try testDecode(decodeStruct, .{ SomeStruct, allocator, .{} }, someStruct, "\x96\xCD\xFF\xFE\xCB\x40\x09\x21\xFB\x54\x44\x2D\x18\xC3\xC0\xA6\x73\x74\x72\x69\x6E\x67\x94\x0B\x16\x21\x2C");
}

pub fn decodeOptionalAlloc(
    comptime T: type,
    allocator: *Allocator,
    options: DecoodingOptions,
    reader: anytype,
) !T {
    const code: u8 = try reader.readIntBig(u8);
    if (code == 0xc0) {
        return null;
    }
    return try decodeAlloc(@typeInfo(T).Optional.child, allocator, options, reader);
}

pub const U8ArrayDecoding = enum {
    array,
    string,
    binary,
};

pub const DecoodingOptions = struct {
    u8_array_decoding: U8ArrayDecoding = .string,
};

pub fn decodeAlloc(
    comptime T: type,
    allocator: *Allocator,
    options: DecoodingOptions,
    reader: anytype,
) !T {
    return switch (@typeInfo(T)) {
        .Float, .ComptimeFloat => decodeFloat(T, reader),
        .Int, .ComptimeInt => decodeInt(T, reader),
        .Bool => decodeBool(reader),
        .Optional => decodeOptionalAlloc(T, allocator, options, reader),
        .Struct => decodeStructAlloc(T, allocator, options, reader),
        .Array => |array_info| if (array_info.child == u8) switch (options.u8_array_decoding) {
            .array => try decodeArrayAlloc(T, allocator, options, reader),
            .string => try decodeStrAlloc(T, allocator, reader),
            .binary => try decodeBinAlloc(T, allocator, reader),
        } else try decodeArrayAlloc(T, allocator, options, reader),
        else => @compileError("Unable to decode type '" ++ @typeName(T) ++ "'"),
    };
}

test "generic decode" {
    const allocator = std.testing.allocator;

    try testDecode(decodeAlloc, .{ bool, allocator, .{} }, true, "\xc3");
    try testDecode(decodeAlloc, .{ bool, allocator, .{} }, false, "\xc2");
}

fn testDecode(func: anytype, func_args: anytype, expected: anytype, input: []const u8) !void {
    var fbs = std.io.fixedBufferStream(input);
    const reader = fbs.reader();

    const args = func_args ++ .{reader};
    const result = try @call(.{}, func, args);
    testing.expectEqual(expected, result);
}

fn testDecodeSlice(func: anytype, func_args: anytype, expected: anytype, input: []const u8) !void {
    var fbs = std.io.fixedBufferStream(input);
    const reader = fbs.reader();

    const allocator = std.testing.allocator;
    const T = @TypeOf(expected);
    const args = .{ T, allocator } ++ func_args ++ .{reader};
    const result = try @call(.{}, func, args);
    defer allocator.free(result);
    testing.expectEqualSlices(std.meta.Child(T), expected, result);
}

fn testDecodeWithCopy(comptime decodeFunc: anytype, comptime prefix: []const u8, comptime str_len: usize) !void {
    const source_string: []const u8 = "a" ** str_len;
    const input: []const u8 = prefix ++ source_string;

    var fbs = std.io.fixedBufferStream(input);
    const reader = fbs.reader();
    const allocator = std.testing.allocator;
    const result = try decodeFunc([]u8, allocator, reader);
    defer allocator.free(result);

    testing.expectEqualSlices(u8, source_string, result);
}
