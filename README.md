# CutScript
---
### About
A very basic functional scripting language interpreter plugin for [Godot 3.5](https://godotengine.org/), written in GDScript. The langauge supports basic variable assignment, and *instruction* calls with instructions defined in a similar fashion as a signal calls.

The purpose for the language is to allow creating broader actions, like a cutscene, without having to strictly code all cutscene actions in GDScript.

**This project is in very early stages! Use are your own risk!**

### Installation
Clone the github repository and copy the *addon/cut_script* folder into the base directory of your Godot project. Within your project settings, go to the *Plugins* tab and enable the *CutScript* plugin.

### How to use
Once enabled, scripts written with the extension *.cut* (these are just text files) can be used like any Resource in Godot.

When selecting the *CutScript* resource, a script editor will become available allowing for the script to be changed in editor without external tools.

### Script Example
```
; Comments start with a semi-colon and take up the rest of a line

variable1 = 5 ; Variable declaration

func_call 5 "string" true ; This is an instruction call
```

### Known Bugs
There exists an issue in Godot where upon saving a script, the following message appears...
```
 editor/editor_file_system.cpp:1724 - BUG: File queued for import, but can't be imported!
 editor/editor_file_system.cpp:1725 - Method failed.
 modules/gdscript/gdscript.cpp:572 - Condition "!p_keep_state && has_instances" is true. Returned: ERR_ALREADY_IN_USE
```

At present, I have not been able to work around this bug, however, early testing shows the resource does save successfully.