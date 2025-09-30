// IMPORTS ---------------------------------------------------------------------
import gleam/http/response
import rsvp
import charecters/arene
import gleam/json
import gleam/io
import components/collapsable
import gleam/option
import gleam/bool
import feats
import gleam/string
import spells
import gleam/list
import gleam/dict
import gleam/result
import gleam/int
import lustre
import lustre/attribute
import lustre/component
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import lustre/effect.{type Effect}
import char.{Charecter,type Charecter,CharecterState,type CharecterState}
import classes/monk
import classes/warlock
import species/goliath
import gleam/string_tree
import plinth/browser/document
import plinth/browser/element as browser_element
import gleam/http
import gleam/http/request

// MAIN ------------------------------------------------------------------------

pub fn main() {
  let assert Ok(_) = collapsable.register()
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

// MODEL -----------------------------------------------------------------------

pub type Model {
  Model(
    charecter:Charecter,
    charecter_state:CharecterState,
    hp_input:Result(Int,String) // could make this a result
  )
}

fn init(_) -> #(Model,Effect(Msg)) {
  echo "running init"
  let #(charecter,init_state) = arene.init()
  let state = document.query_selector("#model")
  |> result.map(browser_element.inner_text)
  |> result.map(json.parse(_,char.charecter_state_decoder()))
  |> result.unwrap(Error(json.UnableToDecode([])))
  |> result.unwrap(init_state)
  #(Model(
    charecter:charecter,
    charecter_state:state,
    hp_input:Ok(0)
  ),tick())
}

fn tick() -> Effect(Msg) {
  use dispatch <- effect.from
  use <- set_timeout(5000)

  dispatch(Save)
}

// UPDATE ----------------------------------------------------------------------

pub opaque type Msg {
  SetHpInput(hp:String)
  UpdateHp(HpUpdateType)
  SpendResource(name:String)
  Save
  SaveRes(Result(response.Response(String), rsvp.Error))
}

pub opaque type HpUpdateType { // should this be in a library function
  Heal
  Damage
  Temp
}

fn update(model: Model, msg: Msg) -> #(Model,Effect(Msg)) {
  case msg {
    Save -> {
      io.print("we should be saving")
      let save_effect = char.charecter_state_to_json(model.charecter_state)
      |> rsvp.post("/",_,rsvp.expect_ok_response(SaveRes))
      #(model,save_effect)
    }
    SaveRes(_) -> #(model,effect.none())
    SetHpInput(hp) -> {
      #(Model(
        ..model,
        hp_input:hp |> int.parse |> result.replace_error(hp),
      ),effect.none())
    }
    UpdateHp(update_type) -> {
      echo update_type
      echo model.hp_input
      use <- bool.guard(model.hp_input |> result.is_error,#(model,effect.none()))
      let hp_mod = case update_type {
        Damage -> -{model.hp_input |> result.unwrap(0)}
        Heal -> {model.hp_input |> result.unwrap(0)}
        Temp -> todo as "add temp health"
      }

      #(Model(
        ..model,
        hp_input:Ok(0),
        charecter_state:CharecterState(
          ..model.charecter_state,
          hp:model.charecter_state.hp + hp_mod
        )
      ),effect.none())
    }
    SpendResource(name:) -> {
      echo "spending resources"
      let resource = dict.get(model.charecter_state.resources,name) |> echo
      |> result.replace_error(#(model,effect.none()))
      result.unwrap_both({
        use resources <- result.map(resource)
        //to do how to replace
        let used_unused = list.partition(resources,char.resource_is_used) |> echo
        //todo figure out how to get back syntax hylighting
        let resource = update_resources(used_unused) |> echo

        #(Model(
          ..model,
          charecter_state:CharecterState(..model.charecter_state,resources:
            dict.insert(model.charecter_state.resources,name,resource))
        ),
        effect.none())
      })  |> echo
    }

  }
}


