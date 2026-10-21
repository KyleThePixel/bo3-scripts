# bo3-scripts

Custom GSC scripts for Call of Duty: Black Ops 3 Zombies, built for the
**ezz boiii** client.

## Scripts

### [papgum](papgum/) — Pack-a-Punch GobbleGum
Replaces the **Bullet Boost** GobbleGum's effect: pop it holding a normal
gun and that gun is Pack-a-Punched in place (permanent, full ammo, random
AAT). Pop it holding an already Pack-a-Punched gun and its Alternate Ammo
Type is re-rolled to a guaranteed-different one. Keeps Bullet Boost's name,
icon, and 2 activations.

### [gungame](gungame/) — Gun Game
Co-op gun game: every player climbs their own 20-weapon ladder, each tier
pairing a weapon with a condition (kills, headshots, melee, streaks,
grenades...). Downed = drop a tier, reviving a teammate = +1 progress,
Bowie Knife finale. Box / wallbuys / PaP are neutralized.

## Install (boiii)

Boiii compiles and loads custom scripts itself — no injector needed.
Drop the script's **source** `.gsc` file into `custom_scripts`, in either
location:

- `<game folder>\boiii\custom_scripts\`
- `%LOCALAPPDATA%\boiii\data\custom_scripts\`

Top level of that folder is fine. Source only — boiii compiles the
`.gsc` itself, so no pre-compiled copies are kept here.

## Co-op

Both scripts are **host-only**: only the host needs them installed. Other
players in the lobby get the effects without having the files.
