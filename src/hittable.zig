const std = @import("std");
const rt = @import("rt.zig");
const material = @import("material.zig");
const vec = @import("vec.zig");

const Ray = @import("Ray.zig");
const Interval = @import("Interval.zig");
const Material = material.Material;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Vec3 = rt.Vec3;
const Point = rt.Point;
const Float = rt.Float;

const v3 = rt.v3;

pub const HitRecord = struct {
    point: Point,
    normal: Vec3,
    t: Float,
    front_face: bool,
    mat: Material,
};

pub const Hittable = union(enum) {
    sphere: Sphere,

    const Self = @This();

    pub fn hit(self: Self, ray: *const Ray, ray_t: Interval) ?HitRecord {
        return switch (self) {
            .sphere => |s| s.hit(ray, ray_t),
        };
    }

    pub fn sphere(centor: Point, radius: Float, mat: Material) Self {
        return .{ .sphere = Sphere.init(centor, radius, mat) };
    }
};

pub const HittableList = struct {
    objects: ArrayList(Hittable),

    const Self = @This();

    pub fn init(allocator: Allocator) Self {
        return .{
            .objects = ArrayList(Hittable).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.objects.deinit();
    }

    pub fn add(self: *Self, object: Hittable) !void {
        try self.objects.append(object);
    }

    pub fn hit(self: *const Self, ray: *const Ray, ray_t: Interval) ?HitRecord {
        var hit_record: HitRecord = undefined;
        var hit_anything: bool = false;
        var closest_so_far: Float = ray_t.max;

        for (self.objects.items) |object| {
            if (object.hit(ray, Interval.init(ray_t.min, closest_so_far))) |rec| {
                hit_anything = true;
                closest_so_far = rec.t;
                hit_record = rec;
            }
        }

        return if (hit_anything)
            hit_record
        else
            null;
    }
};

const Sphere = struct {
    centor: Point,
    radius: Float,
    mat: Material,

    const Self = @This();

    pub fn init(centor: Point, radius: Float, mat: Material) Self {
        return .{
            .centor = centor,
            .radius = radius,
            .mat = mat,
        };
    }

    pub fn hit(self: *const Self, ray: *const Ray, ray_t: Interval) ?HitRecord {
        const oc = ray.origin - self.centor;

        const a = vec.dot(ray.direction, ray.direction);
        const hb = vec.dot(oc, ray.direction);
        const c = vec.dot(oc, oc) - (self.radius * self.radius);

        const d = hb * hb - a * c;

        if (d < 0.0) return null;

        const sqrtd = @sqrt(d);

        var root = (-hb - sqrtd) / a;

        // find the nearest root that lies in the acceptable range: (ray_t.min, ray_t.max)
        if (!ray_t.surrounds(root)) {
            root = (-hb + sqrtd) / a;
            if (!ray_t.surrounds(root)) {
                return null;
            }
        }

        const rec_t = root;
        const rec_point = ray.at(root);

        const outward_normal = (rec_point - self.centor) / v3(self.radius);

        const rec_front_face = vec.dot(outward_normal, ray.direction) < 0.0;

        // always point against the incident ray
        const rec_normal = if (rec_front_face) outward_normal else -outward_normal;

        return .{
            .point = rec_point,
            .normal = rec_normal,
            .t = rec_t,
            .front_face = rec_front_face,
            .mat = self.mat,
        };
    }
};
