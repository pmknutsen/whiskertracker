WT can run your own functions that work on data in the currently
loaded WT datafile. You can access this feature via the WT menu
item Options -> Run function...

Your script should be formatted as a Matlab function, WT will
pass a structure that contains all data in the currently loaded
.mat file. Thus, your function should start with the following
line:

function my_function_name(sStruct)

where my_function_name can be replaced by a name you choose and
sStruct will be the input structure that contains all WT data.

This scripting feature is a convenient and quick way of adding your
own functionality to the WT GUI.

See the main documentation for more information.


