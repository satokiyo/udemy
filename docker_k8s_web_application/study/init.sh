# Create user 
# プライマリーサーバに対して設定を行うので、下記の接続先Podがプライマリーかどうか要確認（rs.status()コマンド）
# シェルの実行はdebug用podで行うので、debug用podにファイルを転送する
# mongo mongodb://mongodb-0.db-svc:27017/weblog -u admin -p Passw0rd --authenticationDatabase admin ./adduser.js
mongo mongodb://mongodb-0.db-svc:27017/weblog --authenticationDatabase admin ./adduser.js

# Create collection & insert initial data
# プライマリーサーバに対して設定を行うので、下記の接続先Podがプライマリーかどうか要確認（rs.status()コマンド）
mongo mongodb://mongodb-0.db-svc:27017/weblog --authenticationDatabase admin ./insert.js
