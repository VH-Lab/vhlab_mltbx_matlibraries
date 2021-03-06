function newra = compute(ra)

%  NEWRA = COMPUTE(RASTEROBJ)
%
%  Compute rasters, PSTH, and other internal data structures.  These are
%  returned via a call to GETOUTPUT.
%
%  See also:  RASTER, GETOUTPUT
%
  
  
% Changes:
% 2003-10-15  chnaged bins{k}=edges{k}-p.res/2 into bins{k}=edges{k}+p.res/2
  
I = getinputs(ra);
p = getparameters(ra);

trigs = I.triggers;

 % cinterval, or computational interval, can be variable for each block
K = length(trigs);
cstart = cell(K,1);
cstop = cell(K,1);
cind = cell(K,1); dt = [];
variation = cell(K,1);
counts = cell(K,1);
ansbins = cell(K,1);
bins = cell(K,1);
edges = cell(K,1);
for k=1:K,
	% cinterval variables
	if size(p.cinterval,1)>1, kj = k; else, kj = 1; end;
	if size(p.interval,1)>1,  ki = k; else, ki = 1; end;
	mi = min(p.interval(ki,:)); mx = max(p.interval(ki,:));
	edges{k}= [mi : p.res : mx]; bins{k} = edges{k}+p.res/2;
	mic= min(p.cinterval(kj,:)); mxc= max(p.cinterval(kj,:));
	cstart{k}=round((mic-mi)/p.res)+1; cstop{k}=round((mxc-mi)/p.res);
	cind{k} = cstart{k}:cstop{k};
	dt(k) = mxc - mic;
	MI(k) = mi; MX(k) = mx;

	% answer variables
	variation{k} = zeros(1,cstop{k}-cstart{k}+1);
	counts{k} = zeros(1,cstop{k}-cstart{k}+1);
	ansbins{k} = bins{k}(cstart{k}:cstop{k});
end;

ra.internals.cstart = cstart;
ra.internals.cstop = cstop;

 % answer variables
ncounts   = zeros(K,1);
ctdev     = zeros(K,1);

for k=1:K,
	rast_x = [];
	rast_y = [];
	vals{k} = zeros(length(bins{k}),length(trigs{k}));
	fftvals{k} = zeros(length(cind{k}),length(trigs{k}));
	fftfreq{k} = (0:length(cind{k})-1)/(p.res*length(cind{k}));
	ccounts{k} = zeros(length(bins{k}),1);

	N(k) = length(trigs{k});
	for i=1:length(trigs{k}),
		try,
			g = get_data(I.spikes,[trigs{k}(i)+MI(k) trigs{k}(i)+MX(k)]);
		catch,
			g = []; warning(['Could not get data: ' lasterr]);
		end;
		if ~isempty(g-trigs{k}(i)),
			n = histc(g-trigs{k}(i),edges{k}); % fix for matlab 6
		else,
			n = [];
		end;
		if size(n,2)>size(n,1),
			n=n';
		end;
		if ~isempty(n),
			fftvals{k}(:,i) = fft(n(cind{k}));
			% now convert to fourier coefficients
			fftvals{k}(1,i) = fftvals{k}(1,i)/(p.res*length(cind{k})); 
			fftvals{k}(2:end,i) = (2/(p.res*length(cind{k})))*(real(fftvals{k}(2:end,i))-...
				sqrt(-1)*imag(fftvals{k}(2:end,i)));
			vals{k}(:,i) = n;
			ccounts{k} = ccounts{k} + n;
			rast_x = cat(2,rast_x,g-trigs{k}(i));
			rast_y = cat(2,rast_y,repmat(i,1,length(g)));

			%cind, size(n),
			zzzzz=sum(n(cind{k}));
			nncounts{k}(i) = zzzzz;
		else,
			vals{k}(:,i) = 0;
			fftvals{k}(:,i) = 0;
			nncounts{k}(i) = 0;
		end;
	end;
	counts{k}(1,:) = ccounts{k}(cind{k})';
	ncounts(k) = sum(counts{k}(1,:));
    
	ctdev(k) = std(sum(vals{k}(cind{k},:)));
	cvariation{k} = std(vals{k},[],2);
	fftmean{k} = mean(fftvals{k}');
	fftstd{k} = std(fftvals{k}');
	fftstderr{k} = fftstd{k}/sqrt(N(k));
	if ~isempty(variation{k}),
		variation{k}(1,:) = cvariation{k}(cind{k})';
	end;
	rast{k} = [ rast_x; rast_y];
	vals{k} = vals{k}(cind{k},:);
end;

ra.internals.counts=ccounts;
ra.internals.variation = cvariation;
ra.internals.bins = bins;


ra.computations = struct('rast',{rast},'bins',{ansbins},...
	'counts',{counts},'variation',{variation},...
        'ncounts',ncounts./((dt.*N)'),'values',{vals},...
	'ctdev',ctdev./dt','stderr',(ctdev./dt')./sqrt(N'),'N',N',...
        'fftfreq',{fftfreq},'fftmean',{fftmean},'fftstd',{fftstd},...
        'fftstderr',{fftstderr},'fftvals',{fftvals});

newra = ra;
