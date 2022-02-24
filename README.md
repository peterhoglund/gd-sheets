![Header](https://imgur.com/HtBLX4O.png)
A spreadsheet directly in the Godot editor for quick and easy data management and storage.
With Godot Sheets, you don't have to use third-party apps like Excel or Google Sheets when making spreadsheet-like data structures. Now you can do it directly in the editor.

**_This addon is work in progress. Add it and test it out, but don't use it in real projects yet._**
Version 0.2 Alpha has focused on implementing basic interactions with the cell grid: inserting, moving, resizing and removing rows/columns, as well as better movement between and editing of cells. The interactions try to mimic Google Sheet and should be familiar to many users.

Install
-------
Download and add to your Godot project's addon-folder. After enabling the addon (from Project Setting's Plugin tab) a "Sheets" section will be available at the top of the editor.

![New Sheets section tab](https://imgur.com/8s33ANy.png)

From there you can add data sheets (for example, "Weapons", "EnemyData", "Items", etc.) and start adding data to them.

Godot Sheets is made for data management so each data point has a unique ID (left column) and a unique Header (top row). Use these unique identifiers to get the data when you need it in code.

![Example use](https://imgur.com/tH4cA5V.png)

How to use
----------
To get the data from within a script you can either call for it directly or iterate over the IDs.

![Code example](https://imgur.com/GewpxyE.png)

First load the sheet with 
`GDSheets.sheet("Sheet Name")`. 

Then you can access the data by entering `[ID][Header]`
Get all IDs by iterating `.values()` of the data (like a `Dictionary`).


Future releases
---------------
This is a very early version of this addon. Moving on I will work on:

* Use VisualServer for cells instead of nodes, to hopefully make larger sheets faster.
* Multiline editing in cells.
* Accepting different data types (integers, floats, strings, etc). Perhaps even arrays and objects.
* Write data from script. Today only reading is possible.
* Export and import CSV (maybe JSON)
* more...


Known issues in this version
----------------------------
* Has only been tested with Godot 3.4.1 on Mac (with HiDPI screen)
* Large sheets are slow to process in the editor.
* All data is one line only (since it uses LineEdit)
