# Valutazione delle prestazioni di HTTP/3 + QUIC
<div align="center">
  <img src="/Media/web.png" width="35%" align="left" Hspace="15" Vspace="0" Border="0"></img>
  <h3>Progettazione di reti e sistemi di comunicazione - Università di Trento - Prof. Fabrizio Granelli</h3><br>
  <p style="text-align: justify;">
    L'obiettivo è quello di costruire un framework virtualizzato per analizzare le prestazoni di HTTP/3 con QUIC rispetto ad HTTP/2 o TCP.<br><br>
    <b>Sofware consigliato</b>: Vagrant, OpenVSwitch, Docker o in alternativa Mininet + Docker (Comnetsemu).<br>
    <b>Software di riferimento</b>: https://blog.cloudflare.com/experiment-with-http-3-using-nginx-and-quiche/
  </p>
  <br>
  <b>Alberto Casagrande | Alessio Belli | Edoardo Maines | Mario Sorrentino</b>
</div>
<br>
<hr>

## Configurazione sistema
L'intero ambiente è stato creato utilizzando due specifici software: *vagrant* e *docker*. Abbiamo deciso di utilizzare tali strumenti in modo tale che la rete possa essere replicata da chiunque.
Come mostrato nell'immagine che seguirà, la rete è composta da: un *client*, un *router* e un *server*. Quest'ultimo ospiterà 2 *container* Docker (HTTP3 + QUIC, HTTP2). 

<div align="center">
  <img src="/Media/rete.png" width="65%"></img>
</div>

| Protocollo   | IP          |  Porte  |
|--------------|-------------|---------|
| HTTP2        | 192.168.2.2 | 84, 453 |
| HTTP3 + QUIC | 192.168.2.2 | 80, 443 |

## Vagrant
Al fine di raggiungere un risultato soddisfacente, *Vagrant* è stato configurato in modo da creare tutta la rete funzionante solamente con l'esecuzione del comando `vagrant up`. Per farlo sono stati creati 3 file script.sh (uno per ogni dispositivo della rete) posizionati all'interno della cartella `vagrant/`. Tali script sono richiamati all'interno del file `Vagrant` e sono eseguiti con il comando `server.vm.provision "shell", path: "vagrant/host*.sh`. Tali file contengono i comandi di routing e i comandi per installare i programmi necessari all'interno degli host.
Tutti gli host sono previsti di una memoria RAM di 2048 MB.

## Docker
Come spiegato in precedenza, sono stati utilizzati *container docker* al fine di andare a creare i nostri *web server*. Dopo un'attenta ricerca, abbiamo deciso di costruire un'immagine docker che ha lo scopo di eseguire un web-server, ispirandoci all'immagine docker presente all'interno di *Docker Hub* trovato [a questo link](https://hub.docker.com/r/ymuski/nginx-quic).
La prima cosa da fare, per poter utilizzare il container, è quella di installare docker all'interno del *Server*.
Per costruire l'immagine docker, è necessario implementare il Dockerfile (`docker/Dockerfile`), posizionarsi nella cartella `docker/` ed eseguire i seguenti comandi:
```
sudo docker build -t alessiobelli/http3_quic .
sudo docker login
sudo docker push alessiobelli/http3_quic:latest
```
Il passo successivo è quello di scaricare l'immagine con il comando `docker pull alessiobelli/http3_quic`.
A questo punto, per eseguire i due container docker (**HTTP/2**, **HTTP/3 - QUIC**) non resta che eseguire i comandi:
```
sudo docker run --name nginxHttp3 -d -p 80:80 -p 443:443/tcp -p 443:443/udp -v /vagrant/docker/confFile/http3.web.conf:/etc/nginx/nginx.conf -v /vagrant/certs/:/etc/nginx/certs/ -v /vagrant/docker/html/:/etc/nginx/html/ alessiobelli/http3_quic
sudo docker run --name nginxHttp2 -d -p 84:80 -p 453:443/tcp -p 453:443/udp -v /vagrant/docker/confFile/http2.web.conf:/etc/nginx/nginx.conf -v /vagrant/certs/:/etc/nginx/certs/ -v /vagrant/docker/html/:/etc/nginx/html/ alessiobelli/http3_quic
```
In questo modo si eseguono due container, uno denominato **nginxHttp3** e uno **nginxHttp2**. Inoltre, mediante questi comandi abbiamo:
- cambiato la configurazione di default del server NGINX, andando ad utilizzare i file di configurazione adatti -> `/docker/confFile/http*.web.conf`.
- utilizzato i certificati SSL posizionati nella cartella `certs/`.
- cambiato la pagina web visualizzata dal server con quella presente all'interno della cartella `docker/html/`.

### Certificati SSL
Per poter eseguire il comando per l'esecuzione del container, QUIC ha bisogno di un certificato SSL/TLS che deve essere generato. Per farlo si deve essere in possesso di un reale dominio e bisogna eseguire il seguente comando: 
```
sudo certbot -d HOST-NAME --manual --preferred-challenges dns certonly
```
I file che verrano generati saranno 2: `fullchain.pem` e `privkey.pem` posizionati all'interno della cartella `certs/` (non caricata all'interno di tale repository per ovvie ragioni di sicurezza).
<br>Prima di utilizzare questa tipologia di certificati, abbiamo provato anche quelli *auto firmati*, ma abbiamo constatato che con QUIC tali certificati non erano adottabili.

