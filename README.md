# Projeto Ruby on Rails

Este é um projeto desenvolvido com Ruby on Rails utilizando Docker para facilitar o ambiente de desenvolvimento. O projeto também está configurado com Tailwind CSS para estilização.

## Tecnologias

- Ruby on Rails  
- PostgreSQL (via Docker)  
- Docker e Docker Compose  
- Bundler  
- Tailwind CSS

## Como rodar o projeto

1. Instale as dependências Ruby:  
`bundle install`

2. Suba os containers Docker (o banco de dados será criado automaticamente):  
`docker compose up -d`

3. Rode as migrations:  
`rails db:migrate`

4. Em um terminal, inicie o servidor Rails:  
`rails server`

5. Em outro terminal, rode o processo do Tailwind CSS em tempo real:  
`rails tailwindcss:watch`

Acesse o projeto em: http://localhost:3000

## Comandos úteis

- `rails console` – Abre o console do Rails  
- `rails db:migrate:status` – Verifica o status das migrations  
- `rails db:seed` – Executa os seeds do banco

## Checklist

- [x] Executou `bundle install`  
- [x] Subiu os containers com `docker compose up -d`  
- [x] Rodou as migrations com `rails db:migrate`  
- [x] Iniciou o servidor com `rails server`  
- [x] Rodou o Tailwind com `rails tailwindcss:watch`
