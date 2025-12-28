# CatFusion - Mobile Idle Game

CatFusion is a mobile idle/evolution/fusion game built with Godot 4.5.1 for Android.

## Gameplay

- Cats generate "Tunca Cans" (currency) automatically over time
- New cats spawn periodically
- Tap two cats of the same level to fuse them into a higher level cat
- Higher level cats generate more currency and look more impressive
- Game progresses even when closed (idle mechanics)

## How to Play

1. **Wait for cats to spawn** - The first cat appears quickly, then spawning slows down
2. **Watch currency accumulate** - Each cat generates Tunca Cans over time
3. **Fuse cats** - Tap two cats of the same level to combine them into a higher level
4. **Progress** - Higher level cats are more valuable and visually impressive

## Controls

- **Tap a cat** - Select it for fusion (yellow highlight appears)
- **Tap another cat of same level** - Fuses the two cats into next level
- **Tap selected cat again** - Deselect it

## Features Implemented

✅ **Core Systems**
- Currency generation system
- Cat spawning with increasing intervals
- Fusion mechanics for evolution
- Save/Load with offline progression
- Mobile-optimized touch controls

✅ **Cat System**
- 10 cat levels with tier progression
- Behavior system (idle, walk, sit, meow)
- Visual scaling by tier
- Currency generation scaling by level

✅ **UI System**
- Currency display
- Spawn timer with progress bar
- Fusion feedback messages
- Mobile-friendly interface

✅ **Persistence**
- Automatic saving every 30 seconds
- Save on app close
- Offline earnings calculation
- Progress restoration on restart

## Technical Details

**Architecture:**
- Data-driven design with JSON config
- Autoload singletons for game state
- Resource-based save system
- Object pooling ready architecture

**Performance:**
- Mobile-optimized rendering
- Efficient update distribution
- Memory-conscious asset loading

**Platform:**
- Built for Android
- Touch-optimized controls
- Mobile performance considerations

## Art System

Currently using procedural colored rectangles as placeholders:
- **Orange** - Tabby cats
- **Gray** - Shorthair cats
- **Dark Gray** - Black cats
- **White** - Persian cats
- **Sandy Brown** - Calico cats

Cats scale up with tier progression and have simple behavioral animations.

## Future Expansion

The game is architected to easily support:
- Custom pixel art sprites
- More cat levels and tiers
- Additional behaviors and animations
- Room decorations and environments
- Meta-progression systems
- Audio and particle effects

## Development

**Required:**
- Godot 4.5.1
- Android SDK (for mobile builds)

**Project Structure:**
```
scripts/
├── autoload/          # Singleton managers
├── data/             # Resource classes
├── systems/          # Core game systems
└── ui/               # UI controllers

scenes/
├── cats/             # Cat scene
├── ui/               # UI scenes
└── main_game.tscn    # Main scene

data/
├── cats/             # Cat data resources
└── config/           # JSON configuration
```

The game is fully functional and ready to play! Run the project in Godot to start playing.