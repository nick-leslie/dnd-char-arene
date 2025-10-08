import gleam/json
import gleam/float
import gleam/int
import gleam/option
import gleam/result
import gleam/list
import gleam/dynamic/decode
// import gleam/json
import gleam/dict
import iv
pub type SheetFunc = fn (Charecter,CharecterState) -> #(Charecter,CharecterState)

pub fn mod_formula(score:Int) {
  float.truncate(float.floor({int.to_float(score)-.10.0} /. 2.))
}

pub type Charecter {
  Charecter(
    name:String,
    pronouns:String,
    species:Species,
    stats:dict.Dict(String,Int),
    skills:dict.Dict(String,Skill),
    feats:dict.Dict(String,Feature),
    //todo seperate this to a stats block
    max_hp:Int,
    classes:dict.Dict(String,Class),
    item_proficencys:dict.Dict(String,String),
  )
}

pub fn set_info(charecter:Charecter,name:String,pronouns:String) {
  Charecter(
    ..charecter,
    name:name,
    pronouns:pronouns,
  )
}


pub type CharecterState {
  CharecterState(
    ac:Int,
    hp:Int,
    speed:Int,
    proficiency_bonus:Int,
    resources:dict.Dict(String,List(Resource)),
    equiped:List(String),
    items:dict.Dict(String,Item),
    gold:Int // todo we might have floating point errors
  )
}

pub fn charecter_state_to_json(charecter_state: CharecterState) -> json.Json {
  let CharecterState(ac:, hp:, speed:, proficiency_bonus:, resources:, equiped:, items:, gold:) = charecter_state
  json.object([
    #("ac", json.int(ac)),
    #("hp", json.int(hp)),
    #("speed", json.int(speed)),
    #("proficiency_bonus", json.int(proficiency_bonus)),
    #("resources", json.dict(resources, fn(string) { string }, json.array(_, resource_to_json))),
    #("equiped", json.array(equiped, json.string)),
    #("items", json.dict(items, fn(string) { string }, item_to_json)),
    #("gold", json.int(gold)),
  ])
}

pub fn charecter_state_decoder() -> decode.Decoder(CharecterState) {
  use ac <- decode.field("ac", decode.int)
  use hp <- decode.field("hp", decode.int)
  use speed <- decode.field("speed", decode.int)
  use proficiency_bonus <- decode.field("proficiency_bonus", decode.int)
  use resources <- decode.field("resources", decode.dict(decode.string, decode.list(resource_decoder())))
  use equiped <- decode.field("equiped", decode.list(decode.string))
  use items <- decode.field("items", decode.dict(decode.string, item_decoder()))
  use gold <- decode.field("gold", decode.int)
  decode.success(CharecterState(ac:, hp:, speed:, proficiency_bonus:, resources:, equiped:, items:, gold:))
}

pub fn init(charecter:Charecter) {
  #(charecter,CharecterState(
    ac:10,
    hp:charecter.max_hp,
    speed:charecter.species.speed,
    resources:dict.new(),
    equiped:[],
    proficiency_bonus:2,
    items:dict.new(),
    gold:0,
  ))
  |> apply_species_features
  |> apply_class_features
  |> apply_feats
  |> setup_hp

}

fn setup_hp(info_bundle:#(Charecter, CharecterState)) {
  let max_hp = info_bundle.0.classes |> dict.values |> list.map(fn(class) { class.hit_dice * class.level}) |> list.fold(0,int.add)
  #(
    Charecter(..info_bundle.0,max_hp:max_hp),info_bundle.1
  )
}

pub fn calculate_proficiency_bonus(charecter:Charecter) {
  let total = {
    use total_lvl,class <- list.fold(charecter.classes |> dict.values,0)
    total_lvl + class.level
  }
  let assert Ok(lvl_mod) = int.floor_divide(total,5)
  2 + lvl_mod
}

fn apply_species_features(info_bundle:#(Charecter, CharecterState)) {
  use info_bundle,feature <- list.fold(info_bundle.0.species.features,info_bundle)
  case feature {
    Passive(_name, _text) -> info_bundle
    Active(_name, _text, _resource,func) -> func(info_bundle.0,info_bundle.1)
    PassiveModification(_name, _text, func) -> func(info_bundle.0,info_bundle.1)
  }
}

