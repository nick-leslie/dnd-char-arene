import gleam/string_tree
import charecters/arene
import char
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/http.{Get, Post}
import gleam/json
import gleam/result
import lustre/attribute
import lustre/element
import lustre/element/html
import mist
import wisp.{type Request, type Response}
import wisp/wisp_mist
import frontend
import simplifile


pub fn main() {
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)



  let static_directory = "frontend/priv/static"

  let assert Ok(_) =
    handle_request(static_directory, _)
    |> wisp_mist.handler(secret_key_base)
    |> mist.new
    |> mist.port(3000)
    |> mist.start

  process.sleep_forever()
}

fn app_middleware(
  req: Request,
  static_directory: String,
  next: fn(Request) -> Response,
) -> Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.serve_static(req, under: "/static", from: static_directory)

  next(req)
}


fn handle_request(
  static_directory: String,
  req: Request,
) -> Response {
  use req <- app_middleware(req, static_directory)

  case req.method, wisp.path_segments(req) {


    // Everything else gets our HTML with hydration data
    Post, [] -> {
        use json <- wisp.require_json(req)
        decode.run(json,char.charecter_state_decoder())
        |> result.replace_error(wisp.bad_request())
        |> result.map(save)
        |> result.replace_error(wisp.internal_server_error())
        |> result.replace(wisp.ok())
        |> result.unwrap_both()
    }
    Get, [] -> serve_index()
    Get, ["char"] -> {
      load()
      |> result.map(string_tree.from_string)
      |> result.map(wisp.json_response(_,200))
      |> result.unwrap(wisp.internal_server_error())
    }

    // Fallback for other methods/paths
    _, _ -> wisp.not_found()
  }
}

fn save(char:char.CharecterState) {
  char.charecter_state_to_json(char)
  |> json.to_string()
  |>  simplifile.write("./arene.json",_)
}
fn load() {
  simplifile.read("./arene.json")
}

fn serve_index() -> Response {
  let #(charecter,_state) = arene.init()
  //todo this is bad its alot of waisted time just to validate that the file is json make this quicker
  // just extract the string out and validate it then discard no need to re apply.
  // you can use result map to flaten
  let assert Ok(state) = load()
  |> result.map(json.parse(_,char.charecter_state_decoder()))
  |> result.replace_error(json.UnableToDecode([]))
  |> result.flatten
  let init_json = char.charecter_state_to_json(state) |> json.to_string
  let model = frontend.Model(charecter,state,Ok(0))
  let content = // piped into from frontend
    frontend.view(model)
  let html =
    html.html([], [
      html.head([], [
        html.title([], "Dnd Char"),
        html.script(
          [attribute.type_("module"), attribute.src("/static/frontend.mjs")],
          "",
        ),
        html.link([
          attribute.href("/static/frontend.css"),
          attribute.rel("stylesheet"),
        ]),
        html.script(
          [attribute.type_("application/json"), attribute.id("model")]
          ,init_json
        ),
      ]),
      html.body([], [html.div([attribute.id("app")], [
        content
      ])]),
    ])

  html
  |> element.to_document_string_tree
  |> wisp.html_response(200)
}