## Server
### Server HTTP/2
Come detto in precedenza, all'interno del server abbiamo eseguito due container docker, uno che implementa *HTTP/2* e uno *HTTP/3 + QUIC*.
Per quanto riguarda il web-server HTTP/2, è stato eseguito con la seguente configurazione: `/docker/confFile/http2.web.conf`.
```
events {
    worker_connections 1024;
}

http {

    server {

        # Enable HTTP/2 (optional).
        listen 443 ssl http2;

        server_name docker-nginx.dprojects.it;

        ssl_certificate certs/fullchain.pem;
        ssl_certificate_key certs/privkey.pem;

        # Enable all TLS versions (TLSv1.3 is required for QUIC).
        ssl_protocols TLSv1.3;
        ssl_early_data on;

        location / {
            root html;
            index index.html index.htm;
        }
    }
}
```
### Server HTTP/3 + QUIC
Per implementare il web-server *HTTP/3 + QUIC*, abbiamo eseguito il relativo container docker con la configurazione  `/docker/confFile/http3.web.conf`.
```
events {
    worker_connections 1024;
}

http {

    server {
        # https://github.com/cloudflare/quiche/tree/master/extras/nginx
        # Enable QUIC and HTTP/3.
        listen 443 quic reuseport;

        # Enable HTTP/2 (optional).
        listen 443 ssl http2;

        server_name docker-nginx.dprojects.it;

        ssl_certificate certs/fullchain.pem;
        ssl_certificate_key certs/privkey.pem;

        # Enable all TLS versions (TLSv1.3 is required for QUIC).
        ssl_protocols TLSv1.3;
        ssl_early_data on;


        # Request buffering in not currently supported for HTTP/3.
        proxy_request_buffering off;

        # Add Alt-Svc header to negotiate HTTP/3.
        add_header alt-svc 'h3-27=":443"; ma=86400';

        location / {
            root html;
            index index.html index.htm;
        }
    }
}
```
## Client
Il client è stato utilizzato per effettuare tutte le prove richieste. Per avere una migliore rappresentazione delle statistiche, abbiamo utilizzato [httpstat](https://github.com/reorx/httpstat), il quale è uno script python che permette di visualizzare le statistiche **curl** in modo semplice e ordinato.<br>
A questo scopo, il comando utilizzato è `python3 httpstat.py "https://docker-nginx.dprojects.it:453"`. Il risultato è il seguente:
```
HTTP/2 200 
server: nginx/1.16.1
date: Sat, 13 Feb 2021 15:57:02 GMT
content-type: text/html
content-length: 440598
last-modified: Fri, 12 Feb 2021 12:11:32 GMT
etag: "60267074-6b916"
accept-ranges: bytes

Body stored in: /tmp/tmpsjtheubm

  DNS Lookup   TCP Connection   TLS Handshake   Server Processing   Content Transfer
[    513ms   |       2ms      |     18ms      |       11ms        |       20ms       ]
             |                |               |                   |                  |
    namelookup:513ms          |               |                   |                  |
                        connect:515ms         |                   |                  |
                                    pretransfer:533ms             |                  |
                                                      starttransfer:544ms            |
                                                                                 total:564ms
```

Per effettuare le richieste al container nel quale è in esecuzione il Server Web HTTP3 + QUIC, non potevamo eseguire il comando sopra citato. Per effettuare una richiesta HTTP3 abbiamo utilizzato un ulteriore container, presente in questo [link](https://hub.docker.com/r/ymuski/curl-http3).
Il comando utilizzato per effettuare il curl "modificato" è: ```sudo docker run -it --rm ymuski/curl-http3 ./httpstat.sh https://docker-nginx.dprojects.it:443 --http3```.
In questo caso, quello che riceverà il client sarà:

```
HTTP/3 200
server: nginx/1.16.1
date: Sat, 13 Feb 2021 17:57:00 GMT
content-type: text/html
content-length: 449250
last-modified: Sat, 13 Feb 2021 09:07:51 GMT
etag: "602796e7-6dae2"
alt-svc: h3-27=":443"; ma=86400
accept-ranges: bytes

Body stored in: /tmp/httpstat-body.116721613239020

  DNS Lookup   TCP Connection   SSL Handshake   Server Processing   Content Transfer
[      67ms  |        36ms    |       17ms    |         14ms      |        443ms     ]
             |                |               |                   |                  |
    namelookup:67ms           |               |                   |                  |
                        connect:104ms         |                   |                  |
                                    pretransfer:120ms             |                  |
                                                      starttransfer:134ms            |
                                                                                 total:577ms
```


Nel Client, è stato installato il programma **Google Chrome** per simulare una normale navigazione di un utente medio. Per poter utilizzare *google chrome* è necessario che la macchina host esegua un X server come ad esempio **XQuartz** per macOS. Qui di seguito verrà mostrata una immagine di come appare il sito:
<br>

![chrome](/Media/docker-nginx.dprojects.png)
<hr>

![devTools](/Media/dev-tools.png)

## Valutazione prestazioni
Per essere il più imparziali possibile, tutti i test sono stati eseguiti utilizzando la stessa macchina (quindi ogni server era nelle stesse condizioni di utilizzo di CPU e RAM). Per valutare le prestazioni di **HTTP/3 + QUIC** rispetto ad **HTTP/2**, sono state eseguiti 3 diversi test.

### Comandi utilizzati
Per realizzare il curl http2 abbiamo utilizzato il comando: 
```
python3 httpstat.py "https://docker-nginx.dprojects.it:453"
```
Per realizzare il curl http3 abbiamo utilizzato il comando: 
```
sudo docker run -it --rm ymuski/curl-http3 ./httpstat.sh https://docker-nginx.dprojects.it:443 --http3
```
Questi comandi ci hanno permesso di visualizzare le statistiche relative al curl in modo semplice e chiaro.

### Test 1
La prima prova è stata eseguita utilizzando la pagina index di default del server *NGINX*.
Questa pagina era molto leggera in quanto presentava solamente tag di testo.

![Test1](/Media/prova1.png)

Tale immagine mostra che le prestazioni dei due protocolli sono molto simili. Come si può notare, HTTP/3 permette l’handshake SSL in un tempo molto minore, confermando così una delle caratteristiche principali di tale protocollo.

### Test 2
La seconda prova è stata realizzata utilizzando un [template](https://www.w3schools.com/w3css/tryw3css_templates_photo.htm) realizzato da *w3schools*, il quale è stato modificato per essere reso maggiormente pesante in termini di memoria (abbiamo semplicemente replicato molte volte il *body* della pagina). In questo caso le prestazioni di HTTP/2 sono migliori rispetto a quelle di HTTP/3, come si può vedere anche dal grafico sotto riportato. In particolare, HTTP/3 impiega più tempo per trasferire il contenuto della pagina e per la risoluzione del nome (DNS), mentre si conferma più veloce nell'*handshake SSL*
![Test2](/Media/prova2.png)

### Test 3
L’ultima prova è stata realizzata utilizzando i server di cloudflare, che permettono una connessione HTTP/3.
Come si può vedere dal grafico, HTTP/3 offre delle prestazioni migliori rispetto ad HTTP/2 nella fase di stabilimento della connessione, arrivando infatti al momento in cui inizia il trasferimento dei dati (**starttransfer**) in un tempo minore. Nonostante ciò, secondo le nostre misurazioni, HTTP/3 impiega più tempo a traferire il contenuto della pagina (**content transfer time**) rispetto ad HTTP/2. Nel complesso quindi, le prestazioni di HTTP/3 e HTTP/2 sono molto simili (in questo test).
![Test3](/Media/prova3.png)

### Test aggiuntivo
Un ulteriore test è stato fatto utilizzando **Firefox Nightly**, nel quale è possibile abilitare HTTP/3 digitando `about:config` e abilitando l'opzione `network.http.http3.enabled`.
Questi sono i risultati: <br>

![firefox](/Media/cloudflare_http2.png)

![firefox](/Media/cloudflare_http3.png)

Come si può notare, con HTTP/3 la pagina ci impiega **2,23 s** per caricarsi, contro i **1,93 s** con HTTP/2. 
