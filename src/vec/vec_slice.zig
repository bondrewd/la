const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;

pub fn VecSlice(comptime T: type, comptime n: usize) type {
    if (@typeInfo(T) != .Int and @typeInfo(T) != .Float) {
        @compileError("Expected numeric types, found '" ++ @typeName(T) ++ "'");
    }
    return struct {
        data: []T = undefined,
        allocator: *Allocator = undefined,
        allocated: bool = false,

        pub const DataT = T;
        pub const len = n;
        pub const Self = @This();

        pub fn init(allocator: *Allocator) !Self {
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

        pub fn realloc(self: *Self) !void {
            if (self.allocated) {
                self.allocator.free(self.data);
            } else {
                self.allocated = true;
            }
            self.data = try self.allocator.alloc(T, n);
        }

        pub fn initFromArray(allocator: *Allocator, array: [n]T) !Self {
            var new_vec_slice = try init(allocator);
            for (new_vec_slice.data) |*value, i| {
                value.* = array[i];
            }

            return new_vec_slice;
        }

        pub fn initFromSlice(allocator: *Allocator, slice: []T) !Self {
            std.debug.assert(slice.len == Self.len);
            var new_vec_slice = try init(allocator);
            mem.copy(T, new_vec_slice.data, slice);

            return new_vec_slice;
        }

        pub fn initFromVecSlice(allocator: *Allocator, vec_slice: Self) !Self {
            var new_vec_slice = try init(allocator);
            mem.copy(T, new_vec_slice.data, vec_slice.data);

            return new_vec_slice;
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
}

test "VecSlice init" {
    const V = VecSlice(u8, 2);

    var v = try V.init(testing.allocator);
    defer v.allocator.free(v.data);

    testing.expect(v.data.len == 2);
    testing.expect(v.allocator == testing.allocator);
    testing.expect(v.allocated == true);
}

test "VecSlice deinit" {
    const V = VecSlice(u8, 2);

    var v = try V.init(testing.allocator);

    v.deinit();

    testing.expect(v.allocator == testing.allocator);
    testing.expect(v.allocated == false);
}

test "VecSlice realloc" {
    const V = VecSlice(u8, 2);

    var v = try V.init(testing.allocator);
    defer v.deinit();

    v.data[0] = 0;
    v.data[1] = 1;

    try v.realloc();

    testing.expect(v.data[0] != 0);
    testing.expect(v.data[1] != 1);
}

test "VecSlice initFromArray" {
    const V = VecSlice(u8, 2);

    var v = try V.initFromArray(testing.allocator, .{ 0, 1 });
    defer v.deinit();

    testing.expect(mem.eql(u8, ([2]u8{ 0, 1 })[0..], v.data));

    const W = VecSlice(f32, 3);

    var w = try W.initFromArray(testing.allocator, .{ -1.0, 1.5, 3.5 });
    defer w.deinit();

    testing.expect(mem.eql(f32, ([3]f32{ -1.0, 1.5, 3.5 })[0..], w.data));
}

test "VecSlice initFromSlice" {
    const V = VecSlice(u8, 2);

    var slice_1 = try testing.allocator.alloc(u8, 2);
    defer testing.allocator.free(slice_1);
    slice_1[0] = 2;
    slice_1[1] = 5;

    var v = try V.initFromSlice(testing.allocator, slice_1);
    defer v.deinit();

    testing.expect(mem.eql(u8, ([2]u8{ 2, 5 })[0..], v.data));

    var slice_2 = try testing.allocator.alloc(u8, 2);
    slice_2[0] = 3;
    slice_2[1] = 6;

    v.deinit();
    v = try V.initFromSlice(testing.allocator, slice_2);
    testing.expect(mem.eql(u8, ([2]u8{ 3, 6 })[0..], v.data));

    slice_2[0] = 1;
    slice_2[1] = 2;
    testing.expect(mem.eql(u8, ([2]u8{ 3, 6 })[0..], v.data));

    testing.allocator.free(slice_2);
    testing.expect(mem.eql(u8, ([2]u8{ 3, 6 })[0..], v.data));
}

test "VecSlice initFromVecSlice" {
    const V = VecSlice(u8, 2);

    var v1 = try V.initFromArray(testing.allocator, .{ 0, 1 });
    defer v1.deinit();

    var v2 = try V.initFromVecSlice(testing.allocator, v1);
    defer v2.deinit();

    testing.expect(mem.eql(u8, v1.data, v2.data));

    const W = VecSlice(f32, 3);

    var w1 = try W.initFromArray(testing.allocator, .{ -1.0, 1.5, 3.5 });
    defer w1.deinit();

    var w2 = try W.initFromVecSlice(testing.allocator, w1);
    defer w2.deinit();

    testing.expect(mem.eql(f32, w1.data, w2.data));
}
