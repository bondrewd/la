const std = @import("std");

pub fn VecArray(comptime T: type, comptime n: usize) type {
    if (@typeInfo(T) != .Int and @typeInfo(T) != .Float) {
        @compileError("Expected numeric types, found '" ++ @typeName(T) ++ "'");
    }
    return struct {
        data: [n]T = undefined,

        pub const DataT = T;
        pub const len = n;
        pub const Self = @This();

        pub fn new() Self {
            return Self{};
        }

        pub fn fromArray(array: [n]T) Self {
            return Self{
                .data = array,
            };
        }

        pub fn fromSlice(slice: []T) Self {
            std.debug.assert(slice.len == Self.len);
            var new_vec_array = Self.new();
            for (new_vec_array.data) |*d, i| {
                d.* = slice[i];
            }

            return new_vec_array;
        }

        pub fn fromVecArray(vec: Self) Self {
            return Self{
                .data = vec.data,
            };
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

test "VecArray fromArray" {
    const V = VecArray(u8, 2);
    var v = V.fromArray(.{ 0, 1 });
    testing.expectEqual([2]u8{ 0, 1 }, v.data);

    const W = VecArray(f32, 3);
    var w = W.fromArray(.{ -1.0, 1.5, 3.5 });
    testing.expectEqual([3]f32{ -1.0, 1.5, 3.5 }, w.data);
}

test "VecArray fromSlice" {
    const V = VecArray(u8, 2);

    var slice_1 = try testing.allocator.alloc(u8, 2);
    defer testing.allocator.free(slice_1);
    slice_1[0] = 2;
    slice_1[1] = 5;

    var v = V.fromSlice(slice_1);
    testing.expectEqual([2]u8{ 2, 5 }, v.data);

    var slice_2 = try testing.allocator.alloc(u8, 2);
    slice_2[0] = 3;
    slice_2[1] = 6;

    v = V.fromSlice(slice_2);
    testing.expectEqual([2]u8{ 3, 6 }, v.data);

    slice_2[0] = 1;
    slice_2[1] = 2;
    testing.expectEqual([2]u8{ 3, 6 }, v.data);

    testing.allocator.free(slice_2);
    testing.expectEqual([2]u8{ 3, 6 }, v.data);
}

test "VecArray fromVecArray" {
    const V = VecArray(u8, 2);
    var v1 = V.fromArray(.{ 0, 1 });
    var v2 = V.fromVecArray(v1);
    testing.expectEqual(v1, v2);

    const W = VecArray(f32, 3);
    var w1 = W.fromArray(.{ -1.0, 1.5, 3.5 });
    var w2 = W.fromVecArray(w1);
    testing.expectEqual(w1, w2);
}
