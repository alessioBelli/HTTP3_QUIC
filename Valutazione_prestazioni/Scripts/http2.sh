#!/bin/bash
printf "" > /vagrant/Valutazione_prestazioni/Results/Prova2/http2.txt
printf "[" >> /vagrant/Valutazione_prestazioni/Results/Prova2/http2.txt
for i in 1 2 3 4 5 6 7 8 9 10
do
    HTTPSTAT_METRICS_ONLY=true python3 httpstat.py "https://docker-nginx.dprojects.it:453" >> /vagrant/Valutazione_prestazioni/Results/Prova2/http2.txt
    #HTTPSTAT_METRICS_ONLY=true python3 httpstat.py "https://cloudflare-quic.com/" >> /vagrant/Valutazione_prestazioni/Results/Prova3/http2.txt
    if [ $i -ne 10 ]
    then
        printf "," >> /vagrant/Valutazione_prestazioni/Results/Prova2/http2.txt
    fi
done
printf "]" >> /vagrant/Valutazione_prestazioni/Results/Prova2/http2.txt