# AnomalusCheck

A lightweight vanilla WoW addon for checking raid members' Arcane Resistance for the Anomalus encounter.

## Features

- Checks all raid/party members for Arcane Resistance
- Shows who meets the 200+ AR requirement (green) and who doesn't (red)
- Simple, clean UI with sortable results
- Works in both raids and parties
- Minimal performance impact

## Installation

### For Turtle WoW:

1. Copy the `AnomalusCheck` folder to your `TurtleWoW/Interface/AddOns/` directory
2. Restart WoW or reload UI with `/reload`
3. Make sure "Load out of date AddOns" is checked in the AddOns menu

### For Regular Vanilla/Classic:

1. Copy the `AnomalusCheck` folder to your `World of Warcraft/Interface/AddOns/` directory
2. Restart WoW
3. Enable the addon in the character select screen

## Usage

### Commands:
- `/ac` or `/anomalus` - Perform an arcane resistance check
- `/ac show` - Show the results window
- `/ac hide` - Hide the results window

### How It Works:

1. All raid members need to have the addon installed
2. Raid leader or raid assistant runs `/ac` or clicks the "Refresh" button
3. The addon queries all raid members who have AnomalusCheck installed
4. Results display in a window showing:
   - **Green names**: Players with 200+ AR (ready for Anomalus)
   - **Red names**: Players below 200 AR (need more resistance gear)
   - Summary count at the top

### Notes:

- Only raid leaders and raid assistants can initiate checks in raids
- In parties, anyone can initiate a check
- Players without the addon installed won't show up in results
- The UI window is draggable - click and drag to move it

## Requirements

- WoW 1.12.1 client (Vanilla)
- All raid members should have the addon installed for best results

## Support

For bugs or feature requests, contact Fayz on Turtle WoW or submit an issue on GitHub.

## Version History

**v1.0** - Initial release
- Basic arcane resistance checking
- Simple UI display
- Raid and party support
