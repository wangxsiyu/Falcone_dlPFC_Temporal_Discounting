function negativeLL = LL(params, md, R, D, Y, nAccept, nTotal)
    pAccept = md.policy(params, R, D, Y);
    pAccept = min(max(pAccept, eps), 1 - eps);
    nReject = nTotal - nAccept;
    negativeLL = -sum( ...
        nAccept.*log(pAccept) + nReject.*log1p(-pAccept));
end
