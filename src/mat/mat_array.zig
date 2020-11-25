const std = @import("std");
const mem = std.mem;

pub fn MatArray(comptime T: type, comptime n: usize, comptime m: usize) type {
    if (@typeInfo(T) != .Int and @typeInfo(T) != .Float) {
        @compileError("Expected numeric type, found '" ++ @typeName(T) ++ "'");
    }
    return struct {
        data: [n][m]T = undefined,

        pub const DataT = T;
        pub const row_len = n;
        pub const col_len = m;
        pub const Self = @This();

        pub fn new() Self {
            return Self{};
        }

        pub fn setFromArrayOfArrays(self: *Self, array: [n][m]T) void {
            for (self.data) |*row, i| {
                mem.copy(T, row[0..], array[i][0..]);
            }
        }

        pub fn setFromSliceOfArrays(self: *Self, slice: [][m]T) void {
            std.debug.assert(n == slice.len);
            for (self.data) |*row, i| {
                mem.copy(T, row[0..], slice[i][0..]);
            }
        }

        pub fn setFromSliceOfSlices(self: *Self, slice: [][]T) void {
            std.debug.assert(n == slice.len);
            for (self.data) |*row, i| {
                mem.copy(T, row[0..], slice[i][0..]);
            }
        }

        //pub fn fromVecArray(vec: Self) Self {
        //return Self{
        //.data = vec.data,
        //};
        //}
    };
}

const testing = std.testing;
test "MatArray" {
    const M = MatArray(u8, 2, 3);
    testing.expect(M.DataT == u8);
    testing.expect(M.row_len == 2);
    testing.expect(M.col_len == 3);

    const N = MatArray(f32, 3, 5);
    testing.expect(N.DataT == f32);
    testing.expect(N.row_len == 3);
    testing.expect(N.col_len == 5);
}

test "MatArray new" {
    const M = MatArray(u8, 2, 3);
    var m = M.new();
    testing.expect(@TypeOf(m) == M);
    testing.expect(m.data.len == 2);
    testing.expect(m.data[0].len == 3);
    testing.expect(@TypeOf(m.data) == [2][3]u8);
}

test "VecArray setFromArrayOfArrays" {
    var m = MatArray(u8, 2, 3).new();
    m.setFromArrayOfArrays(.{
        .{ 1, 2, 3 },
        .{ 4, 5, 6 },
    });
    testing.expectEqual([2][3]u8{
        .{ 1, 2, 3 },
        .{ 4, 5, 6 },
    }, m.data);

    var n = MatArray(f32, 3, 3).new();
    n.setFromArrayOfArrays(.{
        .{ 1.0, 2.0, 3.0 },
        .{ 4.0, 5.0, 6.0 },
        .{ 7.0, 8.0, 9.0 },
    });
    testing.expectEqual([3][3]f32{
        .{ 1.0, 2.0, 3.0 },
        .{ 4.0, 5.0, 6.0 },
        .{ 7.0, 8.0, 9.0 },
    }, n.data);
}

test "VecArray setFromSliceOfArrays" {
    var slice_of_arrays_1 = try testing.allocator.alloc([3]u8, 3);
    defer testing.allocator.free(slice_of_arrays_1);
    slice_of_arrays_1[0] = [3]u8{ 1, 2, 3 };
    slice_of_arrays_1[1] = [3]u8{ 4, 5, 6 };
    slice_of_arrays_1[2] = [3]u8{ 7, 8, 9 };

    var m = MatArray(u8, 3, 3).new();
    m.setFromSliceOfArrays(slice_of_arrays_1);
    testing.expectEqual([3][3]u8{
        .{ 1, 2, 3 },
        .{ 4, 5, 6 },
        .{ 7, 8, 9 },
    }, m.data);

    var slice_of_arrays_2 = try testing.allocator.alloc([3]u8, 3);
    slice_of_arrays_2[0] = [3]u8{ 9, 8, 7 };
    slice_of_arrays_2[1] = [3]u8{ 6, 5, 4 };
    slice_of_arrays_2[2] = [3]u8{ 3, 2, 1 };

    var n = MatArray(u8, 3, 3).new();
    n.setFromSliceOfArrays(slice_of_arrays_2);
    testing.expectEqual([3][3]u8{
        .{ 9, 8, 7 },
        .{ 6, 5, 4 },
        .{ 3, 2, 1 },
    }, n.data);

    slice_of_arrays_2[0] = [3]u8{ 1, 2, 3 };
    slice_of_arrays_2[1] = [3]u8{ 4, 5, 6 };
    slice_of_arrays_2[2] = [3]u8{ 7, 8, 9 };
    testing.expectEqual([3][3]u8{
        .{ 9, 8, 7 },
        .{ 6, 5, 4 },
        .{ 3, 2, 1 },
    }, n.data);

    testing.allocator.free(slice_of_arrays_2);
    testing.expectEqual([3][3]u8{
        .{ 9, 8, 7 },
        .{ 6, 5, 4 },
        .{ 3, 2, 1 },
    }, n.data);
}

test "VecArray setFromSliceOfSlices" {
    var slice_of_slices_1 = try testing.allocator.alloc([]u8, 3);
    defer testing.allocator.free(slice_of_slices_1);
    var array_1 = [3]u8{ 1, 2, 3 };
    var array_2 = [3]u8{ 4, 5, 6 };
    var array_3 = [3]u8{ 7, 8, 9 };
    slice_of_slices_1[0] = array_1[0..];
    slice_of_slices_1[1] = array_2[0..];
    slice_of_slices_1[2] = array_3[0..];

    var m = MatArray(u8, 3, 3).new();
    m.setFromSliceOfSlices(slice_of_slices_1);
    testing.expectEqual([3][3]u8{
        .{ 1, 2, 3 },
        .{ 4, 5, 6 },
        .{ 7, 8, 9 },
    }, m.data);

    //var slice_of_arrays_2 = try testing.allocator.alloc([3]u8, 3);
    //slice_of_arrays_2[0] = [3]u8{ 9, 8, 7 };
    //slice_of_arrays_2[1] = [3]u8{ 6, 5, 4 };
    //slice_of_arrays_2[2] = [3]u8{ 3, 2, 1 };

    //var n = MatArray(u8, 3, 3).new();
    //n.setFromSliceOfArrays(slice_of_arrays_2);
    //testing.expectEqual([3][3]u8{
    //.{ 9, 8, 7 },
    //.{ 6, 5, 4 },
    //.{ 3, 2, 1 },
    //}, n.data);

    //slice_of_arrays_2[0] = [3]u8{ 1, 2, 3 };
    //slice_of_arrays_2[1] = [3]u8{ 4, 5, 6 };
    //slice_of_arrays_2[2] = [3]u8{ 7, 8, 9 };
    //testing.expectEqual([3][3]u8{
    //.{ 9, 8, 7 },
    //.{ 6, 5, 4 },
    //.{ 3, 2, 1 },
    //}, n.data);

    //testing.allocator.free(slice_of_arrays_2);
    //testing.expectEqual([3][3]u8{
    //.{ 9, 8, 7 },
    //.{ 6, 5, 4 },
    //.{ 3, 2, 1 },
    //}, n.data);
}

//test "VecArray fromVecArray" {
//const V = VecArray(u8, 2);
//var v1 = V.fromArray(.{ 0, 1 });
//var v2 = V.fromVecArray(v1);
//testing.expectEqual(v1, v2);

//const W = VecArray(f32, 3);
//var w1 = W.fromArray(.{ -1.0, 1.5, 3.5 });
//var w2 = W.fromVecArray(w1);
//testing.expectEqual(w1, w2);
//}
