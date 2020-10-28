# slipbox-ui

This project's purpose is to make it as easy as possible to take notes in the slipbox note-taking system and get value from it.


### Installation

To run this repo, please follow the instructions at this url to download elm for your respective os. 

https://guide.elm-lang.org/install/elm.html

Then you should be able to run `elm reactor` on the command line to run the project and access it at localhost:8000

### To run locally 

elm make src/Main.elm

http-server --proxy http://localhost:8080?

### To do

I want to try releasing this to the public by December 1st, 2020. To do that I think I need to do the following:
- Hosted by us source summary solution integrated into UI/SPA - 10/25 in progress
- Refactor the User Experience to be
  - SPA
  - Responsive Design to include Mobile
  - More intuitive interface to take notes
- Figure out a way to export data
- Authentication (MFA?)
- Multi-User architecture change + data migration
- Home/Splash page educating about how to use note taking system and benefits
- Deployment pipeline?
