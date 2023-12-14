const std = @import("std");
const hittable = @import("hittable.zig");
const utils = @import("utils.zig");
const vec = @import("vec.zig");
const v3 = vec.v3;

const Ray = @import("Ray.zig");
const RamdonGen = utils.RandomGen;
const HitRecord = hittable.HitRecord;
const Vec3 = vec.Vec3;
const Color = Vec3(f64);

pub const Scatter = struct {
    attenuation: Color,
    scattered: Ray,
};

pub const Material = union(enum) {
    lambertian: Lambertian,
    metal: Metal,
    dielectric: Dielectric,

    const Self = @This();

    pub fn scatter(self: Self, ray_in: *const Ray, rec: *const HitRecord, rng: *RamdonGen) ?Scatter {
        return switch (self) {
            .lambertian => |l| l.scatter(rec, rng),
            .metal => |m| m.scatter(ray_in, rec, rng),
            .dielectric => |d| d.scatter(ray_in, rec),
        };
    }

    pub fn lambertian(albedo: Color) Self {
        return .{ .lambertian = Lambertian.init(albedo) };
    }

    pub fn metal(albedo: Color, fuzz: f64) Self {
        return .{ .metal = Metal.init(albedo, fuzz) };
    }

    pub fn dielectric(ir: f64) Self {
        return .{ .dielectric = Dielectric.init(ir) };
    }
};

const Lambertian = struct {
    albedo: Color,

    const Self = @This();

    pub fn init(albedo: Color) Self {
        return .{ .albedo = albedo };
    }

    pub fn scatter(self: *const Self, rec: *const HitRecord, rng: *RamdonGen) ?Scatter {
        const scatter_direction = blk: {
            const direction = rec.normal + utils.getRandomUnitVec3(rng);
            break :blk if (nearZero(direction)) rec.normal else direction;
        };
        const scattered = Ray.init(rec.*.point, scatter_direction);
        return .{
            .attenuation = self.albedo,
            .scattered = scattered,
        };
    }
};

const Metal = struct {
    albedo: Color,
    fuzz: f64,

    const Self = @This();

    pub fn init(albedo: Color, fuzz: f64) Self {
        return .{
            .albedo = albedo,
            .fuzz = if (fuzz < 1.0) fuzz else 1.0,
        };
    }

    pub fn scatter(self: *const Self, ray_in: *const Ray, rec: *const HitRecord, rng: *RamdonGen) ?Scatter {
        const reflected = reflect(vec.unit(ray_in.direction), rec.*.normal);
        const scattered = Ray.init(rec.*.point, reflected + v3(self.fuzz) * utils.getRandomUnitVec3(rng));
        return if (vec.dot(scattered.direction, rec.normal) > 0.0) .{
            .attenuation = self.albedo,
            .scattered = scattered,
        } else null;
    }
};

const Dielectric = struct {
    ir: f64,

    const Self = @This();

    pub fn init(index_of_refraction: f64) Self {
        return .{
            .ir = index_of_refraction,
        };
    }

    pub fn scatter(self: *const Self, ray_in: *const Ray, rec: *const HitRecord) ?Scatter {
        const refraction_ratio = if (rec.front_face) (1.0 / self.ir) else self.ir;
        const refracted = refract(vec.unit(ray_in.direction), rec.normal, refraction_ratio);
        const scattered = Ray.init(rec.point, refracted);
        return .{
            .attenuation = Color{ 1.0, 1.0, 1.0 },
            .scattered = scattered,
        };
    }
};

fn nearZero(v: Vec3(f64)) bool {
    const e: f64 = 1.0e-8;
    return @fabs(v[0]) < e and @fabs(v[1]) < e and @fabs(v[2]) < e;
}

fn reflect(v: Vec3(f64), n: Vec3(f64)) Vec3(f64) {
    return v - v3(2.0 * vec.dot(v, n)) * n;
}

fn refract(v: Vec3(f64), n: Vec3(f64), etai_over_etat: f64) Vec3(f64) {
    const cos_theta = @min(vec.dot(-v, n), 1.0);
    const perp = v3(etai_over_etat) * (v + v3(cos_theta) * n);
    const parallel = v3(-@sqrt(@fabs(1.0 - vec.dot(perp, perp)))) * n;
    return perp + parallel;
}
