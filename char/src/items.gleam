import gleam/dict
import gleam/list
import char

pub fn crok_gloves(char_tuble:#(char.Charecter,char.CharecterState)) {
  #(char_tuble.0,
    char.CharecterState(..char_tuble.1,
    equiped:list.append(["Unarmed Strike"],char_tuble.1.equiped),
    items:dict.insert(char_tuble.1.items,"Unarmed Strike",char.Weppon(
      name:"Unarmed Strike",
      description:"My bare fists",
      cost:0,
      tags:[""],
      dice:[char.Dice(number:1,max:6),char.Dice(1,4)],// THE 1 D4 IS LIGHTING
      ability_score:["Dexterous"] // will pick the highest
    ))
  ))
}

// three times per day I can add an addional d8 of lighting damamge to an attack
pub fn tazer_staff(char_tuble:#(char.Charecter,char.CharecterState)) {
  #(char_tuble.0,
    char.CharecterState(..char_tuble.1,
    equiped:list.append(["Tazer staff"],char_tuble.1.equiped),
    items:dict.insert(char_tuble.1.items,"Tazer Staff",char.Weppon(
      name:"Tazer Staff",
      description:"three times per day I can add an addional d8 of lighting damamge to an attack",
      cost:0,
      tags:[""],
      dice:[char.Dice(number:1,max:6)],// THE 1 D4 IS LIGHTING
      ability_score:["Dexterous"] // will pick the highest
    ))
  ))
}

// veterens cain
// can use a bonce action to turn it into a long sword one time


// small mechanical crab
// vox seaker
