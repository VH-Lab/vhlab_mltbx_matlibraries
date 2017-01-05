function output_str = vhlv_autothreshold_dir(dirname, varargin)
% VHLV_AUTOTHRESHOLD_DIR - Automatically determine spike threshold values for a directory
%
%  OUTPUT_STR = VHLV_AUTOTHRESHOLD_DIR(DIRNAME, ...)
%
%  Automatically determines the thresholds for a given directory
%
%  DIRNAME is the full path name of the directory to analyze.
%
%  Extra parameters can be passed as name/value pairs:
%  
%  Parameter name (default)   : Description
%  ----------------------------------------------------------------------
%  sigma (4)                         : Number of standard deviations away to set
%                                    :   threshold.
%  usemedian (0)                     : If 1, the standard deviation is estimated
%                                    :   using median(abs(data))/0.6745. Otherwise, it is
%                                    :   determined using the direct method (STD).
%  pretime (20.0)                    : Number of seconds to use to determine median
%                                    :   This data is taken from the beginning of the record.
%  MEDIAN_FILTER_ACROSS_CHANNELS (1) : 0/1 Perform median filter across filtermap channnels

 % step 1 - assign defaults and user modifications

sigma = 4;
start_time = 0;
pretime = 20.0;
usemedian = 0;
MEDIAN_FILTER_ACROSS_CHANNELS = 1;

threshold_struct = struct('channel',0,'threshold',0);
threshold_struct = threshold_struct([]);

assign(varargin{:});

stop_time = pretime;

 % step 2 - read in the header file and channel list

header_filename = [dirname filesep 'vhlvanaloginput.vlh'];
data_filename =   [dirname filesep 'vhlvanaloginput.vld'];

header = readvhlvheaderfile(header_filename);

filtermap_filename = [dirname filesep 'vhlv_filtermap.txt'];
if exist(filtermap_filename),
        filtermap = loadStructArray(filtermap_filename);
else,
        error(['No file ' filtermap_filename '.']);
end;

channelgrouping_filename = [dirname filesep 'vhlv_channelgrouping.txt'];
if exist(channelgrouping_filename),
        channelgrouping = loadStructArray(channelgrouping_filename);
else,
        error(['No file ' channelgrouping_filename '.']);
end;

 % step 3 - loop through the filter maps, and then loop through all channels to find thresholds

for i=1:length(filtermap), 
	[T,D,tot_sam,tot_time] = readvhlvdatafile(data_filename,header,filtermap(i).channel_list,start_time,stop_time);

	if MEDIAN_FILTER_ACROSS_CHANNELS,
		D = D - repmat(median(D,2),1,length(filtermap(i).channel_list));
	end;

	for j=1:length(filtermap(i).channel_list),
		if usemedian,
			stddev = median(abs(D(:,j)))/0.6745;
		else,
			stddev = std(D(:,j));
		end;
		thresh = sigma * stddev;
		threshold_struct(end+1) = struct('channel',filtermap(i).channel_list(j),'threshold',[-thresh -1 0]);	
	end;
end;

 % step 4 - sort the channels into order and write to disk

[dummy,order] = sort([threshold_struct.channel]);
threshold_struct = threshold_struct(order);

saveStructArray([dirname filesep 'vhlv_thresholds.txt'],threshold_struct,1);

output_str = 'success';
