import json

f = open("/vagrant/Valutazione_prestazioni/Results/Prova3/http2.txt", "r")
dati = json.loads(f.read())
f.close()


time_total = []
time_namelookup = []
time_connTCP = []
time_handshakeSSL = []
time_starttransfer = []
time_contenttransfer = []

for x in dati:
    time_total.append(x["time_total"])
    time_namelookup.append(x["time_namelookup"])
    time_connTCP.append(x["range_connection"])
    time_handshakeSSL.append(x["range_ssl"])
    time_starttransfer.append(x["time_starttransfer"])
    time_contenttransfer.append(x["range_transfer"])

#Tempo lookup medio
media = 0
for elem in time_namelookup:
    media = media + elem

media = media / len(time_namelookup)
print("Tempo lookup medio:", media, "ms")

#Tempo conn. TCP medio
media = 0
for elem in time_connTCP:
    media = media + elem
media = media / len(time_connTCP)
print("Tempo connessione TCP medio:", media, "ms")

#Tempo handshake ssl medio
media = 0
for elem in time_handshakeSSL:
    media = media + elem
media = media / len(time_handshakeSSL)
print("Tempo handshake ssl medio:", media, "ms")

#Tempo starttransfer medio
media = 0
for elem in time_starttransfer:
    media = media + elem
media = media / len(time_starttransfer)
print("Tempo starttransfer medio:", media, "ms")

#Tempo trasferimento del contenuto medio
media = 0
for elem in time_contenttransfer:
    media = media + elem
media = media / len(time_contenttransfer)
print("Tempo trasferimento contenuto medio:", media, "ms")

#Tempo totale medio
media = 0
for elem in time_total:
    media = media + elem

media = media / len(time_total)
print("Tempo totale medio:", media, "ms")