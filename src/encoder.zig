const std = @import("std");
const testing = std.testing;
const minInt = std.math.minInt;
const maxInt = std.math.maxInt;

pub fn encodeStrLen(len: u32, writer: anytype) @TypeOf(writer).Error!void {
    if (len <= std.math.maxInt(u5)) {
        return writer.writeIntBig(u8, 0xa0 | @truncate(u8, len));
    }
    if (len <= std.math.maxInt(u8)) {
        try writer.writeIntBig(u8, 0xd9);
        return writer.writeIntBig(u8, @truncate(u8, len));
    }
    if (len <= std.math.maxInt(u16)) {
        try writer.writeIntBig(u8, 0xda);
        return writer.writeIntBig(u16, @truncate(u16, len));
    }
    if (len <= std.math.maxInt(u32)) {
        try writer.writeIntBig(u8, 0xdb);
        return writer.writeIntBig(u32, len);
    }
    unreachable;
}

test "encode string length" {
    try testEncode(encodeStrLen, "\xa0", .{@as(u32, 0x00)});
    try testEncode(encodeStrLen, "\xa1", .{@as(u32, 0x01)});
    try testEncode(encodeStrLen, "\xbe", .{@as(u32, 0x1e)});
    try testEncode(encodeStrLen, "\xbf", .{@as(u32, 0x1f)});

    try testEncode(encodeStrLen, "\xd9\x20", .{@as(u32, 0x20)});
    try testEncode(encodeStrLen, "\xd9\xfe", .{@as(u32, 0xfe)});
    try testEncode(encodeStrLen, "\xd9\xff", .{@as(u32, 0xff)});

    try testEncode(encodeStrLen, "\xda\x01\x00", .{@as(u32, 0x0100)});
    try testEncode(encodeStrLen, "\xda\xff\xfe", .{@as(u32, 0xfffe)});
    try testEncode(encodeStrLen, "\xda\xff\xff", .{@as(u32, 0xffff)});

    try testEncode(encodeStrLen, "\xdb\x00\x01\x00\x00", .{@as(u32, 0x00010000)});
    try testEncode(encodeStrLen, "\xdb\xff\xff\xff\xfe", .{@as(u32, 0xfffffffe)});
    try testEncode(encodeStrLen, "\xdb\xff\xff\xff\xff", .{@as(u32, 0xffffffff)});

    try testEncode(encodeStrLen, "\xa0", .{@as(comptime_int, 0x00)});
    try testEncode(encodeStrLen, "\xa1", .{@as(comptime_int, 0x01)});
    try testEncode(encodeStrLen, "\xbe", .{@as(comptime_int, 0x1e)});
    try testEncode(encodeStrLen, "\xbf", .{@as(comptime_int, 0x1f)});

    try testEncode(encodeStrLen, "\xd9\x20", .{@as(comptime_int, 0x20)});
    try testEncode(encodeStrLen, "\xd9\xfe", .{@as(comptime_int, 0xfe)});
    try testEncode(encodeStrLen, "\xd9\xff", .{@as(comptime_int, 0xff)});

    try testEncode(encodeStrLen, "\xda\x01\x00", .{@as(comptime_int, 0x0100)});
    try testEncode(encodeStrLen, "\xda\xff\xfe", .{@as(comptime_int, 0xfffe)});
    try testEncode(encodeStrLen, "\xda\xff\xff", .{@as(comptime_int, 0xffff)});

    try testEncode(encodeStrLen, "\xdb\x00\x01\x00\x00", .{@as(comptime_int, 0x00010000)});
    try testEncode(encodeStrLen, "\xdb\xff\xff\xff\xfe", .{@as(comptime_int, 0xfffffffe)});
    try testEncode(encodeStrLen, "\xdb\xff\xff\xff\xff", .{@as(comptime_int, 0xffffffff)});
}

pub inline fn encodeStr(str: []const u8, writer: anytype) @TypeOf(writer).Error!void {
    try encodeStrLen(@truncate(u32, str.len), writer);
    return writer.writeAll(str);
}

test "encode string" {
    try testEncode(encodeStr, "\xa6string", .{"string"});
}

pub fn encodeBinLen(len: u32, writer: anytype) @TypeOf(writer).Error!void {
    if (len <= std.math.maxInt(u8)) {
        try writer.writeIntBig(u8, 0xc4);
        return writer.writeIntBig(u8, @truncate(u8, len));
    }
    if (len <= std.math.maxInt(u16)) {
        try writer.writeIntBig(u8, 0xc5);
        return writer.writeIntBig(u16, @truncate(u16, len));
    }
    if (len <= std.math.maxInt(u32)) {
        try writer.writeIntBig(u8, 0xc6);
        return writer.writeIntBig(u32, @truncate(u32, len));
    }
    unreachable;
}

