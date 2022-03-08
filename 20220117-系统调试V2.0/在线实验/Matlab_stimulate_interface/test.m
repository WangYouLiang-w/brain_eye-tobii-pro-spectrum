%% 建立udp连接
% % 接收端
% % 192.168.213.93    
udpt=udp('127.0.0.1', 8848, 'LocalPort', 8847);  %ip7 
% % udpt=udp('192.168.18.19', 40008, 'LocalPort', 40007)  
fopen(udpt); 
flag = 0
while flag==0
    if udpt.BytesAvailable >=1
        data_othermat = fread(udpt,udpt.BytesAvailable);  % 接收反馈结果
        rev_t = datetime;
        rev_t.Second      
        data_othermat = char(data_othermat);
        data1 = data_othermat(1,1)-'a';
        flag = 1;
    end
    
end
fclose(udpt);    
delete(udpt);
clear udpt  


