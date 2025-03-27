compose="docker-compose8.yml"

rm -rf webapp/hello.html
docker-compose -f "$compose" down
docker-compose -f "$compose" build
docker-compose -f "$compose" up -d

# w8 for everything to load well
sleep 20

docker exec project-nginx-1 nginx -T
docker cp hello.html project-nginx-1:/usr/share/nginx/html/static/
curl -v http://localhost/static/hello.html

docker exec project-nginx-1 /usr/share/nginx/html/static/hello.html
curl -v http://localhost/static/hello.html

docker-compose -f docker-compose8.yml exec lavagna ls -la /opt/lavagna-docs

docker-compose -f docker-compose8.yml exec nginx ls -la /usr/share/nginx/html/docs