test "encode bin length" {
    try testEncode(encodeBinLen, "\xc4\x00", .{@as(u32, 0x00)});
    try testEncode(encodeBinLen, "\xc4\x01", .{@as(u32, 0x01)});
    try testEncode(encodeBinLen, "\xc4\x1e", .{@as(u32, 0x1e)});
    try testEncode(encodeBinLen, "\xc4\x1f", .{@as(u32, 0x1f)});

    try testEncode(encodeBinLen, "\xc4\x20", .{@as(u32, 0x20)});
    try testEncode(encodeBinLen, "\xc4\xfe", .{@as(u32, 0xfe)});
    try testEncode(encodeBinLen, "\xc4\xff", .{@as(u32, 0xff)});

    try testEncode(encodeBinLen, "\xc5\x01\x00", .{@as(u32, 0x0100)});
    try testEncode(encodeBinLen, "\xc5\xff\xfe", .{@as(u32, 0xfffe)});
    try testEncode(encodeBinLen, "\xc5\xff\xff", .{@as(u32, 0xffff)});

    try testEncode(encodeBinLen, "\xc6\x00\x01\x00\x00", .{@as(u32, 0x00010000)});
    try testEncode(encodeBinLen, "\xc6\xff\xff\xff\xfe", .{@as(u32, 0xfffffffe)});
    try testEncode(encodeBinLen, "\xc6\xff\xff\xff\xff", .{@as(u32, 0xffffffff)});

    try testEncode(encodeBinLen, "\xc4\x00", .{@as(comptime_int, 0x00)});
    try testEncode(encodeBinLen, "\xc4\x01", .{@as(comptime_int, 0x01)});
    try testEncode(encodeBinLen, "\xc4\x1e", .{@as(comptime_int, 0x1e)});
    try testEncode(encodeBinLen, "\xc4\x1f", .{@as(comptime_int, 0x1f)});

    try testEncode(encodeBinLen, "\xc4\x20", .{@as(comptime_int, 0x20)});
    try testEncode(encodeBinLen, "\xc4\xfe", .{@as(comptime_int, 0xfe)});
    try testEncode(encodeBinLen, "\xc4\xff", .{@as(comptime_int, 0xff)});

    try testEncode(encodeBinLen, "\xc5\x01\x00", .{@as(comptime_int, 0x0100)});
    try testEncode(encodeBinLen, "\xc5\xff\xfe", .{@as(comptime_int, 0xfffe)});
    try testEncode(encodeBinLen, "\xc5\xff\xff", .{@as(comptime_int, 0xffff)});

    try testEncode(encodeBinLen, "\xc6\x00\x01\x00\x00", .{@as(comptime_int, 0x00010000)});
    try testEncode(encodeBinLen, "\xc6\xff\xff\xff\xfe", .{@as(comptime_int, 0xfffffffe)});
    try testEncode(encodeBinLen, "\xc6\xff\xff\xff\xff", .{@as(comptime_int, 0xffffffff)});
}

pub inline fn encodeBin(bin: []const u8, writer: anytype) @TypeOf(writer).Error!void {
    try encodeBinLen(@truncate(u32, bin.len), writer);
    return writer.writeAll(bin);
}

pub fn encodeExtLen(ext_type: i8, len: u32, writer: anytype) @TypeOf(writer).Error!void {
    switch (len) {
        1 => try writer.writeIntBig(u8, 0xd4),
        2 => try writer.writeIntBig(u8, 0xd5),
        4 => try writer.writeIntBig(u8, 0xd6),
        8 => try writer.writeIntBig(u8, 0xd7),
        16 => try writer.writeIntBig(u8, 0xd8),
        else => if (len <= std.math.maxInt(u8)) {
            try writer.writeIntBig(u8, 0xc7);
            try writer.writeIntBig(u8, @truncate(u8, len));
        } else if (len <= std.math.maxInt(u16)) {
            try writer.writeIntBig(u8, 0xc8);
            try writer.writeIntBig(u16, @truncate(u16, len));
        } else if (len <= std.math.maxInt(u32)) {
            try writer.writeIntBig(u8, 0xc9);
            try writer.writeIntBig(u32, len);
        } else {
            unreachable;
        },
    }
    return writer.writeIntBig(i8, ext_type);
}

