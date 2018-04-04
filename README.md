# kymo
matlab script to trace fluorescent particles in kymograph

1. load a kymograph in tiff format
2. select your region of interest by clicking on its top left and bottom right corners in your image
3. select the background region with two clicks
4. select the start region of your trace with two clicks (determines the initial values for position and height of the peak).
the script fits a gaussian to each line of a kymograph, then displays intensity (area under the gaussian) and position (peak of the gaussian) as a function of time (line number * frame rate).
5. check if your fitting is adequte, if yes press "save" to store the results.

run the script specifying the path - 'path', filename (no extension) -
'file', fluorescent channel of your particle of choice for multichannel kymos (for
single channel leave '1') - 'dim', timestep of your acquisition (seconds
per frame, or seconds per line of the kymograph - 'timestep', pixel
dimensions in micrometers - 'pix'

kymo('path','example',2,1,0.16);

works only on single particles.