fn apply_class_features(info_bundle:#(Charecter, CharecterState)) {
  let classes = info_bundle.0.classes |> dict.values
  use info_bundle,class <- list.fold(classes,info_bundle)
  use info_bundle,feature <- list.fold(class.features,info_bundle)
  case feature {
    Passive(_name, _text) -> info_bundle
    Active(_name, _text, _resource,func) -> func(info_bundle.0,info_bundle.1)
    PassiveModification(_name, _text, func) -> func(info_bundle.0,info_bundle.1)
  }
}

// apply equipments
// apply spells

fn apply_feats(info_bundle:#(Charecter, CharecterState)) {
  let feats = info_bundle.0.feats |> dict.values
  use info_bundle,feat <- list.fold(feats,info_bundle)
  case feat {
    Passive(_name, _text) -> info_bundle
    Active(_name, _text, _resource,func) -> func(info_bundle.0,info_bundle.1)
    PassiveModification(_name, _text, func) -> func(info_bundle.0,info_bundle.1)
  }
}


//todo we should also have a way to load in serlized state

pub fn get_stat_assert(charecter:Charecter,name) {
  let assert Ok(stat) = dict.get(charecter.stats,name)
  stat
}


pub fn empty_sheet() {
  Charecter(
    name:"",
    pronouns:"",
    species:Species("",30,[],[]),
    stats:dict.from_list([
      #("strength",10),
      #("dexterity",10),
      #("constitution",10),
      #("intelligence",10),
      #("wisdom",10),
      #("charisma",10),
    ]),
    skills:dict.from_list(
      [
        #("acrobatics", Skill(name: "Acrobatics", attribute: "dexterity", proficient: False)),
        #("animal Handling", Skill(name: "Animal Handling", attribute: "wisdom", proficient: False)),
        #("arcana", Skill(name: "Arcana", attribute: "intelligence", proficient: False)),
        #("athletics", Skill(name: "Athletics", attribute: "strength", proficient: False)),
        #("deception", Skill(name: "Deception", attribute: "charisma", proficient: False)),
        #("history", Skill(name: "History", attribute: "intelligence", proficient: False)),
        #("insight", Skill(name: "Insight", attribute: "wisdom", proficient: False)),
        #("intimidation", Skill(name: "Intimidation", attribute: "charisma", proficient: False)),
        #("investigation", Skill(name: "Investigation", attribute: "intelligence", proficient: False)),
        #("medicine", Skill(name: "Medicine", attribute: "wisdom", proficient: False)),
        #("nature", Skill(name: "Nature", attribute: "intelligence", proficient: False)),
        #("perception", Skill(name: "Perception", attribute: "wisdom", proficient: False)),
        #("performance", Skill(name: "Performance", attribute: "charisma", proficient: False)),
        #("persuasion", Skill(name: "Persuasion", attribute: "charisma", proficient: False)),
        #("religion", Skill(name: "Religion", attribute: "intelligence", proficient: False)),
        #("sleight of hand", Skill(name: "Sleight of Hand", attribute: "dexterity", proficient: False)),
        #("stealth", Skill(name: "Stealth", attribute: "dexterity", proficient: False)),
        #("survival", Skill(name: "Survival", attribute: "wisdom", proficient: False)),
      ]
    ),
    feats:dict.new(),
    max_hp:0,
    classes:dict.new(),
    item_proficencys:dict.new(),
  )
}


pub fn set_species(charecter:Charecter,species:Species) -> Charecter {
  Charecter(
    ..charecter,
    species: species
  )
}


pub fn set_stat_array(charecter charecter:Charecter,strength strength:Int,dexterity dexterity:Int,constitution constitution:Int,intelligence intelligence:Int,wisdom wisdom:Int,charisma charisma:Int) {
  Charecter(
    ..charecter,
    stats:dict.from_list([
      #("strength",strength),
      #("dexterity",dexterity),
      #("constitution",constitution),
      #("intelligence",intelligence),
      #("wisdom",wisdom),
      #("charisma",charisma),
    ]),
  )
}

