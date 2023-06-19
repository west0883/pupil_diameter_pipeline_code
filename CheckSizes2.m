% CheckSizes.m
% Sarah West
% 6/21/22

% Function that searches through your iterators for the inputted file
% names. Does NOT use RunAnalysis, but has similar input structure. 

function [] = CheckSizes2(parameters)

    % Make a loop list from iterators.
    looping_output_list = LoopGenerator(parameters.loop_list, parameters.loop_variables);

    % Initialize missing data cell array. 
    mismatched_data = cell(1, size(parameters.loop_list.iterators,1) + 2);
    
    try 
    % For each item in looping output list,
    for itemi = 1:size(looping_output_list,1)
    
        % Get this list of loading and saving string-creating parameters.keywords and
        % variables
        
        % Keywords should be the names of each iterator, which are in the
        % first column of iterators cell. Also include the iterator names.
        parameters.keywords = [parameters.loop_list.iterators(:,1); parameters.loop_list.iterators(:,3)];

        % Values are the corresponding parameters.values in the looping output list
        % for each keyword's field.
        parameters.values = cell(size(parameters.keywords));
        for i = 1: numel(parameters.keywords)
            parameters.values{i} = looping_output_list(itemi).(cell2mat(parameters.keywords(i)));
        end

        parameters.RunAnalysis_flag = true;
        MessageToUser('Checking ', parameters);
        
        % Get the file names of the files you're checking for
        dir_cell = parameters.loop_list.things_to_check.dir;
        filename_cell = parameters.loop_list.things_to_check.filename;
        variable_cell = parameters.loop_list.things_to_check.variable;
   
        input_dir = CreateStrings(dir_cell,parameters.keywords, parameters.values);
        filename = CreateStrings(filename_cell,parameters.keywords, parameters.values);
        variable_string_checking = CreateStrings(variable_cell,parameters.keywords, parameters.values);

        % Create object for data file.
        if isfile([input_dir filename])
            file_object_checking = matfile([input_dir filename]);
        else
            continue
        end

        % Get filenames & object for data to check against
        dir_cell = parameters.loop_list.check_against.dir;
        filename_cell = parameters.loop_list.check_against.filename;
        variable_cell = parameters.loop_list.check_against.variable;
   
        input_dir = CreateStrings(dir_cell,parameters.keywords, parameters.values);
        filename = CreateStrings(filename_cell,parameters.keywords, parameters.values);
        variable_string_check_against = CreateStrings(variable_cell,parameters.keywords, parameters.values);

        if isfile([input_dir filename])
            file_object_check_against = matfile([input_dir filename]);
        else
            continue
        end

        % Get the condition name 
        location = strcmp(parameters.keywords, {'condition'});
        condition = parameters.values{location};

        % Get sizes of checking and checking against

        % need to see which cells are empty in the checking, because 3rd
        % dimension of empty comes back as 1
        empties_checking =cellfun(@isempty, file_object_checking.segmented_timeseries);
        empties_check_against =cellfun(@isempty, file_object_check_against.segmented_timeseries);
        
        % get sizes
        checking_sizes = cellfun('size', file_object_checking.segmented_timeseries, 2);
        check_against_sizes = cellfun('size', file_object_check_against.segmented_timeseries, 3);
      
        % Make empty checking sizes = 0. 
        checking_sizes(empties_checking) = 0;
        check_against_sizes(empties_check_against) = 0;

        % Compare sizes 
        size_comparison = checking_sizes == check_against_sizes;

        % If there are any mismatches
        if ~any(size_comparison)

            ind = find(size_comparison == 0);
            disp('Found mismatch');
    
            % Add to list of mismatched 
            mismatched_data = [mismatched_data; parameters.values(1:end/2)' {periodi} {ind}];


        end 
               
    end
   
    catch

        % Get output file name strings.
        dir_cell = parameters.loop_list.mismatched_data.dir;
        filename_cell = parameters.loop_list.mismatched_data.filename;
       
        output_dir = CreateStrings(dir_cell,parameters.keywords, parameters.values);
        filename = CreateStrings(filename_cell,parameters.keywords, parameters.values);
      
        MessageToUser('Error at ', parameters);
        % Save
        save([output_dir filename], 'mismatched_data', '-v7.3');
    end


        % Get output file name strings.
        dir_cell = parameters.loop_list.mismatched_data.dir;
        filename_cell = parameters.loop_list.mismatched_data.filename;
       
        output_dir = CreateStrings(dir_cell,parameters.keywords, parameters.values);
        filename = CreateStrings(filename_cell,parameters.keywords, parameters.values);
      
        % Save
        save([output_dir filename], 'mismatched_data', '-v7.3');

end 