/// When writing custom effects that need FFI, it's common practice to define the
/// externals separate to the effect itself.
@external(javascript, "./frontend.ffi.mjs", "set_timeout")
fn set_timeout(_delay: Int, _cb: fn() -> a) -> Nil {
  // It's good practice to provide a fallback for side effects that rely on FFI
  // where possible. This means your app can run - without the side effect - in
  // environments other than the browser.
  Nil
}

// VIEW ------------------------------------------------------------------------
//
pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("px-5")],
    [
      html.button([event.on_click(Save)],[html.text("save")]),
      name_view(model),
      html.div([attribute.class("flex flex-row gap-5")],[
        html.h1([],[element.text(string.append("Ac:",int.to_string(model.charecter_state.ac)))]),
        html.h1([],[element.text(string.append("speed:",int.to_string(model.charecter_state.speed)))]),
        health_view(model)
      ]),
      html.div([attribute.class("flex flex-col gap-5")],[
        // we should change the grid cols based on window size
        html.div([attribute.class("grid grid-cols-6 overflow-x-scroll gap-5 w-full")],dict.to_list(model.charecter.stats) |> list.map(fn(stat_tup) {
            stat_view(stat_tup.0,stat_tup.1)
        })),
        html.div([attribute.class("flex flex-row gap-5 overflow-x-scroll")],
          dict.values(model.charecter.skills)
          |> list.sort(sort_skill)
          //todo pool all the skills into boxes for each and then draw border
          |> list.map(skill_view(_,model.charecter.stats,model.charecter_state.proficiency_bonus)
        )),
      ]),
      html.div([attribute.class("grid grid-cols-3 gap-5")],[
        html.div([attribute.class("flex flex-col")],[
          classes_view(model),
          feats_view(model),
        ]),
        spells_view(model),
        items_view(model)
      ])
    ]
  )
}

fn health_view(model:Model) {
  html.div([attribute.class("flex flex-row")],[
    html.div([attribute.class("flex flex-col")],[
      html.button([event.on_click(UpdateHp(Heal))],[html.text("heal")]),
      html.input([attribute.value(model.hp_input |> result.map(int.to_string) |> result.unwrap_both),attribute.type_("number"),event.on_input(SetHpInput)]),
      case model.hp_input {
        Error("") -> element.none()
        Error(_) -> html.text("please make sure that the value is a number")
        Ok(_) -> element.none()
      },
      html.button([event.on_click(UpdateHp(Damage))],[html.text("damage")]),
    ]),
    html.h1([],[html.text("Health:")]),
    html.h1([],[html.text(int.to_string(model.charecter_state.hp))]),
    html.h1([],[html.text("/")]),
    html.h1([],[html.text(int.to_string(model.charecter.max_hp))])
  ])
}

fn items_view(model:Model) {
  html.div([],
    list.map(model.charecter_state.items |> dict.values,item_view)
  )
}

fn item_view(item:char.Item) {
  html.div([],[
    html.h1([],[html.text(string.append("name",item.name))]),
    html.p([],[html.text(item.description)]),
    case item {
      char.Armor(_name, tags:,description:, cost:, ac:, ability_score:) -> {
        html.div([],[
          html.text(string.append("ac:",int.to_string(ac)))
        ])
      }
      char.Trinket(_name, cost:,description:,tags:) -> element.none()
      char.Weppon(_name, cost:, tags:, dice:, ability_score:,description:) -> {
        html.div([],[
          dice_view(dice)
        ])
      }
    },
    html.h1([],[html.text(string.append("cost",int.to_string(item.cost)))])
  ])
}

fn dice_view(dice:char.Dice) {
  html.div([],[
    html.text(string.concat([int.to_string(dice.number),"d",int.to_string(dice.max)]))
  ])
}

fn sort_skill(skill_a:char.Skill,skill_b:char.Skill) {
  int.compare(order_attribute(skill_a.attribute),order_attribute(skill_b.attribute))
}

fn order_attribute(attribute) {
  case attribute {
    "strength" -> 1
    "dexterity" -> 2
    "constitution" -> 3
    "intelligence" -> 4
    "wisdom" -> 5
    "charisma" -> 6
    _ -> 7
  }
}

