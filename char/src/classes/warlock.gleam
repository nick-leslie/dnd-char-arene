import spells
import lustre/element/html
import gleam/option
import gleam/list
import gleam/dict
import char

pub fn warlock_lvl_1(spells:List(char.Spell)) {
  //todo assert that we cant have more than 2 cantrips and 2 spells
  char.Class(
    name:"warlock",
    level:1,
    hit_dice:8,
    features:[
      char.Passive(
        name:"Eldritch Invocations",
        text:"You have unearthed Eldritch Invocations, pieces of forbidden knowledge that imbue you with an abiding magical ability or other lessons. You gain one invocation of your choice, such as Pact of the Tome. Invocations are described in the “Eldritch Invocation Options” section."
      ),
      char.PassiveModification(
        name:"Pact Magic ",
        text:"Through occult ceremony, you have formed a pact with a mysterious entity to gain magical powers. The entity is a voice in the shadows—its identity unclear—but its boon to you is concrete: the ability to cast spells.",
        func: fn(char,state) {
          let assert Ok(warlock) = char.classes |> dict.get("warlock")
          #(
            char,
            char.CharecterState(..state, resources: dict.insert(state.resources, "pact_magic", char.SpellSlot(used:False,level:warlock_slots_level(warlock.level)) |> list.repeat(warlock_slots_amount(warlock.level)))) // todo this is a bug
          )
        }
      )
    ],
    spells:spells
  , spell_casting_stat: "charisma")
}

fn warlock_slots_amount(lvl:Int) {
  case lvl {
    1 -> 1
    2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 -> 2
    11 | 12 | 13 | 14 | 15 | 16 -> 3
    _ -> 4
  }
}
fn warlock_slots_level(lvl:Int) {
  case lvl {
    1 | 2-> 1
    3 | 4  -> 2
    5 | 6  -> 3
    7 | 8  -> 4
    _ -> 5
  }
}

pub fn warlock_pact_of_the_dreadnought(warlock_class:char.Class) {
  char.Class(
    ..warlock_class,
      name: "warlock pact of the dreadnought",
      features: list.append(warlock_class.features,[
        char.Passive(
          name:"Visions of Power",
          text:"At 1st level, your ability to pick out valuable information, objects or magic becomes uncanny.
          You have advantage on insight checks to glean useful information from someone.
          you have advantage on perception/investigation checks to see valuable objects.
          you have advantage on determining what type of spell is being cast and some parts of what it does."
        )
      ]),
  )
}

// eldrich evocation
pub fn pact_of_the_tomb(warlock_class:char.Class,spells:List(fn(String) -> char.Spell)) {
  char.Class(
    ..warlock_class,
      features: list.append(warlock_class.features,[
        char.Passive(
          name:"pact of the tome",
          text:"
            Stitching together strands of shadow, you conjure forth a book in your hand at the end of a Short or Long Rest. This Book of Shadows (you determine its appearance) contains eldritch magic that only you can access, granting you the benefits below. The book disappears if you conjure another book with this feature or if you die.

            Cantrips and Rituals. When the book appears, choose three cantrips, and choose two level 1 spells that have the Ritual tag. The spells can be from any class’s spell list, and they must be spells you don’t already have prepared. While the book is on your person, you have the chosen spells prepared, and they function as Warlock spells for you.

            Spellcasting Focus. You can use the book as a Spellcasting Focus.
          ",
        ),
      ]),
      spells:list.append(warlock_class.spells,spells |> list.map(fn(spell_fn) { spell_fn("pact_magic")}))
  )
}

// lvl 2
pub fn warlock_level_2(warlock_class:char.Class,spell:fn(String) -> char.Spell) {
  char.Class(
    ..warlock_class,
      level:2,
      features: list.append(warlock_class.features,[
        char.Passive( // todo make this a resouce triggred on long rest
          name:" Magical Cunning ",
          text:"
            You can perform an esoteric rite for 1 minute. At the end of it, you regain expended Pact Magic spell slots but no more than a number equal to half your maximum (round up). Once you use this feature, you can’t do so again until you finish a Long Rest.
          ",
        ),
      ]),
      spells:list.append(warlock_class.spells,[spell("pact_magic")])
  )
}

pub fn devil_sight(warlock_class:char.Class) {
  char.Class(
    ..warlock_class,
      features: list.append(warlock_class.features,[
        char.Passive( // todo make this a resouce triggred on long rest
          name:"Devil’s Sight",
          text:"
          You can see normally in Dim Light and Darkness—both magical and nonmagical—within 120 feet of yourself.
          ",
        ),
      ]),
  )
}

pub fn fiendish_vigor(warlock_class:char.Class) {
  char.Class(
    ..warlock_class,
      features: list.append(warlock_class.features,[
        char.Passive( // todo make this a resouce triggred on long rest
          name:"Fiendish Vigor",
          text:"
          You can cast False Life on yourself without expending a spell slot. When you cast the spell with this feature, you don’t roll the die for the Temporary Hit Points; you automatically get the highest number on the die.
          ",
        ),
      ]),
      spells:list.append(warlock_class.spells,[spells.fiendish_vigor("none")])
  )
}
