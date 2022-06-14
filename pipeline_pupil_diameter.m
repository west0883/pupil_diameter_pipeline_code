% pipeline_pupil_diameter.m
% Sarah West
% 6/14/22 

% Use "create_mice_all.m" before using this.

%% Initial setup
% Put all needed paramters in a structure called "parameters", which you
% can then easily feed into your functions. 
clear all; 

% Output Directories

% Create the experiment name. This is used to name the output folder. 
parameters.experiment_name='Random Motorized Treadmill';

% Output directory name bases
parameters.dir_base='Y:\Sarah\Analysis\Experiments\';
parameters.dir_exper=[parameters.dir_base parameters.experiment_name '\']; 

% *********************************************************

% (DON'T EDIT). Load the "mice_all" variable you've created with "create_mice_all.m"
load([parameters.dir_exper 'mice_all.mat']);

% Add mice_all to parameters structure.
parameters.mice_all = mice_all; 

% ****Change here if there are specific mice, days, and/or stacks you want to work with**** 
% If you want to change the list of stacks, use ListStacks function.
% Ex: numberVector=2:12; digitNumber=2;
% Ex cont: stackList=ListStacks(numberVector,digitNumber); 
% Ex cont: mice_all(1).stacks(1)=stackList;

parameters.mice_all = parameters.mice_all(2:3);       %[1:6, 8]);
parameters.mice_all(1).days = parameters.mice_all(1).days(10); 
parameters.mice_all(1).days(1).stacks = [];
parameters.mice_all(2).days = parameters.mice_all(2).days(9:10); 

% Give the number of digits that should be included in each stack number.
parameters.digitNumber=2; 

% *************************************************************************
% Parameters

% Sampling frequency of eye video, in fps.
parameters.eye_fps = 20;

% Sampling frequency of collected brain data (per channel), in Hz or frames per
% second.
parameters.fps= 20; 

% Number of channels from brain data (need this to calculate correct
% "skip" time length).
parameters.channelNumber = 2;

% Number of frames you recorded from brain and want to keep (don't make chunks longer than this)  
parameters.frames=6000; 

% Number of initial brain frames to skip, allows for brightness/image
% stabilization of camera. Need this to know how much to skip in the
% behavior.
parameters.skip = 1200; 

% Loop variables.
parameters.loop_variables.data_type = {'correlations', 'PCA scores individual mouse'};
parameters.loop_variables.mice_all = parameters.mice_all;
parameters.loop_variables.conditions = {'motorized'; 'spontaneous'};
parameters.loop_variables.conditions_stack_locations = {'stacks'; 'spontaneous'};

%% Import DeepLabCut pupil extraction data. 
% Calls ImportDLCPupilData.m, but that function doesn't really do anything,
% as RunAnalysis can import it in with a load function.

% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               'day', {'loop_variables.mice_all(', 'mouse_iterator', ').days(:).name'}, 'day_iterator';
               'stack_name', { 'dir("Y:\Sarah\Data\Random Motorized Treadmill\', 'day', '\', 'mouse', '\eye\eye*filtered.csv").name'}, 'stack_name_iterator'; 
               };

% Input values
parameters.loop_list.things_to_load.import_in.dir = {'Y:\Sarah\Data\Random Motorized Treadmill\', 'day', '\', 'mouse', '\eye\'};
parameters.loop_list.things_to_load.import_in.filename= {'stack_name'}; 
parameters.loop_list.things_to_load.import_in.variable= {'trial_in'}; 
parameters.loop_list.things_to_load.import_in.level = 'stack_name';
parameters.loop_list.things_to_load.import_in.load_function = @importdata;

% Output
parameters.loop_list.things_to_save.import_out.dir = {[parameters.dir_exper 'behavior\eye\extracted pupil tracking\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_save.import_out.filename= {'trial', 'stack_name', '.mat'};
parameters.loop_list.things_to_save.import_out.variable= {'trial'}; 
parameters.loop_list.things_to_save.import_out.level = 'stack';

RunAnalysis({@ImportDLCPupilData}, parameters)

%% Fit circles to pupil edges
% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               'day', {'loop_variables.mice_all(', 'mouse_iterator', ').days(:).name'}, 'day_iterator';
               'condition', {'loop_variables.conditions'}, 'condition_iterator';
               'stack', {'getfield(loop_variables, {1}, "mice_all", {',  'mouse_iterator', '}, "days", {', 'day_iterator', '}, ', 'loop_variables.conditions_stack_locations{', 'condition_iterator', '})'}, 'stack_iterator'; 
               };

% Number of points plotted
parameters.numberOfPoints = 8;

% Columns of position data.
parameters.xPositionColumns = 2:3: parameters.numberOfPoints * 3 + 1;
parameters.yPositionColumns = 3:3: parameters.numberOfPoints * 3 + 1;
parameters.confidenceColumns = 4:3: parameters.numberOfPoints * 3 + 1;

% Confidence thrshold that the tracking confidence of a point needs to be
% over to be included in the diameter calculation.
parameters.confidenceThreshold = 0.3;

% Info about format of the input data. Should always be the same if using
% "importdata.m" on DLC output .csv files in step above. 
parameters.framesDim = 1;
parameters.dataDim = 2;

% Inputs
parameters.loop_list.things_to_load.DLC_data.dir = {[parameters.dir_exper 'behavior\eye\extracted pupil tracking\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_load.DLC_data.filename= {'trialeye', 'stack', '*.mat'}; % Has a variable middle part to the name
parameters.loop_list.things_to_load.DLC_data.variable= {'trial.data'}; 
parameters.loop_list.things_to_load.DLC_data.level = 'stack';

% Outputs
parameters.loop_list.things_to_save.circle_info.dir = {[parameters.dir_exper 'behavior\eye\pupil diameters\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_save.circle_info.filename= {'trial', 'stack', '.mat'};
parameters.loop_list.things_to_save.circle_info.variable= {'trial'}; 
parameters.loop_list.things_to_save.circle_info.level = 'stack';

RunAnalysis({@FitCircles}, parameters);

%% Normalize pupil diameters within stacks somehow (by % max per stack? Preferably by max by day)