pub type Skill {
  Skill(
    name:String,
    attribute:String,
    proficient:Bool
  )
}

pub fn set_proficent(charecter:Charecter, skill_names:List(String)) {
  use charecter,skill_name <- list.fold(skill_names,charecter)
  case dict.get(charecter.skills,skill_name) {
    Error(_) -> charecter
    Ok(skill) ->  Charecter(
      ..charecter,
      skills:dict.insert(charecter.skills,skill_name,Skill(..skill,proficient:True))
    )
  }
}


pub type Species {
  Species(
    name:String,
    speed:Int,
    features:List(Feature),
    spells:List(Spell),
  )
}




pub type Class {
  Class(
    name:String,
    level:Int,
    hit_dice:Int, // this should be a dice but I was using fixed
    spell_casting_stat:String, // this is going to need a refactor for classes that take feats that add spells
    features:List(Feature),
    spells:List(Spell),
  )
}

//todo make this update as well
pub fn add_class(charecter:Charecter,name:String,class:Class) {
  Charecter(
    ..charecter,
    classes:dict.insert(charecter.classes,name,class)
  )
}

pub  type Resource {
  Generic(
    used:Bool,
    // by:option.Option(Feature)
  )
  SpellSlot(
    used:Bool,
    // by:option.Option(Spell),
    level:Int,
  )
}

pub fn resource_is_used(resource:Resource) {
    resource.used == True
}

pub fn use_resorce(resource:Resource) {
  case resource {
    Generic(used:) -> Generic(!used)
    SpellSlot(used:, level:) -> SpellSlot(!used,level)
  }
}

fn resource_to_json(resource: Resource) -> json.Json {
  case resource {
    Generic(used:) -> json.object([
      #("type", json.string("generic")),
      #("used", json.bool(used)),
    ])
    SpellSlot(used:, level:) -> json.object([
      #("type", json.string("spell_slot")),
      #("used", json.bool(used)),
      #("level", json.int(level)),
    ])
  }
}

fn resource_decoder() -> decode.Decoder(Resource) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "generic" -> {
      use used <- decode.field("used", decode.bool)
      decode.success(Generic(used:))
    }
    "spell_slot" -> {
      use used <- decode.field("used", decode.bool)
      use level <- decode.field("level", decode.int)
      decode.success(SpellSlot(used:, level:))
    }
    _ -> decode.failure(Generic(False), "Resource")
  }
}




pub type Feature {
  Passive(
    name:String,
    text:String,
  )
  PassiveModification(
    name:String,
    text:String,
    func:SheetFunc,
  )
  Active(
    name:String,
    text:String,
    resource:String,
    func: SheetFunc
  )
}

pub fn add_feat(charecter:Charecter,feat:Feature) {
  Charecter(
    ..charecter,
    feats:dict.insert(charecter.feats,feat.name,feat)
  )
}

pub type SpellHitType {
  HitDc
  SpellSave(attribute:String)
  FlatSave(dc:Int)
  Util // this is for stuff like alarm. find a better name
}



pub type TimeUnits {
  Action
  BonusAction
  Reaction
  Minutes(Int)
  Hours(Int)
}

pub type Duration {
  Instant
  Lasting(TimeUnits)
  Concentration(TimeUnits)
}

pub type Spell {
  Spell(
    name:String,
    level:Int,
    casting_time:TimeUnits,
    duration:Duration,
    spell_type:SpellHitType,
    range:Int,
    description:String,
    resource:String
  )
  ModSpell(
    name:String,
    level:Int,
    casting_time:TimeUnits,
    duration:Duration,
    spell_type:SpellHitType,
    range:Int,
    description:String,
    resource:String,
    on_use_func:SheetFunc
  )
}




  pub type Item {
  Weppon(
    name:String,
    cost:Int,
    description:String,
    tags:List(String),
    dice:Dice,
    ability_score:List(String) // will pick the highest
  )
  Armor(
    name:String,
    cost:Int,
    description:String,
    tags:List(String),
    ac:Int,
    ability_score:List(String) // will pick the highest
  )
  Trinket(
    name:String,
    cost:Int,
    description:String,
    tags:List(String),
  )
}