test "encode extension length" {
    try testEncode(encodeExtLen, "\xd4\x00", .{ @as(i8, 0), @as(u32, 0x01) });
    try testEncode(encodeExtLen, "\xd5\x00", .{ @as(i8, 0), @as(u32, 0x02) });
    try testEncode(encodeExtLen, "\xd6\x00", .{ @as(i8, 0), @as(u32, 0x04) });
    try testEncode(encodeExtLen, "\xd7\x00", .{ @as(i8, 0), @as(u32, 0x08) });
    try testEncode(encodeExtLen, "\xd8\x00", .{ @as(i8, 0), @as(u32, 0x10) });

    // ext 8
    try testEncode(encodeExtLen, "\xc7\x11\x00", .{ @as(i8, 0), @as(u32, 0x11) });
    try testEncode(encodeExtLen, "\xc7\xfe\x00", .{ @as(i8, 0), @as(u32, 0xfe) });
    try testEncode(encodeExtLen, "\xc7\xff\x00", .{ @as(i8, 0), @as(u32, 0xff) });

    try testEncode(encodeExtLen, "\xc7\x00\x00", .{ @as(i8, 0), @as(u32, 0x00) });
    try testEncode(encodeExtLen, "\xc7\x03\x00", .{ @as(i8, 0), @as(u32, 0x03) });
    try testEncode(encodeExtLen, "\xc7\x05\x00", .{ @as(i8, 0), @as(u32, 0x05) });
    try testEncode(encodeExtLen, "\xc7\x06\x00", .{ @as(i8, 0), @as(u32, 0x06) });
    try testEncode(encodeExtLen, "\xc7\x07\x00", .{ @as(i8, 0), @as(u32, 0x07) });
    try testEncode(encodeExtLen, "\xc7\x09\x00", .{ @as(i8, 0), @as(u32, 0x09) });
    try testEncode(encodeExtLen, "\xc7\x0a\x00", .{ @as(i8, 0), @as(u32, 0x0a) });
    try testEncode(encodeExtLen, "\xc7\x0b\x00", .{ @as(i8, 0), @as(u32, 0x0b) });
    try testEncode(encodeExtLen, "\xc7\x0c\x00", .{ @as(i8, 0), @as(u32, 0x0c) });
    try testEncode(encodeExtLen, "\xc7\x0d\x00", .{ @as(i8, 0), @as(u32, 0x0d) });
    try testEncode(encodeExtLen, "\xc7\x0e\x00", .{ @as(i8, 0), @as(u32, 0x0e) });
    try testEncode(encodeExtLen, "\xc7\x0f\x00", .{ @as(i8, 0), @as(u32, 0x0f) });

    // ext 16
    try testEncode(encodeExtLen, "\xc8\x01\x00\x00", .{ @as(i8, 0), @as(u32, 0x0100) });
    try testEncode(encodeExtLen, "\xc8\x01\x01\x00", .{ @as(i8, 0), @as(u32, 0x0101) });
    try testEncode(encodeExtLen, "\xc8\xff\xfe\x00", .{ @as(i8, 0), @as(u32, 0xfffe) });
    try testEncode(encodeExtLen, "\xc8\xff\xff\x00", .{ @as(i8, 0), @as(u32, 0xffff) });

    // ext 32
    try testEncode(encodeExtLen, "\xc9\x00\x01\x00\x00\x00", .{ @as(i8, 0), @as(u32, 0x00010000) });
    try testEncode(encodeExtLen, "\xc9\x00\x01\x00\x01\x00", .{ @as(i8, 0), @as(u32, 0x00010001) });
    try testEncode(encodeExtLen, "\xc9\xff\xff\xff\xfe\x00", .{ @as(i8, 0), @as(u32, 0xfffffffe) });
    try testEncode(encodeExtLen, "\xc9\xff\xff\xff\xff\x00", .{ @as(i8, 0), @as(u32, 0xffffffff) });

    try testEncode(encodeExtLen, "\xd4\x00", .{ @as(i8, 0), @as(comptime_int, 0x01) });
    try testEncode(encodeExtLen, "\xd5\x00", .{ @as(i8, 0), @as(comptime_int, 0x02) });
    try testEncode(encodeExtLen, "\xd6\x00", .{ @as(i8, 0), @as(comptime_int, 0x04) });
    try testEncode(encodeExtLen, "\xd7\x00", .{ @as(i8, 0), @as(comptime_int, 0x08) });
    try testEncode(encodeExtLen, "\xd8\x00", .{ @as(i8, 0), @as(comptime_int, 0x10) });

    // ext 8
    try testEncode(encodeExtLen, "\xc7\x11\x00", .{ @as(i8, 0), @as(comptime_int, 0x11) });
    try testEncode(encodeExtLen, "\xc7\xfe\x00", .{ @as(i8, 0), @as(comptime_int, 0xfe) });
    try testEncode(encodeExtLen, "\xc7\xff\x00", .{ @as(i8, 0), @as(comptime_int, 0xff) });

    try testEncode(encodeExtLen, "\xc7\x00\x00", .{ @as(i8, 0), @as(comptime_int, 0x00) });
    try testEncode(encodeExtLen, "\xc7\x03\x00", .{ @as(i8, 0), @as(comptime_int, 0x03) });
    try testEncode(encodeExtLen, "\xc7\x05\x00", .{ @as(i8, 0), @as(comptime_int, 0x05) });
    try testEncode(encodeExtLen, "\xc7\x06\x00", .{ @as(i8, 0), @as(comptime_int, 0x06) });
    try testEncode(encodeExtLen, "\xc7\x07\x00", .{ @as(i8, 0), @as(comptime_int, 0x07) });
    try testEncode(encodeExtLen, "\xc7\x09\x00", .{ @as(i8, 0), @as(comptime_int, 0x09) });
    try testEncode(encodeExtLen, "\xc7\x0a\x00", .{ @as(i8, 0), @as(comptime_int, 0x0a) });
    try testEncode(encodeExtLen, "\xc7\x0b\x00", .{ @as(i8, 0), @as(comptime_int, 0x0b) });
    try testEncode(encodeExtLen, "\xc7\x0c\x00", .{ @as(i8, 0), @as(comptime_int, 0x0c) });
    try testEncode(encodeExtLen, "\xc7\x0d\x00", .{ @as(i8, 0), @as(comptime_int, 0x0d) });
    try testEncode(encodeExtLen, "\xc7\x0e\x00", .{ @as(i8, 0), @as(comptime_int, 0x0e) });
    try testEncode(encodeExtLen, "\xc7\x0f\x00", .{ @as(i8, 0), @as(comptime_int, 0x0f) });

    // ext 16
    try testEncode(encodeExtLen, "\xc8\x01\x00\x00", .{ @as(i8, 0), @as(comptime_int, 0x0100) });
    try testEncode(encodeExtLen, "\xc8\x01\x01\x00", .{ @as(i8, 0), @as(comptime_int, 0x0101) });
    try testEncode(encodeExtLen, "\xc8\xff\xfe\x00", .{ @as(i8, 0), @as(comptime_int, 0xfffe) });
    try testEncode(encodeExtLen, "\xc8\xff\xff\x00", .{ @as(i8, 0), @as(comptime_int, 0xffff) });

    // ext 32
    try testEncode(encodeExtLen, "\xc9\x00\x01\x00\x00\x00", .{ @as(i8, 0), @as(comptime_int, 0x00010000) });
    try testEncode(encodeExtLen, "\xc9\x00\x01\x00\x01\x00", .{ @as(i8, 0), @as(comptime_int, 0x00010001) });
    try testEncode(encodeExtLen, "\xc9\xff\xff\xff\xfe\x00", .{ @as(i8, 0), @as(comptime_int, 0xfffffffe) });
    try testEncode(encodeExtLen, "\xc9\xff\xff\xff\xff\x00", .{ @as(i8, 0), @as(comptime_int, 0xffffffff) });
}

pub inline fn encodeExt(ext_type: i8, bin: []const u8, writer: anytype) @TypeOf(writer).Error!void {
    try encodeExtLen(ext_type, @truncate(u32, bin.len), writer);
    return writer.writeAll(bin);
}

pub inline fn encodeNil(writer: anytype) @TypeOf(writer).Error!void {
    return writer.writeIntBig(u8, 0xc0);
}

test "encode nil" {
    try testEncode(encodeNil, "\xc0", .{});
}

