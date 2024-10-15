# 注意修改 user 和 ip
user=mangosteen
# ips=("huaweiyun")
# ips=("aws")
ips=("aws" "huaweiyun")
NGINX_HOSTS=("mangosteen.cssctrlcv.com" "mangosteen.fangyinghang.org")

version=$(git rev-parse --short HEAD)
cache_dir=tmp/deploy_cache
dist=$cache_dir/mangosteen-$version.tar.gz
current_dir=$(dirname $0)
deploy_dir=/home/$user/deploys/$version
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

# 定义中断处理函数
interrupt_handler() {
    echo -e "\n脚本被用户中断!"
    exit 1
}

# 设置trap来捕获SIGINT信号
trap interrupt_handler SIGINT

# Get the current version
last_version_file="$cache_dir/.last_version"
skip_upload=false
if [[ -f $last_version_file ]]; then
  last_version=$(cat $last_version_file)
  if [[ "$version" == "$last_version" ]]; then
    echo "Current version ($version) matches the last version. Skipping source and frontend upload."
    skip_upload=true
  fi
fi

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
for i in "${!ips[@]}"; do
  ip="${ips[$i]}"
  title "创建远程目录 $ip"
  ssh $user@$ip "mkdir -p $deploy_dir/vendor"



  if [[ "$skip_upload" == false ]]; then
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
    title "上传 API 文档到 $ip"
    scp -r $api_dir $user@$ip:$deploy_dir/

    title "上传版本号到 $ip"
    ssh $user@$ip "echo $version > $deploy_dir/version"
  fi


  title "上传 Dockerfile 到 $ip"
  scp $current_dir/../config/host.Dockerfile $user@$ip:$deploy_dir/Dockerfile
  scp $current_dir/../config/nginx.default.conf.template $user@$ip:$deploy_dir/

  title "上传 setup 脚本到 $ip"
  scp $current_dir/setup_remote.sh $user@$ip:$deploy_dir/


  title "执行远程脚本在 $ip"
  ssh $user@$ip "export version=$version; export need_migrate=$need_migrate; export NGINX_HOST=${NGINX_HOSTS[$i]}; /bin/bash $deploy_dir/setup_remote.sh"

  # If the script executes successfully, update the .last_version file
  if [[ $? -eq 0 ]]; then
    echo $version > $last_version_file
  fi
done
