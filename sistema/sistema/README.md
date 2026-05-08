# FACILITA CELL — Sistema de Gestão de Financiamento

Sistema completo de financiamento de celulares com painel administrativo, portal do cliente, portal do vendedor e integração com Supabase + Asaas.

## 📁 Estrutura

```
├── index.html         # Painel administrativo (admin/vendedor/suporte)
├── cadastro.html      # Formulário de cadastro do cliente (link QR Code)
├── cliente.html       # Portal do cliente (acompanhamento do financiamento)
├── vendedor.html      # Portal do vendedor
├── contrato.html      # Visualização do contrato
├── termo.html         # Termo de ciência e responsabilidade
├── recibo.html        # Recibo de pagamento
├── banco_de_dados.sql # Schema do banco Supabase
└── .nojekyll          # Necessário para GitHub Pages
```

## 🚀 Deploy no GitHub Pages

1. Suba este repositório no GitHub
2. Acesse **Settings → Pages**
3. Em **Source**, selecione `Deploy from a branch`
4. Escolha a branch `main` e pasta `/ (root)`
5. Clique em **Save** — o site estará disponível em:
   ```
   https://SEU_USUARIO.github.io/NOME_DO_REPO/
   ```

## 🗄️ Configuração do Supabase

1. Crie um projeto em [supabase.com](https://supabase.com)
2. Execute o arquivo `banco_de_dados.sql` no **SQL Editor**
3. Crie um bucket de storage chamado `documentos` (público)
4. As credenciais já estão preenchidas no código — substitua se criar novo projeto

## 💳 Integração Asaas

As chamadas à API do Asaas são feitas **diretamente do browser** (sem proxy).
A chave de produção já está configurada em `index.html` no objeto `FC_CONFIG`.

> ⚠️ Se o Asaas bloquear chamadas CORS do browser, acesse
> **Asaas → Configurações → API** e habilite o domínio do GitHub Pages
> na lista de origens permitidas.

## 🔐 Acessos padrão (modo demo)

| Perfil   | E-mail                | Senha    |
|----------|-----------------------|----------|
| Admin    | admin@facilita.com    | admin123 |
| Vendedor | vendedor@facilita.com | vend123  |
| Suporte  | suporte@facilita.com  | sup123   |

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
