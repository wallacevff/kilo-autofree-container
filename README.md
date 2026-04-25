# Kilo Autofree

Projeto de deployment do Kilo CLI em Docker com suporte a Docker Swarm e Nginx como reverse proxy com TLS.

## 📋 Sobre o Projeto

Este projeto configura o **Kilo CLI** - uma ferramenta interativa para engenharia de software - rodando em container Docker. O Kilo funciona como um servidor que fornece uma interface CLI via navegador, permitindo interação remota com o sistema.

### Componentes

- **Kilo CLI**: Servidor principal na porta 4096
- **Nginx**: Reverse proxy opcional com TLS/SSL na porta 443
- **Docker Swarm**: Suporte a deploy em cluster

## 🚀 Instalação Rápida

### Pré-requisitos

- Docker 20.10+
- Docker Compose (para standalone) ou Docker Swarm (para cluster)
- Node.js 22+ (se for construir a imagem localmente)

### Deploy com Docker Compose (Sem Nginx)

```bash
# Na pasta do projeto
docker-compose -f kilo-docker-compose.yaml up -d
```

O Kilo estará disponível em `http://localhost:4096`

### Deploy com Docker Swarm (Com Nginx Opcional)

✅ **Recomendado para produção**

```bash
# Inicializar swarm (se ainda não tiver)
docker swarm init

# Deploy do Kilo
docker stack deploy -c kilo-docker-compose.yaml kilo

# Deploy do Nginx (OPCIONAL - apenas se precisar de TLS/externamente)
docker stack deploy -c nginx-docker-compose.yaml nginx
```

Após o deploy, o Kilo estará disponível:

- **Sem Nginx**: `http://<IP_DO_MANAGER>:4096`
- **Com Nginx**: `https://kilocode.local` (configurado no DNS/hosts)

## 🔐 Configuração TLS/SSL

### Opção 1: Usar Certificados Existentes (Recomendado)

O projeto já inclui certificados autoassinados na pasta `certs/`:

- `ca.crt` - Autoridade Certificadora
- `ca.key` - Chave da AC
- `kilocode.local.crt` - Certificado do domínio
- `kilocode.local.key` - Chave privada do domínio
- `kilocode.local.csr` - Certificate Signing Request

