# FS25_UniversalAutoload
---------------------------------------------------
DEVELOPMENT RELEASE - Please test and leave any bug reports or feedback.
---------------------------------------------------

SUMMARY:
- Single player is working as it should for BALES, PALLETS and BIG-BAGS
- Multiplayer loads without crashing so far BUT I have only done basic testing. **USE AT YOUR OWN RISK**
- Any new vehicles will get autoload after purchasing in the shop (see below)
- Any valid vehicles in a savegame will load settings if available

---------------------------------------------------
NEW FEATURES:
- All pallets, big-bags and bales supported by default
- Automatic detection of trailer loading zones (in shop)
- UI to adjust size of loading zone in shop before purchase
- No external configuration files required!!

---------------------------------------------------
TO CONFIGURE LOADING ZONES:
- Use middle mouse click in the shop to activate editing
- Right click drag to move individual faces
- ALT-right click drag to move opposing faces (**use this for width**)
- SHIFT-right click drag to move the whole zone
- CTRL with any of the above for fine control
- SHIFT-CTRL middle mouse click to auto-calculate the zone from scratch (if you mess up)
- Configuration can be edited in mod settings XML (if you know what you are doing)

---------------------------------------------------
PLANNED FEATURES:
- Menu for global settings (in shop)
- Set vehicle options in the shop before purchase
- Reconfigure vehicles in the workshop
- Bale collection mode
- Log trailers (can be configured, but do not load anything yet)
- Multiplayer synchronisation of settings
- Show debugging display in multiplayer
- Custom key bindings

---------------------------------------------------
KNOWN ISSUES:
- Existing trailers on a savegame will not get autoload added (until restart with valid settings)
- Editing/customising a vehicle in the **workshop** has no effect on the real vehicle
- Object positions slow to update in multiplayer
- Trigger detection of objects is poor in multiplayer (it helps to move them)
- No saving of vehicle configurations when saving multiplayer games