pub inline fn encodeFloat(num: anytype, writer: anytype) @TypeOf(writer).Error!void {
    comptime const T = @TypeOf(num);
    comptime const bits = switch (@typeInfo(T)) {
        .Float => |floatTypeInfo| floatTypeInfo.bits,
        .ComptimeFloat => 64,
        else => @compileError("Unable to encode type '" ++ @typeName(T) ++ "'"),
    };

    if (bits <= 32) {
        try writer.writeIntBig(u8, 0xca);
        const casted = @bitCast(u32, @floatCast(f32, num));
        return writer.writeIntBig(u32, casted);
    }
    if (bits <= 64) {
        try writer.writeIntBig(u8, 0xcb);
        const casted = @bitCast(u64, @floatCast(f64, num));
        return writer.writeIntBig(u64, casted);
    }
    @compileError("Unable to encode type '" ++ @typeName(T) ++ "'");
}

test "test float and double" {
    try testEncode(encodeFloat, "\xca\x3f\x80\x00\x00", .{@as(f32, 1.0)});
    try testEncode(encodeFloat, "\xca\x40\x49\x0f\xdc", .{@as(f32, 3.141593)});
    try testEncode(encodeFloat, "\xca\xfe\x96\x76\x99", .{@as(f32, -1e+38)});

    try testEncode(encodeFloat, "\xcb\x3f\xf0\x00\x00\x00\x00\x00\x00", .{@as(f64, 1.0)});
    try testEncode(encodeFloat, "\xcb\x40\x09\x21\xfb\x54\x44\x2d\x18", .{@as(f64, 3.141592653589793)});
    try testEncode(encodeFloat, "\xcb\xd4\x7d\x42\xae\xa2\x87\x9f\x2e", .{@as(f64, -1e+99)});

    try testEncode(encodeFloat, "\xcb\x3f\xf0\x00\x00\x00\x00\x00\x00", .{@as(comptime_float, 1.0)});
    try testEncode(encodeFloat, "\xcb\x40\x09\x21\xfb\x54\x44\x2d\x18", .{@as(comptime_float, 3.141592653589793)});
    try testEncode(encodeFloat, "\xcb\xd4\x7d\x42\xae\xa2\x87\x9f\x2e", .{@as(comptime_float, -1e+99)});
}

pub fn encodeInt(num: anytype, writer: anytype) @TypeOf(writer).Error!void {
    comptime const T = @TypeOf(num);
    comptime const intInfo = switch (@typeInfo(T)) {
        .Int => |intInfo| intInfo,
        .ComptimeInt => @typeInfo(std.math.IntFittingRange(num, num)).Int,
        else => @compileError("Unable to encode type '" ++ @typeName(T) ++ "'"),
    };
    comptime var bits = intInfo.bits;

    if (intInfo.is_signed) {
        if (num < 0) {
            if (bits <= 6 or num >= minInt(i6)) {
                const casted = @truncate(i8, num);
                return writer.writeIntBig(u8, 0xe0 | @bitCast(u8, casted));
            }
            if (bits <= 8 or num >= minInt(i8)) {
                const casted = @truncate(i8, num);
                try writer.writeIntBig(u8, 0xd0);
                return writer.writeIntBig(i8, casted);
            }
            if (bits <= 16 or num >= minInt(i16)) {
                const casted = @truncate(i16, num);
                try writer.writeIntBig(u8, 0xd1);
                return writer.writeIntBig(i16, casted);
            }
            if (bits <= 32 or num >= minInt(i32)) {
                const casted = @truncate(i32, num);
                try writer.writeIntBig(u8, 0xd2);
                return writer.writeIntBig(i32, casted);
            }
            if (bits <= 64 or num >= minInt(i64)) {
                const casted = @truncate(i64, num);
                try writer.writeIntBig(u8, 0xd3);
                return writer.writeIntBig(i64, casted);
            }
            @compileError("Unable to encode type '" ++ @typeName(T) ++ "'");
        }

        bits -= 1;
    }

    if (bits <= 7 or num <= maxInt(u7)) {
        return writer.writeIntBig(u8, @intCast(u8, num));
    }
    if (bits <= 8 or num <= maxInt(u8)) {
        try writer.writeIntBig(u8, 0xcc);
        return writer.writeIntBig(u8, @intCast(u8, num));
    }
    if (bits <= 16 or num <= maxInt(u16)) {
        try writer.writeIntBig(u8, 0xcd);
        return writer.writeIntBig(u16, @intCast(u16, num));
    }
    if (bits <= 32 or num <= maxInt(u32)) {
        try writer.writeIntBig(u8, 0xce);
        return writer.writeIntBig(u32, @intCast(u32, num));
    }
    if (bits <= 64 or num <= maxInt(u64)) {
        try writer.writeIntBig(u8, 0xcf);
        return writer.writeIntBig(u64, @intCast(u64, num));
    }
    @compileError("Unable to encode type '" ++ @typeName(T) ++ "'");
}

