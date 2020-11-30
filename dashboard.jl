using Genie, Genie.Router, Genie.Renderer.Html, Stipple

# define (reactive) model
Base.@kwdef mutable struct Name <: ReactiveModel
    name::R{String} = "World!"
end

# initialize the model
model = Stipple.init(Name)

# define UI
function ui()
    page(
    root(model), class="container", [
      h1([
        "Hello "
        span("", @text(:name); style="color:red")
      ])

      p([
        "What is your name? "
        input("", placeholder="Type your name", @bind(:name))
      ])
    ], title="Basic Stipple"
  ) |> html
end

# bind root "/" to ui
route("/", ui)

# start web server
# up()