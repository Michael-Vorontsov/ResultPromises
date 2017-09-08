#  ResultPromises iOS example

Application designated to illustrate how promises working. It shows list of users with avatars. Pull to reload gesture avaialble.
Each 5th attempt to reload will produce error.

ViewController intitiate loading list of users from network.
It is using URLRequest extension to generate URL request using,

* then
It is using URLSession extention to load array of users in one call.

* then
It is waiting for 2 seconds to present activity indicator for user. (can be very usefull while debuging)

* then
It check how many time data rloaded, and emmit error on each 5th attempt

## Avatars

Similar mechanism used for loading images for avatars.
