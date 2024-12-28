const rl = @cImport(@cInclude("raylib.h"));
const std = @import("std");
const Assets = @import("assets.zig");
const m = @import("math.zig");
const conf = @import("config.zig");
const utils = @import("utils.zig");
const inventory = @import("inventory.zig");
const AnimationPlayer = Assets.AnimationPlayer;
const Animation = Assets.Animation;
const Vec2 = m.Vec2;
const Vec2i = m.Vec2i;
const Buff = comp.BuffHolder.Buff;





var annoucement: [:0]const u8 = "";
var annouce_t: f32 = 0;
fn Annouce(s: [:0]const u8, duration: f32) void {
    annoucement = s;
    annouce_t = duration;
}




pub var a: std.mem.Allocator = undefined;
pub var arena: std.mem.Allocator = undefined;
pub var dt: f32 = 0;
var et: f64 = 0;

// var item_water = Item{ .tex = &Assets.Texs.weapon_1 };

const esc = @import("esc_engine.zig");
const system = @import("system.zig");
const comp = @import("componet.zig");
const Entity = esc.Entity;
const syss = &system.syss;
fn spawn_player(e: Entity) void {
    const size = 0.08;
    syss.add_comp(e, comp.Pos {.roundabout = true});
    syss.add_comp(e, comp.Vel {
        .drag = 2,
        .rot_drag = 5,
    });
    syss.add_comp(e, comp.View { 
        .tex = &Assets.Texs.fighter, 
        .size = m.splat(size*2)
    });
    syss.add_comp(e, comp.ShipControl {
        .thurst = 3.5,
        .turn_thurst = 25,
        .thurst_anim = Assets.AnimationPlayer {.anim = &Assets.Anims.thrust, .loop = true},
    });
    syss.add_comp(e, comp.Input {});
    syss.add_comp(e, comp.WeaponHolder.init(a));
    syss.add_comp(e, comp.Size {.size = size * 2});
    syss.add_comp(e, comp.Mass {.mass = size * size});
    syss.add_comp(e, comp.Health {.hp = 100, .max = 100, .regen = 1});
    syss.add_comp(e, comp.DeadAnimation {.dead = &Assets.Anims.explode_blue, .dead_size = null});
    // var weapon_comp = comp.Weapon {
    //     .fire_rate = 5, 
    //     .sound = &Assets.Sounds.shoot, 
    //     .bullet = .{ .dmg = 30, .sound = &Assets.Sounds.bullet_hit, .tex = &Assets.Texs.bullet, .size = 0.10, },
    //     .effects = comp.Weapon.ShootEffects.init(a),
    // };
    // const power_shot = struct {
    //     pub fn shoot(
    //         weapon: *comp.Weapon, effect: *comp.Weapon.ShootEffect, 
    //         vel: comp.Vel, pos: comp.Pos, team: comp.Team,
    //         idx: isize) void 
    //     {
    //         effect.data.counter = (effect.data.counter + 1) % 3;
    //         const prev = weapon.get_effect(idx - 1) orelse return;
    //         const bullet = weapon.bullet;
    //         if (effect.data.counter == 0) {
    //             weapon.bullet.size *= 3;
    //             weapon.bullet.dmg *= 3;
    //             weapon.bullet.penetrate = 5;
    //         }
    //         prev.shoot_fn(weapon, prev, vel, pos, team, idx - 1);
    //         weapon.bullet = bullet;
    //     }
    // };
    // weapon_comp.effects.append(comp.Weapon.ShootEffect {.data = .{.counter = 0}, .shoot_fn = power_shot.shoot}) catch unreachable;
    // syss.add_comp(e, weapon_comp);
    syss.add_comp(e, comp.CollisionSet1{});
    syss.add_comp(e, comp.Team.friendly);
    syss.add_comp(e, comp.Collector {.attract_radius = 0.2, .collect_radius = 0.05});
    syss.add_comp(e, comp.Exp {.next_lvl = 50});
    syss.add_comp(e, comp.BuffHolder.init(a));
}
fn spawn_hunter() Entity {
    const e: Entity = syss.new_entity();
    const size = 0.08;
    syss.add_comp(e, comp.Pos {.roundabout = false});
    syss.add_comp(e, comp.Vel {
        .drag = 2,
        .rot_drag = 8,
    });
    syss.add_comp(e, comp.View { 
        .tex = &Assets.Texs.hunter, 
        .size = m.splat(size*2)
    });
    syss.add_comp(e, comp.ShipControl {
        .thurst = 1.5,
        .turn_thurst = 12,
    });
    syss.add_comp(e, comp.Size {.size = size * 2});
    syss.add_comp(e, comp.Mass {.mass = size * size});
    syss.add_comp(e, comp.Health {.hp = 100, .max = 100, });
    syss.add_comp(e, comp.DeadAnimation { .dead = &Assets.Anims.explode_blue});
    var weapon_comp = comp.Weapon {
        .cool_down = 2,
        .fire_rate = 0.5, 
        .bullet_spd = 1,
        .sound = &Assets.Sounds.shoot, 
        .bullet = .{.dmg = 35, .sound = &Assets.Sounds.bullet_hit, .size = 0.1, .tex = &Assets.Texs.bullet_fire},
        .effects = comp.Weapon.ShootEffects.init(a),
    };
    const triple_shot = struct {
        pub fn shoot(
            weapon: *comp.Weapon, effect: *comp.Weapon.ShootEffect, 
            vel: comp.Vel, pos: comp.Pos, team: comp.Team,
            idx: isize) void 
        {
            _ = effect;
            const prev = weapon.get_effect(idx - 1) orelse return;
            var pos2 = pos;
            var vel2 = vel;
            prev.shoot_fn(weapon, prev, vel, pos, team, idx - 1);

            vel2.vel = m.v2rot(vel.vel, rl.PI / 12);
            pos2.rot = pos.rot + rl.PI / 12;
            prev.shoot_fn(weapon, prev, vel2, pos2, team, idx - 1);

            vel2.vel = m.v2rot(vel.vel, -rl.PI / 12);
            pos2.rot = pos.rot  - rl.PI / 12;
            prev.shoot_fn(weapon, prev, vel2, pos2, team, idx - 1);
        }
    };
     weapon_comp.effects.put(comp.Weapon.ShootEffect {.shoot_fn = triple_shot.shoot, .data = undefined}, void{}) catch unreachable;
    syss.add_comp(e, weapon_comp);
    syss.add_comp(e, comp.Ai {.state = .{ .hunter = .{}}});
    syss.add_comp(e, comp.CollisionSet1{});
    syss.add_comp(e, comp.Team.enemey);
    syss.add_comp(e, comp.GemDropper {.value = 50});
    return e;
}
fn spawn_crasher() Entity {
    const e: Entity = syss.new_entity();
    const size = 0.08;
    syss.add_comp(e, comp.Pos {.roundabout = false});
    syss.add_comp(e, comp.Vel {
        .drag = 2,
        .rot_drag = 5,
    });
    syss.add_comp(e, comp.View { 
        .tex = &Assets.Texs.crasher, 
        .size = m.splat(size*2)
    });
    syss.add_comp(e, comp.ShipControl {
        .thurst = 2,
        .turn_thurst = 20,
        .state = .{.dash_cd = 5},
    });
    syss.add_comp(e, comp.Size {.size = size * 2});
    syss.add_comp(e, comp.Mass {.mass = size * size});
    syss.add_comp(e, comp.Health {.hp = 75, .max = 75, });
    syss.add_comp(e, comp.DeadAnimation { .dead = &Assets.Anims.explode_blue});
    // syss.add_comp(e, comp.Weapon {
    //     .fire_rate = 0.5, 
    //     .bullet_spd = 2,
    //     .sound = &Assets.Sounds.shoot, 
    //     .bullet = .{.dmg = 35, .sound = &Assets.Sounds.bullet_hit, .size = 0.1, .tex = &Assets.Texs.bullet_fire}
    // });
    syss.add_comp(e, comp.Ai {.state = .{ .crasher = .{}}});
    syss.add_comp(e, comp.CollisionSet1{});
    syss.add_comp(e, comp.Team.enemey);
    syss.add_comp(e, comp.GemDropper {.value = 40});
    return e;
}
pub fn spawn_asteriod() Entity {
    const e: Entity = syss.new_entity();
    const target = Vec2{ m.randf(-0.75, 0.75), m.randf(-0.75, 0.75) };
    const pos = Vec2 { m.randSign() * m.randf(1.1, 1.5), m.randSign() * m.randf(1.1, 1.5) };
    const size = m.randf(0.02, 0.15);
    syss.add_comp(e, comp.Pos {
        .pos = pos,
        .rot = 0,
    });
    syss.add_comp(e, comp.Vel {
        .vel = m.v2n(target - pos) * m.splat(m.randf(0.05, 0.3)),
        .rot = m.randf(-0.005, 0.005),
        .drag = 0.01,
        .rot_drag = 1,
    });
    var ap = AnimationPlayer{ .anim = &Assets.Anims.asteroid };
    // std.log.debug("frame {} {}", .{ap.curr_frame, ap.anim.frames.items.len});
    syss.add_comp(e, comp.View {.tex = @constCast(ap.play(0) orelse unreachable), .size = m.splat(size*2)});
    syss.add_comp(e, comp.Size {.size = size*2});
    syss.add_comp(e, comp.Mass {.mass = size * size * 3});
    syss.add_comp(e, comp.Health {.hp = 100, .max = 100, });
    syss.add_comp(e, comp.DeadAnimation {.dead = ap.anim, .dead_size = m.splat(size*2)});
    syss.add_comp(e, comp.CollisionSet1{});
    syss.add_comp(e, comp.Team.neutral);

    return e;

}
pub var player: Entity = undefined;
pub fn draw_hud() void {
    // const healthbar_pos = Vec
    const len = 1.5;
    const hei = 0.005;
    const hp_color = rl.RED;
    const hp_bg_color = rl.Color{ .r = 100, .g = 50, .b = 50, .a = 255 };
    const hp_pos = Vec2{ 0, 0.9 };

    {

        const default = comp.Health {.hp = 0, .max = 100};
        const hp_comp = syss.comp_man.get_comp(comp.Health, player) orelse &default;
        const perc = (hp_comp.hp / hp_comp.max);

        // rl.DrawRectangleV(m.coordn2srl(hp_pos), m.sizen2srl(.{0.2, 0.2}), rl.RED);
        utils.DrawRectCentered(hp_pos, .{ len, hei }, hp_bg_color);
        utils.DrawRectCentered(hp_pos - Vec2{ len * (1 - perc) / 2, 0 }, .{ len * perc, hei }, hp_color);
    }

    const gem_color = rl.GREEN;
    const gem_bg_color = rl.Color{ .r = 50, .g = 100, .b = 50, .a = 255 };
    const gem_pos = Vec2{ 0, 0.85 };
    {
        const default = comp.Exp {.curr_exp = 0, .next_lvl = 100};
        const gem_comp = syss.comp_man.get_comp(comp.Exp, player) orelse &default;

        const perc = (@as(f32, @floatFromInt(gem_comp.curr_exp)) / @as(f32, @floatFromInt(gem_comp.next_lvl)));
        utils.DrawRectCentered(gem_pos, .{ len, hei }, gem_bg_color);
        utils.DrawRectCentered(gem_pos - Vec2{ len * (1 - perc) / 2, 0 }, .{ len * perc, hei }, gem_color);
    }

    // const mana_color = rl.BLUE;
    // const mana_bg_color = rl.Color{ .r = 50, .g = 50, .b = 100, .a = 255 };
    // const mana_pos = Vec2{ 0, 0.86 };
    // const mana_len = 0.7;
    // const mana_hei = 0.002;
    // {
    //     const perc = player.mana / player.max_mana;
    //     DrawRectCentered(mana_pos, .{ mana_len, mana_hei }, mana_bg_color);
    //     DrawRectCentered(mana_pos - Vec2{ mana_len * (1 - perc) / 2, 0 }, .{ mana_len * perc, mana_hei }, mana_color);
    // }
    if (annouce_t > 0) {
        annouce_t -= dt;
        const tw = rl.MeasureText(annoucement, 25);
        rl.DrawText(annoucement, @divFloor(-tw + conf.screenw, 2), 50, 25, rl.LIGHTGRAY);
    }
}
var pause = false;
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    a = gpa.allocator();

    syss.* = system.Manager.init(a);
    defer syss.deinit();

    player = syss.new_entity();
    var movement = system.Movement {};
    var view = system.View {};
    var ship_control = system.ShipControl {};
    var input = system.Input {};
    var ai = system.ShipAi {.player = &player};
    var collision = system.Collision(comp.CollisionSet1) {};
    var elastic = system.Elastic {};
    var health = system.Health {};
    var anim = system.Animation {};
    var weapon = system.Weapon {};
    var bullet = system.Bullet {};
    var dead = system.Dead {.player_e = &player};
    var dead_anim = system.DeadAnimation {};
    var gem_dropper = system.GemDropper {};
    var collect = system.Collector {};
    var buff = system.Buff {};


    syss.register(system.get(&input, a));
    syss.register(system.get(&ai, a));
    syss.register(system.get(&ship_control, a));
    syss.register(system.get(&movement, a));

    syss.register(system.get(&view, a));
    syss.register(system.get(&anim, a));

    syss.register(system.get(&buff, a));

    syss.register(system.get(&weapon, a));
    syss.register(system.get(&collision, a));
    syss.register(system.get(&collect, a));
    syss.register(system.get(&elastic, a));
    syss.register(system.get(&health, a));
    syss.register(system.get(&bullet, a));
    syss.register(system.get(&dead_anim, a));
    syss.register(system.get(&gem_dropper, a));
    syss.register(system.get(&dead, a));
    spawn_player(player);


    var invent = inventory.init(a);
    defer invent.deinit();

    invent.append_item(inventory.Item.basic_gun());
    invent.append_item(inventory.Item.basic_gun());
    invent.append_item(inventory.Item.triple_shot());

    m.randGen = std.Random.DefaultPrng.init(@intCast(std.time.microTimestamp()));
    rl.InitWindow(conf.screenw, conf.screenh, "Deep Space Rouge");
    rl.SetTargetFPS(144);
    rl.SetTraceLogLevel(rl.LOG_ERROR);
    defer rl.CloseWindow();

    Assets.load();
    defer Assets.unload();

    Annouce("GAME START!", 5);
    while (!rl.WindowShouldClose()) {
        var aa = std.heap.ArenaAllocator.init(a);
        defer aa.deinit();
        defer syss.clear_events();
        arena = aa.allocator();
        dt = rl.GetFrameTime();
        et = rl.GetTime();

        // std.log.debug("t: {}", .{t});
        rl.BeginDrawing();
        {
            // rl.ClearBackground(rl.RED);
            //
            if (rl.IsKeyPressed(rl.KEY_I)) {
                pause = !pause;

            }
            if (pause) {
                dt = 0;
            }
            const space_tex = &Assets.Texs.space;
            rl.DrawTexturePro(space_tex.*, .{ .x = 0, .y = 0, .width = @floatFromInt(space_tex.width), .height = @floatFromInt(space_tex.height) }, .{ .x = 0, .y = 0, .width = conf.screenw, .height = conf.screenh }, .{ .x = 0, .y = 0 }, 0, .{ .r = 0x9f, .g = 0x9f, .b = 0x9f, .a = 0xff });
            if (rl.IsKeyPressed(rl.KEY_J)) {
                _ = spawn_asteriod();
            }
            if (rl.IsKeyPressed(rl.KEY_K)) {
                if (m.randGen.next() % 2 == 0)
                    _ = spawn_crasher()
                else
                    _ = spawn_hunter();
            }

            syss.update(dt);
            draw_hud();
            if (pause) {
                invent.draw();
            }
            // check for level up
            if (syss.comp_man.get_comp(comp.Exp, player)) |exp| {
                while (exp.curr_exp >= exp.next_lvl) {
                    exp.curr_exp -= exp.next_lvl;
                    exp.next_lvl += 50;
                    rl.PlaySound(Assets.Sounds.level_up);
                    Annouce("Level Up! (Open Inventory With [I])", 2);

                    var spd_buff = Buff.init_simple(comp.ShipControl, "thurst", 2.5, 5);
                    var fire_rate_buff = Buff.init_simple(comp.Weapon, "fire_rate", 1, 5);
                    system.Buff.try_apply(player, &spd_buff);
                    system.Buff.try_apply(player, &fire_rate_buff);
                }
            }
            if (dead.player_dead) {
                Annouce("You Died! Press [R] to restart", 1);
                if (rl.IsKeyPressed(rl.KEY_R)) {
                    syss.clear_all();
                    player = syss.new_entity();
                    Annouce("GAME START!", 5);
                    dead.player_dead = false;
                    spawn_player(player);
                    invent.cal_item();
                }
            }
            if (rl.IsKeyPressed(rl.KEY_M)) {
                const player_input = syss.comp_man.get_comp(comp.Input, player) orelse unreachable;
                player_input.mouse = !player_input.mouse;
            }
        }
        rl.EndDrawing();
    }
}
