# FACILITA CELL — Sistema de Gestão de Financiamento

Sistema completo de financiamento de celulares com painel administrativo, portal do cliente, portal do vendedor e integração com Supabase + Asaas.

## 📁 Estrutura

```
├── index.html          # Painel administrativo (admin/vendedor/suporte)
├── cadastro.html       # Formulário de cadastro do cliente (link QR Code)
├── cliente.html        # Portal do cliente (acompanhamento do financiamento)
├── vendedor.html       # Portal do vendedor
├── contrato.html       # Visualização do contrato
├── termo.html          # Termo de ciência e responsabilidade
├── recibo.html         # Recibo de pagamento
├── banco_de_dados.sql  # Schema do banco Supabase
├── netlify.toml        # Configuração Netlify + redirects
└── netlify/
    └── functions/
        ├── asaas.js    # Proxy Asaas (evita CORS)
        └── paghiper.js # Proxy PagHiper (evita CORS)
```

## 🚀 Deploy na Netlify

1. Faça fork ou importe este repositório no [Netlify](https://app.netlify.com)
2. Em **Site configuration → Environment variables**, adicione:
   ```
   ASAAS_API_KEY = sua_chave_asaas_producao
   ```
3. O build é estático — sem comando de build necessário
4. Diretório de publicação: `/` (raiz)

## 🗄️ Configuração do Supabase

1. Crie um projeto em [supabase.com](https://supabase.com)
2. Execute o arquivo `banco_de_dados.sql` no **SQL Editor** do Supabase
3. Crie um bucket de storage chamado `documentos` (público)
4. Atualize as variáveis em cada arquivo HTML:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`

> As credenciais atuais já estão preenchidas no código — substitua pelas suas caso crie um novo projeto Supabase.

## 💳 Integração Asaas

- A chave de produção já está configurada em `index.html` e `netlify/functions/asaas.js`
- Todas as chamadas à API Asaas passam pelo proxy Netlify (`/.netlify/functions/asaas`) para evitar CORS

## 🔐 Acessos padrão (modo demo)

| Perfil    | E-mail               | Senha     |
|-----------|----------------------|-----------|
| Admin     | admin@facilita.com   | admin123  |
| Vendedor  | vendedor@facilita.com| vend123   |
| Suporte   | suporte@facilita.com | sup123    |

> Em produção, os usuários são gerenciados pelo Supabase Auth.

## 📱 Funcionalidades

- ✅ Cadastro de clientes via QR Code
- ✅ Análise de crédito e aprovação
- ✅ Geração de contrato e termo de ciência
- ✅ Cobrança automática via Asaas (Boleto + PIX)
- ✅ Trava/destrava remota de aparelhos
- ✅ Portal do cliente com acompanhamento de parcelas
- ✅ Portal do vendedor com comissões
- ✅ Recibos digitais
- ✅ Dashboard com métricas em tempo real
