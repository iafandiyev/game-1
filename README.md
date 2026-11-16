# LAST NIGHT

A 2D Survival Horror Zombie Apocalypse Game built with Godot 4.

## Overview

**LAST NIGHT** is a side-scrolling survival horror game where you play as Ethan Cole, a survivor trapped in a ruined city overrun by the undead. Search abandoned buildings, scavenge resources, craft equipment, fight or avoid zombies, and uncover the truth behind the viral outbreak.

### Features

- **5 Unique Zombie Types**: Walkers, Runners, Tanks, Screamers, and Crawlers with distinct AI behaviors
- **4 Weapons**: Pistol, Shotgun, Rifle, and Baseball Bat with realistic mechanics
- **Deep Survival System**: Hunger, thirst, stamina, health, and infection management
- **Day/Night Cycle**: Dynamic lighting, weather effects, and increased danger at night
- **5 Interconnected Locations**: City, Hospital, Supermarket, Metro, Military Base
- **15+ Story Missions** with multiple endings
- **Safehouse System**: Upgradeable base with storage, crafting, and defenses
- **Full Inventory & Crafting**: 20-slot inventory with 12 crafting recipes
- **Checkpoint & Save System**: Automatic and manual saves with versioned JSON
- **iOS Optimized**: Touch controls, safe-area support, 60 FPS target on iPhone 11+
- **Offline Play**: No internet required

## Requirements

- **Godot 4.x** (stable)
- **iOS Export**: macOS with Xcode 15+ for iOS builds
- **Desktop Testing**: Windows/Linux/macOS

## Installation

### Desktop

1. Install Godot 4.x from [godotengine.org](https://godotengine.org/download)
2. Clone this repository:
   ```bash
   git clone https://github.com/iafandiyev/game-1.git
   cd game-1
   ```
3. Open `project.godot` in Godot
4. Press F5 to run

### iOS Build (GitHub Actions)

The project includes GitHub Actions workflows for iOS builds:

1. Push to `main` branch or create a version tag (e.g., `v1.0.0`)
2. GitHub Actions will build the iOS Xcode project
3. Download the `LAST-NIGHT-iOS-Unsigned` artifact from the workflow run
4. Open the Xcode project on macOS and sign with your Apple Developer account
5. Deploy to your iPhone via Xcode

#### Signed IPA (requires Apple Developer account)

Add these secrets to your GitHub repository:
- `IOS_CERTIFICATE_BASE64` - Base64 encoded .p12 certificate
- `IOS_CERTIFICATE_PASSWORD` - Certificate password
- `IOS_PROVISIONING_PROFILE_BASE64` - Base64 encoded .mobileprovision
- `IOS_TEAM_ID` - Your Apple Team ID
- `IOS_BUNDLE_ID` - Your bundle identifier (e.g., com.yourname.lastnight)

The workflow will produce a signed `LAST-NIGHT-iOS-IPA` artifact.

### Manual iOS Build

```bash
# On macOS with Godot and Xcode installed
godot --export-release "iOS" build/last-night.ipa
```

## Controls

### Desktop (Keyboard/Mouse)

| Action | Key |
|--------|-----|
| Move Left | A / Left Arrow |
| Move Right | D / Right Arrow |
| Jump | W / Space / Up Arrow |
| Crouch | S / Down Arrow |
| Aim | Mouse Position |
| Shoot | Left Mouse Button |
| Reload | R |
| Interact | E |
| Flashlight | F |
| Inventory | I |
| Pause | ESC |
| Run | Shift |
| Weapon 1-4 | 1-4 |

### iOS (Touch)

- **Left Side**: Virtual joystick for movement
- **Right Side**: Aim joystick + fire/jump/crouch/reload/interact buttons
- Multi-touch supported

## Game Systems

### Survival Mechanics
- **Hunger**: Decreases over time, restored by food
- **Thirst**: Decreases faster than hunger, restored by water
- **Stamina**: Consumed by running/actions, regenerates at rest
- **Health**: Lost to damage, restored by medicine
- **Infection**: Zombie attacks increase exposure, treated with antibiotics

### Zombie Types
1. **Walker** - Slow, basic melee, standard detection
2. **Runner** - Fast, aggressive pursuit, higher damage
3. **Tank** - High health, heavy attacks, slow movement
4. **Screamer** - Detects player, screams to attract others
5. **Crawler** - Low profile, dangerous in tight spaces

### Weapons
- **Pistol** - Balanced, common ammo
- **Shotgun** - High damage, spread, close range
- **Rifle** - Long range, high accuracy, rare ammo
- **Baseball Bat** - Melee, no ammo, high stamina cost

### Crafting Recipes
- Bandage, Medkit, Molotov, Basic Trap, Wooden Barricade
- Flashlight Battery Pack, Improvised Ammunition, Repair Kit
- Lockpick, Improved Backpack, Noise Distraction, Advanced Barricade

## Project Structure

```
LAST-NIGHT/
├── project.godot
├── README.md
├── LICENSE
├── .gitignore
├── scenes/
│   ├── main/
│   ├── player/
│   ├── enemies/
│   ├── weapons/
│   ├── levels/
│   ├── ui/
│   ├── inventory/
│   └── environment/
├── scripts/
│   ├── autoload/
│   ├── player/
│   ├── enemies/
│   ├── combat/
│   ├── survival/
│   ├── inventory/
│   ├── missions/
│   ├── save/
│   └── utilities/
├── assets/
│   ├── characters/
│   ├── zombies/
│   ├── environments/
│   ├── weapons/
│   ├── ui/
│   ├── audio/
│   ├── fonts/
│   └── effects/
├── data/
│   ├── items/
│   ├── weapons/
│   ├── missions/
│   └── levels/
├── tests/
└── .github/
    └── workflows/
        ├── ci.yml
        └── ios-ipa.yml
```

## Testing

Run automated tests in headless mode:

```bash
godot --headless --script tests/run_tests.gd
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) for details.

## Credits

- Engine: Godot 4.x
- Assets: Original + CC0 licensed
- Audio: Original + CC0 licensed

---

**LAST NIGHT** - Survive the darkness. Find the truth. Escape the city.