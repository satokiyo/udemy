FROM node:10-slim

# コンテナが起動した時のWORKDIRを指定
WORKDIR /app

RUN npm install -g nodemon

# package.jsonのみ最初にコピーし、パッケージがインストールされたキャッシュレイヤーを作る
COPY package*.json ./

RUN npm ci 
RUN npm cache clean --force 
RUN mv /app/node_modules /node_modules

# 最後に全てのファイルをにコピー
COPY . .

# 環境変数を設定
ENV PORT 80

EXPOSE 80

# コンテナが起動した時のコマンドを指定
CMD ["node", "server.js"]
