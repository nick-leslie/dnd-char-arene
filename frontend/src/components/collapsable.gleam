import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/int
import lustre
import lustre/attribute.{type Attribute, attribute}
import lustre/component
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

// MAIN ------------------------------------------------------------------------

//
pub fn register() -> Result(Nil, lustre.Error) {
  let component = lustre.simple(init, update, view)

  // The `register` function does not create an app directly, instead it registers
  // a Lustre app as a Custom Element with the name `"my-counter"`. The main app
  // can then render this component like any other HTML element.
  lustre.register(component, "collapsable-element")
}

/// It's good practice to provide an `element` function that encapsulates the
/// underlying element construction: this way users don't have to remember the
/// exact name of the component.
///
pub fn element(attributes,children) -> Element(msg) {
  element.element("collapsable-element", attributes, children)
}

pub fn title() -> Attribute(msg) {
  component.slot("title")
}
// MODEL -----------------------------------------------------------------------

/// The state for our component will never leak outside the component itself.
/// It's encapsulated the same way internal state for native HTML elements is.
///
type Model =
Bool

fn init(_) -> Model {
  False
}

// UPDATE ----------------------------------------------------------------------

/// Just like our component's `Model`, the `Msg` type is also private to the
/// component and doesn't need to be handled by the parent app. This makes it
/// convenient to use components to encapsulate complex functionality and rich
/// user interaction patterns without complicating the parent app.
///
type Msg {
  ToggleCollaps
}


fn update(model: Model, msg: Msg) -> Model {
  case msg {
    ToggleCollaps -> !model
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("")], [
    html.div([attribute.class("flex flex-row gap-5")],[
      component.named_slot("title",[],[html.text("title fallback ")]),
      html.button([event.on_click(ToggleCollaps)],[
        html.h1([],[html.text("fold")])
      ]) // todo
    ]),
    case model {
        True -> component.default_slot([],[])
        False -> element.none()
    }
  ])
}
