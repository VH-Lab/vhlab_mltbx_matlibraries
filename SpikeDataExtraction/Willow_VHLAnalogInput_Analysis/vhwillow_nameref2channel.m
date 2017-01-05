function c = vhwillow_nameref2channel(dirname, name, ref)
% VHWILLOW_NAMEREF2CHANNEL - Find the corresponding vhwillowanaloginput.vld channel for a name/ref
%
%  C=VHWILLOW_NAMEREF2CHANNEL(DIRNAME,NAME,REF)
%
%  Returns the channel (or channels, in the case of a tetrode or N-trode) that correspond to
%  the NAME/REF pair given in directory DIRNAME.
%
%  This information is read out from the 'reference.txt' file and the 'vhwillow_channelgrouping.txt' file.
%

chan_groupings = loadStructArray([dirname filesep 'vhwillow_channelgrouping.txt']);

c = [];
match = 0;

for i=1:length(chan_groupings),
	if strcmp(chan_groupings.name,name) & chan_groupings.ref==ref),
		c = chan_groupings.channel_list;
		return;
	end;
end;

if match==0,
	error(['Could not locate channel match for name/ref ' name '| ' int2str(ref) ' in ' dirname '.']);
end;
