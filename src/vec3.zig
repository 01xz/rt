const std = @import("std");

pub fn Vec3(comptime T: type) type {
    return struct {
        data: @Vector(3, T),

        const Self = @This();

        pub fn x(self: *const Self) T {
            return self.data[0];
        }

        pub fn y(self: *const Self) T {
            return self.data[1];
        }

        pub fn z(self: *const Self) T {
            return self.data[2];
        }

        pub fn init(data: [3]T) Self {
            return .{
                .data = data,
            };
        }

        pub fn fill(data: T) Self {
            return .{
                .data = @splat(data),
            };
        }

        pub fn add(self: *const Self, n: T) Self {
            return self.vadd(&Self.fill(n));
        }

        pub fn sub(self: *const Self, n: T) Self {
            return self.vsub(&Self.fill(n));
        }

        pub fn mul(self: *const Self, n: T) Self {
            return self.vmul(&Self.fill(n));
        }

        pub fn div(self: *const Self, n: T) Self {
            return self.vdiv(&Self.fill(n));
        }

        pub fn vadd(self: *const Self, other: *const Self) Self {
            return .{
                .data = self.data + other.data,
            };
        }

        pub fn vsub(self: *const Self, other: *const Self) Self {
            return .{
                .data = self.data - other.data,
            };
        }

        pub fn vmul(self: *const Self, other: *const Self) Self {
            return .{
                .data = self.data * other.data,
            };
        }

        pub fn vdiv(self: *const Self, other: *const Self) Self {
            return .{
                .data = self.data / other.data,
            };
        }

        pub fn len(self: *const Self) T {
            return @sqrt(@reduce(.Add, self.data * self.data));
        }

        pub fn unit(self: *const Self) Self {
            return .{
                .data = self.div(self.len()).data,
            };
        }

        pub fn dot(self: *const Self, other: *const Self) T {
            return @reduce(.Add, self.vmul(other).data);
        }

        pub fn cross(self: *const Self, other: *const Self) Self {
            return .{
                .data = @Vector(3, T){
                    self.data[1] * other.data[2] - self.data[2] * other.data[1],
                    self.data[2] * other.data[0] - self.data[0] * other.data[2],
                    self.data[0] * other.data[1] - self.data[1] * other.data[0],
                },
            };
        }
    };
}

test "Vec3 init" {
    const v1 = Vec3(f64).init(.{ 3.0, 4.0, 5.0 });
    try std.testing.expectEqual(v1.data, @Vector(3, f64){ 3.0, 4.0, 5.0 });
}

test "Vec3 fill" {
    const v1 = Vec3(f64).fill(3.0);
    try std.testing.expectEqual(v1.data, @Vector(3, f64){ 3.0, 3.0, 3.0 });
}

test "Vec3 op" {
    const v1 = Vec3(f64).fill(3.0);
    const v2 = Vec3(f64).fill(4.0);
    try std.testing.expectEqual(v1.add(4.0).data, @Vector(3, f64){ 7.0, 7.0, 7.0 });
    try std.testing.expectEqual(v1.sub(4.0).data, @Vector(3, f64){ -1.0, -1.0, -1.0 });
    try std.testing.expectEqual(v1.mul(4.0).data, @Vector(3, f64){ 12.0, 12.0, 12.0 });
    try std.testing.expectEqual(v1.div(4.0).data, @Vector(3, f64){ 0.75, 0.75, 0.75 });
    try std.testing.expectEqual(v1.vadd(&v2).data, @Vector(3, f64){ 7.0, 7.0, 7.0 });
    try std.testing.expectEqual(v1.vsub(&v2).data, @Vector(3, f64){ -1.0, -1.0, -1.0 });
    try std.testing.expectEqual(v1.vmul(&v2).data, @Vector(3, f64){ 12.0, 12.0, 12.0 });
    try std.testing.expectEqual(v1.vdiv(&v2).data, @Vector(3, f64){ 0.75, 0.75, 0.75 });
}

test "Vec3 len" {
    const v1 = Vec3(f64).init(.{ 3.0, 4.0, 5.0 });
    try std.testing.expectEqual(v1.len(), 7.0710678118654755);
}

test "Vec3 unit" {
    const v1 = Vec3(f64).init(.{ 1.0, 2.0, 3.0 });
    const l = @sqrt(14.0);
    try std.testing.expectEqual(v1.unit().data, @Vector(3, f64){ 1.0 / l, 2.0 / l, 3.0 / l });
}

test "Vec3 dot" {
    const v1 = Vec3(f64).init(.{ 1.0, 2.0, 3.0 });
    const v2 = Vec3(f64).init(.{ 1.0, 5.0, 7.0 });
    try std.testing.expectEqual(v1.dot(&v2), 32.0);
}

test "Vec3 cross" {
    const v1 = Vec3(f64).init(.{ 1.0, 2.0, 3.0 });
    const v2 = Vec3(f64).init(.{ 1.0, 5.0, 7.0 });
    try std.testing.expectEqual(v1.cross(&v2).data, @Vector(3, f64){ -1.0, -4.0, 3.0 });
}
