# Combat Lab Spell System

## Available Spell Assets

### Fire Spells 🔥
| Asset File | Spell Name | Description |
|------------|------------|-------------|
| Fire_Explosion_28x28.png | **Fireball** | Classic explosive fireball |
| Fire_Explosion_ISOMETRIC_28x28.png | **Inferno Burst** | Isometric explosion effect |
| Large_Fire_28x28.png | **Flame Wave** | Sustained fire effect |
| Fire_Explosion_Anti-Alias_glow.png | **Meteor Strike** | Large glowing explosion |
| Large_Fire_Anti-Alias_glow_28x28.png | **Hellfire** | Intense burning effect |
| Wizard-Attack01_Effect.png | **Arcane Fire** | Wizard's fire attack |

### Lightning Spells ⚡
| Asset File | Spell Name | Description |
|------------|------------|-------------|
| Lightning_Blast_54x18.png | **Lightning Bolt** | Fast piercing lightning |
| Lightning_Energy_48x48.png | **Static Orb** | Ball lightning effect |
| Red_Lightning_Blast_54x18.png | **Blood Lightning** | Crimson lightning strike |
| Red_Energy_48x48.png | **Crimson Spark** | Red energy ball |
| Lightning_Energy_Anti-Alias_glow_48x48.png | **Storm Orb** | Glowing lightning sphere |
| Lightning_Blast_Anti-Alias_glow_54x18.png | **Thunder Strike** | Intense lightning blast |

### Ice Spells ❄️
| Asset File | Spell Name | Description |
|------------|------------|-------------|
| Ice-Burst_crystal_48x48.png | **Frost Shard** | Crystal ice projectile |
| Ice-Burst_crystal_48x48_Anti-Alias_glow.png | **Glacial Spike** | Glowing ice crystal |
| Ice-Burst_dark-blue_outline_48x48.png | **Deep Freeze** | Dark ice effect |
| Ice-Burst_light-grey_outline_48x48.png | **Hoarfrost** | Pale ice shard |
| Ice-Burst_transparent-blue_outline_48x48.png | **Cryo Blast** | Translucent ice |
| Ice-Burst_no_outline_48x48.png | **Pure Ice** | Clean ice projectile |

### Arcane/Holy Spells ✨
| Asset File | Spell Name | Description |
|------------|------------|-------------|
| Elemental_Spellcasting_Effects_v1_Anti_Alias_glow_8x8.png | **Mana Dart** | Basic magic missile |
| Elemental_Spellcasting_Effects_v2_8x8.png | **Mystic Bolt** | Enhanced magic projectile |
| Extra_Elemental_Spellcasting_Effects_14x14.png | **Eldritch Blast** | Powerful arcane energy |
| Extra_Elemental_Spellcasting_Effects_Anti-Alias_glow_14x14.png | **Void Sphere** | Dark magic orb |
| Red_Energy_48x48.png | **Blood Magic** | Life force projectile |
| Red_Energy_Anti-Alias_glow_48x48.png | **Soul Drain** | Vampiric energy |

### Priest/Holy Spells 🙏
| Asset File | Spell Name | Description |
|------------|------------|-------------|
| Priest-Attack_Effect.png | **Smite** | Divine damage attack |
| Priest-Heal_Effect.png | **Holy Light** | Healing projectile (future) |
| Wizard-Attack02_Effect.png | **Blessed Bolt** | Sanctified magic |

### Weapon-Enhanced Spells 🗡️
| Asset File | Spell Name | Description |
|------------|------------|-------------|
| Staff_Attack_Effect_1.png | **Staff Blast** | Basic staff projectile |
| Slash_Attack_Effect_1.png | **Arcane Slash** | Magic-enhanced melee |

## Spell Schools

### Hybrid Mage System 🎭
Each mage has a **primary** and **secondary** spell school. They alternate between them every 3 attacks, creating interesting visual variety!

**Example:** A Fire+Arcane mage casts:
1. Fireball (fire)
2. Flame Wave (fire)
3. Inferno Burst (fire)
4. **Mana Dart** (arcane) ← switches
5. Mystic Bolt (arcane)
6. Eldritch Blast (arcane)
7. **Fireball** (fire) ← switches back

