function [retval] = SDF_template (template)
%SDF_TEMPLATE - Provides an empty template containing the Standard Data Format (SDF) header 
%  information required to read generic HP/Agilent/Keysight SDF files.
%  The header structure information is detailed in:
%  "User's Guide - Standard Data Format Utilities, Version B.02.01"
%  by Agilent Technologies 
%  Manufacturing Part Number: 5963-1715
%  Printed in USA
%  December 1994
%  © Copyright 1989, 1991-94, 2005 Agilent Technologies, Inc.
% 
% Syntax: [retval] = SDF_template (template)
%
% Inputs:
%   template - String of the desired template, options are:
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
% Outputs:
%   data - Extracted SDF headers, and processed signal traces.
%   file_raw - Unprocessed binary stream.
%
% Other m-files required: none
% Subfunctions: SDF_CHANNEL_HDR_Template, SDF_COMMENT_HDR_Template, SDF_DATA_HDR_Template,
%   SDF_FILE_HDR_Template, SDF_MEAS_HDR_Template, SDF_SCAN_STRUCT_Template, SDF_SCANS_BIG_Template,
%   SDF_SCANS_VAR_Template, SDF_UNIT_Template, SDF_VECTOR_HDR_Template, SDF_WINDOW_Template,
%   SDF_XDATA_HDR_Template, SDF_YDATA_HDR_Template, SDF_UNIQUE_Template.
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: N/A
% © Copyright 2016 Commonwealth of Australia, represented by the Department of Defence
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
% Wrapper function to call any of the Template functions within the file.
  eval(['retval=' template '_Template();']); 
