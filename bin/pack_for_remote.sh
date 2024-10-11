# 注意修改 user 和 ip
user=mangosteen
ips=("huaweiyun")
# ips=("aws")

time=$(git rev-parse --short HEAD)
cache_dir=tmp/deploy_cache
dist=$cache_dir/mangosteen-$time.tar.gz
current_dir=$(dirname $0)
deploy_dir=/home/$user/deploys/$time
gemfile=$current_dir/../Gemfile
gemfile_lock=$current_dir/../Gemfile.lock
vendor_dir=$current_dir/../vendor
vendor_1=rspec_api_documentation
api_dir=$current_dir/../doc/apidoc
frontend_dir=$cache_dir/frontend

function title {
  echo
  echo "###############################################################################"
  echo "## $1"
  echo "###############################################################################"
  echo
}

# Local operations
title '运行测试用例'
if [[ "$*" != *"--no-run-test"* ]]; then
  rspec || exit 1
fi

title '重新生成文档'
if [[ "$*" != *"--no-gen-doc"* ]]; then
  bin/rails docs:generate || exit 2
fi

mkdir -p $cache_dir

title '打包源代码'
tar --exclude="tmp/cache/*" --exclude="tmp/deploy_cache/*" --exclude="vendor/*" -cz -f $dist *

title "打包本地依赖 ${vendor_1}"
bundle cache --quiet
tar -cz -f "$vendor_dir/cache.tar.gz" -C ./vendor cache
tar -cz -f "$vendor_dir/$vendor_1.tar.gz" -C ./vendor $vendor_1

if [[ ! -z "$frontend" ]]; then
  title '打包前端代码'
  mkdir -p $frontend_dir
  rm -rf $frontend_dir/repo
  git clone git@jihulab.com:FrankFang/mangosteen-fe-3.git $frontend_dir/repo
  cd $frontend_dir/repo && pnpm install && pnpm run build; cd -
  tar -cz -f "$frontend_dir/dist.tar.gz" -C "$frontend_dir/repo/dist" .
fi

# Remote operations for each IP
for ip in "${ips[@]}"; do
  title "创建远程目录 $ip"
  ssh $user@$ip "mkdir -p $deploy_dir/vendor"

  title "上传源代码和依赖到 $ip"
  scp $dist $user@$ip:$deploy_dir/
  if [[ "$*" == *"--clean-up"* ]]; then
    yes | rm $dist
  fi
  scp $gemfile $user@$ip:$deploy_dir/
  scp $gemfile_lock $user@$ip:$deploy_dir/
  scp -r $vendor_dir/cache.tar.gz $user@$ip:$deploy_dir/vendor/
  if [[ "$*" == *"--clean-up"* ]]; then
    yes | rm $vendor_dir/cache.tar.gz
  fi
  scp -r $vendor_dir/$vendor_1.tar.gz $user@$ip:$deploy_dir/vendor/
  if [[ "$*" == *"--clean-up"* ]]; then
    yes | rm $vendor_dir/$vendor_1.tar.gz
  fi

  if [[ ! -z "$frontend" ]]; then
    title "上传前端代码到 $ip"
    scp "$frontend_dir/dist.tar.gz" $user@$ip:$deploy_dir/
    if [[ "$*" == *"--clean-up"* ]]; then
      yes | rm -rf $frontend_dir
    fi
  fi

  title "上传 Dockerfile 到 $ip"
  scp $current_dir/../config/host.Dockerfile $user@$ip:$deploy_dir/Dockerfile

  title "上传 Caddyfile 到 $ip"
  scp $current_dir/../config/Caddyfile $user@$ip:$deploy_dir/

  title "上传 compose 文件到 $ip"
  scp $current_dir/../config/compose.yaml $user@$ip:$deploy_dir/

  title "上传 setup 脚本到 $ip"
  scp $current_dir/setup_remote.sh $user@$ip:$deploy_dir/

  title "上传 API 文档到 $ip"
  scp -r $api_dir $user@$ip:$deploy_dir/

  title "上传版本号到 $ip"
  ssh $user@$ip "echo $time > $deploy_dir/version"

  title "执行远程脚本在 $ip"
  ssh $user@$ip "export version=$time; export need_migrate=$need_migrate; /bin/bash $deploy_dir/setup_remote.sh"
done
