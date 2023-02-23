clc;
clear;
eye = load('EYE_Online1.mat');
eye_data = eye.eye_data;

j = 1;
for i=1 : size(eye_data(:,7),1)
    if eye_data(i,7) ~= 0
        a(1,j)= eye_data(i,7);
        j = j + 1;
    end
end
