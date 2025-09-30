import gleam/io
import gleam/option
import gleam/dict
import char
pub fn lucky() {
  //tood we never added the resources
  char.Active(
    name: "lucky",
    text: "You have 2 Luck Points that you can spend on the benefits below. You regain expended Luck Points after a Long Rest.",
    resource: "luck points",
    func: fn(charecter,state) {
      echo "applying the lucky points"

      #(charecter,char.CharecterState(..state,resources:dict.insert(state.resources,"luck points",[char.Generic(False),char.Generic(False)])))
    }
  )
}

//todo add the leg with halfing the modifyer
pub fn leg_of_the_collected() {
  char.PassiveModification(
    name: "leg of the collected",
    text: "your move speed is halved",
    func: fn (char,state) {
      #(char,char.CharecterState(..state,speed:state.speed/2))
    }
  )
}

pub fn prostetic_leg() {
  char.PassiveModification(
    name: "This leg is to replace the collected leg.",
    text: "crewed steel but it works",
    func: fn (char,state) {
      //todo check if the leg of the collected feat is active
      // check if the item is in the invantory
      #(char,char.CharecterState(..state,speed:state.speed*2))
    }
  )
}
