#!/bin/bash
#printf "" > /vagrant/Valutazione_prestazioni/Results/Prova2/http3.txt
for i in 1 2 3 4 5 6 7 8 9 10
do
    sudo docker run -it --rm ymuski/curl-http3 ./httpstat.sh https://docker-nginx.dprojects.it:443 --http3
    #sudo docker run -it --rm ymuski/curl-http3 ./httpstat.sh https://cloudflare-quic.com/ --http3
done