fn skill_view(skill:char.Skill,stats:dict.Dict(String,Int),proficiency_bonus:Int) {
  case dict.get(stats,skill.attribute) {
    Ok(skill_val) -> {
      let mod = case skill.proficient {
        False -> char.mod_formula(skill_val)
        True ->  char.mod_formula(skill_val) + proficiency_bonus
      }
      html.div([],[
        html.h1([],[element.text(skill.name)]),
        html.h1([],[element.text(skill.attribute)]),
        html.h1([],[element.text(bool.to_string(skill.proficient))]),
        html.h1([],[element.text(string.append("+",int.to_string(mod)))]),
      ])
    }
    Error(_) -> element.none()
  }
}


fn name_view(model: Model) -> Element(Msg)  {
  html.div([attribute.class("flex flex-row gap-5 text-2xl")],[
    html.h1([],[element.text(model.charecter.name)]),
    html.h1([],[element.text(model.charecter.pronouns)]),
    html.h1([],[element.text(model.charecter.species.name)]),
    html.h1([],[element.text(
      model.charecter.classes
      |> dict.values()
      |> list.map(fn(class) { string.join([class.name, int.to_string(class.level)]," ") })
      |> string.join(", "))
    ]),
    // html.h1([],[
    //   element.text(string.join(["Speed:",int.to_string(model.charecter_state.speed),"ft"]," "))
    // ])
  ])
}
// this should be a tab section with each of the tabs
fn classes_view(model:Model) {
  html.div([attribute.class("flex flex-col gap-5")],[
    html.h1([attribute.class("text-2xl pb-3")],[html.text("Class features")]),
    html.div([attribute.class("flex flex-col gap-5")],
      model.charecter.classes
      |> dict.values
      |> list.map(class_view(model,_))
    )
  ])
}

fn class_view(model:Model,class:char.Class) {
  html.div([],[
    html.h1([attribute.class("text-2xl")],[html.text(class.name)]),
    html.div([attribute.class("flex flex-col gap-4")],
      class.features |> list.map(feat_view(model,_))
    )
  ])
}

fn spells_view(model:Model) {

  html.div([],[
    html.h1([attribute.class("text-2xl pb-3")],[html.text("Spells")]),
    html.div([],
      model.charecter.classes
      |> dict.values
      |> list.map(fn (class) {
        html.div([attribute.class("flex flex-col gap-5")],
          class.spells
          |>  list.map(fn (spell){
            spell_view(spell,class,model)
          })
        )
      })
    )
  ])
}

fn spell_view(spell:char.Spell,class:char.Class,model:Model) {
  html.div([attribute.class("border rounded-2xl py-2 px-5")],[
    html.h1([attribute.class("pb-2 text-xl")],[html.text(spell.name)]),
    html.h1([],[html.text(string.append("level:", spell.level |> int.to_string))]),
    html.text(spell.description),
    html.h1([],[
      case spell.spell_type {
        char.FlatSave(dc:) -> html.text(string.append("dc",dc |> int.to_string))
        char.HitDc -> spell_mod_view(class,model.charecter)
        char.SpellSave(attribute:) -> spell_save_view(attribute,model.charecter) // todo
        char.Util -> element.none()
      }
    ]),
    case spell.level {
      0 -> element.none()
      _ ->  {
        // todo handle multiple levels of spell slots
        use <- error_boundery(element.none())
        use resources <- result.try(dict.get(model.charecter_state.resources,spell.resource))
        Ok(html.div([],{
          use resource <- list.map(resources)
          let txt = resource.used
          |> bool.to_string
          |> html.text // todo convert this some how kind of graphic
          html.div([],[
            html.text("Cast spell"),
            html.button([attribute.class("px-5"),event.on_click(SpendResource(spell.resource))],[html.h1([],[txt])])
          ])
        }))
      }
    }
  ])
}
//todo check if correct
fn spell_save_view(attribute:String,charecter:Charecter) {
  use <- error_boundery(element.none())
  use stat <- result.map(dict.get(charecter.stats,attribute))
  stat
  |> char.mod_formula
  |> int.add(10)
  // |> int.add(char.calculate_proficiency_bonus(charecter))
  |> int.to_string
  |> string.pad_start(3,"dc:")
  |> html.text()
}

