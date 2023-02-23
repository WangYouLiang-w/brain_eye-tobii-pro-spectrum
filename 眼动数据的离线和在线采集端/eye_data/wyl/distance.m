clc;
clear;
eye = load('EYE_Online1.mat');
event_data = eye.event_data;
eye_data = eye.eye_data;
start = 0;
count = 1;

j = 1;
for i=1 : size(eye_data(:,7),1)
    if eye_data(i,7) ~= 0
        a(1,j)= eye_data(i,7);
        j = j + 1;
    end
end

for i=1:size(event_data,1)
    if event_data(i,1) ~= 0
        off(1,count) = event_data(i,3)-start;
        count = count + 1;
        start = event_data(i,3);
    end
end


start = 0;
j = 1;
for i=1 : size(eye_data(:,7),1)
    if eye_data(i,7) ~= 0
        off1(1,j) = eye_data(i,6)-start;
        j = j + 1;
        start = eye_data(i,6);
    end
end

