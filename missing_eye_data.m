% missing_eye_data.m
% Sarah West
% 6/17/22

% A script that finds stacks that don't have eye data & creates vectors of
% NaN for the pupil diameters. Checks with the not-yet normalized pupil
% diameters, saves with the normalized pupil diameters (so the results
% don't change each time you run it).

%% Initial setup
% Create the experiment name. This is used to name the output folder. 
parameters.experiment_name='Random Motorized Treadmill';

% Output directory name bases
parameters.dir_base='Y:\Sarah\Analysis\Experiments\';
parameters.dir_exper=[parameters.dir_base parameters.experiment_name '\']; 

% (DON'T EDIT). Load the "mice_all" variable you've created with "create_mice_all.m"
load([parameters.dir_exper 'mice_all.mat']);

% Add mice_all to parameters structure.
parameters.mice_all = mice_all; 

% ****Change here if there are specific mice, days, and/or stacks you want to work with**** 
% If you want to change the list of stacks, use ListStacks function.
% Ex: numberVector=2:12; digitNumber=2;
% Ex cont: stackList=ListStacks(numberVector,digitNumber); 
% Ex cont: mice_all(1).stacks(1)=stackList;
parameters.mice_all = parameters.mice_all([1:6, 8]);

% Give the number of digits that should be included in each stack number.
parameters.digitNumber=2; 
digitChar = num2str(parameters.digitNumber);

% Number of frames in recording (after the "skip" number of frames).
parameters.frames = 6000;

% Initialize list of missing stacks (cell of mouse, day, stack number as
% columns, each stack is own row)
missing_data = cell(1, 3);

% Loop variables.
parameters.loop_variables.mice_all = parameters.mice_all;
parameters.loop_variables.conditions = {'motorized'; 'spontaneous'};
parameters.loop_variables.conditions_stack_locations = {'stacks'; 'spontaneous'};

% Directory/filename you're looking at for each potentially missing stack.
parameters.input_filename = {[parameters.dir_exper '\behavior\eye\pupil diameters\'], 'mouse', '\', 'day', '\', 'trial', 'stack', '.mat'};

% Output filename
parameters.output_filename =  {[parameters.dir_exper '\behavior\eye\pupil diameters normalized\'], 'mouse', '\', 'day', '\', 'diameters', 'stack', '.mat'};

% Directory/filename for where to save list of missing data.
parameters.missing_data_filename =  [parameters.dir_exper '\behavior\eye\missing_eye_data.mat'];

% Initialize counter for cells.
counter = 0;

%% Stacks known to be missing, from "Recordings list" spreadsheet
% You don't REALLY need this here, but it's convenient for seeing which
% data "should" be here & which can likely still be found.
for i = 1:4 
    counter = counter + 1; 
    missing_data(i, :) = {'1087', '112121', sprintf(['%0' digitChar 'd'], i)};
end

counter = counter + 1;
missing_data(counter, :) = {'1087', '011122', '16'};

counter = counter + 1;
missing_data(counter, :) = {'1100', '012622', '09'};

counter = counter + 1;
missing_data(counter, :) = {'1107', '020122', '12'};


%% Run through mice_all, search all pupil diameters calculated.
parameters.loop_list.iterators = {
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               'day', {'loop_variables.mice_all(', 'mouse_iterator', ').days(:).name'}, 'day_iterator';
               'condition', {'loop_variables.conditions'}, 'condition_iterator';
               'stack', {'getfield(loop_variables, {1}, "mice_all", {',  'mouse_iterator', '}, "days", {', 'day_iterator', '}, ', 'loop_variables.conditions_stack_locations{', 'condition_iterator', '})'}, 'stack_iterator'; 
               };

looping_output_list = LoopGenerator(parameters.loop_list, parameters.loop_variables); 

% For each element of looping_output_list, 
for itemi = 1:size(looping_output_list,1)

    % Get keywords, like in RunAnalysis
    parameters.keywords = [parameters.loop_list.iterators(:,1); parameters.loop_list.iterators(:,3)];
    
    % Get values, like in RunAnalysis
    parameters.values = cell(size(parameters.keywords));
    for i = 1: numel(parameters.keywords)
        parameters.values{i} = looping_output_list(itemi).(cell2mat(parameters.keywords(i)));
    end

    % Get the filename 
    filestring = CreateStrings(parameters.input_filename, parameters.keywords, parameters.values);

    % Check if that file exists. If not, add it to missing_data
    if ~isfile(filestring)
        counter = counter + 1; 
        missing_data(counter, :) = [parameters.values(1:2)' parameters.values(4)];

    end 
end

% Save list of missing data.
save(parameters.missing_data_filename, 'missing_data');

%% Make missing data stacks into vectors of NaNs.

load(parameters.missing_data_filename, 'missing_data');

% Make new keywords list for CreateStrings
parameters.keywords = {'mouse', 'day', 'stack'};

% Make the vector of NaNs (with a variable name that matches the other files 
% in output folder). (frames x 1)
diameters = NaN(parameters.frames, 1);

% For each entry in missing_data,
for itemi = 1:size(missing_data,1)
     
    % Make a file name
    filestring = CreateStrings(parameters.output_filename, parameters.keywords, missing_data(itemi, :));

    % Save the NaN vector under the name of the missing data stack.
    save(filestring, 'diameters');

end


%% Make a list of stacks/days to rerun now that you have a list of days 
% that "should" be missing.

% Reset counter.
counter = 0;

% List of stacks to rerun (each entry is a row, columns are mouse, day,
% stack).
stacks_to_rerun = cell(1,3);


