version=1.0.0

# Convergence Warrior Bot Command Guide

### Start Script
- Command: `/lua run ConvWAR`
- Description: Starts the Lua script Convergence Warrior.

## General Bot Commands
These commands control general bot functionality, allowing you to start, stop, or save configurations.

### Toggle Bot On/Off
- Command: `/ConvWAR Bot on/off`
- Description: Enables or disables the bot for automated functions.

### Toggle Exit
- Command: `/ConvWAR Exit`
- Description: Closes the bot and script.

### Save Settings
- Command: `/ConvWAR Save`
- Description: Saves the current settings, preserving any configuration changes.

---

## Camp and Navigation
These commands control camping behavior and movement options.

### Set Camp Location
- Command: `/ConvWAR CampHere on/off/<distance>`
- Description: Sets the current location as the designated camp location, enables or disables return to camp, or sets a camp distance.
- Usage: `/ConvWAR CampHere 50` sets a 50-unit radius camp.

### Toggle Chase Mode
- Command: `/ConvWAR Chase <target> <distance>` or `/ConvWAR Chase on/off`
- Description: Sets a target and distance for the bot to chase, or toggles chase mode.
- Example: `/ConvWAR Chase John 30` will set the character John as the chase target at a distance of 30.
- Example: `/ConvWAR Chase off` will turn chasing off.

---

## Combat and Assist Commands
These commands control combat behaviors, including melee assistance and target positioning.

### Set Assist Mode
- Command: `/ConvWAR Assist on/off` or `/ConvWAR Assist <range> <percent>`
- Description: Toggles assist mode on or off, or configures assist mode with a specified range and health percentage threshold.
- Examples:
  - `/ConvWAR Assist on`: Enables assist mode.
  - `/ConvWAR Assist off`: Disables assist mode.
  - `/ConvWAR Assist 50 75`: Sets assist range to 50 and assist health threshold to 75%.

### Set Tank Mode
- Command: `/ConvWAR Tank on/off` or `/ConvWAR TankRange <range>`
- Description: Toggles tank mode on or off, or defines the tank's engagement range.
- Examples:
  - `/ConvWAR Tank on`: Enables tank mode.
  - `/ConvWAR Tank off`: Disables tank mode.
  - `/ConvWAR TankRange 30`: Sets the tank range to 30.

### Set Stick Position (Front/Behind)
- Command: `/ConvWAR Melee front/behind <distance>`
- Description: Configures the bot to stick to the front or back of the target and specifies a stick distance.
- Example: `/ConvWAR Melee front 10`

### Set Switch With Main Assist
- Command: `/ConvWAR SwitchWithMA on/off`
- Description: Enables or disables switching targets with the main assist.

---

## Pulling and Mob Control
These commands manage mob pulling and control within the camp area.

### Tank Ignore List Control
- Command: `/ConvWAR TankIgnore zone/global add/remove`
- Description: Adds or removes the target to/from the tank ignore list, either zone-specific or global.