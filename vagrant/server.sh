export DEBIAN_FRONTEND=noninteractive
sudo ip addr add 192.168.2.2/30 dev enp0s8
sudo ip link set dev enp0s8 up
sudo ip route add 192.168.1.0/30 via 192.168.2.1

sudo apt-get update
sudo apt-get -y install docker.io
sudo systemctl start docker
sudo systemctl enable docker

docker pull alessiobelli/http3_quic
sudo docker run --name nginxHttp3 -d -p 80:80 -p 443:443/tcp -p 443:443/udp -v /vagrant/docker/confFile/http3.web.conf:/etc/nginx/nginx.conf -v /vagrant/certs/:/etc/nginx/certs/ -v /vagrant/docker/html/:/etc/nginx/html/ alessiobelli/http3_quic
sudo docker run --name nginxHttp2 -d -p 84:80 -p 453:443/tcp -p 453:443/udp -v /vagrant/docker/confFile/http2.web.conf:/etc/nginx/nginx.conf -v /vagrant/certs/:/etc/nginx/certs/ -v /vagrant/docker/html/:/etc/nginx/html/ alessiobelli/http3_quic