test "encode int and uint" {
    try testEncode(encodeInt, "\xff", .{@as(i8, -0x01)});
    try testEncode(encodeInt, "\xe2", .{@as(i8, -0x1e)});
    try testEncode(encodeInt, "\xe1", .{@as(i8, -0x1f)});
    try testEncode(encodeInt, "\xe0", .{@as(i8, -0x20)});
    try testEncode(encodeInt, "\xd0\xdf", .{@as(i8, -0x21)});

    try testEncode(encodeInt, "\xd0\x81", .{@as(i8, -0x7f)});
    try testEncode(encodeInt, "\xd0\x80", .{@as(i8, -0x80)});

    try testEncode(encodeInt, "\xd1\xff\x7f", .{@as(i16, -0x81)});
    try testEncode(encodeInt, "\xd1\x80\x01", .{@as(i16, -0x7fff)});
    try testEncode(encodeInt, "\xd1\x80\x00", .{@as(i16, -0x8000)});

    try testEncode(encodeInt, "\xd2\xff\xff\x7f\xff", .{@as(i32, -0x8001)});
    try testEncode(encodeInt, "\xd2\x80\x00\x00\x01", .{@as(i32, -0x7fffffff)});
    try testEncode(encodeInt, "\xd2\x80\x00\x00\x00", .{@as(i32, -0x80000000)});

    try testEncode(encodeInt, "\xd3\xff\xff\xff\xff\x7f\xff\xff\xff", .{@as(i64, -0x80000001)});
    try testEncode(encodeInt, "\xd3\x80\x00\x00\x00\x00\x00\x00\x01", .{@as(i64, -0x7fffffffffffffff)});
    try testEncode(encodeInt, "\xd3\x80\x00\x00\x00\x00\x00\x00\x00", .{@as(i64, -0x8000000000000000)});

    try testEncode(encodeInt, "\x00", .{@as(u8, 0)});
    try testEncode(encodeInt, "\x01", .{@as(u8, 1)});
    try testEncode(encodeInt, "\x7e", .{@as(u8, 0x7e)});
    try testEncode(encodeInt, "\x7f", .{@as(u8, 0x7f)});

    try testEncode(encodeInt, "\xcc\x80", .{@as(u16, 0x80)});
    try testEncode(encodeInt, "\xcc\xfe", .{@as(u16, 0xfe)});
    try testEncode(encodeInt, "\xcc\xff", .{@as(u16, 0xff)});

    try testEncode(encodeInt, "\xcd\xff\xfe", .{@as(u32, 0xfffe)});
    try testEncode(encodeInt, "\xcd\xff\xff", .{@as(u32, 0xffff)});

    try testEncode(encodeInt, "\xce\x00\x01\x00\x00", .{@as(u64, 0x10000)});
    try testEncode(encodeInt, "\xce\xff\xff\xff\xfe", .{@as(u64, 0xfffffffe)});
    try testEncode(encodeInt, "\xce\xff\xff\xff\xff", .{@as(u64, 0xffffffff)});

    try testEncode(encodeInt, "\xff", .{@as(comptime_int, -0x01)});
    try testEncode(encodeInt, "\xe2", .{@as(comptime_int, -0x1e)});
    try testEncode(encodeInt, "\xe1", .{@as(comptime_int, -0x1f)});
    try testEncode(encodeInt, "\xe0", .{@as(comptime_int, -0x20)});
    try testEncode(encodeInt, "\xd0\xdf", .{@as(comptime_int, -0x21)});

    try testEncode(encodeInt, "\xd0\x81", .{@as(comptime_int, -0x7f)});
    try testEncode(encodeInt, "\xd0\x80", .{@as(comptime_int, -0x80)});

    try testEncode(encodeInt, "\xd1\xff\x7f", .{@as(comptime_int, -0x81)});
    try testEncode(encodeInt, "\xd1\x80\x01", .{@as(comptime_int, -0x7fff)});
    try testEncode(encodeInt, "\xd1\x80\x00", .{@as(comptime_int, -0x8000)});

    try testEncode(encodeInt, "\xd2\xff\xff\x7f\xff", .{@as(comptime_int, -0x8001)});
    try testEncode(encodeInt, "\xd2\x80\x00\x00\x01", .{@as(comptime_int, -0x7fffffff)});
    try testEncode(encodeInt, "\xd2\x80\x00\x00\x00", .{@as(comptime_int, -0x80000000)});

    try testEncode(encodeInt, "\xd3\xff\xff\xff\xff\x7f\xff\xff\xff", .{@as(comptime_int, -0x80000001)});
    try testEncode(encodeInt, "\xd3\x80\x00\x00\x00\x00\x00\x00\x01", .{@as(comptime_int, -0x7fffffffffffffff)});
    try testEncode(encodeInt, "\xd3\x80\x00\x00\x00\x00\x00\x00\x00", .{@as(comptime_int, -0x8000000000000000)});

    try testEncode(encodeInt, "\x00", .{@as(comptime_int, 0)});
    try testEncode(encodeInt, "\x01", .{@as(comptime_int, 1)});
    try testEncode(encodeInt, "\x7e", .{@as(comptime_int, 0x7e)});
    try testEncode(encodeInt, "\x7f", .{@as(comptime_int, 0x7f)});

    try testEncode(encodeInt, "\xcc\x80", .{@as(comptime_int, 0x80)});
    try testEncode(encodeInt, "\xcc\xfe", .{@as(comptime_int, 0xfe)});
    try testEncode(encodeInt, "\xcc\xff", .{@as(comptime_int, 0xff)});

    try testEncode(encodeInt, "\xcd\xff\xfe", .{@as(comptime_int, 0xfffe)});
    try testEncode(encodeInt, "\xcd\xff\xff", .{@as(comptime_int, 0xffff)});

    try testEncode(encodeInt, "\xce\x00\x01\x00\x00", .{@as(comptime_int, 0x10000)});
    try testEncode(encodeInt, "\xce\xff\xff\xff\xfe", .{@as(comptime_int, 0xfffffffe)});
    try testEncode(encodeInt, "\xce\xff\xff\xff\xff", .{@as(comptime_int, 0xffffffff)});
}

pub inline fn encodeBool(val: bool, writer: anytype) @TypeOf(writer).Error!void {
    return writer.writeIntBig(u8, @as(u8, if (val) 0xc3 else 0xc2));
}

test "encode bool" {
    try testEncode(encodeBool, "\xc3", .{true});
    try testEncode(encodeBool, "\xc2", .{false});
}

pub fn encodeArrayLen(len: u32, writer: anytype) @TypeOf(writer).Error!void {
    if (len <= std.math.maxInt(u4)) {
        return writer.writeIntBig(u8, 0x90 | @truncate(u8, len));
    }
    if (len <= std.math.maxInt(u16)) {
        try writer.writeIntBig(u8, 0xdc);
        return writer.writeIntBig(u16, @truncate(u16, len));
    }
    try writer.writeIntBig(u8, 0xdd);
    return writer.writeIntBig(u32, @truncate(u32, len));
}

