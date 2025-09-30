import feats
import classes/monk
import spells
import classes/warlock
import species/goliath
import char

pub fn init() {
  char.empty_sheet()
  |> char.set_info("Arene Trueherder Veomiano","she/her")
  |> goliath.cloud_goliath()
  |> char.set_stat_array(strength: 9, dexterity: 18, constitution: 14, intelligence: 10, wisdom: 14, charisma: 17)
  |> char.set_proficent(["arcana","insight","perception","stealth"])
  |> char.add_class("monk",monk.monk_lvl_1()
                            |> monk.monk_lvl_2
  )
  |> char.add_class("warlock",warlock.warlock_lvl_1([])
                              |> warlock.warlock_pact_of_the_dreadnought
                              |> warlock.pact_of_the_tomb([spells.eldritch_blast,spells.alarm,spells.detect_magic,spells.magic_stone,spells.minor_illusion,spells.hex])
  )
  |> char.add_feat(feats.lucky())
  |> char.add_feat(feats.leg_of_the_collected())
  |> char.add_feat(feats.prostetic_leg())
  |> char.init()
}