**Para usar em produção**, substitua os certificados por ones válidos de uma CA confiável (Let's Encrypt, etc).

### Instalando a CA em Sistemas Linux

Para que os sistemas confiem nos certificados autoassinados incluídos neste projeto, você precisa instalar a Autoridade Certificadora (CA) no seu sistema operacional.

#### No Fedora, RHEL, CentOS:

```bash
# Copie o certificado da CA para o diretório de confiança
sudo cp certs/ca.crt /etc/pki/ca-trust/source/anchors/

# Atualize o cache de certificados
sudo update-ca-trust extract
```

#### No Debian, Ubuntu, Linux Mint:

```bash
# Copie o certificado da CA para o diretório de confiança
sudo cp certs/ca.crt /usr/local/share/ca-certificates/kilocode-local.crt

# Atualize o cache de certificados
sudo update-ca-certificates
```

### Opção 2: Gerar Novos Certificados

```bash
cd certs/

# Gerar nova AC
openssl genrsa -out ca.key 4096
openssl req -x509 -new -key ca.key -sha256 -days 3650 -out ca.crt \
  -subj "/C=BR/ST=SP/L=Sao Paulo/O=Kilo/OU=Dev/CN=Kilo CA"

# Gerar chave do servidor
openssl genrsa -out kilocode.local.key 2048

# Gerar CSR
openssl req -new -key kilocode.local.key -out kilocode.local.csr \
  -subj "/C=BR/ST=SP/L=Sao Paulo/O=Kilo/OU=Dev/CN=kilocode.local"

# Assinar certificado
openssl x509 -req -in kilocode.local.csr -CA ca.crt -CAkey ca.key \
  -CAcreateserial -out kilocode.local.crt -days 365 -sha256
```

## ⚙️ Configuração do Nginx (Opcional)

### Por que usar Nginx?

- **TLS/SSL termination**: HTTPS com certificados válidos
- **Load balancing**: Se escalar múltiplas réplicas do Kilo
- **Proxy reverso**: Esconder porta interna 4096
- **Headers de segurança**: CORS, rate limiting, etc

### Por que NÃO é obrigatório?

O Kilo já expõe sua própria porta (4096) e pode ser acessado diretamente. O Nginx é apenas um proxy reverso que:

- Adiciona camada extra de abstração
- Requer configuração adicional de rede e volumes
- Pode ser desnecessário em ambientes de desenvolvimento

### Configuração

O arquivo `kilo.local.conf` contém a configuração completa do Nginx:

```nginx
server {
    listen 80;
    server_name kilocode.local;
    return 301 https://$host$request_uri;  # Redirect HTTP → HTTPS
}

server {
    listen 443 ssl;
    server_name kilocode.local;

    # Certificados
    ssl_certificate     /etc/nginx/certs/kilocode.local.crt;
    ssl_certificate_key /etc/nginx/certs/kilocode.local.key;

    # TLS settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    location / {
        proxy_pass http://kilo-autofree_kilo:4096;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;

        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # Long connections (agent mode)
        proxy_read_timeout 3600;
        proxy_send_timeout 3600;

        # Disable buffering for streaming
        proxy_buffering off;
    }
}
```

## 📁 Estrutura do Projeto

```
kilo-autofree/
├── AGENTS.md                    # Documentação do sistema de agentes
├── Kilo.Dockerfile              # Imagem Docker do Kilo
├── certs/                       # Certificados TLS
│   ├── ca.crt                  # Certificado da Autoridade Certificadora
│   ├── ca.key                  # Chave privada da AC
│   ├── ca.srl                  # Serial number da AC
│   ├── kilocode.local.crt      # Certificado do domínio
│   ├── kilocode.local.csr      # CSR do domínio
│   └── kilocode.local.key      # Chave privada do domínio
├── kilo-docker-compose.yaml    # Stack do Kilo (Docker Swarm)
├── kilo.local.conf             # Configuração do Nginx
├── nginx-docker-compose.yaml   # Stack do Nginx (Docker Swarm)
└── repomix.md                  # Representação completa do codebase
```

## 🌐 Rede e Volumes

### Rede Externa

- `kilo_net`: Rede overlay para comunicação entre serviços (10.0.4.0/24)
- **IP fixo do Kilo**: `10.0.4.3`

### Volumes Persistentes

O Kilo usa volumes Docker para persistência de dados:

- `data`: `~/.local/share` - Configurações e dados do Kilo
- `container-var`, `container-usr`, `container-etc`, `container-root`, `container-opt`: Namespaces de sistema

### Volumes do Nginx

- `ngix_certs`: Montado em `/etc/nginx/certs:ro` (somente leitura)

## 🔧 Comandos Úteis

### Docker Compose (Standalone)

```bash
# Iniciar
docker-compose -f kilo-docker-compose.yaml up -d

# Parar
docker-compose -f kilo-docker-compose.yaml down

# Logs
docker-compose -f kilo-docker-compose.yaml logs -f

# Escalar réplicas (edite o arquivo ou use)
docker-compose -f kilo-docker-compose.yaml up -d --scale kilo=3
```

### Docker Swarm

```bash
# Listar stacks
docker stack ls

# Services da stack
docker stack services kilo

# Logs
docker service logs kilo_kilo

# Atualizar
docker service update --image wallacevff/kilo-autofree:latest kilo_kilo

# Remover
docker stack rm kilo
```

### Nginx Swarm

```bash
# Deploy/update
docker stack deploy -c nginx-docker-compose.yaml nginx

# Logs
docker service logs nginx_nginx

# Remover
docker stack rm nginx
```

## 🐛 Troubleshooting

### Kilo não conecta

1. Verifique se o container está rodando:
```bash
docker ps | grep kilo
```

2. Teste a porta:
```bash
curl http://localhost:4096
```

3. Verifique logs:
```bash
docker logs <container_id> -f
```

### Nginx retorna 502 Bad Gateway

1. Certifique-se que o Kilo está saudável:
```bash
docker service ls | grep kilo
```

2. Verifique rede:
```bash
docker network inspect kilo_net
```

3. Teste connectivity interna:
```bash
docker exec <nginx_container> curl http://kilo-autofree_kilo:4096
```

### Certificados TLS não funcionam

1. Verifique se os arquivos existem no volume:
```bash
docker exec <nginx_container> ls -la /etc/nginx/certs/
```

2. Teste validade:
```bash
docker exec <nginx_container> openssl x509 -in /etc/nginx/certs/kilocode.local.crt -noout -text
```

3. Reinicie Nginx:
```bash
docker service update --force nginx_nginx
```

## 🔄 Atualizações

### Atualizar imagem do Kilo

```bash
# Build local (se modificou o código)
docker build -t wallacevff/kilo-autofree:latest -f Kilo.Dockerfile .

# Push para registry (se necessário)
docker push wallacevff/kilo-autofree:latest

# Update no swarm
docker service update --image wallacevff/kilo-autofree:latest kilo_kilo
```

## 📊 Monitoramento

### Métricas do Kilo

- Health check: `http://localhost:4096/health` (se disponível)
- Logs em tempo real: `docker service logs -f kilo_kilo`

### Métricas Docker Swarm

```bash
# Nodes
docker node ls

# Services
docker service ls

# Tasks (containers)
docker service ps kilo_kilo
```

## 🛡️ Segurança

### HTTPS Obrigatório?

✅ **Sim em produção**. Use o Nginx para forçar HTTPS.

❌ **Não em desenvolvimento local**. Acesse diretamente a porta 4096.

### Headers de Segurança Recomendados

Adicione no `kilo.local.conf` dentro do `location /`:

```nginx
# Security headers
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;

# Rate limiting (limita requisições)
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req zone=api burst=20 nodelay;
```

## 📝 Notas Importantes

1. **Domínio `kilocode.local`**: Deve estar no `/etc/hosts` apontando para o IP do manager:
   ```
   10.0.4.3 kilocode.local
   ```

2. **Portas**: Kilo usa 4096 internamente, Nginx usa 80/443 externamente

3. **Modo Swarm**: Requer que o serviço Kilo esteja na rede `kilo_net` (criada previamente)

4. **Volumes externos**: Devem ser criados antes do primeiro deploy:
   ```bash
   docker volume create data
   docker volume create ngix_certs
   docker network create --driver overlay kilo_net
   ```

5. **Certificados**: Montados `:ro` (read-only) no Nginx para segurança

## 🤝 Contribuindo

Este é um projeto de infraestrutura/deploy. Para mudanças no Kilo CLI em si, consulte o repositório original.

## 📄 Licença

Consulte a licença do Kilo CLI: https://github.com/kilocode/cli

---

**Última atualização**: 2026-04-25
