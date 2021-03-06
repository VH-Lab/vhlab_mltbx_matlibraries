function newrc = compute(rc)

%  Part of the NeuralAnalysis package
%
%  NEWRC = COMPUTE(RC)
%
%  Compute the reverse correlation, receptive field maximum, and receptive
%  field rectangle.  These are returned via a call to GETOUTPUT.
%
%  See also:  REVERSE_CORR, GETOUTPUT

 %  Must produce 
 %     c.reverse_corr.rc_avg  (cell number, stim number, time bin, Y, X)
 %     
 %     c.lags  time period for continuous reverse correlation
 %     c.crc   values for continuous reverse correlation

 % fix for multiple cells  -- I take this to mean that right now it assumes a single cell, which is fine

I = getinputs(rc); p = getparameters(rc); in = rc.internal; c = rc.computations;
 % did timing data change?
td = isempty(in.oldint)|(~eqlen(in.oldint,p.interval))|...
              isempty(in.oldtimeres)|(~eqlen(in.oldtimeres,p.timeres))|...
              isempty(in.oldfeature)|(~eqlen(in.oldfeature,p.feature));
 % did feature parameters change?
fpc = td;
if td,
end;
if fpc,
	in.oldint = p.interval; in.oldtimeres = p.timeres;
	in.oldfeature = p.feature;

	% CALL REVERSE_CORRELATION_COLOR
   
	r_c=struct('rc_avg',rc_avg,'rc_std',[],'rc_raw',[],...
		'bins',[],'norms',[]);
else, r_c = rc.computations.reverse_corr;
end;

%in.crctimeres=p.crctimeres; in.crcproj = p.crcproj;
%in.crctimeint = p.crctimeint;
%in.datatoview = 1; in.crcpixel=-1;
crcmethod = 1;

  % if necessary, calculate continuous reverse correlation
centchanged=(in.crcpixel~=p.crcpixel)|(in.datatoview~=p.datatoview(1))|...
            (in.crctimeres~=p.crctimeres)|...
            (~eqlen(in.crctimeint,p.crctimeint))|...
            (~eqlen(in.crcproj,p.crcproj))|((crcmethod==2)&td);
