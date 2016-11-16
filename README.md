# MagnetExperiment - Experiment VR with magnets

This project shows a way to use magnets as a joystick on a Google Cardboard.
The minimum hardware you will be required to have to properly try it out is an iPhone, a Google Cardboard that works without magnets, two small magnets, a piece of checkered paper, and some scotch.

## Hardware setup

Use your checkered paper to make a 3x3 grid on which you will move your outside magnet. Fix it on one of the sides of the Cardboard.


## How to run the project

CocoaPods is used for the project, you will need to use it to run the project. (https://guides.cocoapods.org/using/getting-started.html)

To make the magnet work, you will need to calibrate it at the start of the application.
Then, when the app is launched, move your magnet to the top-left position, tap on the screen (this should trigger a log with the components of the magnetic field vector). Then move it to the top-middle position, repeat, etc. The final order of tapping should be :
1 2 3
4 5 6
7 8 9
Then, you should be able to pick one of the two elements in the menu by moving forward or backward the magnet. On the selection is made, tap on the screen, and you should be able to either fly in the app or do a bit of bobsleigh!


