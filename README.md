![Header](https://imgur.com/HtBLX4O.png)
A spreadsheet directly in the Godot editor for quick and easy data management and storage.
With Godot Sheets, you don't have to use third-party apps like Excel or Google Sheets when making spreadsheet-like data structures. Now you can do it directly in the editor.

This addon is still very work in progress and should be considered a proof of concept at this stage. Add it and test it out, but don't use it in real projects yet.

After enabling the addon a "Sheets" section will be available at the top of the editor.

![New Sheets section tab](https://imgur.com/8s33ANy.png)

From there you can add data sheets (for example, "Weapons", "EnemyData", "Items", etc.) and start adding data to them.

Godot Sheets is made for data management so each data point has a unique ID (left column) and a unique Header (top row). Use these unique identifiers to get the data when you need it in code.

![Example use](https://imgur.com/tH4cA5V.png)

How to use
----------
To get the data from within a script you can either call for it directly or iterate over the IDs.

![Code example](https://imgur.com/GewpxyE.png)

First load the sheet with GDSheets.sheet("Sheet Name"). Then you can access the data by entering [ID][Header]

This is a very early version of this addon, and should not be used in real projects yet. There are still lots of bugs and I had to down-scope a great deal to make it for the Godot Addon Jam. Moving on I will work on:

* Basic UX features (insert and move rows and columns, move between cells, sheets management, zooming, etc., etc.)
* Accept different data types (integers, floats, strings, etc). Perhaps even arrays and objects.
* Write data from script. Today only reading is possible.
* Export and import CSV (maybe JSON)
* Stability and bug fixes, refactoring code
* more...
