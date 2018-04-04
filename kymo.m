% matlab script to trace fluorescent particles in kymograph
% 1. load a kymograph in tiff format
% 2. select your region of interest by clicking on its top left and bottom right corners in your image
% 3. select the background region with two clicks
% 4. select the start region of your trace with two clicks (determines the initial values for position and height of the peak).
% the script fits a gaussian to each line of a kymograph, then displays intensity (area under the gaussian) and position (peak of the gaussian) as a function of time (line number * frame rate).
% 5. check if your fitting is adequte, if yes press "save" to store the results.
% works only on single particles.
% 
% % run the script specifying the path - 'path', filename (no extension) -
% 'file', fluorescent channel of your particle of choice for multichannel kymos (for
% single channel leave '1') - 'dim', timestep of your acquisition (seconds
% per frame, or seconds per line of the kymograph - 'timestep', pixel
% dimensions in micrometers - 'pix'
function kymo(path,file,dim,timestep,pix)
loadpath=strcat(path,file,'.tif');

kymograph=double(imread(loadpath,dim));
imagesc(kymograph);
ksize = size(kymograph);
kw=ksize(:,2);
kh=ksize(:,1);

% select the region containing the trace of your particle of choice by
% making two clicks: top left and bottom right corners of the future region
% of interest

p = ginput(2); 
sp(1) = min(floor(p(1)), floor(p(2))); %xmin
sp(2) = min(floor(p(3)), floor(p(4))); %ymin
sp(3) = max(ceil(p(1)), ceil(p(2)));   %xmax
sp(4) = max(ceil(p(3)), ceil(p(4)));   %ymax

if sp(1)<1
    sp(1)=1;
end

if sp(2)<1
    sp(2)=1;
end

if sp(3)>(kw-1)
    sp(3)=kw;
end

if sp(4)>(kh-1)
    sp(4)=kh;
end

crop = kymograph(sp(2):sp(4), sp(1): sp(3),:);
close;

figure;
imagesc(crop);

ksize = size(crop);
kw=ksize(:,2);
kh=ksize(:,1);

% choose the background (the region containing no  particles) by
% making two clicks: top left and bottom right corners 


p = ginput(2); 
sp(1) = min(floor(p(1)), floor(p(2))); %xmin
sp(2) = min(floor(p(3)), floor(p(4))); %ymin
sp(3) = max(ceil(p(1)), ceil(p(2)));   %xmax
sp(4) = max(ceil(p(3)), ceil(p(4)));   %ymax

if sp(1)<1
    sp(1)=1;
end

if sp(2)<1
    sp(2)=1;
end

if sp(3)>(kw-1)
    sp(3)=kw;
end

if sp(4)>(kh-1)
    sp(4)=kh;
end


BG = crop(sp(2):sp(4), sp(1): sp(3),:);
BG = reshape(BG.',1,[]);

d=mean(BG);

dsd=2*std(BG);
% dsd=1000;

dmin=d-(2*dsd);
dmax=d+(2*dsd);
close;

figure;
imagesc(crop);

% use 2 clicks to select the start of the particle trace; this will be used
% later for the initial guess of the brightness and position of the
% particle

p = ginput(2); 
sp(11) = min(floor(p(1)), floor(p(2))); %xmin
sp(12) = min(floor(p(3)), floor(p(4))); %ymin
sp(13) = max(ceil(p(1)), ceil(p(2)));   %xmax
sp(14) = max(ceil(p(3)), ceil(p(4)));   %ymax

if sp(11)<1
    sp(11)=1;
end

if sp(12)<1
    sp(12)=1;
end

if sp(13)>(kw-1)
    sp(13)=kw;
end

if sp(14)>(kh-1)
    sp(14)=kh;
end

peak = crop(sp(12):sp(14), sp(11): sp(13),:);

peak = reshape(peak.',1,[]);
a=mean(peak);
amin=a-(3*dsd);
amax=a+(3*dsd);

close;

sz=size(crop);
t=sz(:,1);
w=sz(:,2);

b=(sp(11)+sp(13))/2;
% % b=w-bim
% b=bim;
bmin=b-5;
bmax=b+5;

wrange=[1:1:w];
transpose(wrange);


%    splits the kymograph into lines and fits each line with a gaussian

for i=[1:t]
     subcrop=crop(i,:);
     transpose(subcrop);

     
     fitresult = cell( 2, 1 );
     gof = struct( 'sse', cell( 2, 1 ), ...
         'rsquare', [], 'dfe', [], 'adjrsquare', [], 'rmse', [] );
     [xData, yData] = prepareCurveData( wrange, subcrop );
     
     ft = fittype( 'd + (a*exp(-((x-b)/c)^2))', 'independent', 'x', 'dependent', 'y' );
     opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
     opts.Display = 'Off';
     opts.Lower = [amin bmin -2 dmin];
     opts.StartPoint = [a b -1.3 d];
     opts.Upper = [amax bmax -1 dmax];
     
     [fitresult, gof] = fit( xData, yData, ft, opts );
     
     fitcoef=coeffvalues(fitresult);
     height(i)=fitcoef(:,1);
     width(i)=fitcoef(:,3);
     pixel(i)=fitcoef(:,2);
     timepix(i)=i;

     
     a=fitcoef(:,1);
     amin=a-dsd;
     amax=a+dsd;
     
     b=fitcoef(:,2);
     bmin=b-5;
     bmax=b+5;
end

int=abs(height.*width);
int=transpose(int);

time=timepix*timestep;
time=transpose(time);



position=pixel.*pix;
position=transpose(position);

% plot coordinates (blue) and brightness (green) vs time

figure;
[hAx,hLine1,hLine2] = plotyy(time,position,time,int);
title(file);
xlabel('time, s');
ylabel(hAx(1),'position, \mum');
ylabel(hAx(2),'intensity, a.u.');

% displays the original cropped image side by side with the traced
% coordinates

figure;
title(file);
s1=subplot(1,2,1);imagesc(crop),colormap(gray);
title('kymograph');
xlabel('x, px');
ylabel('y, px');
s2=subplot(1,2,2);
plot(s2,pixel,timepix,'ro');
s2=gca;
xlim(gca,[0 w]);
ylim(gca,[0 t]);
set(gca,'YDir','Reverse');
title('trace');
xlabel('x, px');
ylabel('y, px');

out=horzcat(time,position,int);

newSubFolder = strcat(path,'traced\');
if ~exist(newSubFolder, 'dir')
  mkdir(newSubFolder);
end

filecount = 1;
count = int2str(filecount);
impath=strcat(newSubFolder,file,'-',count,'_subcrop.tif');

if exist(impath,'file')== 2
    filecount = filecount + 1;
    count = int2str(filecount);
    impath=strcat(newSubFolder,file,'-',count,'_subcrop.tif');
    while exist(impath,'file')== 2
        filecount = filecount + 1;
        count = int2str(filecount);
    impath=strcat(newSubFolder,file,'-',count,'_subcrop.tif');
    end
end

crop=uint16(crop);


datapath=strcat(newSubFolder,file,'-',count,'_positions.txt');

%     choose if you want to save or discard the fitted coordinates

choice = menu('Choose an action','Save','Cancel');

if choice == 1
    save(datapath,'out','-ascii','-tabs');
    imwrite(crop,impath,'TIFF','Compression','none');
else
    
end
close all;





end
