const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;

pub fn VecSlice(comptime T: type, comptime n: usize) type {
    if (@typeInfo(T) != .Int and @typeInfo(T) != .Float) {
        @compileError("Expected numeric type, found '" ++ @typeName(T) ++ "'");
    }
    return struct {
        data: []T = undefined,
        allocator: *Allocator = undefined,
        allocated: bool = false,

        pub const DataT = T;
        pub const len = n;
        pub const Self = @This();

        pub fn new() Self {
            return Self{};
        }

        pub fn init(self: Self, allocator: *Allocator) !Self {
            return Self{
                .data = try allocator.alloc(T, n),
                .allocator = allocator,
                .allocated = true,
            };
        }

        pub fn deinit(self: *Self) void {
            if (self.allocated) {
                self.allocator.free(self.data);
                self.allocated = false;
            }
        }

        pub fn setFromArray(self: *Self, array: [n]T) void {
            mem.copy(T, self.data, array[0..]);
        }

        pub fn setFromSlice(self: *Self, slice: []T) void {
            mem.copy(T, self.data, slice);
        }

        pub fn setFromVec(self: *Self, vec: anytype) void {
            const VecT = @TypeOf(vec);
            if (@typeInfo(VecT) != .Struct) @compileError("Expected Vec, found '" ++ @typeName(VecT) ++ "'");
            if (!@hasDecl(VecT, "DataT")) @compileError("Vec does not contain DataT declaration");
            if (!@hasField(VecT, "data")) @compileError("Vec does not contain data field");
            if (VecT.DataT != T) @compileError("Expected Vec of data type '" ++ @typeName(T) ++ "', found '" ++ @typeName(VecT) ++ "'");

            mem.copy(T, self.data, vec.data[0..]);
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
test "VecSlice" {
    const V = VecSlice(u8, 2);
    testing.expect(V.DataT == u8);
    testing.expect(V.len == 2);

    const W = VecSlice(f32, 3);
    testing.expect(W.DataT == f32);
    testing.expect(W.len == 3);

    const A = VecSlice(i32, 5);
    const B = VecSlice(i32, 5);
    testing.expect(A == B);
}

test "VecSlice new" {
    const V = VecSlice(u8, 2);
    var v = V.new();
    testing.expect(@TypeOf(v) == V);
    testing.expect(@TypeOf(v.data) == []u8);
}

test "VecSlice init" {
    var v = try VecSlice(u8, 2).new().init(testing.allocator);
    defer v.allocator.free(v.data);

    testing.expect(v.data.len == 2);
    testing.expect(v.allocator == testing.allocator);
    testing.expect(v.allocated == true);
}

test "VecSlice deinit" {
    var v = try VecSlice(u8, 2).new().init(testing.allocator);

    v.deinit();

    testing.expect(v.allocator == testing.allocator);
    testing.expect(v.allocated == false);

    var w = VecSlice(u8, 2).new();

    w.deinit();

    testing.expect(w.allocated == false);
}

test "VecSlice setFromArray" {
    var v = try VecSlice(u8, 2).new().init(testing.allocator);
    defer v.deinit();

    v.setFromArray(.{ 0, 1 });
    testing.expectEqualSlices(u8, ([2]u8{ 0, 1 })[0..], v.data);

    var w = try VecSlice(f32, 3).new().init(testing.allocator);
    defer w.deinit();

    w.setFromArray(.{ -1.0, 1.5, 3.5 });
    testing.expectEqualSlices(f32, ([3]f32{ -1.0, 1.5, 3.5 })[0..], w.data);
}

test "VecSlice setFromSlice" {
    var slice_1 = try testing.allocator.alloc(u8, 2);
    defer testing.allocator.free(slice_1);
    slice_1[0] = 2;
    slice_1[1] = 5;

    var v = try VecSlice(u8, 2).new().init(testing.allocator);
    defer v.deinit();

    v.setFromSlice(slice_1);
    testing.expectEqualSlices(u8, ([2]u8{ 2, 5 })[0..], v.data);

    var slice_2 = try testing.allocator.alloc(u8, 2);
    slice_2[0] = 3;
    slice_2[1] = 6;

    var w = try VecSlice(u8, 2).new().init(testing.allocator);
    defer w.deinit();

    w.setFromSlice(slice_2);
    testing.expectEqualSlices(u8, ([2]u8{ 3, 6 })[0..], w.data);

    slice_2[0] = 1;
    slice_2[1] = 2;
    testing.expectEqualSlices(u8, ([2]u8{ 3, 6 })[0..], w.data);

    testing.allocator.free(slice_2);
    testing.expectEqualSlices(u8, ([2]u8{ 3, 6 })[0..], w.data);
}

test "VecSlice setFromVec" {
    var v = try VecSlice(u8, 2).new().init(testing.allocator);
    defer v.deinit();
    v.setFromArray(.{ 0, 1 });

    var w = try VecSlice(u8, 2).new().init(testing.allocator);
    defer w.deinit();
    w.setFromVec(v);

    testing.expectEqualSlices(u8, v.data, w.data);
}

test "VecSlice set" {
    var v = try VecSlice(u8, 2).new().init(testing.allocator);
    defer v.deinit();
    var array = [2]u8{ 0, 1 };

    v.set(array);
    testing.expectEqualSlices(u8, ([2]u8{ 0, 1 })[0..], v.data);

    var w = try VecSlice(u8, 2).new().init(testing.allocator);
    defer w.deinit();
    var slice = array[0..];

    w.set(slice);
    testing.expectEqualSlices(u8, ([2]u8{ 0, 1 })[0..], w.data);

    var x = try VecSlice(u8, 2).new().init(testing.allocator);
    defer x.deinit();
    var vec_slice = try VecSlice(u8, 2).new().init(testing.allocator);
    defer vec_slice.deinit();
    vec_slice.setFromArray(.{ 0, 1 });

    x.set(vec_slice);
    testing.expectEqualSlices(u8, ([2]u8{ 0, 1 })[0..], x.data);

    var y = try VecSlice(u8, 2).new().init(testing.allocator);
    defer y.deinit();
    const VecArray = @import("vec_array.zig").VecArray;
    var vec_array = VecArray(u8, 2).new();
    vec_array.set([2]u8{ 0, 1 });

    y.set(vec_array);
    testing.expectEqualSlices(u8, ([2]u8{ 0, 1 })[0..], y.data);
}
