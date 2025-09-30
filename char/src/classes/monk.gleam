import gleam/option
import gleam/int
import gleam/result
import iv
import gleam/dict
import char
import gleam/list


pub fn monk_lvl_1() {
  char.Class(
    name:"monk",
    level:1,
    hit_dice:8,
    features:[
      char.PassiveModification(
        name:"Unarmored Defense",
        text:"While you aren't wearing armor or wielding a
        Shield, your base Armor Class equals 10 plus your
        Dexterity and Wisdom modifiers.",
        func:unarmored_defense
      ),
      char.PassiveModification(
        name:"Martial Arts",
        text:"our practice of martial arts gives you mastery of
        combat styles that use your Unarmed Strike and
        Monk weapons, which are the following:
        Simple Melee weapons
        Martial Melee weapons that have the Light
        property
        You gain the following benefits while you are unarmed
        or wielding only Monk weapons and you
        aren't wearing armor or wielding a Shield.
        Bonus Unarmed Strike. You can make an Unarmed
        Strike as a Bonus Action.
        Martial Arts Die. You can roll ld6 in place of the
        normal damage of your Unarmed Strike or Monk
        weapons. This die changes as you gain Monk levels,
        as shown in the Martial Arts column of the Monk
        Features table.
        Dexterous Attacks. You can use your Dexterity
        modifier instead of your Strength modifier for the
        attack and damage rolls of your Unarmed Strikes
        and Monk weapons. In addition, when you use the
        Grapple or Shove option of your Unarmed Strike,
        you can use your Dexterity modifier instead of your
        Strength modifier to determine the save DC.",
        func:martial_arts
      )
    ],
    spells:[]
  , spell_casting_stat: "wisdom"
  )
}

fn unarmored_defense(charecter:char.Charecter,state:char.CharecterState) {
  let dex_mod = char.get_stat_assert(charecter,"dexterity")
  |> char.mod_formula
  let wis_mod = char.get_stat_assert(charecter,"wisdom") |> char.mod_formula
  case list.length(char.get_armor(state)) {
    0 -> {
      #(charecter,char.CharecterState(..state,ac:10+dex_mod+wis_mod))
    }
    _ -> #(charecter,state)
  }
}
//todo we need to add the table.
//todo we need to add the unarmed attack
fn martial_arts(charecter:char.Charecter,state:char.CharecterState) {
  #(charecter,
    char.CharecterState(..state,
    equiped:list.append(["Unarmed Strike"],state.equiped),
    items:dict.insert(state.items,"Unarmed Strike",char.Weppon(
      name:"Unarmed Strike",
      description:"My bare fists",
      cost:0,
      tags:[""],
      dice:char.Dice(number:1,max:6),
      ability_score:["Dexterous"] // will pick the highest
    ))
  ))
}


pub fn monk_lvl_2(monk_class:char.Class) {
  char.Class(
    ..monk_class,
    level:2,
    features:list.append(monk_class.features,[
      char.PassiveModification(
        name:"Monk Focus",
        text:"Your focus and martial training allow you to har -
        ness a well of extraordinary energy within yourself.
        This energy is represented by Focus Points. Your
        Monk level determines the number of points you
        have, as shown in the Focus Points column of the
        Monk Features table.",
        func:monk_focus
      ),
      char.PassiveModification(
        "Unarmored Movement",
        "Your speed increases by 10 feet while you a ren't
        wearing ar m or or wieldi ng a Shield. This bonus
        increases when you re ach ce rtain Monk levels, as
        shown on the Monk Features table.",
        func:unarmored_movement
      ),
      char.Active(
        name: "Flurry of Blows.",
        text: "You can expend 1 Focus Point to make two Unarmed Strikes as a Bonus Action.",
        resource: "focus",
        func: fn(charecter,state) {
          #(charecter,state)
        }
      ),
      char.Active(
        name: "Patient Defense.",
        text: "You can take the Disengage action as a Bonus Action. Alternatively, you can expend 1 Focus Point to take both the Disengage and the Dodge actions as a Bonus Action.",
        resource: "focus",
        func: fn(charecter,state) {
          #(charecter,state)
        }
      ),
      char.Active(
        name: "Step of the Wind.",
        text: "You can take the Dash action as a Bonus Action. Alternatively, you can expend 1 Focus Point to take both the Disengage and Dash actions as a Bonus Action, and your jump distance is doubled for the turn.",
        resource: "focus",
        func: fn(charecter,state) {
          #(charecter,state)
        }
      ),
    ]),
  )
}

pub fn unarmored_movement(charecter:char.Charecter,state:char.CharecterState) {
  let assert Ok(monk) = dict.get(charecter.classes,"monk")
  let assert Ok(base) = int.floor_divide({monk.level+6},4)
  let mod = base*5
  #(charecter,char.CharecterState(..state,speed:charecter.species.speed+mod))
}

pub fn monk_focus(charecter:char.Charecter,state:char.CharecterState) {
  let assert Ok(monk) = dict.get(charecter.classes,"monk")
  case dict.get(state.resources,"focus") {
    Error(_) -> {
      #(charecter,char.CharecterState(..state,
        resources:dict.insert(
        state.resources,
        "focus",
          char.Generic(False)
          |> list.repeat(monk.level)
        )))

    }
    Ok(_) -> #(charecter,state)
  }
}
