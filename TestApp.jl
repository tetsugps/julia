module TestApp

Base.eval(Main, :(const UserApp = TestApp))

include("genie.jl")

Base.eval(Main, :(const Genie = TestApp.Genie))
Base.eval(Main, :(using Genie))

using Genie, Genie.Router, Genie.Renderer, Genie.AppServer

end
