# Projeto Ruby on Rails

Este é um projeto desenvolvido com Ruby on Rails utilizando Docker para facilitar o ambiente de desenvolvimento.

## Tecnologias

- Ruby on Rails  
- PostgreSQL (via Docker)  
- Docker e Docker Compose  
- Bundler

## Como rodar o projeto

1. Instale as dependências Ruby:  
`bundle install`

2. Suba os containers Docker:  
`docker compose up -d`

3. Crie e migre o banco de dados:  
`rails db:create db:migrate`

4. Inicie o servidor Rails:  
`rails server`

Acesse em: http://localhost:3000

## Comandos úteis

- `rails console` – Abre o console do Rails  
- `rails db:migrate:status` – Verifica o status das migrations  
- `rails db:seed` – Executa os seeds do banco

## Checklist

- [x] Executou `bundle install`  
- [x] Subiu os containers com `docker compose up -d`  
- [x] Criou e migrou o banco com `rails db:create db:migrate`  
- [x] Iniciou o servidor com `rails server`
