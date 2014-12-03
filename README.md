###WhiskerTracker

WhiskerTracker is a Matlab based application for tracking **head**, **whisker** and **limb** movements in high-speed movies of freely moving or restrained rodents. 

Multiple tracking modes are supported through a graphical user interface with a small screen footprint. Choose from many pre-processing routines to track any high-speed movie automatically. Manual error correction is built-in.

Increase tracking speeds significantly by batch processing simultaneously with multiple WhiskerTracker instances running on different computers and CPU cores.

###Features
* Cross-platform (Windows and Linux)
* Simple graphical user interface
* Automated and manual tracking
* Many tracking modes
    * Track whisker shafts in a 2D view
    * Track head, whisker and limb movements in 'labeled dot' mode
* Track in freely-moving or restrained rodents
* High sensitivity (sub-degree movements)
* Data analysis tools
* Pre-processing options (transformations, ROI, background subtraction etc)
* Extendible through custom scripts
* Annotations
* Batch processing
* Multithreaded (requires the Parallel Processing Toolbox)

###Usage examples
* Track the entire shaft of unlabeled whiskers/vibrissae
* Label joints to track movements and rotations fore- and hindlimbs
* Label head in 3 locations and track head movements.

![Screenshot:](https://github.com/pmknutsen/whiskertracker/blob/master/examples/LimbTracking.png =100x "Screenshot - Limb tracking")

###System Requirements
* Matlab 2012b or higher recommended (will also run on 6.1 or higher)
* Statistics Toolbox
* Parallel Processing Toolbox (recommended)

Compiled 32 and 64 bit binaries are included for Windows and Linux.

Source code is included for the impatient and adventurous that would like to port binaries to Mac.

Note that many features of the application does not depend on the compiled parts of the code and will run on any operating system.

###Report bugs
Please report errors, bugs and feature requests using the Issues tracker:
https://github.com/pmknutsen/whiskertracker/issues.

###Reference
Please cite the following reference in any publication using this work:
>Knutsen, Derdikman & Ahissar (2005) “Tracking Whisker and Head Movements in Unrestrained Behaving Rodents.” Journal of Neurophysiology 93 (4) 2294–301.

###License
This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.
