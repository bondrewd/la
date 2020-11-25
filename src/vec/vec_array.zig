const std = @import("std");
const mem = std.mem;

pub fn VecArray(comptime T: type, comptime n: usize) type {
    if (@typeInfo(T) != .Int and @typeInfo(T) != .Float) {
        @compileError("Expected numeric type, found '" ++ @typeName(T) ++ "'");
    }
    return struct {
        data: [n]T = undefined,

        pub const DataT = T;
        pub const len = n;
        pub const Self = @This();

        pub fn new() Self {
            return Self{};
        }

        pub fn setFromArray(self: *Self, array: [n]T) void {
            for (self.data) |*value, i| {
                value.* = array[i];
            }
        }

        pub fn setFromSlice(self: *Self, slice: []T) void {
            mem.copy(T, self.data[0..], slice);
        }

        pub fn setFromVec(self: *Self, vec: anytype) void {
            const VecT = @TypeOf(vec);
            if (@typeInfo(VecT) != .Struct) @compileError("Expected Vec, found '" ++ @typeName(VecT) ++ "'");
            if (!@hasDecl(VecT, "DataT")) @compileError("Vec does not contain DataT declaration");
            if (!@hasField(VecT, "data")) @compileError("Vec does not contain data field");
            if (VecT.DataT != T) @compileError("Expected Vec of data type '" ++ @typeName(T) ++ "', found '" ++ @typeName(VecT) ++ "'");

            mem.copy(T, self.data[0..], vec.data[0..]);
        }

        pub fn set(self: *Self, data: anytype) void {
            switch (@typeInfo(@TypeOf(data))) {
                .Pointer => self.setFromSlice(data),
                .Array => self.setFromArray(data),
                .Struct => self.setFromVec(data),
                else => @compileError("Expected Slice, Array, or Vec, found '" ++ @typeName(@TypeOf(data)) ++ "'"),
            }
        }
    };
}

const testing = std.testing;
test "VecArray" {
    const V = VecArray(u8, 2);
    testing.expect(V.DataT == u8);
    testing.expect(V.len == 2);

    const W = VecArray(f32, 3);
    testing.expect(W.DataT == f32);
    testing.expect(W.len == 3);
}

test "VecArray new" {
    const V = VecArray(u8, 2);
    var v = V.new();
    testing.expect(@TypeOf(v) == V);
    testing.expect(v.data.len == 2);
    testing.expect(@TypeOf(v.data) == [2]u8);
}

test "VecArray setFromArray" {
    var v = VecArray(u8, 2).new();

    v.setFromArray(.{ 0, 1 });
    testing.expectEqual([2]u8{ 0, 1 }, v.data);

    var w = VecArray(f32, 3).new();

    w.setFromArray(.{ -1.0, 1.5, 3.5 });
    testing.expectEqual([3]f32{ -1.0, 1.5, 3.5 }, w.data);
}

test "VecArray setFromSlice" {
    var slice_1 = try testing.allocator.alloc(u8, 2);
    defer testing.allocator.free(slice_1);
    slice_1[0] = 2;
    slice_1[1] = 5;

    var v = VecArray(u8, 2).new();

    v.setFromSlice(slice_1);
    testing.expectEqual([2]u8{ 2, 5 }, v.data);

    var slice_2 = try testing.allocator.alloc(u8, 2);
    slice_2[0] = 3;
    slice_2[1] = 6;

    var w = VecArray(u8, 2).new();

    w.setFromSlice(slice_2);
    testing.expectEqual([2]u8{ 3, 6 }, w.data);

    slice_2[0] = 1;
    slice_2[1] = 2;
    testing.expectEqual([2]u8{ 3, 6 }, w.data);

    testing.allocator.free(slice_2);
    testing.expectEqual([2]u8{ 3, 6 }, w.data);
}

test "VecArray setFromVec" {
    var v = VecArray(u8, 2).new();
    v.setFromArray(.{ 0, 1 });

    var w = VecArray(u8, 2).new();
    w.setFromVec(v);

    testing.expectEqual(v, w);
}

test "VecArray set" {
    var v = VecArray(u8, 2).new();
    var array = [2]u8{ 0, 1 };

    v.set(array);
    testing.expectEqual([2]u8{ 0, 1 }, v.data);

    var w = VecArray(u8, 2).new();
    var slice = array[0..];

    w.set(slice);
    testing.expectEqual([2]u8{ 0, 1 }, w.data);

    var x = VecArray(u8, 2).new();
    var vec_array = VecArray(u8, 2).new();
    vec_array.setFromArray(.{ 0, 1 });

    x.set(vec_array);
    testing.expectEqual([2]u8{ 0, 1 }, x.data);

    var y = VecArray(u8, 2).new();
    const VecSlice = @import("vec_slice.zig").VecSlice;
    var vec_slice = try VecSlice(u8, 2).new().init(testing.allocator);
    defer vec_slice.deinit();
    vec_slice.set([2]u8{ 0, 1 });

    y.set(vec_slice);
    testing.expectEqualSlices(u8, ([2]u8{ 0, 1 })[0..], y.data[0..]);
}