test "encode array length" {
    try testEncode(encodeArrayLen, "\x90", .{@as(u32, 0)});
    try testEncode(encodeArrayLen, "\x91", .{@as(u32, 1)});
    try testEncode(encodeArrayLen, "\x9f", .{@as(u32, 15)});
    try testEncode(encodeArrayLen, "\xdc\x00\x10", .{@as(u32, 16)});
    try testEncode(encodeArrayLen, "\xdc\xff\xfe", .{@as(u32, 0xfffe)});
    try testEncode(encodeArrayLen, "\xdc\xff\xff", .{@as(u32, 0xffff)});
    try testEncode(encodeArrayLen, "\xdd\x00\x01\x00\x00", .{@as(u32, 0x10000)});
    try testEncode(encodeArrayLen, "\xdd\xff\xff\xff\xfe", .{@as(u32, 0xfffffffe)});
    try testEncode(encodeArrayLen, "\xdd\xff\xff\xff\xff", .{@as(u32, 0xffffffff)});

    try testEncode(encodeArrayLen, "\x90", .{@as(comptime_int, 0)});
    try testEncode(encodeArrayLen, "\x91", .{@as(comptime_int, 1)});
    try testEncode(encodeArrayLen, "\x9f", .{@as(comptime_int, 15)});
    try testEncode(encodeArrayLen, "\xdc\x00\x10", .{@as(comptime_int, 16)});
    try testEncode(encodeArrayLen, "\xdc\xff\xfe", .{@as(comptime_int, 0xfffe)});
    try testEncode(encodeArrayLen, "\xdc\xff\xff", .{@as(comptime_int, 0xffff)});
    try testEncode(encodeArrayLen, "\xdd\x00\x01\x00\x00", .{@as(comptime_int, 0x10000)});
    try testEncode(encodeArrayLen, "\xdd\xff\xff\xff\xfe", .{@as(comptime_int, 0xfffffffe)});
    try testEncode(encodeArrayLen, "\xdd\xff\xff\xff\xff", .{@as(comptime_int, 0xffffffff)});
}

pub inline fn encodeArray(arr: anytype, options: EncodingOptions, writer: anytype) @TypeOf(writer).Error!void {
    comptime const T = @TypeOf(arr);
    switch (@typeInfo(T)) {
        .Pointer => |ptr_info| switch (ptr_info.size) {
            .One => switch (@typeInfo(ptr_info.child)) {
                .Array => {
                    const Slice = []const std.meta.Elem(ptr_info.child);
                    return encodeArray(@as(Slice, arr), options, writer);
                },
                else => @compileError("Unable to encode type '" ++ @typeName(T) ++ "'"),
            },
            .Many, .Slice => {
                try encodeArrayLen(@truncate(u32, arr.len), writer);
                for (arr) |value| {
                    try encode(value, options, writer);
                }
            },
            else => @compileError("Unable to encode type '" ++ @typeName(T) ++ "'"),
        },
        .Array => {
            return encodeArray(&arr, options, writer);
        },
        else => @compileError("Unable to encode type '" ++ @typeName(T) ++ "'"),
    }
}

test "encode array" {
    var testArray = [_]i32{ 1, 2, 3, 4 };

    try testEncode(encodeArray, "\x94\x01\x02\x03\x04", .{ testArray, .{} });
    try testEncode(encodeArray, "\x94\x01\x02\x03\x04", .{ &testArray, .{} });
    try testEncode(encodeArray, "\x94\x01\x02\x03\x04", .{ testArray[0..testArray.len], .{} });
}

pub fn encodeMapLen(len: u32, writer: anytype) @TypeOf(writer).Error!void {
    if (len <= std.math.maxInt(u4)) {
        return writer.writeIntBig(u8, 0x80 | @truncate(u8, len));
    }
    if (len <= std.math.maxInt(u16)) {
        try writer.writeIntBig(u8, 0xde);
        return writer.writeIntBig(u16, @truncate(u16, len));
    }
    if (len <= std.math.maxInt(u32)) {
        try writer.writeIntBig(u8, 0xdf);
        return writer.writeIntBig(u32, @truncate(u32, len));
    }
    unreachable;
}

test "encode map length" {
    try testEncode(encodeMapLen, "\x80", .{@as(u32, 0)});
    try testEncode(encodeMapLen, "\x81", .{@as(u32, 1)});
    try testEncode(encodeMapLen, "\x8f", .{@as(u32, 15)});
    try testEncode(encodeMapLen, "\xde\x00\x10", .{@as(u32, 16)});
    try testEncode(encodeMapLen, "\xde\xff\xfe", .{@as(u32, 0xfffe)});
    try testEncode(encodeMapLen, "\xde\xff\xff", .{@as(u32, 0xffff)});
    try testEncode(encodeMapLen, "\xdf\x00\x01\x00\x00", .{@as(u32, 0x10000)});
    try testEncode(encodeMapLen, "\xdf\xff\xff\xff\xfe", .{@as(u32, 0xfffffffe)});
    try testEncode(encodeMapLen, "\xdf\xff\xff\xff\xff", .{@as(u32, 0xffffffff)});

    try testEncode(encodeMapLen, "\x80", .{@as(comptime_int, 0)});
    try testEncode(encodeMapLen, "\x81", .{@as(comptime_int, 1)});
    try testEncode(encodeMapLen, "\x8f", .{@as(comptime_int, 15)});
    try testEncode(encodeMapLen, "\xde\x00\x10", .{@as(comptime_int, 16)});
    try testEncode(encodeMapLen, "\xde\xff\xfe", .{@as(comptime_int, 0xfffe)});
    try testEncode(encodeMapLen, "\xde\xff\xff", .{@as(comptime_int, 0xffff)});
    try testEncode(encodeMapLen, "\xdf\x00\x01\x00\x00", .{@as(comptime_int, 0x10000)});
    try testEncode(encodeMapLen, "\xdf\xff\xff\xff\xfe", .{@as(comptime_int, 0xfffffffe)});
    try testEncode(encodeMapLen, "\xdf\xff\xff\xff\xff", .{@as(comptime_int, 0xffffffff)});
}

