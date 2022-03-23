DB_PASSWORD=123456
container_name=mangosteen-prod-1

version=$(cat mangosteen_deploy/version)

echo 'docker build ...'
docker build mangosteen_deploy -t mangosteen:$version
echo 'docker run ...'
docker run -d -p 3000:3000 --network=network1 -e DB_PASSWORD=$DB_PASSWORD --name=$container_name mangosteen:$version
echo 'docker exec ...'
docker exec -it $container_name bin/rails db:create db:migrate
echo 'DONE!'