if centchanged&(p.crcpixel>0),
  if exist('y')~=1, 
     [x,y,rect]=getgrid(I.stimtime(p.datatoview(1)).stim);
     v = getgridvalues(I.stimtime(p.datatoview(1)).stim);
     f = getstimfeatures(v,I.stimtime(p.datatoview(1)).stim,p,x,y,rect);
  end;
  x_ = fix((p.crcpixel-0.00001)/y) + 1;
  y_ = mod(p.crcpixel,y); if y_==0, y_ = y; end;
  fts = I.stimtime(p.datatoview(1)).mti{1}.frameTimes;
  if crcmethod==1,
    F = reshape(f(y_,x_,:,:),[size(v,2) 3])-repmat(p.crcproj(1,:),size(v,2),1);
    stats = F * p.crcproj(2,:)';
    mt = mean(diff(fts));
    T = (fts(1)+p.crctimeint(1)):p.crctimeres:(fts(end)+p.crctimeint(2));
    X = zeros(size(T)); % for data
    for i=1:length(fts)-1, 
      strt = round((fts(i)-T(1))/p.crctimeres)+1;
      stp  = round((fts(i+1)-T(1))/p.crctimeres)+1;
      X(strt:stp) = stats(i);
    end;
    Stp = min([stp+round(mt/p.crctimeres)+1 length(X)]);
    X(stp:Stp) = stats(end);
    d = zeros(size(T)); % data
    sts = get_data(I.spikes{p.datatoview(1)},[T(1) T(end)],2);
    pos = round((sts-T(1))/p.crctimeres)+1;
    % must use this form since bins may have more than one spike
    for i=1:length(pos), d(pos(i)) = d(pos(i))+1; end;
    %figure(25);
    % hold off; plot(T-T(1),X*0.18); hold on; plot(fts-T(1),0,'gx');
    %plot(sts-T(1),0.1,'rx'); plot(T(find(d))-T(1),-0.1*d(find(d)),'kx');
    maxlags = ceil(max(abs(p.crctimeint))/p.crctimeres);
    [c1,thelags] = xcorr(X,d,maxlags);
    c = sum(d)/(T(end)-T(1))*(c1/sum(d));
    lags = (-maxlags:1:maxlags)*p.crctimeres;
    lagbegin = findclosest(lags,p.crctimeint(1));
    lagend = findclosest(lags,p.crctimeint(2));
    c = c(lagbegin:lagend); lags = lags(lagbegin:lagend);
    maxcalclags = ceil(max(abs(p.crccalcint))/p.crctimeres);
    calclags = (-maxcalclags:1:maxcalclags)*p.crctimeres;
    clagbegin = findclosest(calclags,p.crccalcint(1));
    clagend = findclosest(calclags,p.crccalcint(2));
    calclags = calclags(clagbegin:clagend);
  elseif crcmethod==2,
    lags = p.interval(1):p.timeres:p.interval(2);
    lags = (lags(1:end-1) + lags(2:end))/2;
    h = r_c.rc_avg(p.datatoview(1),:,y_,x_,:);
    l = size(h,2);
    c = (reshape(h,[l 3])-repmat(p.crcproj(1,:),l,1))*p.crcproj(2,:)';
    c = c.*r_c.norms'/(p.timeres*length(fts));
    % if use this again need to fix calclags
  end;
  [overlap,stddevinds] = setxor(lags,calclags);
  [ov,otherinds] = intersect(lags,calclags);
  stddev = std(c(stddevinds)),
  cc = c(otherinds);
  [mm,ii] = max(abs(cc));
  tmax=calclags(ii);
  before=cc(1:ii); after=cc(ii:end);
  try,
   if cc(ii)>0, % positive going peak
    g1 = find(before<2*stddev); if isempty(g1), g1 = 1; end;
    g2 = find(after<0); if isempty(g2), g2 = length(cc); end;
    rb = cc(g2(1)+ii-1:end); [rbpk,iii]=min(rb); % find peak
    rbrest = cc(g2(1)+ii-1+iii-1:end);
    g3 = find(rbrest>-2*stddev); if isempty(g3), g3 = length(cc); end;
    pk = sum(cc(g1(end):ii-1+g2(1)));
    rb = -sum(cc((g2(1)+ii-1):(g3(1)+g2(1)+ii-1+iii-1)));
    %figure(25);
    %subplot(2,1,1);
    %hold off; plot(cc); hold on;
    %plot(g1(end):ii-1+g2(1),cc(g1(end):ii-1+g2(1)),'r');
    %subplot(2,1,2);
    %hold off; plot(cc); hold on;
    %plot((g2(1)+ii-1):(g3(1)+g2(1)+ii-1+iii-1),cc((g2(1)+ii-1):(g3(1)+g2(1)+ii-1+iii-1)),'r');
    %g1(end),g2(1)+ii-1,g3(1)+g2(1)+ii+iii-2,
    transience= rb/pk;
   else, % negative going peak
    g1 = find(before>-2*stddev); if isempty(g1), g1 = 1; end;
    g2 = find(after>0); if isempty(g2), g2 = length(cc); end;
    rb = cc(g2(1)+ii-1:end); [rbpk,iii]=max(rb); % find peak
    rbrest = cc(g2(1)+ii-1+iii-1:end);
    g3 = find(rbrest<2*stddev); if isempty(g3), g3 = length(cc); end;
    pk = -sum(cc(g1(end):ii-1+g2(1)));
    rb = sum(cc(g2(1)+ii-1:g2(1)+ii-1+g3(1)+iii-1));
    transience= rb/pk;
   end;
  catch, transience = NaN; warning(['Could not calculate transience.']); end;
  xcent = round(rect(1)+(x_-0.5)/x * (rect(3)-rect(1)));
  ycent = round(rect(2)+(y_-0.5)/y * (rect(4)-rect(2)));
  crc = struct('lags',lags,'crc',c,'tmax',tmax,'transience',transience,...
          'onoff',cc(ii)>0,'pixel',p.crcpixel,'pixelcenter',[xcent ycent]);
  in.crctimeres=p.crctimeres; in.crcproj = p.crcproj;
  in.crctimeint = p.crctimeint;
  in.datatoview = p.datatoview(1); in.crcpixel=p.crcpixel;
elseif p.crcpixel<=0, crc = [];
else, crc = rc.computations.crc;
end;

%if in.selectedbin==0,
%   st=getstim(rc);p2=getparameters(st);rect=p2.rect;pixSize=p2.pixSize;
%   i=1;j=1; i=i(1);j=j(1); px=rect(1)-1+i; py=rect(2)-1+j;
%
%   width  = rect(3) - rect(1); height = rect(4) - rect(2);
%   if (pixSize(1)>=1), X = pixSize(1); else, X = (width*pixSize(1)); end;
%   if (pixSize(2)>=1), Y = pixSize(2); else, Y = (height*pixSize(2)); end;
%   x=fix((px-rect(1))/X); y = fix((py-rect(2))/Y); b=1+x*fix(Y/height)+y;
%   in.selectedbin = b;
%   thecenter = [px py]; thecenterrect = [px-100 py-100 px+100 py+100];
%else,thecenter=rc.computations.center;thecenterrect=rc.computations.center_rect;
%end;
thecenter=0;thecenterrect=0;   
rc.internal = in;
rc.computations=struct('reverse_corr',r_c,...
     'center',thecenter,'center_rect',thecenterrect,'crc',crc);
newrc = rc;
