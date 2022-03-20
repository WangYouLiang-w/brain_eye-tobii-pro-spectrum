function itr_value = ITR_computer(N,T,p)
if  p==1
    itr_value=p*(log2(N))*60/(T);
elseif p==0
    itr_value=0;
else
    itr_value=(p*log2(p)+(1-p)*log2((1-p)/(N-1))+log2(N))*60/(T);
end
end
