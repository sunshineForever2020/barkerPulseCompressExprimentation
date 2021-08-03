function res = matchedFilter(rx, tx)

rxlen = length(rx);
txlen = length(tx);
trlendiff = rxlen - txlen;
tx_rev = [fliplr(tx);zeros(trlendiff, 1)];
Tx = conj(fft(tx_rev));
Rx = fft(rx);
res = ifft(Tx .* Rx);