const std = @import("std");
const rt = @import("rt.zig");
const hittable = @import("hittable.zig");
const utils = @import("utils.zig");
const vec = @import("vec.zig");

const Ray = @import("Ray.zig");
const HitRecord = hittable.HitRecord;
const RamdonGen = rt.RandomGen;
const Vec3 = rt.Vec3;
const Color = rt.Color;
const Float = rt.Float;

const v3 = rt.v3;

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
            .dielectric => |d| d.scatter(ray_in, rec, rng),
        };
    }

    pub fn lambertian(albedo: Color) Self {
        return .{ .lambertian = Lambertian.init(albedo) };
    }

    pub fn metal(albedo: Color, fuzz: Float) Self {
        return .{ .metal = Metal.init(albedo, fuzz) };
    }

    pub fn dielectric(ir: Float) Self {
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
    fuzz: Float,

    const Self = @This();

    pub fn init(albedo: Color, fuzz: Float) Self {
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
    ir: Float,

    const Self = @This();

    pub fn init(index_of_refraction: Float) Self {
        return .{
            .ir = index_of_refraction,
        };
    }

    pub fn scatter(self: *const Self, ray_in: *const Ray, rec: *const HitRecord, rng: *RamdonGen) ?Scatter {
        const refraction_ratio = if (rec.front_face) (1.0 / self.ir) else self.ir;

        const unit_direction = vec.unit(ray_in.direction);

        const cos_theta = @min(vec.dot(-unit_direction, rec.normal), 1.0);
        const sin_theta = @sqrt(1.0 - cos_theta * cos_theta);

        const cannot_refract = sin_theta * refraction_ratio > 1.0;

        const direction = if (cannot_refract or reflectance(cos_theta, refraction_ratio) > utils.getRandom(rng, Float))
            reflect(unit_direction, rec.normal)
        else
            refract(unit_direction, rec.normal, refraction_ratio);

        const scattered = Ray.init(rec.point, direction);

        return .{
            .attenuation = Color{ 1.0, 1.0, 1.0 },
            .scattered = scattered,
        };
    }
};

fn nearZero(v: Vec3) bool {
    const e: Float = 1.0e-8;
    return @fabs(v[0]) < e and @fabs(v[1]) < e and @fabs(v[2]) < e;
}

fn reflect(v: Vec3, n: Vec3) Vec3 {
    return v - v3(2.0 * vec.dot(v, n)) * n;
}

fn refract(v: Vec3, n: Vec3, etai_over_etat: Float) Vec3 {
    const cos_theta = @min(vec.dot(-v, n), 1.0);
    const perp = v3(etai_over_etat) * (v + v3(cos_theta) * n);
    const parallel = v3(-@sqrt(@fabs(1.0 - vec.dot(perp, perp)))) * n;
    return perp + parallel;
}

fn reflectance(cosine: Float, ref_idx: Float) Float {
    // use Schlick's approximation for reflectance
    var r0 = (1.0 - ref_idx) / (1.0 + ref_idx);
    r0 = r0 * r0;
    return r0 + (1.0 - r0) * std.math.pow(Float, (1.0 - cosine), 5.0);
}