### Pyromancy (Fire Mages) 🔥
**Primary Fire Mages:**
| Mage | Secondary | Combination |
|------|-----------|-------------|
| **Mage** | Arcane | Fire + Void magic |
| **FireSkull** | Arcane | Inferno + Dark energy |
| **DragonGreen** | - | Pure fire (AoE only) |

**Fire Spells:**
1. **Fireball** - Classic explosive projectile
2. **Flame Wave** - Sustained burning damage
3. **Inferno Burst** - Wide area explosion
4. **Meteor Strike** - Heavy single-target damage
5. **Hellfire** - DoT (damage over time) effect
6. **Arcane Fire** - Wizard's purple flame

### Electromancy (Storm Mages) ⚡
**Primary Lightning Mages:**
| Mage | Secondary | Combination |
|------|-----------|-------------|
| **MageHoodedBrown** | Fireball | Storm + Fire = Plasma |

**Lightning Spells:**
1. **Lightning Bolt** - Fast, piercing damage
2. **Static Orb** - Charged ball lightning
3. **Thunder Strike** - Stunning heavy hit
4. **Blood Lightning** - Life-stealing lightning
5. **Crimson Spark** - Rapid-fire red sparks
6. **Storm Orb** - Chained lightning effect

### Cryomancy (Ice Mages) ❄️
**Primary Ice Mages:**
| Mage | Secondary | Combination |
|------|-----------|-------------|
| **MageMascDKGrey** | Lightning | Ice + Storm = Blizzard |

**Ice Spells:**
1. **Frost Shard** - Basic ice projectile
2. **Glacial Spike** - Armor-piercing ice
3. **Deep Freeze** - Slowing effect
4. **Hoarfrost** - Rapid ice shards
5. **Cryo Blast** - Explosive freezing
6. **Pure Ice** - Clean penetrating shot

### Arcanum (Void Magic) 🌌
**Primary Arcane Mages:**
| Mage | Secondary | Combination |
|------|-----------|-------------|
| **Wraith** | Ice | Void + Frost |

**Arcane Spells:**
1. **Mana Dart** - Basic magic missile
2. **Mystic Bolt** - Enhanced arcane shot
3. **Eldritch Blast** - Heavy arcane damage
4. **Void Sphere** - Dark matter projectile
5. **Blood Magic** - Health-cost high damage
6. **Staff Blast** - Weapon-enhanced magic

## Spell Properties

### Damage Multipliers
| Spell Type | Base Multiplier | Notes |
|------------|-----------------|-------|
| Fireball | 1.0x | Standard damage |
| Flame Wave | 0.8x | Slower, more sustained |
| Meteor Strike | 1.3x | Heavy single target |
| Hellfire | 1.2x | High damage, slower |
| Lightning Bolt | 1.1x | Fast projectile |
| Thunder Strike | 1.25x | Highest lightning damage |
| Glacial Spike | 1.15x | Armor piercing |
| Eldritch Blast | 1.2x | Heavy arcane |
| Void Sphere | 1.3x | Slow but powerful |
| Blood Magic | 1.15x | Risk vs reward |

### Speed Variations
| Spell Type | Speed Multiplier |
|------------|------------------|
| Lightning Bolt | 1.3x (fastest) |
| Crimson Spark | 1.4x (rapid fire) |
| Mana Dart | 1.2x |
| Hoarfrost | 1.2x |
| Pure Ice | 1.15x |
| Fireball | 1.0x (standard) |
| Hellfire | 0.8x (slow) |
| Cryo Blast | 0.85x |
| Void Sphere | 0.85x |
| Meteor Strike | 0.85x (heavy) |

## Mage Roster

### Currently Implemented
| Unit | Primary | Secondary | Role |
|------|---------|-----------|------|
| **Mage** | Fireball | Arcane | Battle mage |
| **MageHoodedBrown** | Lightning | Fireball | Storm caller |
| **MageMascDKGrey** | Ice | Lightning | Frost mage |
| **FireSkull** | Fire | Arcane | Death mage |
| **Wraith** | Arcane | Ice | Void walker |
| **DragonGreen** | Fireball | - | Boss (AoE only) |

## Future Enhancements
- [ ] Spell cooldowns per type
- [ ] Mana system for mages
- [ ] Spell combos (fire + lightning = plasma burst)
- [ ] Environmental interactions (fire + water = steam)
- [ ] Spell mastery levels
- [ ] Priest class with holy magic
- [ ] Buff/debuff spells