fn item_to_json(item: Item) -> json.Json {
  case item {
    Weppon(name:, cost:, description:, tags:, dice:, ability_score:) -> json.object([
      #("type", json.string("weppon")),
      #("name", json.string(name)),
      #("cost", json.int(cost)),
      #("description", json.string(description)),
      #("tags", json.array(tags, json.string)),
      #("dice", dice_to_json(dice)),
      #("ability_score", json.array(ability_score, json.string)),
    ])
    Armor(name:, cost:, description:, tags:, ac:, ability_score:) -> json.object([
      #("type", json.string("armor")),
      #("name", json.string(name)),
      #("cost", json.int(cost)),
      #("description", json.string(description)),
      #("tags", json.array(tags, json.string)),
      #("ac", json.int(ac)),
      #("ability_score", json.array(ability_score, json.string)),
    ])
    Trinket(name:, cost:, description:, tags:) -> json.object([
      #("type", json.string("trinket")),
      #("name", json.string(name)),
      #("cost", json.int(cost)),
      #("description", json.string(description)),
      #("tags", json.array(tags, json.string)),
    ])
  }
}



fn item_decoder() -> decode.Decoder(Item) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "weppon" -> {
      use name <- decode.field("name", decode.string)
      use cost <- decode.field("cost", decode.int)
      use tags <- decode.field("tags", decode.list(decode.string))
      use dice <- decode.field("dice", dice_decoder())
      use description <- decode.field("description", decode.string)
      use ability_score <- decode.field("ability_score", decode.list(decode.string))
      decode.success(Weppon(name:, cost:, tags:, dice:, ability_score:, description: ))
    }
    "armor" -> {
      use name <- decode.field("name", decode.string)
      use tags <- decode.field("tags", decode.list(decode.string))
      use cost <- decode.field("cost", decode.int)
      use description <- decode.field("description", decode.string)
      use ac <- decode.field("ac", decode.int)
      use ability_score <- decode.field("ability_score", decode.list(decode.string))
      decode.success(Armor(name:, tags:, cost:, ac:, ability_score:, description: ))
    }
    "trinket" -> {
      use name <- decode.field("name", decode.string)
      use tags <- decode.field("tags", decode.list(decode.string))
      use cost <- decode.field("cost", decode.int)
      use description <- decode.field("description", decode.string)
      decode.success(Trinket(name:, cost:, description: , tags: ))
    }
    _ -> decode.failure(Trinket("fail",99999, description: "curse of fail", tags: []), "Item")
  }
}

pub fn add_item(state:CharecterState,item:Item) {
  CharecterState(
    ..state,
    items:dict.insert(state.items,item.name,item)
  )
}

pub fn get_equipment(state:CharecterState) {
  list.map(state.equiped,dict.get(state.items,_))
  |> result.values
}


pub fn get_armor(state:CharecterState) {
  use item <- list.filter(get_equipment(state))
  case item {
    Armor(_, _,_,_, _, _) -> True
    Trinket(_, _,_,_) -> False
    Weppon(_, _,_, _,_, _) -> False
  }
}

pub fn get_wepons(state:CharecterState) {
  use item <- list.filter(get_equipment(state))
  case item {
    Armor(_, _,_,_, _, _) -> False
    Trinket(_, _,_,_) -> False
    Weppon(_, _,_,_,_, _) -> True
  }
}


/// ---- dice

pub type Dice {
  Dice(
    number:Int,
    max:Int,
  )
}

fn dice_to_json(dice: Dice) -> json.Json {
  let Dice(number:, max:) = dice
  json.object([
    #("number", json.int(number)),
    #("max", json.int(max)),
  ])
}

fn dice_decoder() -> decode.Decoder(Dice) {
  use number <- decode.field("number", decode.int)
  use max <- decode.field("max", decode.int)
  decode.success(Dice(number:, max:))
}