end
function  SDF_CHANNEL_HDR=SDF_CHANNEL_HDR_Template()
%SDF_CHANNEL_HDR_TEMPLATE - Provides a empty template containing the requested header information
%
%                 - SDF_CHANNEL_HDR: Contains channel-specific information for one channel 
%                                    used in the measurement.
% 
% Syntax: [retval] = SDF_CHANNEL_HDR_TEMPLATE()
%
% Inputs: none
%
% Outputs:
%   retval - Extracted SDF header information.
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: 16/03/2018
% © Copyright 2016-2018 Commonwealth of Australia, represented by the Department of Defence
%
% v1.0   27/04/2018 Changed version number to match MATLAB Central
% v0.2.3 16/03/2018 Changed SDF_CHANNEL_HDR.overloaded template entry to
% deal with error in an overloaded file. The value '3' (out of 0-1 range)
% was presen for a file which exhibited 'overloaded' on the instrument
% screen.
SDF_CHANNEL_HDR(1).FieldIndex=1;
SDF_CHANNEL_HDR(1).BinaryIndex=[1 2];
SDF_CHANNEL_HDR(1).FieldName='recordType';
SDF_CHANNEL_HDR(1).DataType='short';
SDF_CHANNEL_HDR(1).RangeUnits='14';
SDF_CHANNEL_HDR(2).FieldIndex=2;
SDF_CHANNEL_HDR(2).BinaryIndex=[3 6];
SDF_CHANNEL_HDR(2).FieldName='recordSize';
SDF_CHANNEL_HDR(2).DataType='long';
SDF_CHANNEL_HDR(2).RangeUnits='212 bytes';
SDF_CHANNEL_HDR(3).FieldIndex=3;
SDF_CHANNEL_HDR(3).BinaryIndex=[7 10];
SDF_CHANNEL_HDR(3).FieldName='unique_record';
SDF_CHANNEL_HDR(3).DataType='long';
SDF_CHANNEL_HDR(3).RangeUnits='-1:2^31-1';
SDF_CHANNEL_HDR(3).Description=...
['byte offset from the beginning of the file to ' ...
'a record containing an instrument-specific vector header. ' ...
'May be ignored if recalled into a different type instrument.'];
SDF_CHANNEL_HDR(4).FieldIndex=4;
SDF_CHANNEL_HDR(4).BinaryIndex=[11 40];
SDF_CHANNEL_HDR(4).FieldName='channelLabel';
SDF_CHANNEL_HDR(4).DataType='char[30]';
SDF_CHANNEL_HDR(4).RangeUnits='i.d.';
SDF_CHANNEL_HDR(4).Description=['channel documentation'];
SDF_CHANNEL_HDR(5).FieldIndex=5;
SDF_CHANNEL_HDR(5).BinaryIndex=[41 52];
SDF_CHANNEL_HDR(5).FieldName='moduleId';
SDF_CHANNEL_HDR(5).DataType='char[12]';
SDF_CHANNEL_HDR(5).RangeUnits='';
SDF_CHANNEL_HDR(5).Description=['location of channel in instrument.'];
SDF_CHANNEL_HDR(6).FieldIndex=6;
SDF_CHANNEL_HDR(6).BinaryIndex=[53 64];
SDF_CHANNEL_HDR(6).FieldName='serialNum';
SDF_CHANNEL_HDR(6).DataType='char[12]';
SDF_CHANNEL_HDR(6).RangeUnits='';
SDF_CHANNEL_HDR(6).Description=['instrument (or module) serial number.'];
SDF_CHANNEL_HDR(7).FieldIndex=7;
SDF_CHANNEL_HDR(7).BinaryIndex=[65 88];
SDF_CHANNEL_HDR(7).FieldName='window';
SDF_CHANNEL_HDR(7).DataType='struct';
SDF_CHANNEL_HDR(7).RangeUnits='see SDF_WINDOW';
SDF_CHANNEL_HDR(7).Description=[''];
SDF_CHANNEL_HDR(8).FieldIndex=8;
SDF_CHANNEL_HDR(8).BinaryIndex=[89 90];
SDF_CHANNEL_HDR(8).FieldName='weight';
SDF_CHANNEL_HDR(8).DataType='short';
SDF_CHANNEL_HDR(8).RangeUnits='0:3';
SDF_CHANNEL_HDR(8).Description=[''];
SDF_CHANNEL_HDR(8).Table=[...
{'0'} {'no weighting'};...
{'1'} {'A-weighting'};...
{'2'} {'B-weighting'};...
{'3'} {'C-weighting'};...
];
SDF_CHANNEL_HDR(30).FieldIndex=8;
SDF_CHANNEL_HDR(30).BinaryIndex=[91 94];
SDF_CHANNEL_HDR(30).FieldName='delayOld';
SDF_CHANNEL_HDR(30).DataType='float';
SDF_CHANNEL_HDR(30).RangeUnits='0:3';
SDF_CHANNEL_HDR(30).Description=['*** Prior to version 3.0'];
SDF_CHANNEL_HDR(9).FieldIndex=9;
SDF_CHANNEL_HDR(9).BinaryIndex=[93 96];
SDF_CHANNEL_HDR(9).FieldName='range';
SDF_CHANNEL_HDR(9).DataType='float';
SDF_CHANNEL_HDR(9).RangeUnits='unit is dBV, range is i.d. & includes overhead for scaling';
SDF_CHANNEL_HDR(9).Description=[''];
SDF_CHANNEL_HDR(10).FieldIndex=10;
SDF_CHANNEL_HDR(10).BinaryIndex=[99 100];
SDF_CHANNEL_HDR(10).FieldName='direction';
SDF_CHANNEL_HDR(10).DataType='short';
SDF_CHANNEL_HDR(10).RangeUnits='-9:9';
SDF_CHANNEL_HDR(10).Description=[''];
SDF_CHANNEL_HDR(10).Table=[...
 {'-9'} {'-TZ'};...
 {'-8'} {'-TY'};...
 {'-7'} {'-TX'};...
 {'-3'} {'-Z'};...
 {'-2'} {'-Y'};...
 {'-1'} {'-X'};...
 {'0'} {'no direction specified'};...
 {'1'} {'X'};...
 {'2'} {'Y'};...
 {'3'} {'Z'};...
 {'4'} {'R (radial)'};...
 {'5'} {'T (tangential � theta angle)'};...
 {'6'} {'P (tangential � phi angle)'};...
 {'7'} {'TX'};...
 {'8'} {'TY'};...
 {'9'} {'TZ'};...
];
SDF_CHANNEL_HDR(11).FieldIndex=11;
SDF_CHANNEL_HDR(11).BinaryIndex=[101 102];
SDF_CHANNEL_HDR(11).FieldName='pointNum';
SDF_CHANNEL_HDR(11).DataType='short';
SDF_CHANNEL_HDR(11).RangeUnits='-0:32676';
SDF_CHANNEL_HDR(11).Description=['test point on device under test'];
SDF_CHANNEL_HDR(12).FieldIndex=12;
SDF_CHANNEL_HDR(12).BinaryIndex=[103 104];
SDF_CHANNEL_HDR(12).FieldName='coupling';
SDF_CHANNEL_HDR(12).DataType='short';
SDF_CHANNEL_HDR(12).RangeUnits='0:1';
SDF_CHANNEL_HDR(12).Description=[''];
SDF_CHANNEL_HDR(12).Table=[...
 {'0'} {'DC'};...
 {'1'} {'AC'};...
];
SDF_CHANNEL_HDR(13).FieldIndex=13;
SDF_CHANNEL_HDR(13).BinaryIndex=[105 106];
SDF_CHANNEL_HDR(13).FieldName='overloaded';
SDF_CHANNEL_HDR(13).DataType='short';
SDF_CHANNEL_HDR(13).RangeUnits='0:1';
SDF_CHANNEL_HDR(13).Description=[''];
SDF_CHANNEL_HDR(13).Table=[...
 {'0'} {'no'};...
 {'1'} {'yes'};...
 {'2'} {'yes, error - undocumented value'};...
 {'3'} {'yes, error - undocumented value'};...
];
SDF_CHANNEL_HDR(14).FieldIndex=14;
SDF_CHANNEL_HDR(14).BinaryIndex=[107 116];
SDF_CHANNEL_HDR(14).FieldName='intLabel';
SDF_CHANNEL_HDR(14).DataType='char[10]';
SDF_CHANNEL_HDR(14).RangeUnits='i.d.';
SDF_CHANNEL_HDR(14).Description=...
['label for the instrument’s internal unit (such as V)'];
SDF_CHANNEL_HDR(15).FieldIndex=15;
SDF_CHANNEL_HDR(15).BinaryIndex=[117 138];
SDF_CHANNEL_HDR(15).FieldName='engUnit';
SDF_CHANNEL_HDR(15).DataType='struct';
SDF_CHANNEL_HDR(15).RangeUnits='see SDF_UNIT';
SDF_CHANNEL_HDR(15).Description=...
['engineering unit (EU) definition for this channel'];
SDF_CHANNEL_HDR(16).FieldIndex=16;
SDF_CHANNEL_HDR(16).BinaryIndex=[139 142];
SDF_CHANNEL_HDR(16).FieldName='int2engrUnit';
SDF_CHANNEL_HDR(16).DataType='float';
SDF_CHANNEL_HDR(16).RangeUnits='|10^34 (except 0)';
SDF_CHANNEL_HDR(16).Description=...
['EU correction factor. Divide internal-unit data ' ...
'by this value to get EU data'];
SDF_CHANNEL_HDR(17).FieldIndex=17;
SDF_CHANNEL_HDR(17).BinaryIndex=[143 146];
SDF_CHANNEL_HDR(17).FieldName='inputImpedance';
SDF_CHANNEL_HDR(17).DataType='float';
SDF_CHANNEL_HDR(17).RangeUnits='unit ohm, range i.d.';
SDF_CHANNEL_HDR(17).Description=['Input impedance'];
SDF_CHANNEL_HDR(18).FieldIndex=18;
SDF_CHANNEL_HDR(18).BinaryIndex=[147 148];
SDF_CHANNEL_HDR(18).FieldName='channelAttribute';
SDF_CHANNEL_HDR(18).DataType='short';
SDF_CHANNEL_HDR(18).RangeUnits='-99:3';
SDF_CHANNEL_HDR(18).Description=[''];
SDF_CHANNEL_HDR(18).Table=[...
 {'-99'} {'unknown attribute'};...
 {'0'} {'no attribute'};...
 {'1'} {'tach attribute'};...
 {'2'} {'reference attribute'};...
 {'3'} {'tach and reference attribute'};...
 {'4'} {'clockwise attribute'};...
];
SDF_CHANNEL_HDR(19).FieldIndex=19;
SDF_CHANNEL_HDR(19).BinaryIndex=[149 150];
SDF_CHANNEL_HDR(19).FieldName='aliasProtected';
SDF_CHANNEL_HDR(19).DataType='short';
SDF_CHANNEL_HDR(19).RangeUnits='0:1';
SDF_CHANNEL_HDR(19).Description=[''];
SDF_CHANNEL_HDR(19).Table=[...
 {'0'} {'data was not alias protected'};...
 {'1'} {'alias protected'};...
];
SDF_CHANNEL_HDR(20).FieldIndex=20;
SDF_CHANNEL_HDR(20).BinaryIndex=[151 152];
SDF_CHANNEL_HDR(20).FieldName='aliasProtected';
SDF_CHANNEL_HDR(20).DataType='short';
SDF_CHANNEL_HDR(20).RangeUnits='0:1';
SDF_CHANNEL_HDR(20).Description=[''];
SDF_CHANNEL_HDR(20).Table=[...
 {'0'} {'analog input channel'};...
 {'1'} {'digital input channel'};...
];
SDF_CHANNEL_HDR(21).FieldIndex=21;
SDF_CHANNEL_HDR(21).BinaryIndex=[153 160];
SDF_CHANNEL_HDR(21).FieldName='channelScale';
SDF_CHANNEL_HDR(21).DataType='double';
SDF_CHANNEL_HDR(21).RangeUnits='range is i.d.';
SDF_CHANNEL_HDR(21).Description=['see channelOffset below'];
SDF_CHANNEL_HDR(22).FieldIndex=22;
SDF_CHANNEL_HDR(22).BinaryIndex=[161 168];
SDF_CHANNEL_HDR(22).FieldName='channelOffset';
SDF_CHANNEL_HDR(22).DataType='double';
SDF_CHANNEL_HDR(22).RangeUnits='range is i.d.';
SDF_CHANNEL_HDR(22).Description=...
['when the data type is "short" or "long" the ' ...
'following formula will convert the data to volts:\n' ...
'Volts=channelOffset + ( channelScale ö Ydata)'];
SDF_CHANNEL_HDR(23).FieldIndex=23;
SDF_CHANNEL_HDR(23).BinaryIndex=[169 176];
SDF_CHANNEL_HDR(23).FieldName='gateBegin';
SDF_CHANNEL_HDR(23).DataType='double';
SDF_CHANNEL_HDR(23).RangeUnits='unit is sec, range is i.d.';
SDF_CHANNEL_HDR(23).Description=['Gated sweep start time'];
SDF_CHANNEL_HDR(24).FieldIndex=24;
SDF_CHANNEL_HDR(24).BinaryIndex=[177 184];
SDF_CHANNEL_HDR(24).FieldName='gateEnd';
SDF_CHANNEL_HDR(24).DataType='double';
SDF_CHANNEL_HDR(24).RangeUnits='unit is sec, range is i.d.';
SDF_CHANNEL_HDR(24).Description=['Gated sweep stop time'];
SDF_CHANNEL_HDR(25).FieldIndex=25;
SDF_CHANNEL_HDR(25).BinaryIndex=[185 192];
SDF_CHANNEL_HDR(25).FieldName='userDelay';
SDF_CHANNEL_HDR(25).DataType='double';
SDF_CHANNEL_HDR(25).RangeUnits='unit is sec, range is i.d.';
SDF_CHANNEL_HDR(25).Description=...
['User specified input channel time delay or line length (not trigger delay)'];
SDF_CHANNEL_HDR(26).FieldIndex=26;
SDF_CHANNEL_HDR(26).BinaryIndex=[193 200];
SDF_CHANNEL_HDR(26).FieldName='delay';
SDF_CHANNEL_HDR(26).DataType='double';
SDF_CHANNEL_HDR(26).RangeUnits='unit is sec, range is i.d.';
SDF_CHANNEL_HDR(26).Description=...
['amount of time between trigger event and start of data collection'];
SDF_CHANNEL_HDR(27).FieldIndex=27;
SDF_CHANNEL_HDR(27).BinaryIndex=[201 208];
SDF_CHANNEL_HDR(27).FieldName='carrierFreq';
SDF_CHANNEL_HDR(27).DataType='double';
SDF_CHANNEL_HDR(27).RangeUnits='unit is Hz, range is i.d.';
SDF_CHANNEL_HDR(27).Description=['carrier frequency for demodulated data'];
SDF_CHANNEL_HDR(28).FieldIndex=28;
SDF_CHANNEL_HDR(28).BinaryIndex=[209 210];
SDF_CHANNEL_HDR(28).FieldName='channelNumber';
SDF_CHANNEL_HDR(28).DataType='short';
SDF_CHANNEL_HDR(28).RangeUnits='0:32767';
SDF_CHANNEL_HDR(28).Description=['zero-based channel number'];
SDF_CHANNEL_HDR(29).FieldIndex=29;
SDF_CHANNEL_HDR(29).BinaryIndex=[211 212];
SDF_CHANNEL_HDR(29).FieldName='channelModule';
SDF_CHANNEL_HDR(29).DataType='short';
SDF_CHANNEL_HDR(29).RangeUnits='0:32767';
SDF_CHANNEL_HDR(29).Description=['zero-based channel module'];
end
function  SDF_COMMENT_HDR =  SDF_COMMENT_HDR_Template()
%SDF_COMMENT_HDR_TEMPLATE - Provides a empty template containing the requested header information
%
%                 - SDF_COMMENT_HDR: Contains text information associated with the file.
%
% Syntax: [retval] = SDF_COMMENT_HDR_TEMPLATE()
%
% Inputs: none
%
% Outputs:
%   retval - Extracted SDF header information.
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: N/A
% © Copyright 2016 Commonwealth of Australia, represented by the Department of Defence
SDF_COMMENT_HDR(1).FieldIndex=1;
SDF_COMMENT_HDR(1).BinaryIndex=[1 2];
SDF_COMMENT_HDR(1).FieldName='recordType';
SDF_COMMENT_HDR(1).DataType = 'short';
SDF_COMMENT_HDR(1).RangeUnits='20';
SDF_COMMENT_HDR(2).FieldIndex=2;
SDF_COMMENT_HDR(2).BinaryIndex=[3 6];
SDF_COMMENT_HDR(2).FieldName='recordSize';
SDF_COMMENT_HDR(2).DataType = 'long';
SDF_COMMENT_HDR(2).RangeUnits='variable';
SDF_COMMENT_HDR(3).FieldIndex=3;
SDF_COMMENT_HDR(3).BinaryIndex=[7 10];
SDF_COMMENT_HDR(3).FieldName='unique_record';
SDF_COMMENT_HDR(3).DataType = 'long';
SDF_COMMENT_HDR(3).RangeUnits='-1:(231)-1';
SDF_COMMENT_HDR(3).Description=...
['byte offset from the beginning of the file to a ' ...
'record containing an instrument-specific comment header. May ' ...
'be ignored if recalled into a different type instrument.'];
SDF_COMMENT_HDR(4).FieldIndex=4;
SDF_COMMENT_HDR(4).BinaryIndex=[11 14];
SDF_COMMENT_HDR(4).FieldName='headersize';
SDF_COMMENT_HDR(4).DataType = 'long';
SDF_COMMENT_HDR(4).RangeUnits='24';
SDF_COMMENT_HDR(4).Description=...
['size of the header portion of this record (excluding the comment text).'];
SDF_COMMENT_HDR(5).FieldIndex=5;
SDF_COMMENT_HDR(5).BinaryIndex=[15 18];
SDF_COMMENT_HDR(5).FieldName='comment_bytes';
SDF_COMMENT_HDR(5).DataType = 'long';
SDF_COMMENT_HDR(5).RangeUnits='-1:recordSize-headerSize';
SDF_COMMENT_HDR(5).Description=...
['size of comment (in bytes). This size may be ' ...
'smaller than the comment text area. If the size of the text is -1, ' ...
'then the entire comment text area is valid (or until an end-of-text ' ...
'marker is found).'];
SDF_COMMENT_HDR(6).FieldIndex=6;
SDF_COMMENT_HDR(6).BinaryIndex=[19 20];
SDF_COMMENT_HDR(6).FieldName='comment_type';
SDF_COMMENT_HDR(6).DataType = 'short';
SDF_COMMENT_HDR(6).RangeUnits='0:0';
SDF_COMMENT_HDR(6).Description=...
['type of comment data'];
SDF_COMMENT_HDR(7).FieldIndex=7;
SDF_COMMENT_HDR(7).BinaryIndex=[21 22];
SDF_COMMENT_HDR(7).FieldName='scope_type';
SDF_COMMENT_HDR(7).DataType = 'short';
SDF_COMMENT_HDR(7).RangeUnits='0:4';
SDF_COMMENT_HDR(7).Description=...
['tells which type of header the comment applies to'];
SDF_COMMENT_HDR(7).Table=[...
{'0'} {'entire file'};...
{'1'} {'SDF_DATA_HDR'};...
{'2'} {'SDF_VECTOR_HDR'};...
{'3'} {'SDF_CHANNEL_HDR'};...
{'4'} {'SDF_SCAN_STRUCT'};...
];
SDF_COMMENT_HDR(8).FieldIndex=8;
SDF_COMMENT_HDR(8).BinaryIndex=[23 24];
SDF_COMMENT_HDR(8).FieldName='scope_info';
SDF_COMMENT_HDR(8).DataType = 'short';
SDF_COMMENT_HDR(8).RangeUnits='-1:32767';
SDF_COMMENT_HDR(8).Description=...
['the index of the header associated with the ' ...
'scope_type (-1 = no specific header)'];
end
function  SDF_DATA_HDR=SDF_DATA_HDR_Template()
%SDF_DATA_HDR_TEMPLATE - Provides a empty template containing the requested header information
%
%                 - SDF_DATA_HDR:    Tells you how reconstruct one block of measurement results 
%                                    (x- and y-axis values for every point of every trace).
%
% Syntax: [retval] = SDF_DATA_HDR_TEMPLATE()
%
% Inputs: none
%
% Outputs:
%   retval - Extracted SDF header information.
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: N/A
% © Copyright 2016 Commonwealth of Australia, represented by the Department of Defence
SDF_DATA_HDR(1).FieldIndex=1;
SDF_DATA_HDR(1).BinaryIndex=[1 2];
SDF_DATA_HDR(1).FieldName='recordType';
SDF_DATA_HDR(1).DataType='short';
SDF_DATA_HDR(1).RangeUnits='12';
SDF_DATA_HDR(2).FieldIndex=2;
SDF_DATA_HDR(2).BinaryIndex=[3 6];
SDF_DATA_HDR(2).FieldName='recordSize';
SDF_DATA_HDR(2).DataType='long';
SDF_DATA_HDR(2).RangeUnits='148 bytes';
SDF_DATA_HDR(3).FieldIndex=3;
SDF_DATA_HDR(3).BinaryIndex=[7 10];
SDF_DATA_HDR(3).FieldName='unique_record';
SDF_DATA_HDR(3).DataType='long';
SDF_DATA_HDR(3).RangeUnits='-1:2^31-1';
SDF_MEAS_HDR(3).Description=['byte offset from the beginning of the file ' ...
'to a record containing an instrument-specific data header. ' ...
'May be ignored if recalled into a different type instrument.'];
SDF_DATA_HDR(4).FieldIndex=4;
SDF_DATA_HDR(4).BinaryIndex=[11 26];
SDF_DATA_HDR(4).FieldName='dataTitle';
SDF_DATA_HDR(4).DataType='char[16]';
SDF_DATA_HDR(4).RangeUnits='i.d.';
SDF_MEAS_HDR(4).Description=['instrument- or user-supplied name ' ...
'for data type.'];
SDF_DATA_HDR(5).FieldIndex=5;
SDF_DATA_HDR(5).BinaryIndex=[27 28];
SDF_DATA_HDR(5).FieldName='domain';
SDF_DATA_HDR(5).DataType='short';
SDF_DATA_HDR(5).RangeUnits='-99, 0:6';
SDF_MEAS_HDR(5).Description=[''];
SDF_DATA_HDR(5).Table=[...
 {'-99'} {'unknown'};...
 {'0'} {'frequency'};...
 {'1'} {'time'};...
 {'2'} {'amplitude'};...
 {'3'} {'RPM'};...
 {'4'} {'order'};...
 {'5'} {'channel'};...
 {'6'} {'octave'};...
];
SDF_DATA_HDR(6).FieldIndex=6;
SDF_DATA_HDR(6).BinaryIndex=[29 30];
SDF_DATA_HDR(6).FieldName='dataType';
SDF_DATA_HDR(6).DataType='short';
SDF_DATA_HDR(6).RangeUnits='-99, 0:76';
SDF_MEAS_HDR(6).Description=[''];
SDF_DATA_HDR(6).Table=[...
 {'-99'} {'unknown'};...
 {'0'} {'time'};...
 {'1'} {'linear spectrum'};...
 {'2'} {'auto-power spectrum'};...
 {'3'} {'cross-power spectrum'};...
 {'4'} {'frequency response'};...
 {'5'} {'auto-correlation'};...
 {'6'} {'cross-correlation'};...
 {'7'} {'impulse response'};...
 {'8'} {'ordinary coherence'};...
 {'9'} {'partial coherence'};...
 {'10'} {'multiple coherence'};...
 {'11'} {'full octave'};...
 {'12'} {'third octave'};...
 {'13'} {'convolution'};...
 {'14'} {'histogram'};...
 {'15'} {'probability density function'};...
 {'16'} {'cumulative density function'};...
 {'17'} {'power spectrum order tracking'};...
 {'18'} {'composite power tracking'};...
 {'19'} {'phase order tracking'};...
 {'20'} {'rpm spectral'};...
 {'21'} {'order ratio'};...
 {'22'} {'orbit'};...
 {'23'} {'HP 35650 series calibration'};...
 {'24'} {'sine rms pwr data'};...
 {'25'} {'sine variance data'};...
 {'26'} {'sine range data'};...
 {'27'} {'sine settle time data'};...
 {'28'} {'sine integ time data'};...
 {'29'} {'sine source data'};...
 {'30'} {'sine overload data'};...
 {'31'} {'sine linear data'};...
 {'32'} {'synthesis'};...
 {'33'} {'curve fit weighting function'};...
 {'34'} {'frequency corrections (for capture)'};...
 {'35'} {'all pass time data'};...
 {'36'} {'norm reference data'};...
 {'37'} {'tachometer data'};...
 {'38'} {'limit line data'};...
 {'39'} {'twelfth octave data'};...
 {'40'} {'S11 data'};...
 {'41'} {'S21 data'};...
 {'42'} {'S12 data'};...
 {'43'} {'S22 data'};...
 {'44'} {'PSD data'};...
 {'45'} {'decimated time data'};...
 {'46'} {'overload data'};...
 {'47'} {'compressed time data'};...
 {'48'} {'external trigger data'};...
 {'49'} {'pressure data'};...
 {'50'} {'intensity data'};...
 {'51'} {'PI index data'};...
 {'52'} {'velocity data'};...
 {'53'} {'PV index data'};...
 {'54'} {'sound power data'};...
 {'55'} {'field indicator data'};...
 {'56'} {'partial power data'};...
 {'57'} {'Ln 1 data'};...
 {'58'} {'Ln 10 data'};...
 {'59'} {'Ln 50 data'};...
 {'60'} {'Ln 90 data'};...
 {'61'} {'Ln 99 data'};...
 {'62'} {'Ln user data'};...
 {'63'} {'T20 data'};...
 {'64'} {'T30 data'};...
 {'65'} {'RT60 data'};...
 {'66'} {'average count data'};...
 {'68'} {'IQ measured time'};...
 {'69'} {'IQ measured spectrum'};...
 {'70'} {'IQ reference time'};...
 {'71'} {'IQ reference spectrum'};...
 {'72'} {'IQ error magnitude'};...
 {'73'} {'IQ error phase'};...
 {'74'} {'IQ error vector time'};...
 {'75'} {'IQ error vector spectrum'};...
 {'76'} {'symbol table data'};...
];
SDF_DATA_HDR(7).FieldIndex=7;
SDF_DATA_HDR(7).BinaryIndex=[31 32];
SDF_DATA_HDR(7).FieldName='num_of_pointsOld';
SDF_DATA_HDR(7).DataType='short';
SDF_DATA_HDR(7).RangeUnits='';
SDF_MEAS_HDR(7).Description=['*** Prior to version 3.0'];
SDF_DATA_HDR(8).FieldIndex=8;
SDF_DATA_HDR(8).BinaryIndex=[33 34];
SDF_DATA_HDR(8).FieldName='last_valid_indexOld';
SDF_DATA_HDR(8).DataType='short';
SDF_DATA_HDR(8).RangeUnits='';
SDF_MEAS_HDR(8).Description=['*** Prior to version 3.0'];
SDF_DATA_HDR(9).FieldIndex=9;
SDF_DATA_HDR(9).BinaryIndex=[35 38];
SDF_DATA_HDR(9).FieldName='abscissa_firstXOld';
SDF_DATA_HDR(9).DataType='float';
SDF_DATA_HDR(9).RangeUnits='';
SDF_MEAS_HDR(9).Description=['** Prior to version 2.0'];
SDF_DATA_HDR(10).FieldIndex=10;
SDF_DATA_HDR(10).BinaryIndex=[39 42];
SDF_DATA_HDR(10).FieldName='abscissa_deltaXOld';
SDF_DATA_HDR(10).DataType='float';
SDF_DATA_HDR(10).RangeUnits='';
SDF_MEAS_HDR(10).Description=['** Prior to version 2.0'];
SDF_DATA_HDR(11).FieldIndex=11;
SDF_DATA_HDR(11).BinaryIndex=[43 44];
SDF_DATA_HDR(11).FieldName='xResolution_type';
SDF_DATA_HDR(11).DataType='short';
SDF_DATA_HDR(11).RangeUnits='0:4';
SDF_MEAS_HDR(11).Description=['tells you how to find x-axis values for this ' ...
'Data Header record’s traces.\n' ...
'0=linear —calculate values from abscissa_firstX and abscissa_deltaX\n' ...
'1=logarithmic—calculate values from abscissa_firstX and abscissa_deltaX\n' ...
'2=arbitrary, one per file—find values in the X-axis Data record; same ' ...
'vector used for every trace in the measurement file\n' ...
'3=arbitrary, one per data type—find values in the X-axis Data record; ' ...
'same x-axis vector used for each trace associated with this record\n' ...
'4=arbitrary, one per trace—find values in the X-axis Data record; ' ...
'unique x-axis vector for each trace associated with this record'];
SDF_DATA_HDR(11).Table=[...
 {'0'} {'linear'};...
 {'1'} {'logarithmic'};...
 {'2'} {'arbitrary, one per file'};...
 {'3'} {'arbitrary, one per data type'};...
 {'4'} {'arbitrary, one per trace'};...
];
SDF_DATA_HDR(12).FieldIndex=12;
SDF_DATA_HDR(12).BinaryIndex=[45 46];
SDF_DATA_HDR(12).FieldName='xdata_type';
SDF_DATA_HDR(12).DataType='short';
SDF_DATA_HDR(12).RangeUnits='1:4';
SDF_MEAS_HDR(12).Description=...
['tells you the size and format of each x-axis value.' ...
'1=short (two-byte, binary-encoded integer)\n' ...
'2=long (four-byte, binary-encoded integer)\n' ...
'3=float (four-byte, binary floating-point number)\n' ...
'4=double (eight-byte, binary floating-point number)\n' ...
'This field is only valid if xResolution_type is 2, 3, or 4.'];
SDF_DATA_HDR(12).Table=[...
 {'1'} {'short'};...
 {'2'} {'long'};...
 {'3'} {'float'};...
 {'4'} {'double'};...
];
SDF_DATA_HDR(13).FieldIndex=13;
SDF_DATA_HDR(13).BinaryIndex=[47 48];
SDF_DATA_HDR(13).FieldName='xPerPoint';
SDF_DATA_HDR(13).DataType='short';
SDF_DATA_HDR(13).RangeUnits='0:32767';
SDF_MEAS_HDR(13).Description=...
['number of x-axis values per each trace point. ' ...
'This field is only valid if xResolution_type is 2, 3, or 4.'];
SDF_DATA_HDR(14).FieldIndex=14;
SDF_DATA_HDR(14).BinaryIndex=[49 50];
SDF_DATA_HDR(14).FieldName='ydata_type';
SDF_DATA_HDR(14).DataType='short';
SDF_DATA_HDR(14).RangeUnits='1:4';
SDF_MEAS_HDR(14).Description=...
['tells you the size and format of each y-axis value.\n' ...
'NOTE: If yIsComplex=1, both the real and imaginary ' ...
'components of each y value require the number of bytes specified here.\n' ...
'1=short (two-byte, binary-encoded integer)\n' ...
'2=long (four-byte, binary-encoded integer)\n' ...
'3=float (four-byte, binary floating-point number)\n' ...
'4=double (eight-byte, binary floating-point number)\n'];
SDF_DATA_HDR(14).Table=[...
 {'1'} {'short'};...
 {'2'} {'long'};...
 {'3'} {'float'};...
 {'4'} {'double'};...
];
SDF_DATA_HDR(15).FieldIndex=15;
SDF_DATA_HDR(15).BinaryIndex=[51 52];
SDF_DATA_HDR(15).FieldName='yPerPoint';
SDF_DATA_HDR(15).DataType='short';
SDF_DATA_HDR(15).RangeUnits='0:32767';
SDF_MEAS_HDR(15).Description=...
['number of y-axis values per each trace point.\n' ...
'NOTE: A value containing both real and imaginary ' ...
'components is still considered a single value.'];
SDF_DATA_HDR(16).FieldIndex=16;
SDF_DATA_HDR(16).BinaryIndex=[53 54];
SDF_DATA_HDR(16).FieldName='yIsComplex';
SDF_DATA_HDR(16).DataType='short';
SDF_DATA_HDR(16).RangeUnits='0:1';
SDF_MEAS_HDR(16).Description=[''];
SDF_DATA_HDR(16).Table=[...
 {'0'} {'each y value has only a real component'};...
 {'1'} {'each y value has both a real and an imaginary component'};...
];
SDF_DATA_HDR(17).FieldIndex=17;
SDF_DATA_HDR(17).BinaryIndex=[55 56];
SDF_DATA_HDR(17).FieldName='yIsNormalised';
SDF_DATA_HDR(17).DataType='short';
SDF_DATA_HDR(17).RangeUnits='0:1';
SDF_MEAS_HDR(17).Description=['0=not normalized\n' ...
'1=normalized (all y values fall between 0.0 and 1.0 and ' ...
'are unitless, for example coherence or power spectrum).'];
SDF_DATA_HDR(17).Table=[...
 {'0'} {'not normalised'};...
 {'1'} {'normalized'};...
];
SDF_DATA_HDR(18).FieldIndex=18;
SDF_DATA_HDR(18).BinaryIndex=[57 58];
SDF_DATA_HDR(18).FieldName='yIsPowerData';
SDF_DATA_HDR(18).DataType='short';
SDF_DATA_HDR(18).RangeUnits='0:1';
SDF_MEAS_HDR(18).Description=...
['0=not power data (for example, linear spectrum)\n' ...
'1=power data (for example, auto-power spectrum)'];
SDF_DATA_HDR(18).Table=[...
 {'0'} {'not power data'};...
 {'1'} {'power data'};...
];
SDF_DATA_HDR(19).FieldIndex=19;
SDF_DATA_HDR(19).BinaryIndex=[59 60];
SDF_DATA_HDR(19).FieldName='yIsValid';
SDF_DATA_HDR(19).DataType='short';
SDF_DATA_HDR(19).RangeUnits='0:1';
SDF_MEAS_HDR(19).Description=[''];
SDF_DATA_HDR(19).Table=[...
{'0'} {'non valid'};...
{'1'} {'valid'};...
];
SDF_DATA_HDR(20).FieldIndex=20;
SDF_DATA_HDR(20).BinaryIndex=[61 64];
SDF_DATA_HDR(20).FieldName='first_VECTOR_recordNum';
SDF_DATA_HDR(20).DataType='long';
SDF_DATA_HDR(20).RangeUnits='0:(num_of_VECTOR_record) − 1(SDF_FILE_HDR)';
SDF_MEAS_HDR(20).Description=['first Vector Header record ' ...
'belonging to this Data Header record'];
SDF_DATA_HDR(21).FieldIndex=21;
SDF_DATA_HDR(21).BinaryIndex=[65 66];
SDF_DATA_HDR(21).FieldName='total_rows';
SDF_DATA_HDR(21).DataType='short';
SDF_DATA_HDR(21).RangeUnits='1:32767';
SDF_MEAS_HDR(21).Description=['used to determine the number of traces ' ...
'associated with this Data header record; just multiply ' ...
'total_rows by total_columns'];
SDF_DATA_HDR(22).FieldIndex=22;
SDF_DATA_HDR(22).BinaryIndex=[67 68];
SDF_DATA_HDR(22).FieldName='total_cols';
SDF_DATA_HDR(22).DataType='short';
SDF_DATA_HDR(22).RangeUnits='1:32767';
SDF_MEAS_HDR(22).Description=['used to determine the number of traces ' ...
'associated with this Data header record; just multiply ' ...
'total_rows by total_columns'];
SDF_DATA_HDR(23).FieldIndex=23;
SDF_DATA_HDR(23).BinaryIndex=[69 90];
SDF_DATA_HDR(23).FieldName='xUnit';
SDF_DATA_HDR(23).DataType='struct';
SDF_DATA_HDR(23).RangeUnits='see SDF_UNIT';
SDF_MEAS_HDR(23).Description=['engineering unit used for x-axis values.'];
SDF_DATA_HDR(24).FieldIndex=24;
SDF_DATA_HDR(24).BinaryIndex=[91 92];
SDF_DATA_HDR(24).FieldName='yUnitValid';
SDF_DATA_HDR(24).DataType='short';
SDF_DATA_HDR(24).RangeUnits='0:1';
SDF_MEAS_HDR(24).Description=['yUnit field in this record is valid'];
SDF_DATA_HDR(24).Table=[...
{'0'} {'use Channel Header record’s engUnit field for y-axis units.'};...
{'1'} {'use this record’s yUnit field for y-axis unit.'};...
];
SDF_DATA_HDR(25).FieldIndex=25;
SDF_DATA_HDR(25).BinaryIndex=[93 114];
SDF_DATA_HDR(25).FieldName='yUnit';
SDF_DATA_HDR(25).DataType='struct';
SDF_DATA_HDR(25).RangeUnits='see SDF_UNIT';
SDF_MEAS_HDR(25).Description=['engineering unit used for y-axis values.'];
SDF_DATA_HDR(26).FieldIndex=26;
SDF_DATA_HDR(26).BinaryIndex=[115 122];
SDF_DATA_HDR(26).FieldName='abscissa_firstX';
SDF_DATA_HDR(26).DataType='double';
SDF_DATA_HDR(26).RangeUnits='|10^34';
SDF_MEAS_HDR(26).Description=...
['firstX—x-axis value of first point. This field is only ' ...
'valid if xResolution_type is 0 or 1.'];
SDF_DATA_HDR(27).FieldIndex=27;
SDF_DATA_HDR(27).BinaryIndex=[123 130];
SDF_DATA_HDR(27).FieldName='abscissa_deltaX';
SDF_DATA_HDR(27).DataType='double';
SDF_DATA_HDR(27).RangeUnits='|10^34';
SDF_MEAS_HDR(27).Description=['spacing between x-axis points.\n' ...
'xn=x(n-1) + abscissa_deltaX (xResolution_type 0)\n' ...
'xn=x(n-1)öabscissa_deltaX (xResolution_type 1)\n' ...
'This field is only valid if xResolution_type is 0 or 1.'];
SDF_DATA_HDR(28).FieldIndex=28;
SDF_DATA_HDR(28).BinaryIndex=[131 132];
SDF_DATA_HDR(28).FieldName='scanData';
SDF_DATA_HDR(28).DataType='short';
SDF_DATA_HDR(28).RangeUnits='0:1';
SDF_MEAS_HDR(28).Description=['indicates whether the data is scanned'];
SDF_DATA_HDR(28).Table=[...
{'0'} {'This data header is associated with non-scanned data'};...
{'1'} {'This data header is associated with the scan structure'};...
];
SDF_DATA_HDR(29).FieldIndex=29;
SDF_DATA_HDR(29).BinaryIndex=[133 134];
SDF_DATA_HDR(29).FieldName='windowApplied';
SDF_DATA_HDR(29).DataType='short';
SDF_DATA_HDR(29).RangeUnits='0:1';
SDF_MEAS_HDR(29).Description=['indicates whether the windows indicated ' ...
'have already been applied to the data'];
SDF_DATA_HDR(29).Table=[...
{'0'} {'windows have not been applied'};...
{'1'} {'windows have been applied'};...
];
SDF_DATA_HDR(30).FieldIndex=30;
SDF_DATA_HDR(30).BinaryIndex=[135 138];
SDF_DATA_HDR(30).FieldName='num_of_points';
SDF_DATA_HDR(30).DataType='long';
SDF_DATA_HDR(30).RangeUnits='0:(2^31)-1';
SDF_MEAS_HDR(30).Description=['number of discrete points in each trace ' ...
'associated with this record.'];
SDF_DATA_HDR(31).FieldIndex=31;
SDF_DATA_HDR(31).BinaryIndex=[139 142];
SDF_DATA_HDR(31).FieldName='last_valid_index';
SDF_DATA_HDR(31).DataType='long';
SDF_DATA_HDR(31).RangeUnits='0:(num_of_points)-1';
SDF_MEAS_HDR(31).Description=['last point containing valid data.'];
SDF_DATA_HDR(32).FieldIndex=32;
SDF_DATA_HDR(32).BinaryIndex=[143 144];
SDF_DATA_HDR(32).FieldName='overSampleFactor';
SDF_DATA_HDR(32).DataType='short';
SDF_DATA_HDR(32).RangeUnits='0:32767';
SDF_MEAS_HDR(32).Description=['Usually 1\n' ...
'> 1=the data has been low-pass filtered but not decimated.'];
SDF_DATA_HDR(33).FieldIndex=33;
SDF_DATA_HDR(33).BinaryIndex=[145 146];
SDF_DATA_HDR(33).FieldName='multiPassMode';
SDF_DATA_HDR(33).DataType='short';
SDF_DATA_HDR(33).RangeUnits='0:5';
SDF_MEAS_HDR(33).Description=...
['"Multi-pass" refers to a mode where data for ' ...
'multiple frequency spans is interleaved.'];
SDF_DATA_HDR(33).Table=[...
{'0'} {'non multipass data'};...
{'1'} {'multi-pass, corresponding the HP 3565 gate array modes'};...
{'2'} {'multi-pass, corresponding the HP 3565 gate array modes'};...
{'3'} {'multi-pass, corresponding the HP 3565 gate array modes'};...
{'4'} {'multi-pass, corresponding the HP 3565 gate array modes'};...
{'5'} {'future multi-pass mode'};...
];
SDF_DATA_HDR(34).FieldIndex=34;
SDF_DATA_HDR(34).BinaryIndex=[147 148];
SDF_DATA_HDR(34).FieldName='multiPassDecimations';
SDF_DATA_HDR(34).DataType='short';
SDF_DATA_HDR(34).RangeUnits='0:32767';
SDF_MEAS_HDR(34).Description=...
['> 0=the number of decimations included in the multi-pass data.  '];
end
function SDF_FILE_HDR=SDF_FILE_HDR_Template()
%SDF_FILE_HDR_TEMPLATE - Provides a empty template containing the requested header information
% 
%                 - SDF_FILE_HDR:    Provides an index to the file.
%
% Syntax: [retval] = SDF_FILE_HDR_TEMPLATE()
%
% Inputs: none
%
% Outputs:
%   retval - Extracted SDF header information.
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: N/A
% © Copyright 2016 Commonwealth of Australia, represented by the Department of Defence
SDF_FILE_HDR(1).FieldIndex=1;
SDF_FILE_HDR(1).BinaryIndex=[1 2];
SDF_FILE_HDR(1).FieldName=['recordType'];
SDF_FILE_HDR(1).DataType='short';
SDF_FILE_HDR(1).RangeUnits='10';
SDF_FILE_HDR(2).FieldIndex=2;
SDF_FILE_HDR(2).BinaryIndex=[3 6];
SDF_FILE_HDR(2).FieldName=['recordSize'];
SDF_FILE_HDR(2).DataType='long';
SDF_FILE_HDR(2).RangeUnits='80 bytes';
SDF_FILE_HDR(3).FieldIndex=3;
SDF_FILE_HDR(3).BinaryIndex=[7 8];
SDF_FILE_HDR(3).FieldName=['revisionNum'];
SDF_FILE_HDR(3).DataType='short';
SDF_FILE_HDR(3).RangeUnits='0:32767';
SDF_FILE_HDR(3).Description='measurement file version number.';
SDF_FILE_HDR(4).FieldIndex=4;
SDF_FILE_HDR(4).BinaryIndex=[9 10];
SDF_FILE_HDR(4).FieldName=['applic'];
SDF_FILE_HDR(4).DataType='short';
SDF_FILE_HDR(4).RangeUnits='-99:32767';
SDF_FILE_HDR(4).Description='file saved from this instrument or application.';
SDF_FILE_HDR(4).Table=...
    [{'-1'} {'HP VISTA'};...
    {'-2'} {'HP SINE'};...
    {'-3'} {'HP 35660A'};...
    {'-4'} {'HP 3562A, HP 3563A'};...
    {'-5'} {'HP 3588A'};...
    {'-6'} {'HP 3589A'};...
    {'-99'} {'unknown'};...
    {'1'} {'HP 3566A, HP 3567A'};...
    {'2'} {'HP 35665A'};...
    {'3'} {'HP 3560A'};...
    {'4'} {'HP 89410A, HP 89440A'};...
    {'7'} {'HP 35635R'};...
    {'8'} {'HP 35654A-S1A'};...
    {'9'} {'HP 3569A'};...
    {'10'} {'HP 35670A'};...
    {'11'} {'HP 3587S'};...
    ];
