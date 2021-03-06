function agcontextmenucallback(ag)

%  AGCONTEXTMENUCALLBACK
%
%  The callback for the contextmenu associated with ANALYSIS_GENERIC objects.
%
%  See also:  ANALYSIS_GENERIC

disp('callback'),
obj = gcbo;  % find contextmenu parent
cmenu = obj;
while ~strcmp(get(cmenu,'type'),'uicontextmenu'),
	cmenu = get(cmenu,'parent'); % should not fail
end;
fig = gcbf;
ud = get(fig,'userdata');
if strcmp(class(ud),'cell'),
	for i=1:length(ud), a=0;
		try, a=(contextmenu(ud{i})==cmenu); catch, a=0; end;
		if a==1, break; end;
	end;
	if a~=1,  % try to repair handle links
		for i=1:length(ud),
			try,
				ud{i}=repairhandles(ud{i});
				a=(contextmenu(ud{i})==cmenu); if a,break;end;
			end;
		end;
	end;
	if a==1,
		[nag,b]=handlecontextmenu(ud{i},obj,fig);
		% userdata could have changed; try to find it again
		ud = get(fig,'userdata'); a = 0;
		cmenu = contextmenu(nag);
       		for i=1:length(ud), a=0;
                	try,a=(contextmenu(ud{i})==cmenu);catch,a=0;end;
                	if a==1, break; end;
		end;
		if a~=1,  % try to repair handle links
			for i=1:length(ud),
                        	try,
                                	ud{i}=repairhandles(ud{i});
                                	a=(contextmenu(ud{i})==cmenu);
					if a,break;end;
                		end;
		        end;
		end;
		if a==1,
			i,
			ud{i} = nag; set(fig,'userdata',ud);
		end;
	end;
end;
