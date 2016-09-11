% Brick, also called "fn toolbox" is a set of useful general functions for Matlab
% Version 1.1   04-Mar-2012
% 
% ARRAY MANIPULATION
% - indices manipulation
%   fn_indices        - Convert between global and per-dimension indices 
%   fn_mod            - Return modulus between 1 and n instead of between 0 and n-1
%   fn_reshapepermute - Combination of reshape and permute in a single function call
%   fn_interleave     - Interleave data 
%   fn_add            - Add arrays whose dimensions only partially match
%   fn_mult           - Multiply arrays whose dimensions only partially match
%   fn_sizecompare    - Check whether two size vectors are equivalent
% - data operation
%   fn_bin            - Data binning
%   fn_round          - Round x to the closest multiple of y
%   fn_coerce         - Restrict data to a specific range
%   fn_clip           - Rescale data, restrict the range, color
%   fn_normalize      - Normalize data based on averages in some specific dimension
%   fn_smooth         - 1D or 2D smoothing using Gaussian convolution
%   fn_smooth3        - 3D smoothing using Gaussian convolution
% - interpolation
%   fn_decale         - Interpolate a translated vector
%   fn_translate      - Interpolate a translated image or movie
%   fn_interprows     - Realign temporally the frames of a raster scan movie 
%   fn_gettrend       - Remove signals modelled by specific low-frequency regressors  
%   fn_register       - Coregister frames of a movie
% - min, max, mean,...
%   fn_max            - Global maximum of an array and its coordinates
%   fn_min            - Global minimum of an array and its coordinates
%   fn_minmax         - Basic min/max operations (e.g. intersection of 2 ranges)
%   fn_localmax       - Find local maxima in a vector 
%   fn_means          - Average the successive argumments
%   fn_meanc          - Return mean and alpha level confidence interval
%   fn_meanangle      - Average of angles (result in [-pi pi])
%   fn_meantc         - Average time course of a movie
%   fn_trigger        - Do trigger-averaging of movie
% - other
%   fn_sym            - Convert a symmetric matrix to a vector and vice-versa
%   fn_timevector     - Convert set of times to vector of counts and vice-versa
%
% Matlab types
% - conversions
%   fn_num2str        - Convert numeric to char, unless input is already char!
%   fn_str2double     - Convert to numeric if not already numeric
%   fn_str2struct     - Evaluate strings that define a structure
%   fn_struct2str     - Convert a structure to strings that define it
% - structures
%   fn_structdisp     - Recursive display of a structure content
%   fn_structedit     - Edit a structure; this is a wrapper of fn_control
%   fn_structexplore  - Navigate using command line inside a large structure
%   fn_structmerge    - Merge two structure
% 
% MATHEMATICS
% - shortcuts
%   fn_fit            - Shortcut for using Matlab fit function 
% - tools
%   fn_fftfrequencies - Frequencies corresponding to the output of Matlab fft function
% 
% PROGRAMMING
% - shortcuts
%   fn_switch         - Shortcut for avoiding using if/else and switch 
%   fn_isemptyc       - Which elements of a cell array are empty
%   fn_disp           - Display multiple arguments
%   fn_dispandexec    - Display commands in Matlab and executes them 
%   fn_subsref        - Shortcut for calling Matlab subsref function
%   fn_ismemberstr    - Check whether string is part of a set of strings
%   fn_flags          - Detect flags in the arguments of a function 
%   fn_map            - Apply a given function to the elements, columns or rows of an array
% - tools
%   fn_progress       - Print the state of a calculation 
%   fn_hash           - Unique hash number for an array/cell/structure (Copyright M Kleder)
% - debuggingv
%   fn_dbstack        - Display current function name, with indent according to stack length 
%   fn_basevars       - Load base workspace variables in caller workspace and vice-versa 
%
% FILES
% - shortcuts
%   fn_cd             - User definition of shortcut to fast access directories
%   fn_fileparts      - Get specific file parts  
%   fn_ls             - Return folder content
%   fn_mkdir          - Create a directory if does not exist
%   fn_movefile       - Rename files in current directory using regular expression
% - user selection
%   fn_getfile        - Select file and remember the containing folder of the last selected file 
%   fn_savefile       - User select file for saving and remember last containing folder 
%   fn_getdir         - Select directory and remember last containing folder 
% - input
%   fn_readtext       - Read text file
%   fn_readasciimatrix      - Read 2D array from text file
%   fn_readbin        - Read binary file containing some header followed by numerical data
%   fn_readdatlabview - Read binary matrix (Labview format: nrow, ncol and then data)
%   fn_readimg        - Read image
%   fn_readmovie      - Read AVI movie
%   fn_readmesh       - Read surface mesh from file (Anatomist format)
%   fn_readtexture    - Read surface texture from file (Anatomist format)
%   fn_readxml        - Read XML file (Copyright Jarek Tuszynski)
%   fn_readxmllabview - Read Labview data saved in XML format
% - output
%   fn_savetext       - Save text in text file
%   fn_saveasciimatrix      - Save 2D array in text file
%   fn_saveimg        - Save image or stack of images, options for clipping, color map...
%   fn_savemovie      - Save a movie into an AVI file
%   fn_savemesh       - Save surface as a mesh (Anatomist format)
%   fn_savetexture    - Save surface texture (Anatomist format)
%   fn_savexml        - Save a structure in an XML file (Copyright Jarek Tuszynski)
%   fn_savefig        - Save figure with possibility to control the output size
%   linux_savefig     - Save a figure exactly as it is by calling system operator function
%
% IMAGE OPERATION
% - basic operations
%   fn_imvect         - Convert an image to a vector of pixels inside a mask, and vice-versa 
%   fn_imageop        - Apply a series of transformations to an image 
%   fn_maskavg        - Cluster pixels in an image or movie
% - GUI programs
%   fn_maskselect     - Manual selection of a mask inside an image
%   fn_subrect        - Manual selection of a rectangular mask inside an image
%   fn_alignimage     - Manual alignment of 2 images
%   fn_color2bw       - Reduce color to grayscale image while keeping as much information 
%
% DATA DISPLAY
% - shortcuts
%   fn_drawpoly       - Shortcut for line(poly(:,1),poly(:,2))
%   fn_isfigurehandle - Is handle a plausible figure handle
% - general tools
%   fn_colorset       - Set of color, alternative to Matlab default 'ColorOrder' 
%   fn_lines          - Draw a series of vertical and/or horizontal lines
%   fn_review         - Navigate with arrow keys inside a set of data
%   fn_review_showres - function called by fn_review; can be edited by user
% - time courses displays
%   fn_errorbar       - Display nice error bars 
%   fn_drawspline     - Fit a curve using splines with movable control points 
%   fn_eegplot        - Display multiple time courses with a small gap between each of them 
%   fn_eegdisplay     - Joint image and time courses display of 2D data
%   fn_regression     - Display of data points together with linear regression
%   fn_rasterplot     - Raster plot display (display of punctual events as small bars)
% - time courses tools
%   fn_axis           - Set axis range for a better visual aspect than 'axis tight' 
%   fn_nicegraph      - Improve aspect of graph display
%   fn_labels         - Improve aspect of a graph display and add labels and more
%   fn_plotscale      - Two-directional scale bar for graph display
%   fn_linespecs      - Handle abbreviated plot options (e.g. 'r.') 
% - 2D displays
%   fn_displayarrows  - Display an image and a velocity field on top of it 
%   fn_tensordisplay  - Display of a field of 2x2 symmetric matrices using ellipses
%   fn_framedisplay   - Sequential display of frames from a movie 
% - 2D tools
%   fn_axispixel      - Set axis size for an optimal display of images 
%   fn_imdistline     - Show the distance between two points (Copyright The MathWorks)
%   fn_scale          - Scale bar for image display
%   fn_showcolormap   - Display a color map
% - movie displays
%   fn_playmovie      - Simple showing of a movie
%   fn_movie          - Show a movie, large number of options
% - mesh computations and displays
%   fn_meshclosestpoint     - Closest vertex on a mesh to a given point
%   fn_meshinv        - Invert the orientation of faces 
%   fn_meshnormals    - Compute the normals to faces of a mesh
%   fn_meshplot       - Display a mesh
%   fn_meshselectpoint      - Display a mesh and let user select a point with mouse
%   fn_cubemesh       - Render the "faces" of a 3D data (creates a mesh and texture) 
%   fn_cubeview       - Render the "faces" of a 3D data (creates an image)
% - elaborate programs
%   fn_imvalue        - Automatic link graphs and images for point selection and zooming
%   fn_4Dview         - Navigation inside 3D, 4D or 5D imaging data
%
% GUI PROGRAMMING
% - shortcuts
%   fn_evalcallback   - Evaluate a callback, i.e. a char array, function handle or cell array 
%   fn_multcallback   - Apply several callback functions to an object
%   fn_get            - Get mutiple properties of multiple objects at once 
%   fn_set            - Set simultaneously multiple properties of multiple graphic objects
% - tools
%   fn_pixelpos       - Position of an object in pixel units 
%   fn_pixelsize      - Size of an object in pixel units
%   fn_coordinates    - Conversion of screen/figure/axes, normalized/pixel coordinates
%   fn_controlpositions     - Position uicontrol objects relative to an axes
%   fn_setfigsize     - Change the size of a figure, while keeping it visible
%   fn_setpropertyandmark   - Change both an object property and a control value 
% - mouse actions
%   fn_buttonmotion   - Execute a task while mouse pointer is movedaround 
%   fn_moveobject     - Move a graphic object with mouse
%   fn_getline        - Modified version of Matlab getline function 
%   fn_mouse          - Manual selection of a variety of shapes
% - elaborate tools
%   fn_framedesign    - Utility to let user reposition graphic objects inside a figure 
%   interface         - Parent class to create cool graphic interfaces
% - pre-defined arrangements of controls
%   fn_okbutton       - Small 'ok' button waits to be pressed
%   fn_menu           - Utility to create a basic GUI made of a line of buttons
% - special controls
%   fn_multcheck      - Special control made of multiple check boxes
%   fn_buttongroup    - Set of radio buttons or toggle buttons
%   fn_slider         - Special control that improves the functionality of Matlab slider
%   fn_sliderenhance  - Allow a slider uicontrol to evaluate its callback during scrolling
%   fn_stepper        - Special numeric control that includes increment/decrement buttons
%   fn_sensor         - Special control whose value is changed by clicking onto it and dragging
% - elaborate controls
%   fn_control        - Arrangement of control that reflect the state of a set of parameters 
%   fn_supercontrol   - Super arrangement of control 
% - dialogs
%   fn_reallydlg      - Ask for confirmtaion
%   fn_dialog_questandmem   - Confirmation question with an option for not asking again 
%   fn_input          - Prompt user for a single value. Function based on fn_structedit 
%
% MISCELLANEOUS
%   alias             - Create command shortcuts 
%   fn_email          - Send e-mails from Matlab! Automatically attach figures, M-files and more
%   fn_figmenu        - An automatic custom menu for figures: save figure, distance tool, ... 
%   pointer           - Implement a pointer to any Matlab object
%
% UNDER DEVELOPMENT - BETTER NOT USE
%   fn_dialog         - Under development
%   fn_filter         - Apply general linear model to remove some regressors from signals
%   fn_interp1        - Under development 
%   fn_registernd     - Under evelopment
%   fn_subplot        - Under development
%   fn_uicontrol      - Embed a control


