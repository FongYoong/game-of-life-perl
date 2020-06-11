# Conway's Game of Life - Perl
- [Conway's Game of Life - Perl](#conways-game-of-life---perl)
- [Prerequisites](#prerequisites)
- [Scripts](#scripts)
  - [GOL_Grid](#gol_grid)
  - [GOL_Playground](#gol_playground)
  - [GOL_Logic_Gates](#gol_logic_gates)
  - [GOL](#gol)

# Prerequisites
* [Tk (CPAN)](https://metacpan.org/pod/Tk)
    - For installation, Debian users may benefit from the following: ```sudo apt-get install perl-tk```
* [OpenGL (CPAN)](https://metacpan.org/pod/OpenGL)
    - Note: OpenGL libraries must be installed first before installing this Perl module.

***
# Scripts
The sections below briefly describe the Perl scripts respectively.

## GOL_Grid
This script is located in the **_modules_** folder and manages the implementation of the game. Structurally, it is actually a Perl module which can be used to instantiate a quasi-object which manages the game state.

The object manages a 2D array which stores the live/dead states of each cell. Another 2D array is also allocated to store the states of the previous iteration. When updating the grid, it initially uses the naive method of checking every state of the grid. This incurs a peformance hit for substantially large grids due to the <img src="https://render.githubusercontent.com/render/math?math=O(n^2)"> complexity. To soften the impact, the object obtains the smallest area covering all the live cells and only checks the cells in this area. It is a quick hack which still performs terribly under certain conditions. Only a superior algorithm which effectively compartmentalises the grid into many regions such as [Hashlife](https://www.drdobbs.com/jvm/an-algorithm-for-compressing-space-and-t/184406478) can adapt to expanding grid sizes.

There are two possible behaviours in regards to the cells at the border of the grid. This is imperative because the neighbours of these cells can be outside the grid.
* Wrap-Around
    - Assume that corresponding cells in the other extreme end of the grid will constitute the "outside" neighbours.
* Destroy At Border
    - The "outside" neighbours are "destroyed" in the sense that they are always assumed to be dead. Hence, the grid can be thought of as surrounded by an instant-death zone.

## GOL_Playground
This script serves up a user interface (UI) using **Tk** and displays a grid. The UI is basically a "playground" whereby the user can experiment with the game and change various parameters. Possible actions include:
* Adding and removing live cells (**Mouse Click** to add, **X** to remove)
* Adding hardcoded presets such as gliders, guns etc
* Save/Load grid configuration
* Change border behaviour (as described in [GOL_Grid](#gol_grid))
* Display grid in terminal or **Tk** canvas or both

The code below at the top of the script is meant to locate the **_modules_** folder so that **_GOL_Grid_.pm** can be included.
```perl
use Cwd qw(abs_path);
use FindBin;
use lib abs_path("$FindBin::Bin/modules");
```

## GOL_Logic_Gates
This script was initially intended to showcase the generation of GOL-flavoured logic gates comprising of cellular guns. However, time constraints have limited its use to a pathetic single Boolean expression. Although its UI is almost identical to [GOL_Playground](#gol_playground), it permanently prevents cells from crossing the border and does not allow the user to change the behaviour so that the gliders do not interfere with the guns.
More info on the subject can be found at [Link 1](https://www.springer.com/gp/book/9781852335403), [Link 2](https://www.youtube.com/watch?v=vGWGeund3eA) and [Link 3](https://nicholas.carlini.com/writing/2020/digital-logic-game-of-life.html).


## GOL
This script acts as a "glue" which enables users to easily access either [GOL_Playground](#gol_playground) or [GOL_Logic_Gates](#gol_logic_gates). It also parses command-line arguments which are appropriately channeled to the target script.