pub inline fn encodeStruct(
    structure: anytype,
    options: EncodingOptions,
    writer: anytype,
) @TypeOf(writer).Error!void {
    const T = @TypeOf(structure);
    if (comptime std.meta.trait.hasFn("encodeMsgPack")(T)) {
        return structure.encodeMsgPack(options, writer);
    }
    comptime const fields = @typeInfo(T).Struct.fields;
    try switch (options.struct_encoding) {
        .array => encodeArrayLen(fields.len, writer),
        .map => encodeMapLen(fields.len, writer),
    };

    inline for (fields) |Field| {
        if (Field.field_type == void) {
            continue;
        }

        if (options.struct_encoding == StructEncoding.map) {
            try encode(Field.name, options, writer);
        }
        try encode(@field(structure, Field.name), options, writer);
    }
}

test "encode struct" {
    const testingStruct = .{
        .int = @as(i32, 65534),
        .float = @as(f64, 3.141592653589793),
        .boolean = true,
        .nil = null,
        .string = "string",
        .array = @as([4]i16, .{ 11, 22, 33, 44 }),
    };

    try testEncode(
        encodeStruct,
        "\x96\xCD\xFF\xFE\xCB\x40\x09\x21\xFB\x54\x44\x2D\x18\xC3\xC0\xA6\x73\x74\x72\x69\x6E\x67\x94\x0B\x16\x21\x2C",
        .{ testingStruct, .{ .struct_encoding = .array, .u8_array_encoding = .string } },
    );
    try testEncode(
        encodeStruct,
        "\x86\xA3\x69\x6E\x74\xCD\xFF\xFE\xA5\x66\x6C\x6F\x61\x74\xCB\x40\x09\x21\xFB\x54\x44\x2D\x18\xA7\x62\x6F\x6F\x6C\x65\x61\x6E\xC3\xA3\x6E\x69\x6C\xC0\xA6\x73\x74\x72\x69\x6E\x67\xA6\x73\x74\x72\x69\x6E\x67\xA5\x61\x72\x72\x61\x79\x94\x0B\x16\x21\x2C",
        .{ testingStruct, .{ .struct_encoding = .map, .u8_array_encoding = .string } },
    );

    const CustomStruct = struct {
        int: i64 = 0,
        float: f64 = 0,
        boolean: bool = false,

        const Self = @This();
        pub fn encodeMsgPack(value: Self, options: EncodingOptions, writer: anytype) @TypeOf(writer).Error!void {
            return encodeBool(true, writer);
        }
    };
    try testEncode(encodeStruct, "\xc3", .{
        CustomStruct{},
        .{},
    });
}

pub inline fn encodeOptional(
    value: anytype,
    options: EncodingOptions,
    writer: anytype,
) @TypeOf(writer).Error!void {
    return if (value) |payload| encode(payload, options, writer) else encodeNil(writer);
}

test "encode optional" {
    try testEncode(encodeOptional, "\xc0", .{ @as(?i32, null), .{} });
    try testEncode(encodeOptional, "\xcd\xff\xfe", .{ @as(?i32, 65534), .{} });
}

pub fn encodeUnion(
    value: anytype,
    options: EncodingOptions,
    writer: anytype,
) @TypeOf(writer).Error!void {
    comptime const T = @TypeOf(value);
    if (comptime std.meta.trait.hasFn("encodeMsgPack")(T)) {
        return value.encodeMsgPack(options, writer);
    }
    comptime const info = switch (@typeInfo(T)) {
        .Union => |unionInfo| unionInfo,
        else => @compileError("Unable to encode type '" ++ @typeName(T) ++ "'"),
    };

    if (info.tag_type) |TagType| {
        inline for (info.fields) |field| {
            if (value == @field(TagType, field.name)) {
                return encode(@field(value, field.name), options, writer);
            }
        }
    } else {
        @compileError("Unable to encode untagged union '" ++ @typeName(T) ++ "'");
    }
}

test "encode tagged union" {
    const TaggedUnion = union(enum) {
        int: i64,
        float: f64,
        boolean: bool,
    };

    try testEncode(encodeUnion, "\xd3\xff\xff\xff\xff\x7f\xff\xff\xff", .{
        TaggedUnion{ .int = -0x80000001 },
        .{},
    });
    try testEncode(encodeUnion, "\xcb\x3f\xf0\x00\x00\x00\x00\x00\x00", .{
        TaggedUnion{ .float = 1.0 },
        .{},
    });
    try testEncode(encodeUnion, "\xc3", .{
        TaggedUnion{ .boolean = true },
        .{},
    });

    const TaggedUnionCustom = union(enum) {
        int: i64,
        float: f64,
        boolean: bool,

        const Self = @This();
        pub fn encodeMsgPack(value: Self, options: EncodingOptions, writer: anytype) @TypeOf(writer).Error!void {
            return encodeBool(true, writer);
        }
    };
    try testEncode(encodeUnion, "\xc3", .{
        TaggedUnionCustom{ .boolean = false },
        .{},
    });

    const EnumCustom = enum {
        a,
        b,
        c,
        const Self = @This();
        pub fn encodeMsgPack(value: Self, options: EncodingOptions, writer: anytype) @TypeOf(writer).Error!void {
            return encodeBool(true, writer);
        }
    };
    try testEncode(encode, "\xc3", .{
        EnumCustom.a,
        .{},
    });
}

const U8ArrayEncoding = enum {
    auto, // encodes as string if valid utf8 string, otherwise encodes as binary
    array,
    string,
    binary,
};
const StructEncoding = enum {
    array,
    map,
};
pub const EncodingOptions = struct {
    u8_array_encoding: U8ArrayEncoding = .auto,
    struct_encoding: StructEncoding = .array,
};

