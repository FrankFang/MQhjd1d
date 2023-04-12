user=mangosteen
root=/home/$user/deploys/$version
container_name=mangosteen-prod-1
nginx_container_name=mangosteen-nginx-1
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

title 'app: docker build'
docker build $root -t mangosteen:$version

if [ "$(docker ps -aq -f name=^mangosteen-prod-1$)" ]; then
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

if [ "$(docker ps -aq -f name=^${nginx_container_name}$)" ]; then
  title 'doc: docker rm'
  docker rm -f $nginx_container_name
fi

title 'doc: docker run'
cd /home/$user/deploys/$version
if [[ -f dist.tar.gz ]]; then
  mkdir ./dist
  tar xf dist.tar.gz --directory=./dist
fi
cd -

docker run -d -p 80:80 -p 443:443 -p 8080:8080\
           --network=network1 \
           -e PUID=1000 \
           -e PGID=1000 \
           -e TZ=Etc/GMT-8 \
           -e URL=mangosteen2.hunger-valley.com \
           -e VALIDATION=http \
           --name=$nginx_container_name \
           -v /home/$user/nginx-config:/config \
           -v /home/$user/deploys/$version/nginx.default.conf:/config/nginx/site-confs/default \
           -v /home/$user/deploys/$version/dist:/usr/share/nginx/html \
           -v /home/$user/deploys/$version/api:/usr/share/nginx/html/apidoc \
           linuxserver/swag:latest

title '全部执行完毕'
