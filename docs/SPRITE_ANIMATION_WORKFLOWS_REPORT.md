# Godot 4.6 Sprite Animation Workflows: Executive Summary

## Dominant Workflow (80% of solo devs)

```
Aseprite → Aseprite Wizard Plugin → AnimatedSprite2D
```

## Key Tools

| Tool | Cost | Use Case |
|------|------|----------|
| **Aseprite** | $20 | Pixel art animation (industry standard) |
| **Aseprite Wizard** | Free | Godot import automation |
| **Spine** | $69-$369 | Professional skeletal 2D |
| **DragonBones** | Free | Deprecated (2022) |
| **Godot Skeleton2D** | Free | Limited, not production-ready |

## Recommendation for Jewelflame

**Aseprite + AnimatedSprite2D** is optimal because:
- Pixel art aesthetic
- 50v50 performance requirements met
- Fast iteration (30 seconds vs 30 minutes per sprite)

## Naming Conventions

```
idle_up, idle_down, idle_left, idle_right
walk_up, walk_down, walk_left, walk_right
attack_up, attack_down, attack_left, attack_right
hurt_up, hurt_down, hurt_left, hurt_right
die_up, die_down, die_left, die_right
```

## Frame Count Consistency

All directions must have identical frame counts:
- walk_up: 8 frames ✓
- walk_down: 8 frames ✓
- walk_left: 6 frames ✗ (MISMATCH!)

## FPS Guidelines

| Animation | FPS |
|-----------|-----|
| Idle | 4-6 |
| Walk | 8-12 |
| Run | 12-16 |
| Attack | 12-20 |
| Hurt | 8-12 |
| Die | 8-10 |
