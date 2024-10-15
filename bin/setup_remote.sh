user=mangosteen
root=/home/$user/deploys/$version
container_name=mangosteen-app-1
caddy_container_name=mangosteen-caddy-1
db_container_name=db-for-mangosteen

function set_env {
  name=$1
  hint=$2
  [[ ! -z "${!name}" ]] && return
  while [ -z "${!name}" ]; do
    [[ ! -z "$hint" ]] && echo "> 请输入 $name: $hint" || echo "> 请输入 $name:"
    read $name
  done
  sed -i "1s/^/export $name=${!name}\n/" ~/.bashrc
  echo "${name} 已保存至 ~/.bashrc 。如果需要修改，请自行编辑 ~/.bashrc"
}
function title {
  echo
  echo "###############################################################################"
  echo "## $1"
  echo "###############################################################################"
  echo
}

title '设置远程机器的环境变量'
set_env DB_HOST
set_env DB_PASSWORD
set_env RAILS_MASTER_KEY '请将 config/credentials/production.key 的内容复制到这里'

title '创建数据库'
if [ "$(docker ps -aq -f name=^${DB_HOST}$)" ]; then
  echo '已存在数据库'
else
  docker run -d --name $DB_HOST \
            --network=network1 \
            -e POSTGRES_USER=mangosteen \
            -e POSTGRES_DB=mangosteen_production \
            -e POSTGRES_PASSWORD=$DB_PASSWORD \
            -e PGDATA=/var/lib/postgresql/data/pgdata \
            -v mangosteen-data:/var/lib/postgresql/data \
            postgres:14
  echo '创建成功'
fi

# 检查镜像是否存在
if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^mangosteen:${version}$"; then
  echo "Image ${mangosteen}:${version} already exists. Skipping build."
else
  title 'app: docker build'
  docker build $root -t mangosteen:$version
fi

if [ "$(docker ps -aq -f name=^${container_name}$)" ]; then
  title 'app: docker rm'
  docker rm -f $container_name
fi

title 'app: docker run'
docker run -d -p 3000:3000 \
           --network=network1 \
           --name=$container_name \
           -e DB_HOST=$DB_HOST \
           -e DB_PASSWORD=$DB_PASSWORD \
           -e RAILS_MASTER_KEY=$RAILS_MASTER_KEY \
           mangosteen:$version

if [[ ! -z "$need_migrate" ]]; then
  title '更新数据库'
  docker exec $container_name bin/rails db:create db:migrate
fi

if [ "$(docker ps -aq -f name=^${caddy_container_name}$)" ]; then
  title 'caddy: docker rm'
  docker rm -f $caddy_container_name
fi

title 'caddy: static files'
cd /home/$user/deploys/$version
if [[ -f dist.tar.gz ]]; then
  mkdir ./dist
  tar xf dist.tar.gz --directory=./dist
fi

title 'caddy: docker run'

docker compose down
docker compose up -d

cd -

echo "NGINX_HOST: $NGINX_HOST"
docker run -d -p 80:80 -p 443:443 -p 8080:8080\
           --network=network1 \
           --name=$nginx_container_name \
           -e NGINX_HOST=${NGINX_HOST:-mangosteen.fangyinghang.com} \
           -v nginx-log:/var/log/nginx/ \
           -v /home/$user/deploys/$version/nginx.default.conf.template:/etc/nginx/templates/default.conf.template \
           -v /home/$user/deploys/$version/dist:/usr/share/nginx/html \
           -v /home/$user/deploys/$version/apidoc:/usr/share/nginx/html/apidoc \
           -v /home/$user/.certbot/config:/certs \
           nginx:latest \
           sh -c "rm /etc/nginx/conf.d/default.conf && exec /docker-entrypoint.sh nginx -g 'daemon off;'"

title '只留下最新的三个目录'
ls -dt /home/$user/deploys/* | tail -n +4 | xargs -r rm -rf

title '全部执行完毕'