SDF_FILE_HDR(5).FieldIndex=5;
SDF_FILE_HDR(5).BinaryIndex=[11 12];
SDF_FILE_HDR(5).FieldName=['yearStamp'];
SDF_FILE_HDR(5).DataType='short';
SDF_FILE_HDR(5).RangeUnits='0:9999';
SDF_FILE_HDR(5).Description = 'year at measurement start.';
SDF_FILE_HDR(6).FieldIndex=6;
SDF_FILE_HDR(6).BinaryIndex=[13 14];
SDF_FILE_HDR(6).FieldName=['monthDayStamp'];
SDF_FILE_HDR(6).DataType='short';
SDF_FILE_HDR(6).RangeUnits='0:1231';
SDF_FILE_HDR(6).Description = ['month at measurement start.\n' ...
'Encoded as (month ö 100) + day\n' ...
'For example, November 9 = 1109'];
SDF_FILE_HDR(7).FieldIndex=7;
SDF_FILE_HDR(7).BinaryIndex=[15 16];
SDF_FILE_HDR(7).FieldName=['hourMinStamp'];
SDF_FILE_HDR(7).DataType='short';
SDF_FILE_HDR(7).RangeUnits='0:2359';
SDF_FILE_HDR(7).Description = ['time at measurement start.' ...
'Encoded as (hour ö 100) + minute' ...
'For example, 14:45 = 1445'];
SDF_FILE_HDR(8).FieldIndex=8;
SDF_FILE_HDR(8).BinaryIndex=[17 24];
SDF_FILE_HDR(8).FieldName=['applicVer'];
SDF_FILE_HDR(8).DataType='char[8]';
SDF_FILE_HDR(8).RangeUnits='i.d.';
SDF_FILE_HDR(8).Description = 'software or firmware version number.';
SDF_FILE_HDR(9).FieldIndex=9;
SDF_FILE_HDR(9).BinaryIndex=[25 26];
SDF_FILE_HDR(9).FieldName=['num_of_DATA_HDR_record'];
SDF_FILE_HDR(9).DataType='short';
SDF_FILE_HDR(9).RangeUnits='1:32767';
SDF_FILE_HDR(9).Description = 'total Data Header records.';
SDF_FILE_HDR(10).FieldIndex=10;
SDF_FILE_HDR(10).BinaryIndex=[27 28];
SDF_FILE_HDR(10).FieldName=['num_of_VECTOR_record'];
SDF_FILE_HDR(10).DataType='short';
SDF_FILE_HDR(10).RangeUnits='1:32767';
SDF_FILE_HDR(10).Description = 'total Vector Header records.';
SDF_FILE_HDR(11).FieldIndex=11;
SDF_FILE_HDR(11).BinaryIndex=[29 30];
SDF_FILE_HDR(11).FieldName=['num_of_CHANNEL_record'];
SDF_FILE_HDR(11).DataType='short';
SDF_FILE_HDR(11).RangeUnits='1:32767';
SDF_FILE_HDR(11).Description = 'total Channel Header records.';
SDF_FILE_HDR(12).FieldIndex=12;
SDF_FILE_HDR(12).BinaryIndex=[31 32];
SDF_FILE_HDR(12).FieldName=['num_of_UNIQUE_record'];
SDF_FILE_HDR(12).DataType='short';
SDF_FILE_HDR(12).RangeUnits='0:32767';
SDF_FILE_HDR(12).Description = 'total Unique records.';
SDF_FILE_HDR(13).FieldIndex=13;
SDF_FILE_HDR(13).BinaryIndex=[33 34];
SDF_FILE_HDR(13).FieldName=['num_of_SCAN_STRUCT_record'];
SDF_FILE_HDR(13).DataType='short';
SDF_FILE_HDR(13).RangeUnits='0:1';
SDF_FILE_HDR(13).Description = 'total Scan Structure records.';
SDF_FILE_HDR(14).FieldIndex=14;
SDF_FILE_HDR(14).BinaryIndex=[35 36];
SDF_FILE_HDR(14).FieldName=['num_of_XDATA_record'];
SDF_FILE_HDR(14).DataType='short';
SDF_FILE_HDR(14).RangeUnits='0:1';
SDF_FILE_HDR(14).Description = 'total X-axis Data records.';
SDF_FILE_HDR(15).FieldIndex=15;
SDF_FILE_HDR(15).BinaryIndex=[37 40];
SDF_FILE_HDR(15).FieldName=['offset_of_DATA_HDR_record'];
SDF_FILE_HDR(15).DataType='long';
SDF_FILE_HDR(15).RangeUnits='-1:(2^31)-1';
SDF_FILE_HDR(15).Description = ['first Data Header record’s byte offset ' ...
'from beginning of file.'];
 