fn spell_mod_view(class:char.Class,charecter:Charecter) {
   use <- error_boundery(element.none())
   use stat <- result.map(dict.get(charecter.stats,class.spell_casting_stat))
   stat
   |> char.mod_formula
   |> int.add(char.calculate_proficiency_bonus(charecter)) // could precalculate to avoid expensive cost
   |> int.to_string
   |> string.pad_start(5,"mod:")
   |> html.text()
}

//todo add in a way to see and edit the resources attached
fn feats_view(model:Model) {
  html.div([],[
    html.h1([attribute.class("text-2xl pb-3")],[html.text("Feats")]),
    html.h1([attribute.class("text-lg pb-10")],[html.text("charecter feats")]),
    html.div([attribute.class("flex flex-col gap-5")],{
      use feat <- list.map(model.charecter.feats |> dict.values)
      feat_view(model,feat)
    },),
    html.div([attribute.class("p-5")],[]),
    html.h1([attribute.class("text-lg pb-10")],[html.text("species feats")]),
    html.div([attribute.class("flex flex-col gap-5")],{
      use feat <- list.map(model.charecter.species.features)
      feat_view(model,feat)
    },),
  ])
}

fn feat_view(model:Model,feature:char.Feature) {
  collapsable.element([],[
      html.h1([collapsable.title()],[html.text(feature.name)]),
      html.h1([],[html.text(feature.text)]),
      {
        use <- error_boundery(element.none())
        case feature {
          char.Active(name, _text, resource_key,_func) -> {
            use resource <- result.try(dict.get(model.charecter_state.resources,resource_key))
            Ok(html.div([],{
              use resource <- list.map(resource)
              let txt = resource.used
              |> bool.to_string
              |> html.text // todo convert this some how kind of graphic
              html.button([attribute.class("px-5"),event.on_click(SpendResource(resource_key))],[html.h1([],[txt])])
            }))
          }
          _ -> Ok(element.none())
        }
      }
  ])
}


fn error_boundery(or:element.Element(a),try:fn() -> Result(element.Element(a),Nil)) {
  case try() {
    Error(_) -> or
    Ok(elm) -> elm
  }
}

fn stat_view(name:String,val:Int) {
  html.div([attribute.class("flex flex-col gap-5 border-solid border-2 rounded-2xl w-fit p-5")],[
    html.h1([attribute.class("")],[html.text(name)]),
    html.h1([attribute.class("place-self-center")],[html.text(int.to_string(val))]),
    html.h1([attribute.class("place-self-center")],[html.text(string.append("+", char.mod_formula(val) |> int.to_string))])
  ])
}





/// Re-usable ui elements in Lustre most often take the form of "view functions".
/// Because these are just Gleam functions, they can take any number of arguments
/// and often include messages or event handlers.
///
// fn view_button(on_click handle_click: msg, label text: String) -> Element(msg) {
//   html.button([event.on_click(handle_click)], [html.text(text)])
// }

/// It's common practice for view functions that never produce events to return
/// `Element(msg)` instead of `Element(Nil)`. This allows you to use these view
/// functions in other contexts, while also communicating that these cannot
/// possibly produce events: there's no way to create a `msg` from nothing!
///
// fn view_count(count: Int) -> Element(msg) {

// }
fn update_resources(used_unused) {
  case used_unused {
    #(_ as used, []) -> used
    #(_ as used, [first_unused]) -> {
      let newly_used =  char.use_resorce(first_unused)
      [newly_used,..used]
    }
    #(_ as used, [first_unused,..unused]) -> {
        let newly_used =  char.use_resorce(first_unused)
        list.flatten([[newly_used,..used,],unused])
    }
  }
}
