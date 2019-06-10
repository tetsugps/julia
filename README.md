![Genie Logo](https://dl.dropboxusercontent.com/s/0dbiza50r63cvvc/genie_logo.png)

Code for sample app presented here:
https://github.com/genieframework/Genie.jl/blob/master/docs/content/Working_with_Genie_apps/index.md

## Instructions:
1. clone the repo: `$ git clone https://github.com/genieframework/Genie-Searchlight-example-app.git`
2. in a terminal, `cd` to the app's folder: `$ cd Genie-Searchlight-example-app/`
3. start a Julia REPL session in the app's root: `$ julia` (or on Windows,
  if you don't have Julia in your path, you will have to start a new Julia session and then
  `julia> cd(...)` into the app's root).
4. `julia> ]` to enter `Pkg` mode
5. `pkg> activate .`
6. `pkg> instantiate` to download the dependencies for the project

## Starting the app
Once all the dependencies have been installed please run:
1. `julia> using Genie # bring Genie into scope`
2. `julia> Genie.REPL.write_secrets_file() # needed to set up the encryption key`
3. `julia> Genie.loadapp() # load the web app environment`
4. `julia> Genie.startup() # start the web app`

After a few seconds you should get a message letting you know that the app can
now be accessed in the web browser, by default at `http://localhost:8000`

## Restarting the app
Later on you can load your Genie app in the OS terminal by running in the app's folder:

`$ bin/repl # to start an interactive REPL session`
and then 
`julia> Genie.startup() # to start the web server`

Or directly start the web app at the OS terminal:
`$ bin/server # will start the web app non-interactively`

## Questions?
For more info about running and building Genie apps please follow the Genie README:
* https://github.com/genieframework/Genie.jl/blob/master/README.md

For a step-by-step tutorial of how this app is built go to:
* https://github.com/genieframework/Genie.jl/blob/master/docs/content/Working_with_Genie_apps/index.md
(Work in progress)
