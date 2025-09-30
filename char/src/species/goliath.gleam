import gleam/option
import gleam/dict
import char

pub fn cloud_goliath(charecter:char.Charecter) {
  char.Charecter(
    ..charecter,
    species: char.Species(
      name: "Cloud Goliath",
      features: [
        char.Passive(
          name: "Powerful Build",
          text: "You have Advantage on any ability check you make to end the Grappled condition. You also count as one size larger when determining your carrying capacity.",
        ),
        char.Active(
          name: "Cloud’s Jaunt (Cloud Giant)",
          text: "As a Bonus Action, you magically teleport up to 30 feet to an unoccupied space you can see.",
          resource: "Cloud’s Jaunt (Cloud Giant)",
          func: fn(charecter,state) {
            #(charecter,char.CharecterState(..state,resources:dict.insert(state.resources,"Cloud’s Jaunt (Cloud Giant)",[char.Generic(False),char.Generic(False)])))

          }
        )
      ],
      spells: [
      ],
      speed: 35,
    ),
  )
}