SDF_FILE_HDR(16).FieldIndex=16;
SDF_FILE_HDR(16).BinaryIndex=[41 44];
SDF_FILE_HDR(16).FieldName=['offset_of_VECTOR_record'];
SDF_FILE_HDR(16).DataType='long';
SDF_FILE_HDR(16).RangeUnits='-1:(2^31)-1';
SDF_FILE_HDR(16).Description = ['first Vector Header record’s byte offset ' ...
'from beginning of file.'];
SDF_FILE_HDR(17).FieldIndex=17;
SDF_FILE_HDR(17).BinaryIndex=[45 48];
SDF_FILE_HDR(17).FieldName=['offset_of_CHANNEL_record'];
SDF_FILE_HDR(17).DataType='long';
SDF_FILE_HDR(17).RangeUnits='-1:(2^31)-1';
SDF_FILE_HDR(17).Description = ['first Channel Header record’s byte offset ' ...
'from beginning of file.'];
SDF_FILE_HDR(18).FieldIndex=18;
SDF_FILE_HDR(18).BinaryIndex=[49 52];
SDF_FILE_HDR(18).FieldName=['offset_of_UNIQUE_record'];
SDF_FILE_HDR(18).DataType='long';
SDF_FILE_HDR(18).RangeUnits='-1:(2^31)-1';
SDF_FILE_HDR(18).Description = ['first Unique record’s byte offset ' ...
'from beginning of file.'];
SDF_FILE_HDR(19).FieldIndex=19;
SDF_FILE_HDR(19).BinaryIndex=[53 56];
SDF_FILE_HDR(19).FieldName=['offset_of_SCAN_STRUCT_record'];
SDF_FILE_HDR(19).DataType='long';
SDF_FILE_HDR(19).RangeUnits='-1:(2^31)-1';
SDF_FILE_HDR(19).Description = ['Scan Structure record’s byte offset ' ...
'from beginning of file.'];
SDF_FILE_HDR(20).FieldIndex=20;
SDF_FILE_HDR(20).BinaryIndex=[57 60];
SDF_FILE_HDR(20).FieldName=['offset_of_XDATA_record'];
SDF_FILE_HDR(20).DataType='long';
SDF_FILE_HDR(20).RangeUnits='-1:(2^31)-1';
SDF_FILE_HDR(20).Description = ['X-axis Data record’s byte offset ' ...
'from beginning of file.'];
SDF_FILE_HDR(21).FieldIndex=21;
SDF_FILE_HDR(21).BinaryIndex=[61 64];
SDF_FILE_HDR(21).FieldName=['offset_of_YDATA_record'];
SDF_FILE_HDR(21).DataType='long';
SDF_FILE_HDR(21).RangeUnits='-1:(2^31)-1';
SDF_FILE_HDR(21).Description = ['Y-axis Data record’s byte offset ' ...
'from beginning of file.'];
SDF_FILE_HDR(22).FieldIndex=22;
SDF_FILE_HDR(22).BinaryIndex=[65 66];
SDF_FILE_HDR(22).FieldName=['num_of_SCAN_BIG_RECORD'];
SDF_FILE_HDR(22).DataType='short';
SDF_FILE_HDR(22).RangeUnits='0:32767';
SDF_FILE_HDR(22).Description = 'total of SDF_SCAN_BIG and SDF_SCAN_VAR records.';
SDF_FILE_HDR(23).FieldIndex=23;
SDF_FILE_HDR(23).BinaryIndex=[67 68];
SDF_FILE_HDR(23).FieldName=['num_of_COMMENT_record'];
SDF_FILE_HDR(23).DataType='short';
SDF_FILE_HDR(23).RangeUnits='0:32767';
SDF_FILE_HDR(23).Description = 'total of SDF_COMMENT_HDR records.';
SDF_FILE_HDR(24).FieldIndex=24;
SDF_FILE_HDR(24).BinaryIndex=[69 72];
SDF_FILE_HDR(24).FieldName=['offset_of_SCAN_BIG_record'];
SDF_FILE_HDR(24).DataType='long';
SDF_FILE_HDR(24).RangeUnits='-1:(2^31)-1';
SDF_FILE_HDR(24).Description = ['the offset (from beginning of file) ' ...
'of the first Scan Big or Scan Variable record.'];
SDF_FILE_HDR(25).FieldIndex=25;
SDF_FILE_HDR(25).BinaryIndex=[73 76];
SDF_FILE_HDR(25).FieldName=['offset_of_next_SDF_FILE'];
SDF_FILE_HDR(25).DataType='long';
SDF_FILE_HDR(25).RangeUnits='-1:(2^31)-1';
SDF_FILE_HDR(25).Description = ['allows more than one logical ' ...
'SDF FILE in a physical file.\n' ...
'This supports multiple independent results taken at the \n' ...
'same time. (For example, a time capture where the span \n' ...
'and center frequencies of each channel are completely \n' ...
'unrelated.) This offset points to the FORMAT_STRUCT \n' ...
'record of the next logical SDF FILE in this physical file. \n' ...
'All offsets in the next SDF FILE are relative to the start of \n' ...
'the FORMAT field of the logical file (that is, "B" \n' ...
'followed by "\\0").'];
end
function  SDF_MEAS_HDR=SDF_MEAS_HDR_Template()
%SDF_MEAS_HDR_TEMPLATE - Provides a empty template containing the requested header information
%
%                 - SDF_MEAS_HDR:    Contains settings of measurement parameters.
%
% Syntax: [retval] = SDF_MEAS_HDR_TEMPLATE()
%
% Inputs: none
%
% Outputs:
%   retval - Extracted SDF header information.
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: N/A
% © Copyright 2016 Commonwealth of Australia, represented by the Department of Defence
SDF_MEAS_HDR(1).FieldIndex=1;
SDF_MEAS_HDR(1).BinaryIndex=[1 2];
SDF_MEAS_HDR(1).FieldName='recordType';
SDF_MEAS_HDR(1).DataType='short';
SDF_MEAS_HDR(1).RangeUnits='11';
SDF_MEAS_HDR(2).FieldIndex=2;
SDF_MEAS_HDR(2).BinaryIndex=[3 6];
SDF_MEAS_HDR(2).FieldName='recordSize';
SDF_MEAS_HDR(2).DataType='long';
SDF_MEAS_HDR(2).RangeUnits='156 bytes';
SDF_MEAS_HDR(3).FieldIndex=3;
SDF_MEAS_HDR(3).BinaryIndex=[7 10];
SDF_MEAS_HDR(3).FieldName='unique_record';
SDF_MEAS_HDR(3).DataType='long';
SDF_MEAS_HDR(3).RangeUnits='-1:0:2^31-1';
SDF_MEAS_HDR(3).Description=['byte offset from the beginning of the file ' ...
'to a record containing an instrument-specific measurement ' ...
'header. This field may be ignored when the file is recalled ' ...
'if it is recalled into an instrument type other than that used ' ...
'to create it.'];
SDF_MEAS_HDR(4).FieldIndex=4;
SDF_MEAS_HDR(4).BinaryIndex=[11 14];
SDF_MEAS_HDR(4).FieldName='centerFreqOld';
SDF_MEAS_HDR(4).DataType='float';
SDF_MEAS_HDR(4).RangeUnits='unit is Hz range is i.d.';
SDF_MEAS_HDR(4).Description=['center frequency. ' ...
'** Prior to version 2.0'];
SDF_MEAS_HDR(5).FieldIndex=5;
SDF_MEAS_HDR(5).BinaryIndex=[15 18];
SDF_MEAS_HDR(5).FieldName='spanFreqOld';
SDF_MEAS_HDR(5).DataType='float';
SDF_MEAS_HDR(5).RangeUnits='unit is Hz range is i.d.';
SDF_MEAS_HDR(5).Description=['frequency span. ' ...
'** Prior to version 2.0'];
SDF_MEAS_HDR(6).FieldIndex=6;
SDF_MEAS_HDR(6).BinaryIndex=[19 22];
SDF_MEAS_HDR(6).FieldName='blockSize';
SDF_MEAS_HDR(6).DataType='long';
SDF_MEAS_HDR(6).RangeUnits='';
SDF_MEAS_HDR(6).Description=['number of time-domain samples taken. This ' ...
'field is only valid for FFT measurements.'];
SDF_MEAS_HDR(7).FieldIndex=7;
SDF_MEAS_HDR(7).BinaryIndex=[23 24];
SDF_MEAS_HDR(7).FieldName='zoomModeOn';
SDF_MEAS_HDR(7).DataType='short';
SDF_MEAS_HDR(7).RangeUnits='0:1';
SDF_MEAS_HDR(7).Description=['zoom mode (0=not zoomed, 1=zoomed). ' ...
'This field is only valid for FFT measurements'];
SDF_MEAS_HDR(7).Table=[...
{'0'} {'non zoomed'};...
{'1'} {'zoomed'};...
];
SDF_MEAS_HDR(8).FieldIndex=8;
SDF_MEAS_HDR(8).BinaryIndex=[25 26];
SDF_MEAS_HDR(8).FieldName='startFreqIndexOld';
SDF_MEAS_HDR(8).DataType='short';
SDF_MEAS_HDR(8).RangeUnits=' 0:last_valid_index(SDF_DATA_HDR)';
SDF_MEAS_HDR(8).Description=['the first alias-protected point on a ' ...
'frequency-domain trace. ' ...
'*** Prior to version 3.0'];
SDF_MEAS_HDR(9).FieldIndex=9;
SDF_MEAS_HDR(9).BinaryIndex=[27 28];
SDF_MEAS_HDR(9).FieldName='stopFreqIndexOld';
SDF_MEAS_HDR(9).DataType='short';
SDF_MEAS_HDR(9).RangeUnits=' 0:last_valid_index(SDF_DATA_HDR)';
SDF_MEAS_HDR(9).Description=['the last alias-protected point on a ' ...
'frequency-domain trace. ' ...
'*** Prior to version 3.0'];
SDF_MEAS_HDR(10).FieldIndex=10;
SDF_MEAS_HDR(10).BinaryIndex=[29 30];
SDF_MEAS_HDR(10).FieldName='averageType';
SDF_MEAS_HDR(10).DataType='short';
SDF_MEAS_HDR(10).RangeUnits='0:6';
SDF_MEAS_HDR(10).Description=[''];
SDF_MEAS_HDR(10).Table=[...
{'0'} {'none'};...
{'1'} {'rms'};...
{'2'} {'rms exponential'};...
{'3'} {'vector'};...
{'4'} {'vector exponential'};...
{'5'} {'continuous peak hold'};...
{'6'} {'peak'};...
];
SDF_MEAS_HDR(11).FieldIndex=11;
SDF_MEAS_HDR(11).BinaryIndex=[31 34];
SDF_MEAS_HDR(11).FieldName='averageNum';
SDF_MEAS_HDR(11).DataType='long';
SDF_MEAS_HDR(11).RangeUnits='range is i.d.';
SDF_MEAS_HDR(11).Description=['number of averages.'];
SDF_MEAS_HDR(12).FieldIndex=12;
SDF_MEAS_HDR(12).BinaryIndex=[35 38];
SDF_MEAS_HDR(12).FieldName='pctOverlap';
SDF_MEAS_HDR(12).DataType='float';
SDF_MEAS_HDR(12).RangeUnits='number between 0 and 1';
SDF_MEAS_HDR(12).Description=['percentage of time-domain samples that are ' ...
'shared between successive time records. This field is only ' ...
'valid for FFT measurements.'];
SDF_MEAS_HDR(13).FieldIndex=13;
SDF_MEAS_HDR(13).BinaryIndex=[39:98];
SDF_MEAS_HDR(13).FieldName='measTitle';
SDF_MEAS_HDR(13).DataType='char[60]';
SDF_MEAS_HDR(13).RangeUnits='i.d.';
SDF_MEAS_HDR(13).Description=['measurement title or automath label.'];
SDF_MEAS_HDR(14).FieldIndex=14;
SDF_MEAS_HDR(14).BinaryIndex=[99 102];
SDF_MEAS_HDR(14).FieldName='videoBandWidth';
SDF_MEAS_HDR(14).DataType='float';
SDF_MEAS_HDR(14).RangeUnits='unit is Hz';
SDF_MEAS_HDR(14).Description=['tells you the bandwidth of the instrument’s ' ...
'video filter. This field is only valid for swept spectrum measurements.'];
SDF_MEAS_HDR(15).FieldIndex=15;
SDF_MEAS_HDR(15).BinaryIndex=[103 110];
SDF_MEAS_HDR(15).FieldName='centerFreq';
SDF_MEAS_HDR(15).DataType='double';
SDF_MEAS_HDR(15).RangeUnits='unit is Hz range is i.d.';
SDF_MEAS_HDR(15).Description=['center frequency'];
SDF_MEAS_HDR(16).FieldIndex=16;
SDF_MEAS_HDR(16).BinaryIndex=[111 118];
SDF_MEAS_HDR(16).FieldName='spanFreq';
SDF_MEAS_HDR(16).DataType='double';
SDF_MEAS_HDR(16).RangeUnits='unit is Hz range is i.d.';
SDF_MEAS_HDR(16).Description=['frequency span'];
SDF_MEAS_HDR(17).FieldIndex=17;
SDF_MEAS_HDR(17).BinaryIndex=[119 126];
SDF_MEAS_HDR(17).FieldName='sweepFreq';
SDF_MEAS_HDR(17).DataType='double';
SDF_MEAS_HDR(17).RangeUnits='unit is Hz range is i.d.';
SDF_MEAS_HDR(17).Description=['current frequency for a swept measurement'];
SDF_MEAS_HDR(18).FieldIndex=18;
SDF_MEAS_HDR(18).BinaryIndex=[127 128];
SDF_MEAS_HDR(18).FieldName='measType';
SDF_MEAS_HDR(18).DataType='short';
SDF_MEAS_HDR(18).RangeUnits='-99:10';
SDF_MEAS_HDR(18).Description=['measurement type'];
SDF_MEAS_HDR(18).Table=[...
{'-99'} {'unknown measurement'};...
{'0'} {'spectrum measurement'};...
{'1'} {'network measurement'};...
{'2'} {'swept measurement'};...
{'3'} {'FFT measurement'};...
{'4'} {'orders measurement'};...
{'5'} {'octave measurement'};...
{'6'} {'capture measurement'};...
{'7'} {'correlation measurement'};...
{'8'} {'histogram measurement'};...
{'9'} {'swept network measurement'};...
{'10'} {'FFT network measurement'};...
];
SDF_MEAS_HDR(19).FieldIndex=19;
SDF_MEAS_HDR(19).BinaryIndex=[129 130];
SDF_MEAS_HDR(19).FieldName='realTime';
SDF_MEAS_HDR(19).DataType='short';
SDF_MEAS_HDR(19).RangeUnits='0:1';
SDF_MEAS_HDR(19).Description=['whether the measurement was continuous in time'];
SDF_MEAS_HDR(19).Table=[...
{'0'} {'non continuous'};...
{'1'} {'continuous'};...
];
SDF_MEAS_HDR(20).FieldIndex=20;
SDF_MEAS_HDR(20).BinaryIndex=[131 132];
SDF_MEAS_HDR(20).FieldName='detection';
SDF_MEAS_HDR(20).DataType='short';
SDF_MEAS_HDR(20).RangeUnits='-99:3';
SDF_MEAS_HDR(20).Description=['detection type'];
SDF_MEAS_HDR(20).Table=[...
{'-99'} {'unknown detection type'};...
{'0'} {'sample detection'};...
{'1'} {'positive peak detection'};...
{'2'} {'negative peak detection'};...
{'3'} {'rose-and-fell detection'};...
];
SDF_MEAS_HDR(21).FieldIndex=21;
SDF_MEAS_HDR(21).BinaryIndex=[133 140];
SDF_MEAS_HDR(21).FieldName='sweepTime';
SDF_MEAS_HDR(21).DataType='double';
SDF_MEAS_HDR(21).RangeUnits='unit is sec range is i.d.';
SDF_MEAS_HDR(21).Description=['actual time for a swept measurement'];
SDF_MEAS_HDR(22).FieldIndex=22;
SDF_MEAS_HDR(22).BinaryIndex=[141 144];
SDF_MEAS_HDR(22).FieldName='startFreqIndex';
SDF_MEAS_HDR(22).DataType='long';
SDF_MEAS_HDR(22).RangeUnits='0:last_valid_index(SDF_DATA_HDR)';
SDF_MEAS_HDR(22).Description=['the first alias-protected point on a ' ...
'frequency-domain trace. This field is only valid for FFT ' ...
'measurements, long'];
SDF_MEAS_HDR(23).FieldIndex=23;
SDF_MEAS_HDR(23).BinaryIndex=[145 148];
SDF_MEAS_HDR(23).FieldName='stopFreqIndex';
SDF_MEAS_HDR(23).DataType='long';
SDF_MEAS_HDR(23).RangeUnits='0:last_valid_index(SDF_DATA_HDR)';
SDF_MEAS_HDR(23).Description=['the last alias-protected point on a ' ...
'frequency-domain trace. This field is only valid for FFT ' ...
'measurements, long'];
SDF_MEAS_HDR(24).FieldIndex=2;
SDF_MEAS_HDR(24).BinaryIndex=[149 156];
SDF_MEAS_HDR(24).FieldName='expAverageNum';
SDF_MEAS_HDR(24).DataType='double';
SDF_MEAS_HDR(24).RangeUnits='range is i.d.';
SDF_MEAS_HDR(24).Description=['—number of exponential averages.'];
end
function  SDF_SCAN_STRUCT=SDF_SCAN_STRUCT_Template()
%SDF_SCAN_STRUCT_HDR_TEMPLATE - Provides a empty template containing the requested header information
%
%                 - SDF_SCAN_STRUCT: Tells you how vectors are organized in the Y-axis Data 
%                                    record when the measurement includes multiple scans of data.
%
% Syntax: [retval] = SDF_SCAN_STRUCT_HDR_TEMPLATE()
%
% Inputs: none
%
% Outputs:
%   retval - Extracted SDF header information.
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: N/A
% © Copyright 2016 Commonwealth of Australia, represented by the Department of Defence
SDF_SCAN_STRUCT(1).FieldIndex=1;
SDF_SCAN_STRUCT(1).BinaryIndex=[1 2];
SDF_SCAN_STRUCT(1).FieldName='recordType';
SDF_SCAN_STRUCT(1).DataType='short';
SDF_SCAN_STRUCT(1).RangeUnits='15';
SDF_SCAN_STRUCT(2).FieldIndex=2;
SDF_SCAN_STRUCT(2).BinaryIndex=[3 6];
SDF_SCAN_STRUCT(2).FieldName='recordSize';
SDF_SCAN_STRUCT(2).DataType='long';
SDF_SCAN_STRUCT(2).RangeUnits='variable';
SDF_SCAN_STRUCT(3).FieldIndex=3;
SDF_SCAN_STRUCT(3).BinaryIndex=[7 8];
SDF_SCAN_STRUCT(3).FieldName='num_of_scan';
SDF_SCAN_STRUCT(3).DataType='short';
SDF_SCAN_STRUCT(3).RangeUnits='1:(215)-1';
SDF_SCAN_STRUCT(3).Description=...
['number of times the instrument collected a complete set of x- and y-axis ' ...
'vectors for all scan-based data types.'];
SDF_SCAN_STRUCT(4).FieldIndex=4;
SDF_SCAN_STRUCT(4).BinaryIndex=[9 10];
SDF_SCAN_STRUCT(4).FieldName='last_scan_index';
SDF_SCAN_STRUCT(4).DataType='short';
SDF_SCAN_STRUCT(4).RangeUnits='0:(num_of_scan)-1';
SDF_SCAN_STRUCT(4).Description=...
['index of the last valid scan'];
SDF_SCAN_STRUCT(5).FieldIndex=5;
SDF_SCAN_STRUCT(5).BinaryIndex=[11 12];
SDF_SCAN_STRUCT(5).FieldName='scan_type';
SDF_SCAN_STRUCT(5).DataType='short';
SDF_SCAN_STRUCT(5).RangeUnits='0:1';
SDF_SCAN_STRUCT(5).Description=...
['tells you how the vectors from different scans ' ...
'are organized in the Y-axis Data record.\n' ...
'0=depth—all scans for the first data type’s vectors ' ...
'followed by all scans for the second data type’s vectors, and so on.\n' ...
'1=scan—all data type’s vectors for the first scan ' ...
'followed by all data type’s vectors for the second scan,and so on.'];
SDF_SCAN_STRUCT(5).Table=[...
{'0'} {'depth'};...
{'1'} {'scan'};...
];
SDF_SCAN_STRUCT(6).FieldIndex=6;
SDF_SCAN_STRUCT(6).BinaryIndex=[13 14];
SDF_SCAN_STRUCT(6).FieldName='scanVar_type';
SDF_SCAN_STRUCT(6).DataType='short';
SDF_SCAN_STRUCT(6).RangeUnits='';
SDF_SCAN_STRUCT(6).Description=...
['tells you the size and format of each scan variable value.\n' ...
'1=short (two-byte, binary-encoded integer)\n' ...
'2=long (four-byte, binary-encoded integer)\n' ...
'3=float (four-byte, binary floating-point number)\n' ...
'4=double (eight-byte, binary floating-point number)'];
SDF_SCAN_STRUCT(6).Table=[...
{'1'} {'short'};...
{'2'} {'long'};...
{'3'} {'float'};...
{'4'} {'double'};...
];
SDF_SCAN_STRUCT(7).FieldIndex=7;
SDF_SCAN_STRUCT(7).BinaryIndex=[15 36];
SDF_SCAN_STRUCT(7).FieldName='scanUnit';
SDF_SCAN_STRUCT(7).DataType='struct';
SDF_SCAN_STRUCT(7).RangeUnits='see SDF_UNIT';
SDF_SCAN_STRUCT(7).Description=...
['engineering unit used for scan variables'];
end
function  SDF_SCANS_BIG =  SDF_SCANS_BIG_Template()
%SDF_SCANS_BIG_TEMPLATE - Provides a empty template containing the requested header information
%
%                 - SDF_SCANS_BIG:   Extended scan header which tells how vectors are organized 
%                                    in the Y-axis data record when the measurement may include 
%                                    more than 32767 scans of data.
%
% Syntax: [retval] = SDF_SCANS_BIG_TEMPLATE()
%
% Inputs: none
%
% Outputs:
%   retval - Extracted SDF header information.
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: N/A
% © Copyright 2016 Commonwealth of Australia, represented by the Department of Defence
SDF_SCANS_BIG(1).FieldIndex=1;
SDF_SCANS_BIG(1).BinaryIndex=[1 2];
SDF_SCANS_BIG(1).FieldName='recordType';
SDF_SCANS_BIG(1).DataType = 'short';
SDF_SCANS_BIG(1).RangeUnits='18';
SDF_SCANS_BIG(2).FieldIndex=2;
SDF_SCANS_BIG(2).BinaryIndex=[3 6];
SDF_SCANS_BIG(2).FieldName='recordSize';
SDF_SCANS_BIG(2).DataType = 'long';
SDF_SCANS_BIG(2).RangeUnits='20';
SDF_SCANS_BIG(3).FieldIndex=3;
SDF_SCANS_BIG(3).BinaryIndex=[7 10];
SDF_SCANS_BIG(3).FieldName='unique_record';
SDF_SCANS_BIG(3).DataType = 'long';
SDF_SCANS_BIG(3).RangeUnits='-1:(231)-1';
SDF_SCANS_BIG(3).Description=...
['byte offset from the beginning of the file to a ' ...
'record containing an instrument-specific scan big header. May ' ...
'be ignored if recalled into a different type instrument.'];
SDF_SCANS_BIG(4).FieldIndex=4;
SDF_SCANS_BIG(4).BinaryIndex=[11 14];
SDF_SCANS_BIG(4).FieldName='num_of_scan';
SDF_SCANS_BIG(4).DataType = 'long';
SDF_SCANS_BIG(4).RangeUnits='-1:(231)-1';
SDF_SCANS_BIG(4).Description=...
['number of times the instrument collected a ' ...
'complete set of x- and y-axis vectors for all scan-based data types.'];
SDF_SCANS_BIG(5).FieldIndex=5;
SDF_SCANS_BIG(5).BinaryIndex=[15 18];
SDF_SCANS_BIG(5).FieldName='last_scan_index';
SDF_SCANS_BIG(5).DataType = 'long';
SDF_SCANS_BIG(5).RangeUnits=':(num_of_scan)-1';
SDF_SCANS_BIG(5).Description=...
['index of the last valid scan.'];
SDF_SCANS_BIG(6).FieldIndex=6;
SDF_SCANS_BIG(6).BinaryIndex=[19 20];
SDF_SCANS_BIG(6).FieldName='scan_type';
SDF_SCANS_BIG(6).DataType = 'short';
SDF_SCANS_BIG(6).RangeUnits='0:1';
SDF_SCANS_BIG(6).Description=...
['tells you how the vectors from different scans ' ...
'are organized in the Y-axis Data record.\n' ...
'0=depth—all scans for the first data type’s vectors ' ...
'followed by all scans for the second data type’s vectors, ' ...
'and so on.\n' ...
'1=scan—all data type’s vectors for the first scan ' ...
'followed by all data type’s vectors for the second scan, ' ...
'and so on.'];
SDF_SCANS_BIG(6).Table=[...
{'0'} {'depth'};...
{'1'} {'scan'};...
];
end
function  SDF_SCANS_VAR=SDF_SCANS_VAR_Template()
%SDF_SCANS_VAR_TEMPLATE - Provides a empty template containing the requested header information
%
%                 - SDF_SCANS_VAR:   Contains a number that identifies every scan 
%                                    (scan time, RPM, or scan number).
%
% Syntax: [retval] = SDF_SCANS_VAR_TEMPLATE()
%
% Inputs: none
%
% Outputs:
%   retval - Extracted SDF header information.
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: N/A
% © Copyright 2016 Commonwealth of Australia, represented by the Department of Defence
SDF_SCANS_VAR(1).FieldIndex=1;
SDF_SCANS_VAR(1).BinaryIndex=[1 2];
SDF_SCANS_VAR(1).FieldName='recordType';
SDF_SCANS_VAR(1).DataType='short';
SDF_SCANS_VAR(1).RangeUnits='19';
SDF_SCANS_VAR(2).FieldIndex=2;
SDF_SCANS_VAR(2).BinaryIndex=[3 6];
SDF_SCANS_VAR(2).FieldName='recordSize';
SDF_SCANS_VAR(2).DataType='long';
SDF_SCANS_VAR(2).RangeUnits='variable';
SDF_SCANS_VAR(3).FieldIndex=3;
SDF_SCANS_VAR(3).BinaryIndex=[7 10];
SDF_SCANS_VAR(3).FieldName='unique_record';
SDF_SCANS_VAR(3).DataType='long';
SDF_SCANS_VAR(3).RangeUnits='-1:(231)-1';
SDF_SCANS_VAR(3).Description=...
['byte offset from the beginning of the file to a ' ...
'record containing an instrument-specific scan variable header. ' ...
'May be ignored if recalled into a different type instrument.'];
SDF_SCANS_VAR(4).FieldIndex=4;
SDF_SCANS_VAR(4).BinaryIndex=[11 14];
SDF_SCANS_VAR(4).FieldName='headersize';
SDF_SCANS_VAR(4).DataType='long';
SDF_SCANS_VAR(4).RangeUnits='54';
SDF_SCANS_VAR(4).Description=...
['size of the header portion of this record ' ...
'(excluding the scan variable values).'];
SDF_SCANS_VAR(5).FieldIndex=5;
SDF_SCANS_VAR(5).BinaryIndex=[15 16];
SDF_SCANS_VAR(5).FieldName='scanBase_type';
SDF_SCANS_VAR(5).DataType='short';
SDF_SCANS_VAR(5).RangeUnits='0:5';
SDF_SCANS_VAR(5).Description=...
['type of scan variable'];
SDF_SCANS_VAR(5).Table=[...
{'0'} {'unknown'};...
{'1'} {'scan number'};...
{'2'} {'time'};...
{'3'} {'RPM'};...
{'4'} {'temperature'};...
{'5'} {'tachometer count'};...
];
SDF_SCANS_VAR(6).FieldIndex=6;
SDF_SCANS_VAR(6).BinaryIndex=[17 18];
SDF_SCANS_VAR(6).FieldName='scanOrder_type';
SDF_SCANS_VAR(6).DataType='short';
SDF_SCANS_VAR(6).RangeUnits='0:2';
SDF_SCANS_VAR(6).Description=...
['progression of scan values'];
SDF_SCANS_VAR(6).Table=[...
{'0'} {'unknown'};...
{'1'} {'increasinhg in value'};...
{'2'} {'decreasing in value'};...
];
SDF_SCANS_VAR(7).FieldIndex=7;
SDF_SCANS_VAR(7).BinaryIndex=[19 20];
SDF_SCANS_VAR(7).FieldName='DATA_recordNum';
SDF_SCANS_VAR(7).DataType='short';
SDF_SCANS_VAR(7).RangeUnits='0:num_of_DATA_HDR_record -1';
SDF_SCANS_VAR(7).Description=...
['SDF_DATA_HDR record number associated with this record, ' ...
'(-1 if no specific association).'];
SDF_SCANS_VAR(8).FieldIndex=8;
SDF_SCANS_VAR(8).BinaryIndex=[21:30];
SDF_SCANS_VAR(8).FieldName='scan_ID';
SDF_SCANS_VAR(8).DataType='char[10]';
SDF_SCANS_VAR(8).RangeUnits='i.d.';
SDF_SCANS_VAR(8).Description=...
['name of scan information.'];
SDF_SCANS_VAR(9).FieldIndex=9;
SDF_SCANS_VAR(9).BinaryIndex=[31 32];
SDF_SCANS_VAR(9).FieldName='scanVar_type';
SDF_SCANS_VAR(9).DataType='short';
SDF_SCANS_VAR(9).RangeUnits='0:4';
SDF_SCANS_VAR(9).Description=...
['tells you the size and format of each scan variable value\n' ...
'1=short (two-byte binary-encoded integer)\n' ...
'2=long (four-byte binary-encoded integer)\n' ...
'3=float (four-byte floating-point number)\n' ...
'4=double (eight-byte floating-point number)'];
SDF_SCANS_VAR(9).Table=[...
{'1'} {'short'};...
{'2'} {'long'};...
{'3'} {'float'};...
{'4'} {'double'};...
];
SDF_SCANS_VAR(10).FieldIndex=10;
SDF_SCANS_VAR(10).BinaryIndex=[33 54];
SDF_SCANS_VAR(10).FieldName='scanUnit';
SDF_SCANS_VAR(10).DataType='struct';
SDF_SCANS_VAR(10).RangeUnits='see SDF_UNIT';
SDF_SCANS_VAR(10).Description=...
['engineering unit used for sca'];
end
function  SDF_UNIT =  SDF_UNIT_Template()
%SDF_UNIT_TEMPLATE - Provides a empty template containing the requested header information
% 
%                 - SDF_UNIT:        Contains eng. units & scaling information for the traces.
%
% Syntax: [retval] = SDF_UNIT_TEMPLATE()
%
% Inputs: none
%
% Outputs:
%   retval - Extracted SDF header information.
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: N/A
% © Copyright 2016 Commonwealth of Australia, represented by the Department of Defence
SDF_UNIT(1).FieldIndex=1;
SDF_UNIT(1).BinaryIndex=[1 10];
SDF_UNIT(1).FieldName='label';
SDF_UNIT(1).DataType = 'char[10]';
SDF_UNIT(1).RangeUnits='i.d.';
SDF_UNIT(2).FieldIndex=2;
SDF_UNIT(2).BinaryIndex=[11 14];
SDF_UNIT(2).FieldName='factor';
SDF_UNIT(2).DataType = 'float';
SDF_UNIT(2).RangeUnits='|10^34(except 0)';
SDF_UNIT(3).FieldIndex=3;
SDF_UNIT(3).BinaryIndex=[15];
SDF_UNIT(3).FieldName='mass';
SDF_UNIT(3).DataType = 'char';
SDF_UNIT(3).RangeUnits='-128:127';
SDF_UNIT(3).Description=...
['2 times the unit exponent for the mass dimension'];
SDF_UNIT(4).FieldIndex=4;
SDF_UNIT(4).BinaryIndex=[16];
SDF_UNIT(4).FieldName='length';
SDF_UNIT(4).DataType = 'char';
SDF_UNIT(4).RangeUnits='-128:127';
SDF_UNIT(4).Description=...
['2 times the unit exponent for the length dimension'];
SDF_UNIT(5).FieldIndex=5;
SDF_UNIT(5).BinaryIndex=[17];
SDF_UNIT(5).FieldName='time';
SDF_UNIT(5).DataType = 'char';
SDF_UNIT(5).RangeUnits='-128:127';
SDF_UNIT(5).Description=...
['2 times the unit exponent for the time dimension'];
SDF_UNIT(6).FieldIndex=6;
SDF_UNIT(6).BinaryIndex=[18];
SDF_UNIT(6).FieldName='current';
SDF_UNIT(6).DataType = 'char';
SDF_UNIT(6).RangeUnits='-128:127';
SDF_UNIT(6).Description=...
['2 times the unit exponent for the current dimension'];
SDF_UNIT(7).FieldIndex=7;
SDF_UNIT(7).BinaryIndex=[19];
SDF_UNIT(7).FieldName='temperature';
SDF_UNIT(7).DataType = 'char';
SDF_UNIT(7).RangeUnits='-128:127';
SDF_UNIT(7).Description=...
['2 times the unit exponent for the temperature dimension'];
SDF_UNIT(8).FieldIndex=8;
SDF_UNIT(8).BinaryIndex=[20];
SDF_UNIT(8).FieldName='luminal_intensity';
SDF_UNIT(8).DataType = 'char';
SDF_UNIT(8).RangeUnits='-128:127';
SDF_UNIT(8).Description=...
['2 times the unit exponent for the luminal intensity dimension'];
SDF_UNIT(9).FieldIndex=9;
SDF_UNIT(9).BinaryIndex=[21];
SDF_UNIT(9).FieldName='mole';
SDF_UNIT(9).DataType = 'char';
SDF_UNIT(9).RangeUnits='-128:127';
SDF_UNIT(9).Description=...
['2 times the unit exponent for the mole dimension'];
SDF_UNIT(10).FieldIndex=10;
SDF_UNIT(10).BinaryIndex=[22];
SDF_UNIT(10).FieldName='plane_angle';
SDF_UNIT(10).DataType = 'char';
SDF_UNIT(10).RangeUnits='-128:127';
SDF_UNIT(10).Description=...
['2 times the unit exponent for the plane angle dimension'];
SDF_UNIT(10).Table={};
end
function  SDF_VECTOR_HDR=SDF_VECTOR_HDR_Template()
%SDF_VECTOR_HDR_TEMPLATE - Provides a empty template containing the requested header information
%
%                 - SDF_VECTOR_HDR:  Tells you which channel (or pair of channels) provided data 
%                                    for a single trace.
%
% Syntax: [retval] = SDF_VECTOR_HDR_TEMPLATE()
%
% Inputs: none
%
% Outputs:
%   retval - Extracted SDF header information.
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: N/A
% © Copyright 2016 Commonwealth of Australia, represented by the Department of Defence
SDF_VECTOR_HDR(1).FieldIndex=1;
SDF_VECTOR_HDR(1).BinaryIndex=[1 2];
SDF_VECTOR_HDR(1).FieldName='recordType';
SDF_VECTOR_HDR(1).DataType='short';
SDF_VECTOR_HDR(1).RangeUnits='13';
SDF_VECTOR_HDR(2).FieldIndex=2;
SDF_VECTOR_HDR(2).BinaryIndex=[3 6];
SDF_VECTOR_HDR(2).FieldName='recordSize';
SDF_VECTOR_HDR(2).DataType='long';
SDF_VECTOR_HDR(2).RangeUnits='18 bytes';
SDF_VECTOR_HDR(3).FieldIndex=3;
SDF_VECTOR_HDR(3).BinaryIndex=[7 10];
SDF_VECTOR_HDR(3).FieldName='unique_record';
SDF_VECTOR_HDR(3).DataType='long';
SDF_VECTOR_HDR(3).RangeUnits='-1:0:2^31-1';
SDF_VECTOR_HDR(3).Description=...
['byte offset from the beginning of the file to ' ...
'a record containing an instrument-specific vector header. ' ...
'May be ignored if recalled into a different type instrument.'];
SDF_VECTOR_HDR(4).FieldIndex=4;
SDF_VECTOR_HDR(4).BinaryIndex=[11 12];
SDF_VECTOR_HDR(4).FieldName='the_CHANNEL_record(1)';
SDF_VECTOR_HDR(4).DataType='short';
SDF_VECTOR_HDR(4).RangeUnits='-1, 0:32767';
SDF_VECTOR_HDR(4).Description=...
['tells you which channel or channels provided data for this trace.\n' ...
'Each element of this array contains an index to a Channel Header record.\n' ...
'An element refers to no channel if the index value is -1.'];
SDF_VECTOR_HDR(6).FieldIndex=4;
SDF_VECTOR_HDR(6).BinaryIndex=[13 14];
SDF_VECTOR_HDR(6).FieldName='the_CHANNEL_record(2)';
SDF_VECTOR_HDR(6).DataType='short';
SDF_VECTOR_HDR(6).RangeUnits='-1, 0:32767';
SDF_VECTOR_HDR(6).Description=...
['tells you which channel or channels provided data for this trace.\n' ...
'Each element of this array contains an index to a Channel Header record.\n' ...
'An element refers to no channel if the index value is -1.'];
SDF_VECTOR_HDR(5).FieldIndex=5;
SDF_VECTOR_HDR(5).BinaryIndex=[15 16];
SDF_VECTOR_HDR(5).FieldName='powrOfChan(1)';
SDF_VECTOR_HDR(5).DataType='short';
SDF_VECTOR_HDR(5).RangeUnits='0:32767';
SDF_VECTOR_HDR(5).Description=...
['tells you what exponent was applied to corresponding channel data to ' ...
'create this trace. (For example, pwrOfChan[0] is the exponent applied to ' ...
'the_CHANNEL record[0]’s data.)\n\n' ...
'record [0] for row channel\n' ...
'Chan [0] “ ��? \n\n' ...
'record [1] for column channel\n' ...
'Chan [1] “ ��? \n\n' ...
'NOTE: You must divide each pwrOfChan value by 48 to obtain ' ...
'the true value of the exponent.'];
SDF_VECTOR_HDR(7).FieldIndex=5;
SDF_VECTOR_HDR(7).BinaryIndex=[17 18];
SDF_VECTOR_HDR(7).FieldName='powrOfChan(2)';
SDF_VECTOR_HDR(7).DataType='short';
SDF_VECTOR_HDR(7).RangeUnits='0:32767';
SDF_VECTOR_HDR(7).Description=...
['tells you what exponent was applied to corresponding channel data to ' ...
'create this trace. (For example, pwrOfChan[0] is the exponent applied to ' ...
'the_CHANNEL record[0]’s data.)\n\n' ...
'record [0] for row channel\n' ...
'Chan [0] “ ��? \n\n' ...
'record [1] for column channel\n' ...
'Chan [1] “ ��? \n\n' ...
'NOTE: You must divide each pwrOfChan value by 48 to obtain ' ...
'the true value of the exponent.'];
SDF_VECTOR_HDR(7).Table={};
end
function  SDF_WINDOW =  SDF_WINDOW_Template()
%SDF_WINDOW_TEMPLATE - Provides a empty template containing the requested header information
% 
%                 - SDF_WINDOW:      Contains windowing information for frequency domain traces.
%
% Syntax: [retval] = SDF_WINDOW_TEMPLATE()
%
% Inputs: none
%
% Outputs:
%   retval - Extracted SDF header information.
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: N/A
% © Copyright 2016 Commonwealth of Australia, represented by the Department of Defence
SDF_WINDOW(1).FieldIndex=1;
SDF_WINDOW(1).BinaryIndex=[1 2];
SDF_WINDOW(1).FieldName='windowType';
SDF_WINDOW(1).DataType = 'short';
SDF_WINDOW(1).RangeUnits='0:12';
SDF_WINDOW(1).Table=[...
{'0'} {'window not applied'};...
{'1'} {'Hanning'};...
{'2'} {'Flat Top'};...
{'3'} {'Uniform'};...
{'4'} {'Force'};...
{'5'} {'Response'};...
{'6'} {'user-defined'};...
{'7'} {'Hamming'};...
{'8'} {'P301'};...
{'9'} {'P310'};...
{'10'} {'Kaiser-Bessel'};...
{'11'} {'Harris'};...
{'12'} {'Blackman'};...
{'13'} {'Resolution filter'};...
{'14'} {'Correlation Lead Lag'};...
{'15'} {'Correlation Lag'};...
{'16'} {'Gated'};...
{'17'} {'P400'};...
]; 
SDF_WINDOW(2).FieldIndex=2;
SDF_WINDOW(2).BinaryIndex=[3 4];
SDF_WINDOW(2).FieldName='windowCorrMode';
SDF_WINDOW(2).DataType = 'short';
SDF_WINDOW(2).RangeUnits='0:2';
SDF_WINDOW(2).Table=[...
{'0'} {'correction not applied'};...
{'1'} {'narrow band correction applied'};...
{'2'} {'wide band correction applied'};...
];
SDF_WINDOW(3).FieldIndex=3;
SDF_WINDOW(3).BinaryIndex=[5 8];
SDF_WINDOW(3).FieldName='windowBandWidth';
SDF_WINDOW(3).DataType = 'float';
SDF_WINDOW(3).RangeUnits='unit is bins unit is Hz (if windowType=13), range is i.d.';
SDF_WINDOW(3).Descripton=...
['NOTE: When windowType = 13, this field contains the ' ...
'instrument’s resolution bandwidth.'];
SDF_WINDOW(4).FieldIndex=4;
SDF_WINDOW(4).BinaryIndex=[9 12];
SDF_WINDOW(4).FieldName='windowTimeConst';
SDF_WINDOW(4).DataType = 'long';
SDF_WINDOW(4).RangeUnits='unit is sec, range is i.d.';
SDF_WINDOW(4).Descripton=...
['determines decay of Force and Response windows'];
SDF_WINDOW(5).FieldIndex=5;
SDF_WINDOW(5).BinaryIndex=[13 16];
SDF_WINDOW(5).FieldName='windowTrunc';
SDF_WINDOW(5).DataType = 'float';
SDF_WINDOW(5).RangeUnits='unit is sec, range is i.d.';
SDF_WINDOW(5).Descripton=...
['width of FORCE window'];
SDF_WINDOW(6).FieldIndex=6;
SDF_WINDOW(6).BinaryIndex=[17 20];
SDF_WINDOW(6).FieldName='wideBandCorr';
SDF_WINDOW(6).DataType = 'float';
SDF_WINDOW(6).RangeUnits='|10^34 (except 0)';
SDF_WINDOW(6).Descripton=...
['correction factor for wide-band signals (like random noise)'];
SDF_WINDOW(7).FieldIndex=7;
SDF_WINDOW(7).BinaryIndex=[21 24];
SDF_WINDOW(7).FieldName='narrowBandCorr';
SDF_WINDOW(7).DataType = 'float';
SDF_WINDOW(7).RangeUnits='|10^34 (except 0)';
SDF_WINDOW(7).Descripton=...
['correction factor for narrow band signals (like sinesoidal wave)'];
end
function  SDF_XDATA_HDR =  SDF_XDATA_HDR_Template()
%SDF_XDATA_HDR_TEMPLATE - Provides a empty template containing the requested header information
%
%                 - SDF_XDATA_HDR:   Contains the x-axis data needed to reconstruct any trace.
%
% Syntax: [retval] = SDF_XDATA_HDR_TEMPLATE()
%
% Inputs: none
%
% Outputs:
%   retval - Extracted SDF header information.
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: N/A
% © Copyright 2016 Commonwealth of Australia, represented by the Department of Defence
SDF_XDATA_HDR(1).FieldIndex=1;
SDF_XDATA_HDR(1).BinaryIndex=[1 2];
SDF_XDATA_HDR(1).FieldName='recordType';
SDF_XDATA_HDR(1).DataType = 'short';
SDF_XDATA_HDR(1).RangeUnits='20';
SDF_XDATA_HDR(2).FieldIndex=2;
SDF_XDATA_HDR(2).BinaryIndex=[3 6];
SDF_XDATA_HDR(2).FieldName='recordSize';
SDF_XDATA_HDR(2).DataType = 'long';
SDF_XDATA_HDR(2).RangeUnits='variable';
SDF_XDATA_HDR(2).Table = {};
end
function  SDF_YDATA_HDR =  SDF_YDATA_HDR_Template()
%SDF_YDATA_HDR_TEMPLATE - Provides a empty template containing the requested header information
%
%                 - SDF_YDATA_HDR:   Contains the y-axis data needed to reconstruct any trace.
%
% Syntax: [retval] = SDF_YDATA_HDR_TEMPLATE()
%
% Inputs: none
%
% Outputs:
%   retval - Extracted SDF header information.
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: N/A
% © Copyright 2016 Commonwealth of Australia, represented by the Department of Defence
SDF_YDATA_HDR(1).FieldIndex=1;
SDF_YDATA_HDR(1).BinaryIndex=[1 2];
SDF_YDATA_HDR(1).FieldName='recordType';
SDF_YDATA_HDR(1).DataType = 'short';
SDF_YDATA_HDR(1).RangeUnits='20';
SDF_YDATA_HDR(2).FieldIndex=2;
SDF_YDATA_HDR(2).BinaryIndex=[3 6];
SDF_YDATA_HDR(2).FieldName='recordSize';
SDF_YDATA_HDR(2).DataType = 'long';
SDF_YDATA_HDR(2).RangeUnits='variable';
SDF_YDATA_HDR(2).Table = {};
end
function  SDF_UNIQUE =  SDF_UNIQUE_Template()
%SDF_UNIQUE_HDR_TEMPLATE - Provides a empty template containing the requested header information
% 
%                 - SDF_UNIQUE:      Makes the SDF file format flexible. The eight common record
%                                    types define parameters that are common to many instruments 
%                                    and systems. However, a particular instrument or system may 
%                                    need to save and recall the states of additional parameters. 
%                                    These states can reside in Unique records.
%
% Syntax: [retval] = SDF_UNIQUE_HDR_TEMPLATE()
%
% Inputs: none
%
% Outputs:
%   retval - Extracted SDF header information.
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% Author: Justin Dinale
% DST Group, Department of Defence
% email: Justin.Dinale@dst.defence.gov.au
% Website: http://www.dst.defence.gov.au
% November 2016; Latest Version: N/A
% © Copyright 2016 Commonwealth of Australia, represented by the Department of Defence
SDF_UNIQUE(1).FieldIndex=1;
SDF_UNIQUE(1).BinaryIndex=[1 2];
SDF_UNIQUE(1).FieldName='recordType';
SDF_UNIQUE(1).DataType = 'short';
SDF_UNIQUE(1).RangeUnits='20';
SDF_UNIQUE(2).FieldIndex=2;
SDF_UNIQUE(2).BinaryIndex=[3 6];
SDF_UNIQUE(2).FieldName='recordSize';
SDF_UNIQUE(2).DataType = 'long';
SDF_UNIQUE(2).RangeUnits='variable';
SDF_UNIQUE(2).Table = {};
end