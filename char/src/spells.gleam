import gleam/option
import char.{Spell, Minutes, Hours, Concentration, Action}

// warlock ----
pub fn eldritch_blast(resource:String) {
  Spell(
    name:"Eldritch Blast",
    level:0,
    description:"You hurl a beam of crackling energy. Make a ranged spell attack against one creature or object in range. On a hit, the target takes 1d10 Force damage.",
    resource:,
    casting_time: Action,
    spell_type: char.HitDc,
    range: 120,
    duration: char.Instant
  )
}
pub fn magic_stone(resource:String) {
  Spell(
    name:"Magic Stone",
    level:0,
    description:"You touch one to three pebbles and imbue them with magic. You or someone else can make a ranged spell attack with one of the pebbles by throwing it or hurling it with a sling. If thrown, it has a range of 60 feet. If someone else attacks with the pebble, that attacker adds your spellcasting ability modifier, not the attacker’s, to the attack roll. On a hit, the target takes bludgeoning damage equal to 1d6 + your spellcasting ability modifier. Hit or miss, the spell then ends on the stone.

    If you cast this spell again, the spell ends early on any pebbles still affected by it.",
    resource:,
    casting_time:char.BonusAction,
    spell_type: char.HitDc,
    range: 0
  , duration: char.Lasting(Minutes(10))
  )
}
pub fn minor_illusion(resource:String) {
  Spell(
    name:"Minor Illusion",
    level:0,
    description:"You create a sound or an image of an object within range that lasts for the duration. See the descriptions below for the effects of each. The illusion ends if you cast this spell again.

    If a creature takes a Study action to examine the sound or image, the creature can determine that it is an illusion with a successful Intelligence (Investigation) check against your spell save DC. If a creature discerns the illusion for what it is, the illusion becomes faint to the creature.

    Sound. If you create a sound, its volume can range from a whisper to a scream. It can be your voice, someone else’s voice, a lion’s roar, a beating of drums, or any other sound you choose. The sound continues unabated throughout the duration, or you can make discrete sounds at different times before the spell ends.

    Image. If you create an image of an object—such as a chair, muddy footprints, or a small chest—it must be no larger than a 5-foot Cube. The image can’t create sound, light, smell, or any other sensory effect. Physical interaction with the image reveals it to be an illusion, since things can pass through it.
    Tags:",
    resource:,
    casting_time: Action,
    spell_type: char.SpellSave("intelligence"),
    range: 30
  , duration: char.Lasting(char.Minutes(1))
  )
}

// lvl 1
pub fn alarm(resource:String) {
  Spell(
    name:"alarm",
    level:1,
    description:"
      You set an alarm against unwanted intrusion. Choose a door, a window, or an area within range that is no larger than a 20-foot cube. Until the spell ends, an alarm alerts you whenever a Tiny or larger creature touches or enters the warded area. When you cast the spell, you can designate creatures that won't set off the alarm. You also choose whether the alarm is mental or audible.

      A mental alarm alerts you with a ping in your mind if you are within 1 mile of the warded area. This ping awakens you if you are sleeping.

      An audible alarm produces the sound of a hand bell for 10 seconds within 60 feet.
    ",
    resource:,
    casting_time: Minutes(1),
    spell_type: char.Util,
    range: 30,
    duration: Concentration(Hours(8))
  )
}
pub fn detect_magic(resource:String) {
  Spell(
    name:"alarm",
    level:1,
    description:"
    For the duration, you sense the presence of magical effects within 30 feet of yourself. If you sense such effects, you can take the Magic action to see a faint aura around any visible creature or object in the area that bears the magic, and if an effect was created by a spell, you learn the spell’s school of magic.

    The spell is blocked by 1 foot of stone, dirt, or wood; 1 inch of metal; or a thin sheet of lead.
    ",
    resource:,
    casting_time: Action,
    spell_type: char.Util,
    range: 30,
    duration: char.Concentration(char.Minutes(10))
  )
}

pub fn arms_of_hadar(resource:String) {
  Spell(
    name: "Arms of hadar",
    level: 1,
    description: "Invoking Hadar, you cause tendrils to erupt from yourself. Each creature in a 10-foot Emanation originating from you makes a Strength saving throw. On a failed save, a target takes 2d6 Necrotic damage and can’t take Reactions until the start of its next turn. On a successful save, a target takes half as much damage only.",
    resource:,
    casting_time: Action,
    spell_type: char.SpellSave("strength"),
    range: 10
  , duration: char.Instant
  )
}
pub fn hex(resource:String) {
  Spell(
    name: "Hex",
    level: 1,
    description: "You place a curse on a creature that you can see within range. Until the spell ends, you deal an extra 1d6 Necrotic damage to the target whenever you hit it with an attack roll. Also, choose one ability when you cast the spell. The target has Disadvantage on ability checks made with the chosen ability.

    If the target drops to 0 Hit Points before this spell ends, you can take a Bonus Action on a later turn to curse a new creature.

    Using a Higher-Level Spell Slot. Your Concentration can last longer with a spell slot of level 2 (up to 4 hours), 3–4 (up to 8 hours), or 5+ (24 hours).",
    resource:,
    casting_time: char.BonusAction,
    spell_type: char.SpellSave("strength"),
    range: 90
  , duration: char.Concentration(char.Minutes(10))
  )
}