pub inline fn encode(
    value: anytype,
    options: EncodingOptions,
    writer: anytype,
) @TypeOf(writer).Error!void {
    const T = @TypeOf(value);
    return switch (@typeInfo(T)) {
        .Float, .ComptimeFloat => encodeFloat(value, writer),
        .Int, .ComptimeInt => encodeInt(value, writer),
        .Bool => encodeBool(value, writer),
        .Optional => encodeOptional(value, options, writer),
        .Struct => encodeStruct(value, options, writer),
        .Pointer => |ptr_info| switch (ptr_info.size) {
            .One => switch (@typeInfo(ptr_info.child)) {
                .Array => blk: {
                    const Slice = []const std.meta.Elem(ptr_info.child);
                    break :blk encode(@as(Slice, value), options, writer);
                },
                else => encode(value.*, options, writer),
            },
            .Many, .Slice => blk: {
                if (ptr_info.child == u8) {
                    break :blk switch (options.u8_array_encoding) {
                        .array => encodeArray(value, options, writer),
                        .auto => {
                            if (std.unicode.utf8ValidateSlice(value)) {
                                break :blk encodeStr(value, writer);
                            } else {
                                break :blk encodeBin(value, writer);
                            }
                        },
                        .string => encodeStr(value, writer),
                        .binary => encodeBin(value, writer),
                    };
                }
                break :blk encodeArray(value, options, writer);
            },
            else => @compileError("Unable to encode type '" ++ @typeName(T) ++ "'"),
        },
        .Array => encodeArray(&value, options, writer),
        .ErrorSet => encodeStr(@errorName(value), writer),
        .Enum => {
            if (comptime std.meta.trait.hasFn("encodeMsgPack")(T)) {
                return value.encodeMsgPack(options, writer);
            }
            @compileError("Unable to encode enum '" ++ @typeName(T) ++ "'");
        },
        .Union => encodeUnion(value, options, writer),
        .Null => encodeNil(writer),
        else => @compileError("Unable to encode type '" ++ @typeName(T) ++ "'"),
    };
}

test "encode" {
    const opts = .{};

    try testEncode(encode, "\xca\x40\x49\x0f\xdc", .{ @as(f32, 3.141593), opts });
    try testEncode(encode, "\xcb\x40\x09\x21\xfb\x54\x44\x2d\x18", .{ @as(f64, 3.141592653589793), opts });

    try testEncode(encode, "\xd2\xff\xff\x7f\xff", .{ @as(i32, -0x8001), opts });
    try testEncode(encode, "\xcd\xff\xfe", .{ @as(u32, 0xfffe), opts });

    try testEncode(encode, "\xc0", .{ null, opts });

    try testEncode(encode, "\xc3", .{ true, opts });
    try testEncode(encode, "\xc2", .{ false, opts });

    try testEncode(encode, "\xa6string", .{ "string", opts });

    try testEncode(encode, "\xc0", .{ @as(?i32, null), opts });
    try testEncode(encode, "\xcd\xff\xfe", .{ @as(?i32, 65534), opts });

    const testingStruct = .{
        .int = @as(i32, 65534),
        .float = @as(f64, 3.141592653589793),
        .boolean = true,
        .nil = null,
        .string = "string",
        .array = @as([4]i16, .{ 11, 22, 33, 44 }),
    };
    try testEncode(
        encode,
        "\x96\xCD\xFF\xFE\xCB\x40\x09\x21\xFB\x54\x44\x2D\x18\xC3\xC0\xA6\x73\x74\x72\x69\x6E\x67\x94\x0B\x16\x21\x2C",
        .{ testingStruct, .{ .struct_encoding = .array, .u8_array_encoding = .string } },
    );
    try testEncode(
        encode,
        "\x86\xA3\x69\x6E\x74\xCD\xFF\xFE\xA5\x66\x6C\x6F\x61\x74\xCB\x40\x09\x21\xFB\x54\x44\x2D\x18\xA7\x62\x6F\x6F\x6C\x65\x61\x6E\xC3\xA3\x6E\x69\x6C\xC0\xA6\x73\x74\x72\x69\x6E\x67\xA6\x73\x74\x72\x69\x6E\x67\xA5\x61\x72\x72\x61\x79\x94\x0B\x16\x21\x2C",
        .{ testingStruct, .{ .struct_encoding = .map, .u8_array_encoding = .string } },
    );

    var testArray = [_]i32{ 1, 2, 3, 4 };
    try testEncode(encode, "\x94\x01\x02\x03\x04", .{ testArray, opts });
    try testEncode(encode, "\x94\x01\x02\x03\x04", .{ &testArray, opts });
    try testEncode(encode, "\x94\x01\x02\x03\x04", .{ testArray[0..testArray.len], opts });

    const TaggedUnionCustom = union(enum) {
        int: i64,
        float: f64,
        boolean: bool,

        const Self = @This();
        pub fn encodeMsgPack(value: Self, options: EncodingOptions, writer: anytype) @TypeOf(writer).Error!void {
            return encodeBool(true, writer);
        }
    };
    try testEncode(encode, "\xc3", .{
        TaggedUnionCustom{ .boolean = false },
        .{},
    });

    const test_string_non_utf8 = "\xff\xff\xff\xff";
    try testEncode(encode, "\xC4\x04" ++ test_string_non_utf8, .{
        test_string_non_utf8,
        .{ .u8_array_encoding = .auto },
    });
    const test_string_utf8 = "some string";
    try testEncode(encode, "\xAB" ++ test_string_utf8, .{
        test_string_utf8,
        .{ .u8_array_encoding = .auto },
    });
    try testEncode(encode, "\x9B" ++ test_string_utf8, .{
        test_string_utf8,
        .{ .u8_array_encoding = .array },
    });
    try testEncode(encode, "\xAB" ++ test_string_utf8, .{
        test_string_utf8,
        .{ .u8_array_encoding = .string },
    });
    try testEncode(encode, "\xC4\x0B" ++ test_string_utf8, .{
        test_string_utf8,
        .{ .u8_array_encoding = .binary },
    });
}

fn testEncode(func: anytype, comptime expected: []const u8, input: anytype) !void {
    var buf: [255]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buf);
    const writer = fbs.writer();

    const args = input ++ .{writer};
    try @call(.{}, func, args);
    const result = fbs.getWritten();
    testing.expectEqualSlices(u8, expected, result);
}
