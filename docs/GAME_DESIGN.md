# BALANCE — Game Design Document

**Status:** v0.1 — concept baseline, 12 November 2026  
**Working title:** Balance  
**Project:** `spyrostrimis/balance3`  
**Design owner:** Project creator. Claude Code / Codex implement with human review.

> **Design principle:** Every faction claims to seek *Balance*, but defines it differently. Players should experience meaningful scarcity, tactical choices, and morally complicated factions in an accessible 2D RTS.

## 1. Confirmed pillars

- **Genre:** Single-player-first, sprite-based, orthogonal 2D real-time strategy. Visual direction: Dune II with the polish and readability of Dune Legacy HD and Dune II: The Maker.
- **Scope:** Small armies, few buildings and units initially; losing a unit hurts; repairing and retreating matter.
- **Economy:** One primary scarce material, **Orichalcum**, initially mined from small rock formations. Additional deposit forms (mountains, mines) are future possibilities.
- **Harvesting concept:** A harvester travels as a truck, transforms into a humanoid robot at a deposit, extracts Orichalcum, transforms back, then returns to a refinery.
- **Tactical leaders:** Selected commander/hero characters have active and potentially passive abilities.
- **Missions:** Standard base-destruction missions coexist with other objectives, including resource control and survival.
- **Campaigns:** Blue and Red factions receive full single-player campaigns. Green and possibly the Palatinate receive limited campaigns / standalone missions.
- **Hazards:** Some planets have powerful wandering creatures that may attack harvesters, armies, civilians, and even structures. Not part of prototype 001.
- **Design inspiration, NOT reusable IP:** Dune II, Command & Conquer, Red Alert, Warcraft III, DotA, Northgard, Transformers, Star Wars, Lord of the Rings, Greek mythology, and other stories. Everything shipped must be original or properly licensed.

## 2. Factions and ideological conflicts

### Blue — freedom, justice, self-determination
Generally sympathetic, democratic coalition against arbitrary power. Flaws: bureaucracy, slow decisions, arrogance, losing contact with ordinary citizens. Thematically associated with protection, restoration, shared morale. **Suggested** gameplay strengths: preserving and coordinating scarce units; healing / repair. These are not yet balanced or finalized.

### Red — order, power, centralized command
Authoritarian, ruthless, decisive; promises peace through unified strength and believes ends may justify means. Not merely cartoon villains: leadership and logistical effectiveness have appeal. **Suggested** gameplay strengths: offensive power, coordinated strikes and swift action; costs and weaknesses TBD.

### Green — opportunism, merchants and local lords
Loose collection of self-interested actors, not focused on ruling the galaxy. Can ally with either side if profitable. **Suggested** style: ambush, stealth and lethal equipment, weak large-army cohesion. Do not dismiss their narrative importance.

### Palatinate / Clergy — ancient covert religious order
Antagonistic or unpredictable forces, sometimes opposing all factions or quietly supporting one. Historically they tried spreading religions among intelligent civilizations to impose social order; unintended sectarian conflicts discredited the plan. A **new guard** replaced the old guard and favors hidden guidance/manipulation, in the spirit of a covert intellectual order. Treat religions and peoples in the game's setting as fictional; do not assert real-world faiths were created by fictional villains. Their powers and technology are not yet defined.

**Faction names, insignia, units, and all detailed mechanics remain open.** Color names are provisional identifiers.

## 3. Political backstory

A just and widely respected king, called **the Peacebringer**, united much of his home planet through diplomacy and brought neighboring planets in the system into alliance. Peace and prosperity followed. Believing large ground forces were no longer necessary, he abruptly discharged most of his military, leaving the Royal Guard and police while relying heavily on automated orbital defenses. Many displaced military families and associated workers suffered economically and lost social standing; others considered the policy a strategic danger.

A young lieutenant capitalized on the backlash, organized a military coup during a palace ceremony, slaughtered the king and seized power. The king's sole son, **17 years old**, arrived late to the ceremony and escaped with loyalists, helped by a brave woman from the Royal Guard. Their intermittent romance developed in the intervening adult years; they have not been together for some time.

