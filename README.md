# README

## 部署脚本

```bash
bin/pack_for_remote.sh
frontend=yes need_migrate=yes bin/pack_for_remote.sh
```

其中

1. frontend 表示是否需要打包和上传前端代码
2. need_migrate 表示是否需要 migrate 数据库


## 开发配置


### 数据库创建

```
docker run -d --name db-for-mangosteen -e POSTGRES_USER=mangosteen -e POSTGRES_PASSWORD=123456 -e POSTGRES_DB=mangosteen_dev -e PGDATA=/var/lib/postgresql/data/pgdata -v mangosteen-data:/var/lib/postgresql/data --network=network1 postgres:14
```

### 创建密钥

创建密钥分两种情况：

一，如果你想保留之前创建的 `config/master.key` 和 `config/credentials.yml.enc` 两个文件，就直接把之前的文件复制到本项目的 config 里。

二，如果你之前没有创建过 `config/master.key` 和 `config/credentials.yml.enc` 两个文件，就按下面的步骤做：

```
rm config/credentials.yml.enc
EDITOR="code --wait" bin/rails credentials:edit
```

在打开的文件中写下如下内容（其中 xxx 应该是一串密码或者一串随机字符串，如果你不知道怎么生成随机，那么你可以运行 bin/rake secret 即可）：

```
secret_key_base: xxx
email_password: xxx
hmac_secret: xxx
```

这样，你就得到了 `config/master.key` 和 `config/credentials.yml.enc` 两个文件。此时你应该提交代码。


### 启动应用

```
bin/rails s
或者
bundle exec rails s
```
