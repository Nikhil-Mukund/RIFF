function [data, file_raw] = SDF_import( filename )
%SDF_IMPORT - Imports HP/Agilent/Keysight Standard Data Format (SDF) files to MATLAB and OCTAVE
%  This code is an implementation of the SDF standard as defined in:
%  'User's Guide - Standard Data Format Utilities, Version B.02.01'
%  by Agilent Technologies
%  Manufacturing Part Number: 5963-1715
%  Printed in USA
%  December 1994
%  © Copyright 1989, 1991-94, 2005 Agilent Technologies, Inc.
%
% Syntax: [data file_raw] = SDF_import( filename )
%
% Inputs:
%   filename - String of the filename of the SDF file including the file extension.
%
% Outputs:
%   data - Extracted SDF headers, and processed signal traces.
%   file_raw - Raw byte array of the SDF file which is being intepreted.
%
% Other m-files required: SDF_template.m
% Subfunctions: capitaliseFirstLetters, dataTypeByteSize, SDF_DataType,
%   SDF_uintX, SDF_int8, SDF_char, SDF_short, SDF_long, SDF_float, SDF_double, SDF_struct,
%   SDF_uintX_vector, SDF_short_vector, SDF_long_vector, SDF_float_vector, SDF_double_vector,
%   SDF_DATA_SizesX, SDF_DATA_SizesY, SDF_extract_labels, SDF_Interpret_Template,
%   SDF_Multi_ChannelX, SDF_Multi_ChannelY, SDF_Multi_TraceX, SDF_Multi_TraceY,
%   SDF_Single_TraceX, SDF_Single_TraceY, SDF_XDATA_Process, SDF_YDATA_Process, SDF_Y_scale.
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: 01/08/2018
% © Copyright 2016-2018 Commonwealth of Australia, represented by the Department of Defence
%
% v1.0.4 01/08/2018 Swapped row & column order and reduced dimensions in "Import SCAN_STRUCT_record"
% section of SDF_Import(), this change allows '.SDF_SCAN_STRUCT.scanVar' to be read correctly.
% Merged multiple scans into single array '.ext.sXd#v#'. The z-axis data is stored in scanVar.
% Window corrections are now applied based on Channel information specified by 
% "SDF_VECTOR_HDR.the_CHANNEL_record". Frequency and Order datasets have narrowband correction applied
% by default (No indication on whether to use narrow or wide band correction was found).
% Minor spelling corrections.
% v1.0.3 19/07/2018 No changes to the project. Number increased due to File Exchange not uploading 
% correctly. Re-synching version numberig with File Exchange. Code basse is identical to v1.0.1.
% v1.0.2 18/07/2018 No changes to the project. Number increased due to File Exchange not uploading 
% correctly. Mathworks Staff attempted this upload.
% v1.0.1 12/07/2018 Applied correction to SDF_Y_Scale, Created chA and chB. Value is based on their 
% entry in  SDF_VECTOR_HDR.the_channel_record. If chA > chB, correction factor is inverted.
% Corrected typo in 'logarithmic' section of SDF_Multi_ChannelX, which referred to SDF_XDATA_HDR
% instead of SDF_DATA_HDR. Added 'if' statement in SDF_YDATA_Process to catch case where file is 
% 'scan' data mode without there actually being scanned data present. Thanks go to John Sarloos for \
% reporting the error and providing the sample file.
% v1.0   27/04/2018 Changed version number to match MATLAB Central
% v0.2.3 16/03/2018 Changed SDF_CHANNEL_HDR.overloaded template entry to
% deal with error in an overloaded file. The value '3' (out of 0-1 range)
% was presen for a file which exhibited 'overloaded' on the instrument
% screen.
% v0.2.2 06/04/2017 Changed the untested decimated time data field name to decimatedRealValue and
%   decimated ImaginaryValue, to reduce confusion associated with using minimum and maximum Real and 
%   Imaginary values (see B-37 of standard)
% v0.2.1 04/04/2017 Reformatted under Matlab, and recast everything to
%   double to avoid values being quantised.
% v0.2 - 03/04/2017 Corrected major Matlab/Octave syntax issues:
%            - Use of '_' at start of variable names replaced with 'zz_'
%            - 'data._SDF_ADDTL' renamed 'data.SDF_ADDTL'
%            - Replaced '!' with '~' for the 'not' statements
%            - Replaced double quotes (") with single quotes (') as appropriate
% v0.1 - 31/03/2017 Initial alpha release
%   This file is part of SDF Importer.
% 
% Copyright 2016-2018 Commonwealth of Australia, represented by the Department of Defence.
%
% Redistribution and use in source and binary forms, with or without modification, are 
% permitted provided that the following conditions are met:
%
% 1. Redistributions of source code must retain the above copyright notice, this list of 
%    conditions and the following disclaimer.
%
% 2. Redistributions in binary form must reproduce the above copyright notice, this list 
%    of conditions and the following disclaimer in the documentation and/or other materials 
%    provided with the distribution.
%
% 3. Neither the name of the copyright holder nor the names of its contributors may be used 
%    to endorse or promote products derived from this software without specific prior 
%    written permission.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR 
% IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
% AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR 
% CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
% LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
% LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%% Initialise Variables
data.ext.traceList = [{},{}];
data.SDF_ADDTL.DATA_HDR_sizes = 0; % Array of recordSize entries from the DATA_HDR header
data.SDF_ADDTL.VECTOR_HDR_sizes = 0; % Array of recordSize entries from the VECTOR_HDR header
data.SDF_ADDTL.CHANNEL_HDR_sizes = 0; % Array of recordSize entries from the CHANNEL_HDR header
data.SDF_ADDTL.UNIQUE_sizes = 0; % Array of recordSize entries from the UNIQUE header
data.SDF_ADDTL.SCAN_STRUCT_sizes = 0; % Array of recordSize entries from the SCAN_STRUCT header
data.SDF_ADDTL.SCAN_BIG_sizes = 0; % Array of recordSize entries from the SCAN_BIG header
data.SDF_ADDTL.SCANS_VAR_sizes = 0; % Array of recordSize entries from the SANS_VAR header
data.SDF_ADDTL.COMMENT_sizes = 0;  % Array of recordSize entries from the COMMENT header
data.SDF_ADDTL.filename=filename; % Store filename for reference in error messages and warnings
fid = fopen(filename,'r'); % Open file in read only mode to avoid corruption
file_raw = fread(fid); % Read file marker to make sure it is SDF file
fclose(fid); % Close file
%% Confirm the file contains an SDF header by looking for 'B\0' as first two bytes of the file.
if strcmp(char(file_raw(1:2)),[ 'B'; char(0) ])
    
    
    % Import SDF_FILE_HDR
    data.SDF_FILE_HDR = SDF_Interpret_Template('SDF_FILE_HDR', file_raw, 3);
    
    % Import SDF_MEAS_HDR
    data.SDF_MEAS_HDR = SDF_Interpret_Template('SDF_MEAS_HDR', file_raw,data.SDF_FILE_HDR.recordSize+3);
    
    % Estimate the version of the SDF file
    % Based on the size of MEAS_HDR, we deduce the SDF Format version
    switch data.SDF_MEAS_HDR.recordSize
        case 102
            data.SDF_ADDTL.SDF_version = 1.0;
        case 140
            data.SDF_ADDTL.SDF_version = 2.0;
        case 156
            data.SDF_ADDTL.SDF_version = 3.0;
        otherwise % Catch-all case incase the standard is modified
            error('Unrecognised SDF version: data.SDF_MEAS_HDR.recordSize = %d',...
                data.SDF_MEAS_HDR.recordSize);
    end
    
    % Import SDF_DATA_HDR
    if (data.SDF_FILE_HDR.num_of_DATA_HDR_record>0)
        for n = 1:data.SDF_FILE_HDR.num_of_DATA_HDR_record % Iterated over all the DATA_HDR records
            % Import the nth 'DATA' record
            data.SDF_DATA_HDR(n) = ...
                SDF_Interpret_Template('SDF_DATA_HDR', ...
                file_raw,data.SDF_FILE_HDR.offset_of_DATA_HDR_record + 1 + ...
                sum(data.SDF_ADDTL.DATA_HDR_sizes));
            % Update vector of record sizes
            data.SDF_ADDTL.DATA_HDR_sizes(n) = data.SDF_DATA_HDR(n).recordSize;
        end
    end
    
    % Import SDF_VECTOR_HDR
    if (data.SDF_FILE_HDR.num_of_VECTOR_record>0)
        for n = 1:data.SDF_FILE_HDR.num_of_VECTOR_record
            % Import the nth 'VECTOR'record
            data.SDF_VECTOR_HDR(n) = ...
                SDF_Interpret_Template('SDF_VECTOR_HDR', ...
                file_raw,data.SDF_FILE_HDR.offset_of_VECTOR_record + 1 + ...
                sum(data.SDF_ADDTL.VECTOR_HDR_sizes));
            % Update vector of record sizes
            data.SDF_ADDTL.VECTOR_HDR_sizes(n) = data.SDF_VECTOR_HDR(n).recordSize;
        end
    end
    
    % Import SDF_CHANNEL_HDR
    if (data.SDF_FILE_HDR.num_of_CHANNEL_record>0)
        for n = 1:data.SDF_FILE_HDR.num_of_CHANNEL_record
            % Import the nth 'CHANNEL'record
            data.SDF_CHANNEL_HDR(n) = ...
                SDF_Interpret_Template('SDF_CHANNEL_HDR', ...
                file_raw,data.SDF_FILE_HDR.offset_of_CHANNEL_record + 1 + ...
                sum(data.SDF_ADDTL.CHANNEL_HDR_sizes));
            % Update vector of record sizes
            data.SDF_ADDTL.CHANNEL_HDR_sizes(n) = data.SDF_CHANNEL_HDR(n).recordSize;
        end
    end
    
    % Import UNIQUE records
    if (data.SDF_FILE_HDR.num_of_UNIQUE_record > 0)
        for n = 1:data.SDF_FILE_HDR.num_of_UNIQUE_record
            % Import the nth 'UNIQUE'record
            data.SDF_UNIQUE(n) = ...
                SDF_Interpret_Template('SDF_UNIQUE', ...
                file_raw,data.SDF_FILE_HDR.offset_of_UNIQUE_record + 1 + ...
                sum(data.SDF_ADDTL.UNIQUE_sizes));
            % Update vector of record sizes
            data.SDF_ADDTL.UNIQUE_sizes(n) = data.SDF_UNIQUE(n).recordSize;
        end
    end
    
    % Import SCAN_STRUCT_record
    if (data.SDF_FILE_HDR.num_of_SCAN_STRUCT_record>0)
        for n = 1:data.SDF_FILE_HDR.num_of_SCAN_STRUCT_record
            % Import the nth 'SCAN_STRUCT'record
            data.SDF_SCAN_STRUCT(n) = ...
                SDF_Interpret_Template('SDF_SCAN_STRUCT', ...
                file_raw,data.SDF_FILE_HDR.offset_of_SCAN_STRUCT_record + 1 + ...
                sum(data.SDF_ADDTL.SCAN_STRUCT_sizes));
            % Update vector of record sizes
            data.SDF_ADDTL.SCAN_STRUCT_sizes(n) = data.SDF_SCAN_STRUCT(n).recordSize;
            % Add in interpretation of scan struct raw_data for HP89410 and HP9440 (Applies to all?)
            y = reshape(data.SDF_SCAN_STRUCT.zz_raw_data,length(data.SDF_SCAN_STRUCT.zz_raw_data)/data.SDF_SCAN_STRUCT.num_of_scan,...
                        data.SDF_SCAN_STRUCT.num_of_scan);
            eval(['data.SDF_SCAN_STRUCT.scanVar(n,:,:) = SDF_' data.SDF_SCAN_STRUCT.zz_scanVar_type ...
                '_vector(y);']);
            
        end
        % Discard excess dimensions.
        data.SDF_SCAN_STRUCT.scanVar=squeeze(data.SDF_SCAN_STRUCT.scanVar);
    end
    
    % Check the file version support SCAN_BIG, SCAN_VAR, and COMMENTS ( >= 3.0)
    if(data.SDF_ADDTL.SDF_version  >= 3.0)
        % Import all SCAN_BIG
        % Check there are SCANG_BIG records
        if (data.SDF_FILE_HDR.num_of_SCAN_BIG_RECORD>0)
            warning([data.SDF_ADDTL.filename ': SCAN_BIG_RECORD, entering untested section of code.']);
            % Iterate over the SCAN_BIG records
            for n = 1:data.SDF_FILE_HDR.num_of_SCAN_BIG_RECORD
                % Import the nth 'SCAN_BIG'record
                data.SDF_SCAN_BIG(n) = ...
                    SDF_Interpret_Template('SDF_SCAN_BIG', ...
                    file_raw,data.SDF_FILE_HDR.offset_of_SCAN_BIG_record + 1 + ...
                    sum(data.SDF_ADDTL.SCAN_BIG_sizes));
                % Update vector of record sizes
                data.SDF_ADDTL.SCAN_BIG_sizes(n) = data.SDF_SCAN_BIG(n).recordSize;
            end
            
            
            % We have not implemented the SDF_SCANS_VAR importation.
            % We make the assumption that the SCANS_VAR is located just after the SCAN_BIG
            % section, so we will define an additonal variable:
            % SDF_ADDTL.offset_of_SCAN_VAR_record
            warning([data.SDF_ADDTL.filename ': SDF_SCANS_VAR importation has not been implemented.']);
            warning('data.SDF_ADDTL.offset_of_SCANS_VAR_record has been created');
            % Initialise to zero in case of empty set.
            data.SDF_ADDTL.SCANS_VAR_sizes = 0;
            % Calculate offset based on previous dataset
            data.SDF_ADDTL.offset_of_SCANS_VAR_record = ...
                data.SDF_FILE_HDR.offset_of_SCAN_BIG_record + ...
                sum(data.SDF_ADDTL.SCAN_BIG_sizes);
            
            if (data.SDF_FILE_HDR.num_of_COMMENT_record>0)
                warning([data.SDF_ADDTL.filename ': SDF_COMMENT_HDR importation has not been implemented.']);
                warning('data.SDF_ADDTL.offset_of_COMMEENT_record has been created');
                %% We have not implemented the SDF_COMMENT_HDR importation.
                % Initialise to zero in case of empty set.
                data.SDF_ADDTL.COMMENT_sizes = 0;
                % Calculate offset based on previous dataset
                data.SDF_ADDTL.offset_of_COMMENT_record = ...
                    data.SDF_FILE_HDR.offset_of_SCANS_VAR_record + ...
                    sum(data.SDF_ADDTL.SCANS_VAR_sizes);
            end %num_of_COMMENT_record
        end%num_of_SCAN_BIG_RECORD
    end
    
    % Import all YDATA
    data = SDF_YDATA_Process(data,file_raw);
    
    % Import all XDATA if necessary
    data = SDF_XDATA_Process(data,file_raw);
else %if strcmp(char(file_raw(1:2)),[ 'B'; char(0) ])
    error(['The input file: ' filename 'is not an SDF file']);
end  %if strcmp(char(file_raw(1:2)),[ 'B'; char(0) ]), else
end % function [ data file_raw] = SDF_import( filename )
function [retval] = SDF_Interpret_Template(template, file_raw, start_address)
%SDF_INTERPRET_TEMPLATE - Iterates over the elements in the array of structures
% referred to by the string in template, reading input byte array 'file_raw',
% from index 'start_address', returning the new structure in 'retval'
%
%  This code is an implementation of the SDF standard as defined in:
%  'User's Guide - Standard Data Format Utilities, Version B.02.01'
%  by Agilent Technologies
%  Manufacturing Part Number: 5963-1715
%  Printed in USA
%  December 1994
%  © Copyright 1989, 1991-94, 2005 Agilent Technologies, Inc.
%
% Syntax: [retval] = SDF_Interpret_Template(template, file_raw, start_address)
%
% Inputs:
%   template - String of the desired header, options are:
%                 - SDF_FILE_HDR:    Provides an index to the file.
%                 - SDF_MEAS_HDR:    Contains settings of measurement parameters.
%                 - SDF_DATA_HDR:    Tells you how reconstruct one block of measurement results
%                                    (x- and y-axis values for every point of every trace).
%                 - SDF_VECTOR_HDR:  Tells you which channel (or pair of channels) provided data
%                                    for a single trace.
%                 - SDF_CHANNEL_HDR: Contains channel-specific information for one channel
%                                    used in the measurement.
%                 - SDF_SCAN_STRUCT: Tells you how vectors are organized in the Y-axis Data
%                                    record when the measurement includes multiple scans of data.
%                 - SDF_SCANS_BIG:   Extended scan header which tells how vectors are organized
%                                    in the Y-axis data record when the measurement may include
%                                    more than 32767 scans of data.
%                 - SDF_SCANS_VAR:   Contains a number that identifies every scan
%                                    (scan time, RPM, or scan number).
%                 - SDF_COMMENT_HDR: Contains text information associated with the file.
%                 - SDF_XDATA_HDR:   Contains the x-axis data needed to reconstruct any trace.
%                 - SDF_YDATA_HDR:   Contains the y-axis data needed to reconstruct any trace.
%                 - SDF_UNIQUE:      Makes the SDF file format flexible. The eight common record
%                                    types define parameters that are common to many instruments
%                                    and systems. However, a particular instrument or system may
%                                    need to save and recall the states of additional parameters.
%                                    These states can reside in Unique records.
%                 - SDF_UNIT:        Contains eng. units & scaling information for the traces.
%                 - SDF_WINDOW:      Contains windowing information for frequency domain traces.
%   file_raw - Raw byte array of the SDF file which is being intepreted.
%   start_address - array index of the header's first element.
%
% Outputs:
%   retval - Header structure with data populated as specified in the template.
%
% Other m-files required: SDF_template.m
% Subfunctions: SDF_DataType, SDF_uintX, SDF_int8, SDF_char, SDF_short, SDF_long, SDF_float,
%   SDF_double, SDF_struct,
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: 04/04/2017
% © Copyright 2016-2017 Commonwealth of Australia, represented by the Department of Defence
% Get the retval Template
tmplt = SDF_template(template);
% Use start address as a flag to identify if file_raw is all the imported file,
% or just the section of data relevant to SDF_UNIT or SDF_WINDOW templates
if (start_address >0) % The case for HDR template
    % Interpret the header length bytes.
    recordSize = SDF_long(file_raw(start_address+2:start_address+2+3));
    % Get only the data relevant to the HDR being imported
    data = file_raw(start_address:recordSize+start_address-1);
else % The case for  SDF_UNIT or SDF_WINDOW templates
    % The relevant data will have already been selected before being passed.
    data = file_raw;
    recordSize = length(file_raw); % Allows all data to be processed.
end
% idx is used to track the largest 'Binary Index' referred to by the header.
% It is necessary because to maintain the same 'Field Index' as the SDF doc.
% Additional 'Field Index' values were created to account for struct arrays.
idx = 0;
retval = []; % Initiate retval (return value) variable
% Iterate over the template entries to extract data and place in retval
for cnt = tmplt
    if cnt.BinaryIndex(end)  <= recordSize % Confirm record has not ended
        retval = SDF_DataType(cnt,data,retval); % Convert single element of data (not vector)
        idx = max([idx cnt.BinaryIndex(end)+1]); % Track the byte after the current element
    end
end
% Iterate over entries reproduce 'Old' variables as 'new' if they don't exist
for cnt = tmplt
    if strcmp(cnt.FieldName(end-2:end),'Old') % Identify 'Old' variables from the template
        if (~isfield(retval, cnt.FieldName(1:end-3))) % Identify non-existant variables
            % Copy the old address to the new one variable location
            eval(['retval.' cnt.FieldName(1:end-3) ' = retval.' cnt.FieldName ';']);
        end
    end
end
for cnt = tmplt % Iterate over entries to populate any entries with a table associated.
    if cnt.BinaryIndex(end)  <= recordSize
        if (size(cnt.Table,1) ~= 0) % Populate Fields with Table associated
            eval(['retval.zz_' cnt.FieldName ' = cnt.Table{' ...
                'find(strcmp(cnt.Table,num2str(retval.' cnt.FieldName '))),2};']);
        end
    end
end
% If there is data remaining in header, dump into _raw_data
if (start_address  ~= 0)
    tmp = data(idx:retval.recordSize);
    if (numel(tmp) ~= 0) % Only create variable if there is data
        retval.zz_raw_data = tmp;
    end
end
% End of the function
end
function [retval] = SDF_YDATA_Process(data,file_raw)
%SDF_YDATA_PROCESS - Identifies how y-data is stored in file_raw, and then extracts it to a
%  standardised structure.
%
%  This code is an implementation of the SDF standard as defined in:
%  'User's Guide - Standard Data Format Utilities, Version B.02.01'
%  by Agilent Technologies
%  Manufacturing Part Number: 5963-1715
%  Printed in USA
%  December 1994
%  © Copyright 1989, 1991-94, 2005 Agilent Technologies, Inc.
%
% Syntax: [retval] = SDF_YDATA_Process(data,file_raw)
%
% Inputs:
%   data - Structure containing the populated SDF header information.
%   file_raw - Raw byte array of the SDF file which is being intepreted.
%
% Outputs:
%   retval - Input variable 'data' with the y-data added
%
% Other m-files required: none
% Subfunctions: capitaliseFirstLetters, dataTypeByteSize, SDF_DataType,
%   SDF_uintX, SDF_int8, SDF_char, SDF_short, SDF_long, SDF_float, SDF_double, SDF_struct,
%   SDF_uintX_vector, SDF_short_vector, SDF_long_vector, SDF_float_vector, SDF_double_vector,
%   SDF_DATA_SizesY, SDF_extract_labels, SDF_Interpret_Template, SDF_Multi_ChannelY,
%   SDF_Multi_TraceX, SDF_Multi_TraceY, SDF_Single_TraceY, SDF_YDATA_Process, SDF_Y_scale.
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: 01/08/2018
% © Copyright 2016-2017 Commonwealth of Australia, represented by the Department of Defence
% Calculate the offsets for each new set of Y-data
data_offsets = [0 data.SDF_ADDTL.DATA_HDR_sizes(1:end-1)];
% Import the YDATA header and its raw_data based on the DATA_HDR offsets.
data.SDF_YDATA_HDR = ...
    SDF_Interpret_Template ('SDF_YDATA_HDR',file_raw,data.SDF_FILE_HDR.offset_of_YDATA_record+1 );
% Find the size of each vector/data block so we can work at extracting the correct vectors.
data = SDF_DATA_SizesY(data);
% Based on the scan structure, interpret data differently.
if data.SDF_FILE_HDR.num_of_SCAN_STRUCT_record % If there is a scan structure check what type
    switch data.SDF_SCAN_STRUCT.zz_scan_type
        case 'scan'
            y_idx = 0; % Initialise the index counter for the block of data
            % Scan #, Data #, Vector #,
            for n_s = 1 : data.SDF_SCAN_STRUCT.num_of_scan    %Iterate over all the scans
                for n_d = 1 : sum(data.SDF_ADDTL.is_scan_data) %Assume sequential, iterate datasets
                    [data,y_idx] = SDF_Multi_TraceY(data,n_s,n_d,y_idx);
                end %n_d
            end %n_s
            
            % Assume the non-scan data is after the scan structured data, import
            % the non-scanned data starting with the first non-scan datatype
            % Note we assume the scans are all before the non-scan.
            if sum(data.SDF_ADDTL.is_scan_data) % Check for case where there isn't any scan data
              for n_ns = sum(data.SDF_ADDTL.is_scan_data)+1:length(data.SDF_ADDTL.is_scan_data)
               [data,y_idx] = SDF_Multi_ChannelY(data,n_ns,y_idx); % For some reason 'data' was 'tmp'
              end %n_ns
            else % Since there is no scan data treat as a trace file.
                data = SDF_Single_TraceY(data); % Old way for reading a single trace
            end
            
        case 'depth'
            warning([data.SDF_ADDTL.filename ': An untested section of code was executed in '...
                'SDF_YDATA_Process. data.SDF_SCAN_STRUCT.zz_scan_type = ''depth''']);
            % Data #, Scan #, Vector #
            y_idx = 0; % Initialise the index counter for the block of data
            % Scan #, Data #, Vector #,
            for n_d = 1 : sum(data.SDF_ADDTL.is_scan_data)  %Iterate over all the scans
                for n_s = 1 : data.SDF_SCAN_STRUCT.num_of_scan %Assume sequential, iterate datasets
                    [data,y_idx] = SDF_Multi_TraceY(data,n_s,n_d,y_idx);
                end %n_d
            end %n_s
            % Assume the non-scan data is after the scan structured data, import
            % the non-scanned data starting with the first non-scan datatype
            % Note we assume the scans are all before the non-scan.
            for n_ns = sum(data.SDF_ADDTL.is_scan_data)+1:length(data.SDF_ADDTL.is_scan_data)
                [data,y_idx] = SDF_Multi_ChannelY(data,n_ns,y_idx); % For some reason 'data' was 'tmp'
            end %n_ns
        otherwise
            % Do nothing
            warning([data.SDF_ADDTL.filename ': An unreachable section of code was executed in '...
                'SDF_YDATA_Process. data.SDF_SCAN_STRUCT.zz_scan_type  ~= ''depth'' | ''scan''']);
    end % switch data.SDF_SCAN_STRUCT.zz_scan_type
else % There is no scan struct, read y trace
    data = SDF_Single_TraceY(data); % Old way for reading a single trace
end % if data.SDF_FILE_HDR.num_of_SCAN_STRUCT_record
% Return data
retval = data;
% End of function
end
function [retval] = SDF_DataType(cnt,raw_data,data)
%SDF_DATATYPE - Interprets a sequence of bytes within data, return as datatype
%  cnt.DataType. retval is updated with the interpreted value.
%
%  This code is an implementation of the SDF standard as defined in:
%  'User's Guide - Standard Data Format Utilities, Version B.02.01'
%  by Agilent Technologies
%  Manufacturing Part Number: 5963-1715
%  Printed in USA
%  December 1994
%  © Copyright 1989, 1991-94, 2005 Agilent Technologies, Inc.
%
% Syntax: [retval] = SDF_DataType(cnt,raw_data,data)
%
% Inputs:
%   cnt - Nth sub-structure from SDF template structure.
%   raw_data - Raw byte array of the SDF file sub-section which is being intepreted.
%   data - Structure containing the populated SDF header information.
%
% Outputs:
%   retval - Input variable 'data' with the interpreted data added
%
% Other m-files required: none
% Subfunctions: SDF_uintX, SDF_int8, SDF_char, SDF_short, SDF_long, SDF_float, SDF_double,
%               SDF_struct.
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: 04/04/2017
% © Copyright 2016-2017 Commonwealth of Australia, represented by the Department of Defence
% Preload the existing data into the new variable to be returned.
retval = data;
% Catch the char and struct fields by looking at their first four characters
switch cnt.DataType(1:4)
    % Process all strings. Single strings are 'int8', and dealt with by the
    % SDF_char function. If the standard is updated to include single chars
    % which are displayed as chars, a different implementation is needed.
    case {'char'}
        eval(['retval.' cnt.FieldName ' = SDF_char' ...
            '(raw_data(cnt.BinaryIndex(1):cnt.BinaryIndex(end)));']);
        % Process the structures in their own way
    case {'stru'} %struct
        eval(['retval.' cnt.FieldName ' = SDF_struct(''' cnt.RangeUnits(5:end)...
            ''',raw_data(cnt.BinaryIndex(1):cnt.BinaryIndex(end)));']);
        % Process all standard datatypes as per their name
    otherwise
        eval(['retval.' cnt.FieldName ' = SDF_' cnt.DataType ...
            '(raw_data(cnt.BinaryIndex(1):cnt.BinaryIndex(end)));']);
end
% End of function
end
function [retval] = SDF_uintX (arg)
%SDF_UINTX - converts a 1D array of N = 2:2:8 bytes to an unsigned integer
%  concatenanting the bits in reverse byte order. (To account for SDF byte order)
%
% Syntax: [retval] = SDF_uintX( arg )
%
% Inputs:
%   arg - 1D array of bytes of length 2 to 8.
%
% Outputs:
%   retval - Unsigned integer of N bits, where N = 8*length(arg);
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: 04/04/2017
% © Copyright 2016-2017 Commonwealth of Australia, represented by the Department of Defence
% Reverse bytes
arg = arg(end:-1:1)';
% Get number of bytes (2:2:8)
bytes = length(arg);
eval(['retval = uint' num2str(bytes * 8) '(0);']);
% Create index of bytes
n = (1:bytes)';
% Use vector operations to scale the bytes appropriately
retval = retval+arg * (2.^((n-1) * 8));
% End function
end
function [retval] = SDF_uintX_vector (arg)
%SDF_UINTX_VECTOR - converts a 2D array of N x M where N = 2:2:8 bytes to an unsigned integer
%  concatenanting the bits in reverse byte order. (To account for SDF byte order)
%
% Syntax: [retval] = SDF_uintX_vector( arg )
%
% Inputs:
%   arg - 2D array of bytes of 2 to 8 rows, by M columns.
%
% Outputs:
%   retval - Array of length M of unsigned integer of N bits, where N = 8*size(arg,1);
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: 04/04/2017
% © Copyright 2016-2017 Commonwealth of Australia, represented by the Department of Defence
% Reverse bytes
arg = arg(end:-1:1,:);
% Get number of bytes (2:2:8)
bytes = size(arg,1);
col = size(arg,2);
eval(['retval = uint' num2str(bytes * 8) '(0);']);
retval = repmat(retval,1,col);
eval(['arg = uint' num2str(bytes * 8) '(arg);']);
% Create index of bytes
eval(['n = uint' num2str(bytes * 8) '(((1:bytes)-1) * 8);']);
n = repmat(transpose(n),1,col);
% Use vector operations to scale the bytes appropriately
retval = (2.^n).* arg; % Scale the bytes by powers of two
retval = eval(['uint' num2str(bytes * 8) '(sum(retval,1))']); % Sum columns to get the vector.
% End function
end
function [output] = SDF_char(arg)
%SDF_CHAR - converts an array of N bytes to a string in
%  reverse byte order. (To account for SDF byte order)
%
% Syntax: [retval] = SDF_char( arg )
%
% Inputs:
%   arg - 2D array of bytes of length N
%
% Outputs:
%   retval - Array of char of length N;
%
% Other m-files required: none
% Subfunctions: SDF_int8
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: 04/04/2017
% © Copyright 2016-2017 Commonwealth of Australia, represented by the Department of Defence
% Reverse bytes
arg = arg';
% Check if sting or single char (int8?)
if length(arg)>1
    % Convert to a text string
    output = char(arg);
    % Remove unprintable chars
    output(~ismember(double(output),32:255)) = '';
else
    % Convert the char to an int8
    output = SDF_int8(arg);
end
% End function
end
function [retval] = SDF_int8(arg)
%SDF_INT8 - converts a 1D array of N = 1 bytes to a signed 8-bit integer.
%
% Syntax: [retval] = SDF_int8( arg )
%
% Inputs:
%   arg - 1D array of bytes of length 1.
%
% Outputs:
%   retval - arg interpreted as an int8;
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: 04/04/2017
% © Copyright 2016-2017 Commonwealth of Australia, represented by the Department of Defence
if  bitget(arg,8)%Convert if 8th bit is 1 (negative number)
    arg = arg - 254;
end
retval = arg;
end
function [retval] = SDF_short(arg)
%SDF_SHORT - converts a 1D array of N = 2 bytes to a short (signed 16 bit integer)
%  concatenanting the bits in reverse byte order. (To account for SDF byte order)
%
% Syntax: [retval] = SDF_short( arg )
%
% Inputs:
%   arg - 1D array of bytes of length 2.
%
% Outputs:
%   retval - arg interpreted as an int16;
%
% Other m-files required: none
% Subfunctions: SDF_uintX
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: 04/04/2017
% © Copyright 2016-2017 Commonwealth of Australia, represented by the Department of Defence
% Merge send the bytes to be merged in reverse order and typecast them.
retval = double(int32(typecast(SDF_uintX(arg),'int16')));
end
function [output] = SDF_long(arg)
%SDF_LONG - converts a 1D array of N = 4 bytes to a short (signed 32 bit integer)
%  concatenanting the bits in reverse byte order. (To account for SDF byte order)
%
% Syntax: [retval] = SDF_long( arg )
%
% Inputs:
%   arg - 1D array of bytes of length 4.
%
% Outputs:
%   retval - arg interpreted as an int32;
%
% Other m-files required: none
% Subfunctions: SDF_uintX
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: 04/04/2017
% © Copyright 2016-2017 Commonwealth of Australia, represented by the Department of Defence
% Merge send the bytes to be merged in reverse order and typecast them.
output = double(typecast(SDF_uintX(arg),'int32'));
end
function [retval] = SDF_float(arg)
%SDF_FLOAT - converts a 1D array of N = 4 bytes to a float (signed 32 bit floating point precision,
%  also known as a single) concatenanting the bits in reverse byte order.
%  (To account for SDF byte order)
%
% Syntax: [retval] = SDF_float( arg )
%
% Inputs:
%   arg - 1D array of bytes of length 4.
%
% Outputs:
%   retval - arg interpreted as an float (single);
%
% Other m-files required: none
% Subfunctions: SDF_uintX
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: 04/04/2017
% © Copyright 2016-2017 Commonwealth of Australia, represented by the Department of Defence
% Merge send the bytes to be merged in reverse order and typecast them.
retval = double(typecast(SDF_uintX(arg),'single'));
end
function [retval] = SDF_double(arg)
%SDF_DOUBLE - converts a 1D array of N = 8 bytes to a double (signed 64 bit floating point
%  precision) concatenanting the bits in reverse byte order. (To account for SDF byte order)
%
% Syntax: [retval] = SDF_double( arg )
%
% Inputs:
%   arg - 1D array of bytes of length 8.
%
% Outputs:
%   retval - arg interpreted as a double;
%
% Other m-files required: none
% Subfunctions: SDF_uintX
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: 04/04/2017
% © Copyright 2016-2017 Commonwealth of Australia, represented by the Department of Defence
% Merge send the bytes to be merged in reverse order and typecast them.
retval = typecast(SDF_uintX(arg),'double');
end
function [retval] = SDF_short_vector(arg)
%SDF_SHORT_VECTOR - converts a 2D array of (N = 2) x M bytes to an array of short
%  (signed 16 bit integers) concatenanting the bits in reverse byte order.
%  (To account for SDF byte order)
%
% Syntax: [retval] = SDF_short_vector( arg )
%
% Inputs:
%   arg - 2D array of bytes of length 2xM.
%
% Outputs:
%   retval - Array of length M of shorts (integer of 16 bits);
%
% Other m-files required: none
% Subfunctions: SDF_uintX_vector
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: 04/04/2017
% © Copyright 2016-2017 Commonwealth of Australia, represented by the Department of Defence
% Merge send the bytes to be merged in reverse order and typecast them.
retval = double(int32(typecast(SDF_uintX_vector(arg),'int16')));
end
function [output] = SDF_long_vector(arg)
%SDF_LONG_VECTOR - converts a 2D array of (N = 4) x M bytes to an array of short
%  (signed 16 bit integers) concatenanting the bits in reverse byte order.
%  (To account for SDF byte order)
%
% Syntax: [retval] = SDF_long_vector( arg )
%
% Inputs:
%   arg - 2D array of bytes of length 4xM.
%
% Outputs:
%   retval - Array of length M of shorts (integer of 32 bits);
%
% Other m-files required: none
% Subfunctions: SDF_uintX_vector
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: 04/04/2017
% © Copyright 2016-2017 Commonwealth of Australia, represented by the Department of Defence
% Merge send the bytes to be merged in reverse order and typecast them.
output = double(typecast(SDF_uintX_vector(arg),'int32'));
end
function [retval] = SDF_float_vector(arg)
%SDF_FLOAT_VECTOR - converts a 2D array of (N = 4) x M bytes to an array of short
%  (signed 16 bit integers) concatenanting the bits in reverse byte order.
%  (To account for SDF byte order)
%
% Syntax: [retval] = SDF_float_vector( arg )
%
% Inputs:
%   arg - 2D array of bytes of length 4xM.
%
% Outputs:
%   retval - Array of length M of float (single - 32 bits of floating point precision);
%
% Other m-files required: none
% Subfunctions: SDF_uintX_vector
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: 04/04/2017
% © Copyright 2016-2017 Commonwealth of Australia, represented by the Department of Defence
% Merge send the bytes to be merged in reverse order and typecast them.
retval = double(typecast(SDF_uintX_vector(arg),'single'));
end
function [retval] = SDF_double_vector(arg)
%SDF_DOUBLE_VECTOR - converts a 2D array of (N = 8) x M bytes to an array of short
%  (signed 16 bit integers) concatenanting the bits in reverse byte order.
%  (To account for SDF byte order)
%
% Syntax: [retval] = SDF_DOUBLE_vector( arg )
%
% Inputs:
%   arg - 2D array of bytes of length 8xM.
%
% Outputs:
%   retval - Array of length M of double (double - 64 bits of floating point precision);
%
% Other m-files required: none
% Subfunctions: SDF_uintX_vector
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: 04/04/2017
% © Copyright 2016-2017 Commonwealth of Australia, represented by the Department of Defence
% Merge send the bytes to be merged in reverse order and typecast them.
retval = typecast(SDF_uintX_vector(arg),'double');
end
function [retval] = SDF_struct(struct_template,arg)
%SDF_STRUCT - converts a 1D array of bytes to a SDF_UNIT or SDF_WINDOW structure.
%
% Syntax: [retval] = SDF_struct( arg )
%
% Inputs:
%   struct_template - A text string identifying the relectan structure to apply, options:
%                       'SDF_UNIT'
%                       'SDF_WINDOW'
%   arg - 1D array of bytes.
%
% Outputs:
%   retval - arg interpreted SDF_UNIT of SDF_WINDOW(single);
%
% Other m-files required: none
% Subfunctions: SDF_Interpret_Template
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: 04/04/2017
% © Copyright 2016-2017 Commonwealth of Australia, represented by the Department of Defence
% Check which struct needs to be processed, return error if not implemented
switch struct_template
    case {'SDF_UNIT'}
        retval = SDF_Interpret_Template('SDF_UNIT', arg, 0);
    case {'SDF_WINDOW'}
        retval = SDF_Interpret_Template('SDF_WINDOW', arg, 0);
    otherwise
        error('This is a struct which is not implemented: %s',struct_template)
end
end
function [retval] = SDF_Single_TraceY(data)
%SDF_SINGLE_TRACEY - Reconstructs the Y-data for the simplest type of SDF file, which contains a
%  single trace.
%  This code is an implementation of the SDF standard as defined in:
%  'User's Guide - Standard Data Format Utilities, Version B.02.01'
%  by Agilent Technologies
%  Manufacturing Part Number: 5963-1715
%  Printed in USA
%  December 1994
%  © Copyright 1989, 1991-94, 2005 Agilent Technologies, Inc.
%
% Syntax: [retval] = SDF_Single_TraceY(data)
%
% Inputs:
%   data - Extracted SDF headers, containing the raw y-data.
%
% Outputs:
%   retval - Extracted SDF headers, and processed y-axis traces.
%
% Other m-files required: none
% Subfunctions: capitaliseFirstLetters, dataTypeByteSize, SDF_DataType,
%   SDF_uintX_vector, SDF_short_vector, SDF_long_vector, SDF_float_vector, SDF_double_vector,
%   SDF_DATA_SizesY, SDF_extract_labels, SDF_Y_scale.
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: 04/04/2017
% © Copyright 2016-2017 Commonwealth of Australia, represented by the Department of Defence
% Perform the import of data for a single trace.
var_name = 'data.ext.s0d1v1.y'; % Define variable name
% var_size is the size (in bytes) of the Y-axis Data record’s data block
for n = 1:length(data.SDF_DATA_HDR)
    % If there is a single trace immediately sort data chunks are individual datapoint values.
    data.SDF_YDATA_HDR.zz_raw_data = ...
        reshape(data.SDF_YDATA_HDR.zz_raw_data, ...
        data.SDF_ADDTL.YDATA_var_size,...
        length(data.SDF_YDATA_HDR.zz_raw_data)/...
        data.SDF_ADDTL.YDATA_var_size);
    % Merge the bytes within the rows to allow byte conversion
    eval(['data.SDF_YDATA_HDR.zz_data = '...
        'SDF_' data.SDF_DATA_HDR(n).zz_ydata_type '_vector(data.SDF_YDATA_HDR.zz_raw_data);']);
    % Abbreviate some variable names for neatness
    dataHdr = data.SDF_DATA_HDR;
    vctHdr = data.SDF_VECTOR_HDR(dataHdr.first_VECTOR_recordNum+1);
    chHdr = data.SDF_CHANNEL_HDR;
    tmp = data.SDF_YDATA_HDR.zz_data;
    % Scale the converted data chuncks from volts to engineering units, and spit by yPerPoint and
    % by isComplex
    eval([var_name ' = SDF_Y_scale(chHdr,dataHdr,vctHdr,tmp);']); % scale the results
    % Extract user-readable data assiciated with the processed channels/axes.
    data = SDF_extract_labels(data,var_name);
    retval = data;
end
end
function [retval,y_idx] = SDF_Multi_TraceY(data,n_s,n_d,y_idx)
%SDF_MULTI_TRACEY - Reconstructs the scan Y-data for the datasets which are part of a multiscan file.
%  This code is an implementation of the SDF standard as defined in:
%  'User's Guide - Standard Data Format Utilities, Version B.02.01'
%  by Agilent Technologies
%  Manufacturing Part Number: 5963-1715
%  Printed in USA
%  December 1994
%  © Copyright 1989, 1991-94, 2005 Agilent Technologies, Inc.
%
% Syntax: [retval] = SDF_Multi_TraceY(data)
%
% Inputs:
%   data - Extracted SDF headers, containing the raw y-data.
%   n_s - Scan number (must be greater than zero)
%   n_d - Data header number (must be greater than zero)
%   y_idx - index of the first byte relevant to the Multi Trace input data.SDF_YDATA_HDR.zz_raw_data
%
% Outputs:
%   retval - Extracted SDF headers, and processed y-axis traces.
%
% Other m-files required: none
% Subfunctions: capitaliseFirstLetters, dataTypeByteSize, SDF_DataType,
%   SDF_uintX_vector, SDF_short_vector, SDF_long_vector, SDF_float_vector, SDF_double_vector,
%   SDF_DATA_SizesY, SDF_extract_labels, SDF_Y_scale.
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: 01/08/2018
% © Copyright 2016-2017 Commonwealth of Australia, represented by the Department of Defence
%Calculate the number of vectors for this datatype
num_v = data.SDF_DATA_HDR(n_d).total_rows * ...
    data.SDF_DATA_HDR(n_d).total_cols;
% Read the block size we have calculated
blk_size = data.SDF_ADDTL.YDATA_block_sizes(n_d); %Includes yPerPoint and isComplex
% Import all the vectors reshaped to be in rows
for n_v = 1:num_v
    strt = y_idx+(n_v-1) * blk_size+1; % Start index of data of interest
    stp = y_idx+(n_v) * blk_size; % Stop index of data of interest
    
    
    % Define the variable name
    var_name = ['data.ext.s' num2str(n_s) ...
        'd' num2str(n_d) 'v' num2str(n_v) '.y'];
    % Used to 
    var_name2 = ['data.ext.sX' ...
        'd' num2str(n_d) 'v' num2str(n_v) '.y(' num2str(n_s) ',:,:)'];
    % Abbreviate some variable names for neatness
    dataHdr = data.SDF_DATA_HDR(n_d);
    vctHdr = data.SDF_VECTOR_HDR(dataHdr.first_VECTOR_recordNum+n_v);
    chHdr = data.SDF_CHANNEL_HDR;
    % Place the relevant data into reshaped tmp array vector
    tmp = reshape(data.SDF_YDATA_HDR.zz_raw_data(strt:stp),...
        data.SDF_ADDTL.YDATA_var_size(n_d), ...
        blk_size/int32(data.SDF_ADDTL.YDATA_var_size(n_d)));
    % Convert the vector to datatype and scale in single command.
    eval([var_name ' = SDF_Y_scale(chHdr,dataHdr,vctHdr,' ...
        'SDF_' data.SDF_DATA_HDR(n_d).zz_ydata_type '_vector(tmp));']); % scale the results
    % Extract user-readable data assiciated with the processed channels/axes.
    data = SDF_extract_labels(data,var_name);
    %Merge multiple scans.
    eval([var_name2 ' = ' var_name ';']);
 end
% Increment the index counter
y_idx = stp;
% Return data
retval = data;
end
function [retval,y_idx] = SDF_Multi_ChannelY(data,n_ns,y_idx)
%SDF_MULTI_CHANNELY - Reconstructs non-scan Y-data for the datasets which are part of a multiscan file.
%  This code is an implementation of the SDF standard as defined in:
%  'User's Guide - Standard Data Format Utilities, Version B.02.01'
%  by Agilent Technologies
%  Manufacturing Part Number: 5963-1715
%  Printed in USA
%  December 1994
%  © Copyright 1989, 1991-94, 2005 Agilent Technologies, Inc.
%
% Syntax: [retval] = SDF_Multi_ChannelY(data)
%
% Inputs:
%   data - Extracted SDF headers, containing the raw y-data.
%   n_ns - Data header number (must be greater than zero)
%   y_idx - index of the first byte relevant to the Multi Channel input data.SDF_YDATA_HDR.zz_raw_data
%
% Outputs:
%   retval - Extracted SDF headers, and processed y-axis traces.
%
% Other m-files required: none
% Subfunctions: capitaliseFirstLetters, dataTypeByteSize, SDF_DataType,
%   SDF_uintX_vector, SDF_short_vector, SDF_long_vector, SDF_float_vector, SDF_double_vector,
%   SDF_DATA_SizesY, SDF_extract_labels, SDF_Y_scale.
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: 04/04/2017
% © Copyright 2016-2017 Commonwealth of Australia, represented by the Department of Defence
numCh = length(data.SDF_CHANNEL_HDR);
%Calculate the number of vectors for this datatype
num_v = data.SDF_DATA_HDR(n_ns).total_rows * ...
    data.SDF_DATA_HDR(n_ns).total_cols;
  ySize = dataTypeByteSize(data.SDF_DATA_HDR(n_ns).ydata_type);
numBytes = numCh * data.SDF_ADDTL.YDATA_block_sizes(n_ns); %Includes yPerPoint and isComplex
tmp = data.SDF_YDATA_HDR.zz_raw_data(y_idx+1:y_idx+numBytes);
% Place the relevant data into reshaped tmp array vector
tmp = reshape(tmp,...
    ySize, ...
    length(tmp)/int32(ySize));
eval(['tmp = SDF_' data.SDF_DATA_HDR(n_ns).zz_ydata_type '_vector(tmp);']);
tmp = reshape(tmp,length(tmp)/numCh, numCh);
for n_v = 1: num_v
    % Abbreviate some variable names for neatness
    dataHdr = data.SDF_DATA_HDR(n_ns);
    vctHdr = data.SDF_VECTOR_HDR(dataHdr.first_VECTOR_recordNum+n_v);
    chHdr = data.SDF_CHANNEL_HDR;
    % Define the variable name
    var_name = ['data.ext.s0d' num2str(n_ns) 'v' num2str(n_v) '.y'];
    % Scale the results
    eval([var_name ' = SDF_Y_scale(chHdr,dataHdr,vctHdr,tmp(:,n_v));']); % scale the results
    % Extract user-readable data assiciated with the processed channels/axes.
    data = SDF_extract_labels(data,var_name);
end
% Increment index
y_idx = y_idx+numBytes;
% Return values
retval = data;
end
function  [retval] = SDF_DATA_SizesY(data)
%SDF_DATA_SIZEY -Get all the Y variable and element sizes for the DATA_HRD referred data-vectors.
%  This code is an implementation of the SDF standard as defined in:
%  'User's Guide - Standard Data Format Utilities, Version B.02.01'
%  by Agilent Technologies
%  Manufacturing Part Number: 5963-1715
%  Printed in USA
%  December 1994
%  © Copyright 1989, 1991-94, 2005 Agilent Technologies, Inc.
%
% Syntax: [retval] = SDF_Multi_ChannelY(data)
%
% Inputs:
%   data - Extracted SDF headers, containing the raw y-data.
%
% Outputs:
%   retval - Extracted SDF headers, with the ollowing variables updated:
%               data.SDF_ADDTL.YDATA_var_size - Data size for the relevant data header.
%               data.SDF_ADDTL.YDATA_block_sizes - Size (in bytes) of the Y-axis Data record’s data block
%               data.SDF_ADDTL.is_scan_data - Array of 0/1 representing which DATA_HDR are scan-data
%
% Other m-files required: none
% Subfunctions: dataTypeByteSize
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: 04/04/2017
% © Copyright 2016-2017 Commonwealth of Australia, represented by the Department of Defence
%Iterate over all the YDATA elements specified in the header
for n = 1:length(data.SDF_DATA_HDR)
    % For the present data header, calculate the data size.
    data.SDF_ADDTL.YDATA_var_size(n) = dataTypeByteSize(data.SDF_DATA_HDR(n).ydata_type);
    
    % Determine the number of Vectors for this DATA_HDR
    
    % Determine the size (in bytes) of the Y-axis Data record’s data block with
    % the following formula:
    data.SDF_ADDTL.YDATA_block_sizes(n) = ...
        int32(data.SDF_DATA_HDR(n).num_of_points) * ...
        int32(data.SDF_DATA_HDR(n).yPerPoint) * ...
        int32(data.SDF_ADDTL.YDATA_var_size(n)) * ...
        (2^(int32(data.SDF_DATA_HDR(n).yIsComplex)));
    
    % Ascertain if the data type is to be included in the scanData
    data.SDF_ADDTL.is_scan_data(n) = data.SDF_DATA_HDR(n).scanData;
end
% Return values
retval = data;
end
function  [retval] = SDF_DATA_SizesX(data)
%SDF_DATA_SIZEX - Get all the X variable and element sizes for the DATA_HRD referred data-vectors.
%  This code is an implementation of the SDF standard as defined in:
%  'User's Guide - Standard Data Format Utilities, Version B.02.01'
%  by Agilent Technologies
%  Manufacturing Part Number: 5963-1715
%  Printed in USA
%  December 1994
%  © Copyright 1989, 1991-94, 2005 Agilent Technologies, Inc.
%
% Syntax: [retval] = SDF_Multi_ChannelY(data)
%
% Inputs:
%   data - Extracted SDF headers, containing the raw y-data.
%
% Outputs:
%   retval - Extracted SDF headers, with the ollowing variables updated:
%               data.SDF_ADDTL.XDATA_var_size - Data size for the relevant data header.
%               data.SDF_ADDTL.XDATA_block_sizes - Size (in bytes) of the X-axis Data record’s data block
%               data.SDF_ADDTL.is_scan_data - Array of 0/1 representing which DATA_HDR are scan-data
%
% Other m-files required: none
% Subfunctions: dataTypeByteSize
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: 04/04/2017
% © Copyright 2016-2017 Commonwealth of Australia, represented by the Department of Defence
% Get all the X variable and element sizes for the DATA_HRD referred data-vectors.
%Iterate over all the YDATA elements specified in the header
for n = 1:length(data.SDF_DATA_HDR)
    % For the present data header, calculate the data size.
    data.SDF_ADDTL.XDATA_var_size(n) = dataTypeByteSize(data.SDF_DATA_HDR(n).xdata_type);
    % Determine the number of Vectors for this DATA_HDR
    
    % Determine the size (in bytes) of the X-axis Data record’s data block with
    % the following formula:
    data.SDF_ADDTL.XDATA_block_sizes(n) = ...
        int32(data.SDF_DATA_HDR(n).num_of_points) * ...
        int32(data.SDF_DATA_HDR(n).xPerPoint) * ...
        int32(data.SDF_ADDTL.YDATA_var_size(n));
    
    % Ascertain if the data type is to be included in the scanData
    data.SDF_ADDTL.is_scan_data(n) = data.SDF_DATA_HDR(n).scanData;
end
% Return values
retval = data;
end
function [retval] = SDF_XDATA_Process(data,file_raw)
%SDF_XDATA_PROCESS - Identifies how x-data is stored in file_raw, and then extracts it to a
%  standardised structure.
%
%  This code is an implementation of the SDF standard as defined in:
%  'User's Guide - Standard Data Format Utilities, Version B.02.01'
%  by Agilent Technologies
%  Manufacturing Part Number: 5963-1715
%  Printed in USA
%  December 1994
%  © Copyright 1989, 1991-94, 2005 Agilent Technologies, Inc.
%
% Syntax: [retval] = SDF_XDATA_Process(data,file_raw)
%
% Inputs:
%   data - Structure containing the populated SDF header information.
%   file_raw - Raw byte array of the SDF file which is being intepreted.
%
% Outputs:
%   retval - Input variable 'data' with the x-data added
%
% Other m-files required: none
% Subfunctions: capitaliseFirstLetters, dataTypeByteSize, SDF_DataType,
%   SDF_uintX, SDF_int8, SDF_char, SDF_short, SDF_long, SDF_float, SDF_double, SDF_struct,
%   SDF_uintX_vector, SDF_short_vector, SDF_long_vector, SDF_float_vector, SDF_double_vector,
%   SDF_DATA_SizesX, SDF_extract_labels, SDF_Interpret_Template, SDF_Multi_ChannelX,
%   SDF_Multi_TraceX, SDF_Single_TraceX, SDF_X_scale.
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: 04/04/2017
% © Copyright 2016-2017 Commonwealth of Australia, represented by the Department of Defence
% Generate array of byte-offsets for each dataset, base on DATA_HDR
data_offsets = [0 data.SDF_ADDTL.DATA_HDR_sizes(1:end-1)];
% Import the XDATA header and its raw_data based on the DATA_HDR offsets.
if data.SDF_FILE_HDR.offset_of_XDATA_record  >= 0
    data.SDF_XDATA_HDR = ...
        SDF_Interpret_Template ('SDF_XDATA_HDR', ...
        file_raw,data.SDF_FILE_HDR.offset_of_XDATA_record+1 );%+ ...
    %data_offsets(n));
    % Find the of each vector/data block so we can work at extracting the correct vectors.
    data = SDF_DATA_SizesX(data);
end
%% Include a switch statement to address the following three cases:
%      - 1 Trace (Original example), all YDATA is a single vectorize (S0D1V1)
%      - 1 Scan (No scan structure) N vectors (S0D#V#)
%      - N Scans M Vectors (S#D#V#)
% Based on the scan structure, interpred data differently.
if data.SDF_FILE_HDR.num_of_SCAN_STRUCT_record % If there is a scan structure check what type
    switch data.SDF_SCAN_STRUCT.zz_scan_type
        case 'scan'
            x_idx = 0; % Initialise the index counter for the block of data
            % Scan #, Data #, Vector #
            for n_s = 1 : data.SDF_SCAN_STRUCT.num_of_scan
                %Iterate over all the scans
                for n_d = 1 : sum(data.SDF_ADDTL.is_scan_data) %Assume sequential
                    [data,x_idx] = SDF_Multi_TraceX(data,n_s,n_d,x_idx);
                end %n_d
            end %n_s
            % Assume the non-scan data is after the scan structured data, import
            % the non-scanned data starting with the first non-scan datatype
            % Note we assume the scans are all before the non-scan.
            for n_ns = sum(data.SDF_ADDTL.is_scan_data)+1:length(data.SDF_ADDTL.is_scan_data)
                [data,x_idx] = SDF_Multi_ChannelX(data,n_ns,x_idx);
            end %n_ns
        case 'depth'
            x_idx = 0; % Initialise the index counter for the block of data
            % Data #, Scan #, Vector #
            warning('SDF_XDATA_Process: scan_type ''depth'' has not been tested.');
            for n_d = 1 : sum(data.SDF_ADDTL.is_scan_data) %Assume sequential
                %Iterate over all the scans
                for n_s = 1 : data.SDF_SCAN_STRUCT.num_of_scan
                    [data,x_idx] = SDF_Multi_TraceX(data,n_s,n_d,x_idx);
                end %n_d
            end %n_s
            % Assume the non-scan data is after the scan structured data, import
            % the non-scanned data starting with the first non-scan datatype
            % Note we assume the scans are all before the non-scan.
            for n_ns = sum(data.SDF_ADDTL.is_scan_data)+1:length(data.SDF_ADDTL.is_scan_data)
                [data,x_idx] = SDF_Multi_ChannelX(data,n_ns,x_idx);
            end %n_ns
        otherwise
            % Do nothing
    end % switch data.SDF_SCAN_STRUCT.zz_scan_type
else % There is no scan struct, read y trace
    data = SDF_Single_TraceX(data); % Old way for single trace
end % if data.SDF_FILE_HDR.num_of_SCAN_STRUCT_record
retval = data;
end
function [retval,x_idx] = SDF_Multi_TraceX(data,n_s,n_d,x_idx)
%SDF_MULTI_TRACEX - Reconstructs the scan X-data for the datasets which are part of a multiscan file.
%  This code is an implementation of the SDF standard as defined in:
%  'User's Guide - Standard Data Format Utilities, Version B.02.01'
%  by Agilent Technologies
%  Manufacturing Part Number: 5963-1715
%  Printed in USA
%  December 1994
%  © Copyright 1989, 1991-94, 2005 Agilent Technologies, Inc.
%
% Syntax: [retval] = SDF_Multi_TraceX(data)
%
% Inputs:
%   data - Extracted SDF headers, containing the raw x-data.
%   n_s - Scan number (must be greater than zero)
%   n_d - Data header number (must be greater than zero)
%   y_idx - index of the first byte relevant to the Multi Trace input data.SDF_YDATA_HDR.zz_raw_data
%
% Outputs:
%   retval - Extracted SDF headers, and processed x-axis traces.
%
% Other m-files required: none
% Subfunctions: capitaliseFirstLetters, dataTypeByteSize, SDF_DataType, SDF_uintX_vector,
% SDF_short_vector, SDF_long_vector, SDF_float_vector, SDF_double_vector, SDF_extract_labels.
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: 04/04/2017
% © Copyright 2016-2017 Commonwealth of Australia, represented by the Department of Defence
%Calculate the number of vectors for this datatype
num_v = data.SDF_DATA_HDR(n_d).total_rows * ...
    data.SDF_DATA_HDR(n_d).total_cols;
switch data.SDF_DATA_HDR(n_d).zz_xResolution_type
    case {'linear'}
        n = 0:1.0:data.SDF_DATA_HDR(n_d).num_of_points-1;
        data.SDF_XDATA_HDR(n_d).zz_data = ...
            data.SDF_DATA_HDR(n_d).abscissa_firstX + ...
            data.SDF_DATA_HDR(n_d).abscissa_deltaX * n;
        for n_v = 1:num_v
            % Define the variable name
            var_name = ['data.ext.s' num2str(n_s) ...
                'd' num2str(n_d) 'v' num2str(n_v) '.x'];
            eval([var_name ...
                ' = data.SDF_XDATA_HDR(n_d).zz_data;']); % import the results
            % Extract user-readable data assiciated with the processed channels/axes.
            data = SDF_extract_labels(data,var_name);
        end
    case {'logarithmic'}
        n = 0:data.SDF_XDATA_HDR.num_of_points-1;
        data.SDF_XDATA_HDR(n_d).zz_data = ...
            data.SDF_DATA_HDR(n_d).abscissa_firstX * ...
            data.SDF_DATA_HDR(n_d).abscissa_deltaX ^ n;
        for n_v = 1:num_v
            % Define the variable name
            var_name = ['data.ext.s' num2str(n_s) ...
                'd' num2str(n_d) 'v' num2str(n_v) '.x'];
            eval([var_name ...
                ' = data.SDF_XDATA_HDR(n_d).zz_data;']); % import the results
            % Extract user-readable data assiciated with the processed channels/axes.
            data = SDF_extract_labels(data,var_name);
        end
    otherwise
        % Read the block size we have calculated
        blk_size = data.SDF_ADDTL.XDATA_block_sizes(n_d);
        % Import all the vectors reshaped to be in rows
        for n_v = 1:num_v
            strt = x_idx+(n_v-1) * blk_size+1;
            stp = x_idx+(n_v) * blk_size;
            % Define the variable name
            var_name = ['data.ext.s' num2str(n_s) ...
                'd' num2str(n_d) 'v' num2str(n_v) '.x'];
            dataHdr = data.SDF_DATA_HDR(n_d);
            vctHdr = data.SDF_VECTOR_HDR(dataHdr.first_VECTOR_recordNum+n_v);
            chHdr(1) = data.SDF_CHANNEL_HDR(vctHdr.the_CHANNEL_record(1)+1);
            if (vctHdr.the_CHANNEL_record(2) > -1)
                chHdr(2) = data.SDF_CHANNEL_HDR(vctHdr.the_CHANNEL_record(2)+1);
            end
            % Place the relevant data into reshaped tmp array vector
            tmp = reshape(data.SDF_XDATA_HDR.zz_raw_data(strt:stp),...
                data.SDF_ADDTL.XDATA_var_size(n_d), ...
                blk_size/int32(data.SDF_ADDTL.XDATA_var_size(n_d)));
            % Convert the vector to datatype and scale in single command.
            eval([var_name ' = SDF_' data.SDF_DATA_HDR(n_d).zz_xdata_type '_vector(tmp);']); % import the results
            % Extract user-readable data assiciated with the processed channels/axes.
            data = SDF_extract_labels(data,var_name);
        end
        x_idx = stp;
end
% Increment the index counter
retval = data;
end
function [retval,x_idx] = SDF_Multi_ChannelX(data,n_ns,x_idx)
%SDF_MULTI_CHANNELX - Reconstructs non-scan X-data for the datasets which are part of a multiscan file.
%  This code is an implementation of the SDF standard as defined in:
%  'User's Guide - Standard Data Format Utilities, Version B.02.01'
%  by Agilent Technologies
%  Manufacturing Part Number: 5963-1715
%  Printed in USA
%  December 1994
%  © Copyright 1989, 1991-94, 2005 Agilent Technologies, Inc.
%
% Syntax: [retval] = SDF_Multi_ChannelX(data)
%
% Inputs:
%   data - Extracted SDF headers, containing the raw y-data.
%   n_ns - Data header number (must be greater than zero)
%   x_idx - index of the first byte relevant to the Multi Channel input data.SDF_XDATA_HDR.zz_raw_data
%
% Outputs:
%   retval - Extracted SDF headers, and processed y-axis traces.
%
% Other m-files required: none
% Subfunctions: capitaliseFirstLetters, dataTypeByteSize, SDF_DataType, SDF_uintX_vector,
%   SDF_short_vector, SDF_long_vector, SDF_float_vector, SDF_double_vector, SDF_DATA_SizesX,
%   SDF_extract_labels, SDF_X_scale.
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: 12/07/2018
% © Copyright 2016-2017 Commonwealth of Australia, represented by the Department of Defence
%Calculate the number of vectors for this datatype
num_v = data.SDF_DATA_HDR(n_ns).total_rows * data.SDF_DATA_HDR(n_ns).total_cols;
switch data.SDF_DATA_HDR(n_ns).zz_xResolution_type
    case {'linear'}
        n = 0:data.SDF_DATA_HDR(n_ns).num_of_points-1;
        data.SDF_XDATA_HDR(n_ns).zz_data = ...
            data.SDF_DATA_HDR(n_ns).abscissa_firstX + ...
            data.SDF_DATA_HDR(n_ns).abscissa_deltaX * n;
        for n_v = 1:num_v
            % Define the variable name
            var_name = ['data.ext.s0' ...
                'd' num2str(n_ns) 'v' num2str(n_v) '.x'];
            eval([var_name ...
                ' = data.SDF_XDATA_HDR(n_ns).zz_data;']); % import the results
            % Extract user-readable data assiciated with the processed channels/axes.
            data = SDF_extract_labels(data,var_name);
        end
    case {'logarithmic'}
        n = 0:data.SDF_DATA_HDR.num_of_points-1;
        data.SDF_XDATA_HDR(n_ns).zz_data = ...
            data.SDF_DATA_HDR(n_ns).abscissa_firstX * ...
            data.SDF_DATA_HDR(n_ns).abscissa_deltaX .^ n;
        for n_v = 1:num_v
            % Define the variable name
            var_name = ['data.ext.s0' ...
                'd' num2str(n_ns) 'v' num2str(n_v) '.x'];
            eval([var_name ...
                ' = data.SDF_XDATA_HDR(n_ns).zz_data;']); % import the results
            % Extract user-readable data assiciated with the processed channels/axes.
            data = SDF_extract_labels(data,var_name);
        end
    otherwise
        % Issue warning since this section of code was never tested (lack of test input files)
        warning([data.SDF_ADDTL.filename ': An untested section of code was executed in '...
            'SDF_Multi_ChannelX: data.SDF_DATA_HDR(' num2str(n_ns) ').zz_xResolution_type = ''' ...
            data.SDF_DATA_HDR(n_ns).zz_xResolution_type '''']);
        % Account for the byte Size of the variable
        xSize = dataTypeByteSize(data.SDF_DATA_HDR(n_ns).xdata_type);
        
        % Calculate the number of bytes to read
        numBytes = int32(data.SDF_DATA_HDR(n_ns).num_of_points * xSize);
        % Get the data
        tmp = data.SDF_YDATA_HDR.zz_raw_data(x_idx+1:x_idx+numBytes);
        % Place the relevant data into reshaped tmp array vector
        tmp = reshape(tmp,xSize,length(tmp)/int32(xSize));
        for n_v = 1:num_v
            % Define the variable name path to the standardise export location
            var_name = ['data.ext.s0' 'd' num2str(n_ns) 'v' num2str(n_v) '.x'];
            %Convert the data to the correct data type
            eval([var_name ' = SDF_' data.SDF_DATA_HDR(n_ns).zz_xdata_type '_vector(tmp);']);
            % Extract user-readable data assiciated with the processed channels/axes.
            data = SDF_extract_labels(data,var_name);
            % Increment to the next block of x_idx
            x_idx = x_idx+numBytes;
        end
end
retval = data; % Return data
end
function [retval] = SDF_Single_TraceX(data)
%SDF_SINGLE_TRACEX - Reconstructs the X-data for the simplest type of SDF file, which contains a
%  single trace.
%  This code is an implementation of the SDF standard as defined in:
%  'User's Guide - Standard Data Format Utilities, Version B.02.01'
%  by Agilent Technologies
%  Manufacturing Part Number: 5963-1715
%  Printed in USA
%  December 1994
%  © Copyright 1989, 1991-94, 2005 Agilent Technologies, Inc.
%
% Syntax: [retval] = SDF_Single_TraceX(data)
%
% Inputs:
%   data - Extracted SDF headers, containing the raw x-data.
%   file_raw - Raw byte array of the SDF file which is being intepreted.
%
% Outputs:
%   retval - Extracted SDF headers, and processed x-axis traces.
%
% Other m-files required: none
% Subfunctions: capitaliseFirstLetters, dataTypeByteSize, SDF_DataType,
%   SDF_uintX_vector, SDF_short_vector, SDF_long_vector, SDF_float_vector, SDF_double_vector,
%   SDF_DATA_SizesX, SDF_extract_labels.
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: 04/04/2017
% © Copyright 2016-2017 Commonwealth of Australia, represented by the Department of Defence
% Define the variable name path to the standardise export location
var_name = 'data.ext.s0d1v1.x';
switch data.SDF_DATA_HDR.zz_xResolution_type
    case {'linear'} % X-axis has a linear scale
        n = 0:data.SDF_DATA_HDR.num_of_points-1;
        data.SDF_XDATA_HDR.zz_data = ...
            data.SDF_DATA_HDR.abscissa_firstX + ...
            data.SDF_DATA_HDR.abscissa_deltaX * n;
    case {'logarithmic'} % X-axis has a log scale
        n = 0:data.SDF_XDATA_HDR.num_of_points-1;
        data.SDF_XDATA_HDR.zz_data = ...
            data.SDF_DATA_HDR.abscissa_firstX * ...
            data.SDF_DATA_HDR.abscissa_deltaX ^ n;
        %    case {'arbitrary, one per file'}
        %    case {'arbitrary, one per data type'}
        %    case {'arbitrary, one per trace'}
    otherwise
        % Issue warning since this section of code was never tested (lack of test input files)
        warning([data.SDF_ADDTL.filename ': An untested section of code was executed in '...
            'SDF_Single_TraceX: data.SDF_DATA_HDR.zz_xResolution_type = ''' ...
            data.SDF_DATA_HDR.zz_xResolution_type '''']);
        % Issue warning since this section is not fully implemented
        warning([data.SDF_ADDTL.filename ': An un-implmented section of code was executed in '...
            'SDF_Single_TraceX: data.SDF_DATA_HDR.zz_xResolution_type = ''' ...
            data.SDF_DATA_HDR.zz_xResolution_type '''']);
        
        % Calculate how many bytes there are per datapoint
        var_size = dataTypeByteSize(data.SDF_DATA_HDR.xdata_type);
        
        % Reshape the _raw_data to make a 2D array of bytes relevant to x-axis
        data.SDF_XDATA_HDR.zz_raw_data = ...
            reshape(data.SDF_XDATA_HDR.zz_raw_data, ...
            var_size,length(data.SDF_XDATA_HDR.zz_raw_data)/var_size);
        
        % Convert the smaller arrays to their appropriate data types.
        for n = 1:size(data.SDF_XDATA_HDR.zz_raw_data,2)
            eval(['data.SDF_XDATA_HDR.zz_data(n) = ' ...
                'SDF_' data.SDF_DATA_HDR.zz_xdata_type ...
                '(data.SDF_XDATA_HDR.zz_raw_data(:,n));']);
        end
        
        % Reshape the array to de-interlieve the datasets.
        data.SDF_XDATA_HDR.zz_data = ...
            reshape(data.SDF_XDATA_HDR.zz_data, ...
            data.SDF_DATA_HDR.xPerPoint, ...
            length(data.SDF_XDATA_HDR.zz_data)/data.SDF_DATA_HDR.xPerPoint);
end
% Save the data to the standardise export location
eval([var_name ' = data.SDF_XDATA_HDR.zz_data;']);
% Extract user-readable data assiciated with the processed channels/axes.
data = SDF_extract_labels(data,var_name);
retval = data; % Return data
end
function [retval] = SDF_extract_labels(data,var_name)
%SDF_EXTRACT_LABELS - Extracts the trace units (e.g. V^2/Hz), and other relevant descriptors, such
% as channel/module identifiers for the trace specified in 'var_name'.
%  This code is an implementation of the SDF standard as defined in:
%  'User's Guide - Standard Data Format Utilities, Version B.02.01'
%  by Agilent Technologies
%  Manufacturing Part Number: 5963-1715
%  Printed in USA
%  December 1994
%  © Copyright 1989, 1991-94, 2005 Agilent Technologies, Inc.
%
% Syntax: [retval] = SDF_extract_labels(data,var_name)
%
% Inputs:
%   data - Extracted SDF headers, containing the headers, and extracted trace.
%   var_name - Trace structure variable name, matching the format 'data.ext.s#d#v#.axis', where for:
%              s (scan number), # >= 0, since 'Scan 0' represents non-scan data, e.g. 's0'
%              d (data header number), # > 0, since it is an index, e.g. 'd2'
%              v (vector header number), # > 0, since it is an index, e.g. 'v2'
%              axis - specifies which axis is beinf processed: 'x' or 'y'
%
% Outputs:
%   retval - Extracted SDF headers, and processed labels.
%            The extracted data is stores in retval.ext.s#d#v# as follows:
%              - xUnit, the unit-label associated with the x-axis by the SDF file
%              - xResolution_type, identifies if data is linear, logarithmic or one of
%                  the three arbitrary formats.
%              - xLabel, the domain of the trace: 'Time', 'Frequency' or blank.
%                  (Based on the x-channel units)
%              - ch#num, the physical channel number from which the trace was taken (# is 1 or 2)
%              - ch#label, the stored label of the physical channel from which the trace was taken.
%              - ch#moduleId, location of the channel in the instrument (or instrument i.d.).
%              - ch#serialNum, instrument or module serial number.
%              - yUnit, the unit-label associated with the y-axis by the SDF file.
%              - yLabel, DATA_HDR dataType variable with the first letter of each word capitalised.
%              - dataType, the DATA_HDR dataType variable.
%              - dataTitle, the DATA_HDR dataTitle variable.
%              - yIsPowerData, the DATA_HDR yIsPowerData variable.
%              - idx, the vector of valid data identified by the instrument:
%                  [SDF_MEAS_HDR.startFreqIndex:SDF_MEAS_HDR.stopFreqIndex)+1]
%              - DATA_HDRnum, the DATA_HDR index (for convenience)
%              - VECTOR_HDRnum, the VECTOR_HDR index (for convenience)
%              - SCANnum, the SCAN number (for convenience)
%              - traceList, a list of every trace and its associated dataType.
%
% Other m-files required: none
% Subfunctions: capitaliseFirstLetters.
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: 04/04/2017
% © Copyright 2016-2017 Commonwealth of Australia, represented by the Department of Defence
% Interpret the variable name to extract the scan, data and vector numbers.
[s] = sscanf(var_name(1:end-2),'data.ext.s%dd%dv%d');
d = s(2); %DATA_HDR #
v = s(3); %VECTOR_HDR #
s = s(1); %SCAN #
x_or_y = var_name(end); %Determine if we are labelling the x or y axis
% Allow function to operate differently if x or y dataset is being processed
% This accounts for the fact that there is no x data extracted until the endof the program
switch x_or_y
    case 'x'
        % xLabel is always defined
        eval([var_name(1:end-1) 'xUnit = data.SDF_DATA_HDR(d).xUnit.label;']);
        % Save the resolution type (linear or logarithmic)
        eval([var_name(1:end-1) ...
            'xResolution_type = data.SDF_DATA_HDR(d).zz_xResolution_type;']);
        % Use the x label to identify is we are in the frequency or time domain
        if strcmp(data.SDF_DATA_HDR(d).xUnit.label,'Hz') % Frequency domain
            eval([var_name(1:end-1) 'xLabel = ''Frequency'';']);
        elseif strcmp(data.SDF_DATA_HDR(d).xUnit.label,'s') % Time domain
            eval([var_name(1:end-1) 'xLabel = ''Time'';']);
        else % Unknown unit used
            % Provide a warning
            warning([data.SDF_ADDTL.filename ': An unknown x-axis unit ''' ...
                data.SDF_DATA_HDR(d).xUnit.label ''' was used in ' ...
                'data.SDF_DATA_HDR(' num2str(d) ').xUnit.label, ' var_name(1:end-1) 'xLabel' ...
                ' has been left blank.']);
            % Provide blank variable
            eval([var_name(1:end-1) 'xLabel = '''';']);
        end
    case 'y'
        % Save the instrument dependent channel Label, model and serial number
        flag = [0 0]; % A flag to identify which channels are used
        for ch = 1 : 2 % Iterate over numerator and denominator channels
            tmp = data.SDF_VECTOR_HDR(v).the_CHANNEL_record(ch)+1; %Included 0 offset
            if tmp > 0
                % Channel Number
                eval([var_name(1:end-1) 'ch' num2str(ch) 'num = tmp;']);
                % Channel label
                eval([var_name(1:end-1) 'ch' num2str(ch) ...
                    'label = data.SDF_CHANNEL_HDR(tmp).channelLabel;']);
                % Module ID
                eval([var_name(1:end-1) 'ch' num2str(ch) ...
                    'moduleId = data.SDF_CHANNEL_HDR(tmp).moduleId;']);
                % Serial number
                eval([var_name(1:end-1) 'ch' num2str(ch) ...
                    'serialNum = data.SDF_CHANNEL_HDR(tmp).serialNum;']);
            else % Flag is the channel is unused
                flag(ch) = 1;
            end
        end
        
        % Check for presense of a yUnit label
        if length(data.SDF_DATA_HDR(d).yUnit.label)<1
            flag=[2 1]*flag';
            switch flag % If no units have been upplied, make them up using the channel data.
                case 0%[0 0] % Both channels are used (E.g. A transfer function)
                    eval([var_name(1:end-1) 'yUnit = [data.SDF_CHANNEL_HDR(1).engUnit.label ''/''  data.SDF_CHANNEL_HDR(2).engUnit.label];']);
                case 1%[0 1] % Only denominator channel is used (unlikely to ever occur)
                    eval([var_name(1:end-1) 'yUnit = data.SDF_CHANNEL_HDR(2).engUnit.label;']);
                case 2%[1 0] % Only numerator channel is used (E.g. noise/time measurement)
                    eval([var_name(1:end-1) 'yUnit = data.SDF_CHANNEL_HDR(1).engUnit.label;']);
                case 3%[1 1] % Neither channel is used (unlikely to ever occur, used as a catchall)
                    eval([var_name(1:end-1) 'yUnit = data.SDF_DATA_HDR(d).yUnit.label;']);
            end
        else % Use the yUnit label if it has been supplied
            eval([var_name(1:end-1) 'yUnit = data.SDF_DATA_HDR(d).yUnit.label;']);
        end
        % Use the datatype as a temporary label for the dataset.
        eval([var_name(1:end-1) 'yLabel = capitaliseFirstLetters(data.SDF_DATA_HDR(d).zz_dataType);']);
        % Copy the datatype without capitalisation
        eval([var_name(1:end-1) 'dataType = data.SDF_DATA_HDR(d).zz_dataType;']);
        % Copy the userdefined title for the dataset
        eval([var_name(1:end-1) 'dataTitle = data.SDF_DATA_HDR(d).dataTitle;']);
        % Record if the data is power data
        eval([var_name(1:end-1) 'yIsPowerData = data.SDF_DATA_HDR(d).zz_yIsPowerData;']);
        % Record the valid indexes
        eval([var_name(1:end-1) ...
            'idx=(data.SDF_MEAS_HDR.startFreqIndex:data.SDF_MEAS_HDR.stopFreqIndex)+1;']);
        % Save the DATA_HDR index (for convenience)
        eval([var_name(1:end-1) 'DATA_HDRnum = d;']);
        % Save the VECTOR_HDR index (for convenience)
        eval([var_name(1:end-1) 'VECTOR_HDRnum = v;']);
        % Save the SCAN number (for convenience)
        eval([var_name(1:end-1) 'SCANnum = s;']);
        % Save the tracetype and varname to a list of cells in data.ext
        data.ext.traceList = [data.ext.traceList ;...
            {['s',num2str(s, '%d'),'d',num2str(d, '%d'),'v',num2str(v,'%d')]},...
            { data.SDF_DATA_HDR(d).zz_dataType}];
end
retval = data;
end
function txt = capitaliseFirstLetters(txt)
%CAPITALISEFIRSTLETTERS - This function capitalises the first character in every word of a text string.
%
% Syntax: [txt] = capitaliseFirstLetters(txt)
%
% Inputs:
%   txt - Test requiring reformatting
%
% Outputs:
%   txt - The processed text string.
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: 04/04/2017
% © Copyright 2016-2017 Commonwealth of Australia, represented by the Department of Defence
txt(1) = upper(txt(1)); % Always capitalise the first char in the string_fill_char
idx = strfind(txt,' ')+1; % Identify first letter after each space
idx = idx(idx<length(txt)); % Remove case where last character is a space
for n = idx % Iterate over the characters to capitalise
    txt(n) = upper(txt(n));
end
end
function varSize = dataTypeByteSize(dataType)
%DATATYPEBYTESIZE - Calculates the number of bytes associated with dataType.
% dataType = 1, short  (varSize = 2 bytes)
% dataType = 2, long   (varSize = 4 bytes)
% dataType = 3, float  (varSize = 4 bytes)
% dataType = 4, double (varSize = 8 bytes)
%
% Syntax: [varSize] = dataTypeByteSize(dataType)
%
% Inputs:
%   dataType - Integer of value 1 to 4 (see SDF standard)
% Outputs:
%   varSize - Positive integer representing the number of bytes required.
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: 04/04/2017
% © Copyright 2016-2017 Commonwealth of Australia, represented by the Department of Defence
if dataType == 3 % 3 = float
    varSize = 4;
elseif(dataType  <= 4) % 1 = short, 2 = long, 4 = double
    varSize = dataType * 2;
else % Other datatypes have not been defined in the SDF standard.
    error('Unknown dataType');
end
end
function [retval] = SDF_Y_scale(chHdr,dataHdr,vctHdr,y)
%SDF_Y_SCALE - Scales and re-arranges trace to the appropriate units/shape.
%
% Syntax: [retval] = SDF_Y_scale(chHdr,dataHdr,vctHdr,y)
%
% Inputs:
%   chHdr - Channel headers relevant to the data.
%   dataHdr - Data header relevant to the data.
%   vctHdr - Vector header relevant to the data.
%   y - Unscaled data
% Outputs:
%   retval - Scaled and re-arranged results.
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: justin.dinale@dsto.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: 01/08/2018
% © Copyright 2016-2017 Commonwealth of Australia, represented by the Department of Defence
%SDF_Y_scale
% Calculate scaling factor base on dataheader type
y = double(y);
switch dataHdr.zz_dataType
    case 'time'
        % Since only one channel is used, identify which is valid
        ch_idx = vctHdr.the_CHANNEL_record > -1;
        % Extract relevant channel offset and scale, apply them
        retval = chHdr(ch_idx).channelOffset + y * chHdr(ch_idx).channelScale;
    case 'overload data'
        retval = y;
    case 'decimated time data'
        retval.overloadFlag = y(5:5:end);
        % the minimume/maximum values are in integer for, so need scaling.
        % Since only one channel is used, identify which is valid
        ch_idx = vctHdr.the_CHANNEL_record > -1;
        % Extract relevant channel offset and scale, apply them
        y = chHdr(ch_idx).channelOffset + y * chHdr(ch_idx).channelScale;
        retval.decimatedRealValue = y(1:5:end);
        retval.decimatedImaginaryValue = y(2:5:end);
        warning(['Decimated time data has been extracted. '...
            'This code was not tested. Please verify.']);
    case 'compressed time data'
        retval.overloadFlag = y(5:5:end);
        % the minimume/maximum values are in integer for, so need scaling.
        % Since only one channel is used, identify which is valid
        ch_idx = vctHdr.the_CHANNEL_record > -1;
        % Extract relevant channel offset and scale, apply them
        y = chHdr(ch_idx).channelOffset + y * chHdr(ch_idx).channelScale;
        retval.minimumRealValue = y(1:5:end);
        retval.minimumImaginaryValue = y(2:5:end);
        retval.maximumRealValue = y(3:5:end);
        retval.maximumImaginaryValue = y(4:5:end);
    case 'tachometer data'
        retval.number_of_tach_points = (dataHdr.total_rows * dataHdr.total_cols) * ...
            dataHdr.num_of_points + dataHdr.last_valid_index;
        retval.tach_pulses_per_rev = dataHdr.abscissa_deltaX;
        retval.tach_frequency = dataHdr.abscissa_firstX;
        retval.tach_time_sec = y/retval.tach_frequency;
        retval.tach_pulse_delta_sec = diff(retval.tach_time_sec);
        retval.tach_pulses_per_sec = 1./retval.tach_pulse_delta_sec;
        retval.tach_pulses_per_min = 60 * retval.tach_pulses_per_sec;
        retval.tach_rpm = retval.tach_pulses_per_min / retval.tach_pulses_per_rev;
        retval.userDelay = chHdr.userDelay; % Delay between tachometer zero count and start of capture.
        warning(['Tachometer data has been extracted. ' ...
            'This code was not tested. Please verify.']);
    case 'external trigger data'
        retval.number_of_ext_trigger_points = (dataHdr.total_rows * dataHdr.total_cols) * ...
            dataHdr.num_of_points + dataHdr.last_valid_index;
        retval.ext_trigger_pulses_per_rev = dataHdr.abscissa_deltaX;
        retval.ext_trigger_frequency = dataHdr.abscissa_firstX;
        retval.ext_trigger_time_sec = y/retval.ext_trigger_frequency;
        retval.ext_trigger_pulse_delta_sec = diff(retval.ext_trigger_time_sec);
        retval.ext_trigger_pulses_per_sec = 1./retval.ext_trigger_pulse_delta_sec;
        retval.ext_trigger_pulses_per_min = 60 * retval.ext_trigger_pulses_per_sec;
        retval.ext_trigger_rpm = retval.ext_trigger_pulses_per_min / retval.ext_trigger_pulses_per_rev;
        retval.userDelay = chHdr.userDelay; % Delay between tachometer zero count and start of capture.
        warning(['External trigger data has been extracted. ' ...
            'This code was not tested. Please verify.']);
        
    otherwise % Assume everything else is treated the same way as frequency domain
        %% The following window correction will require further work. The documentation
        % is unclear  on how to identify which type of correction is required when a
        % correction has not already been applied.
        % Correction factors
        tmp(1)=chHdr(vctHdr.the_CHANNEL_record(1)+1);
        if (vctHdr.the_CHANNEL_record(2) >=0)        
          tmp(2)=chHdr(vctHdr.the_CHANNEL_record(2)+1);
        else
          tmp(2)=tmp(1);
        end
        chHdr = tmp;
        WINDOW_corr(1:2) = 1; % Initialise flag variable
        if  or(strcmp(dataHdr.zz_domain,'frequency') , ...
                strcmp(dataHdr.zz_domain,'order'))
            for m = (1:2) %Iterate over numberator and denominator.
                switch chHdr(m).window.windowCorrMode
                    case 0 % No window
                        WINDOW_corr(m) = chHdr(m).window.narrowBandCorr;%1;
                        warning(['No window correction has been applied by the instrument.'...
                        ' Applying narrowband correction by default.']);
                    case 1 % Narrow band window
                        WINDOW_corr(m) = 1;%chHdr(m).window.narrowBandCorr;
                    case 2 % Broadband window
                        WINDOW_corr(m) = 1;%chHdr(m).window.wideBandCorr;
                end %switch chHdr(m).window.windowCorrMode
            end % for m = (1:2)
        end %if  or(strcmp(data.SDF_DATA_HDR(n).zz_domain,'frequency') , ...
        %    strcmp(data.SDF_DATA_HDR(n).zz_domain,'order'))
        
   
        % Calculare the integer to engineerig units and 'power' of the channel
        % corrections
        EU_corr(1) = chHdr(1).int2engrUnit;
        EU_corr(2) = chHdr(2).int2engrUnit;
        % Divide VECTOR_HDR.powrOfChan by 48 as specified in the standard
        POW_corr(1) = double(vctHdr.powrOfChan(1)/48);
        POW_corr(2) = double(vctHdr.powrOfChan(2)/48);
        if vctHdr.the_CHANNEL_record(2) == -1
            % Forcibly disable WINDOW correction, due to them already having been applied.
            % This hack is required when only one channel is used. See page B-30 (Note & final paragraph)
            WINDOW_corr(2) = 1;%[1 1]
            EU_corr(2) = 1;
        end
        % Make array of 1's and 0's on whether to apply correction.
        use_channel = (vctHdr.the_CHANNEL_record ~= -1);
        % Page B-33 '4. Create a correction factor by multiplying the two chanenl correction factors'
        correction = prod((WINDOW_corr./EU_corr).^(use_channel .* POW_corr));
        % Page B-31 disagrees with B-33 (unless reciprocal is part of SDF_VECTOR_HDR.powrOfChan(2))
        %correction = (WINDOW_corr./EU_corr).^(use_channel .* POW_corr);
        %correction = correction(1)/correction(2);
        
        % If data is complex then take real and imaginary parts.
        if dataHdr.yIsComplex
            y = y(1:2:end-1) + 1i * y(2:2:end);
        end
        % Reshape the data to get the multiple traces as specified in
        % SDF_DATA_HDR(n).yPerPoint
        y = reshape(y, dataHdr.yPerPoint, length(y)/dataHdr.yPerPoint);
        % Apply the correction
        retval = y * correction;
        
end
end
function [retval] = setGlobal(var,var1)
% Debugging function.  Push a local variale to be global, allowing it to be accessed.
global debug_var
global debug_var1
debug_var = var;
debug_var1 = var1;
end
