function [filtered_data] = time_domain_filtering(z,p,k,fs,data)
% time_domain_filtering.m Returns the filtered time series
% 
% Nikhil Mukund (AEI Hannover).

% resample to higher sampling rate 
% and use higher order anti-aliasing before applying the discrete ZPK filter
FAC = 32; %resampling factor
antiAliasFac = 100; %2 × n × max(p,q).
data_rs = resample(data,FAC,1,antiAliasFac);

% bilinear transform
[zd,pd,kd] = bilinear(z,p,k,fs*FAC);

% create second-order-sections
[sos,g]    = zp2sos(zd,pd,kd);

% filter data 
filtered_data = real(g)*sosfilt(sos,data_rs);

% resample back to fs
filtered_data = resample(filtered_data,1,FAC,antiAliasFac);

end