**Game begins ten years later:** former prince and future Blue leader **27**; coup leader and Red leader **40**; Royal Guard veteran and Blue field commander approximately **37**. The latter is the Blue leader's right hand; she is more than a romantic supporting character and requires independent goals and judgment.

**Open lore issue:** Explain how a lieutenant-led coup succeeded despite automated orbital defenses and the king's surviving loyalists. Avoid committing to a particular answer yet.

## 4. Heroes and abilities

- **Blue leader (27):** Active area **healing / repair pulse** affecting nearby friendly units. A passive morale/coordination ability tentatively named **Encouragement**. No appearance in the first mission.
- **Blue field commander (~37):** Fearless former Royal Guard; helped the prince escape. Reference concept: weathered blue armor, desert scarf, practical gear and scars. Active **single-target healing/repair**. Leads Blue tutorial mission in a forest.
- **Red leader (40):** Coup leader, formidable weapon; **Dominion** proposed as ability name, exact behavior unconfirmed. No appearance in the first mission.
- **Red field commander:** Right-hand character of Red leader, not yet designed. Leads desert tutorial mission.

**Balance note:** Healing living troops vs repairing mechanical units needs a consistent science-fiction explanation and rules. Defer exact costs, cooldowns, range, and healing amounts until playtesting.

## 5. Missions

### M01 — The First Claim (Blue variant: forest; Red variant: desert)

**Creative objective:** Teach the player by playing, not through lengthy exposition. Four allied troops versus four opponents contest a single central Orichalcum-bearing rock formation. Leaders remain off-map; each side's field commander participates.

**Suggested future victory rule:** Maintain uncontested control near the rock for a short period, or eliminate resistance. The exact objective timer, contest radius and balance are provisional.

**Full mission eventually teaches:** selecting troops, move commands, basic positioning, attacking, targeted commander ability, preservation and control points.

**Prototype 001 is only the movement sandbox**, not this entire mission: the two squads and central deposit are present, but combat, capture logic, enemy AI, and abilities are deferred. This avoids attempting too much in the first code pass.

## 6. Economy and escalation (post-prototype)

Orichalcum is extracted from discrete deposits; deposits are rare and/or finite (rate, renewal and economy tuning TBD). Harvesters are high-value targets. Repair and retreat generally matter more than replacement. Base building, refinery, production and repair cost mechanics follow once the tactical foundation is stable.

**Risk:** Strict scarcity can deadlock a mission. Plan safeguards such as recoverable income, mission-specific reserves, or alternative victory conditions; decide by playtesting.

## 7. Technical framing

- Engine: Godot **4.7.2 stable** if installed/available; otherwise agent reports observed version and compatibility issues before changing version.
- Language: GDScript, no unnecessary C# or plugins for the initial prototype.
- Rendering: native 2D sprites, orthogonal/square grid, explicit building footprints, separate logical tile coordinates from source image pixel resolution and camera zoom.
- Provisional, **not locked**: 32 logical world units per tile and artwork at up to 64 px source resolution. Validate on screen before settling.
- Architecture: data-driven future units; separation of world rules, orders, pathfinding, input, rendering and UI.
- Platforms: Windows desktop first; browser and multiplayer are not initial commitments.

## 8. Out of scope for Prototype 001

Combat, harvesting, transforming, construction, economy, multi-faction AI, campaign map, diplomacy, fog of war simulation, monsters, multiplayer, sophisticated art, full story cinematics.

## 9. Questions for later (not blockers today)

1. Are Blue/Red faction labels replaced by formal names? What are their symbols?
2. How does Orichalcum enable machines / repairs / abilities?
3. How limited is resource regeneration, and what prevents stalemate?
4. What uniquely characterizes the Red commander and their ability?
5. Why couldn't orbital defenses prevent the coup?
6. What causes Blue/Red separation 10 years after the coup, and what makes this first deposit strategically important?
7. What visual scale makes a 4v4 clash fun at 1080p? Compare playtests instead of arguing abstract pixel dimensions.
8. What degree of unit behavior is automatic versus explicitly player-controlled?

---

**Change control:** Put confirmed user decisions in this document; keep brainstormed options under `Proposed` or `Open`. Update `docs/DECISIONS.md` after design decisions are approved.
