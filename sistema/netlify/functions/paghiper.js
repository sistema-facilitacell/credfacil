// ============================================================
// FACILITA CELL — Netlify Function: Proxy PagHiper
// Boleto R$0,99 | PIX grátis | Sem mensalidade
// ============================================================
// Para usar: cadastre em paghiper.com e obtenha:
//   - apiKey (chave da API)
//   - token (token do usuário)
// Configure em Netlify → Site Settings → Environment Variables

const PAGHIPER_KEY   = process.env.PAGHIPER_API_KEY   || 'SUA_API_KEY_PAGHIPER';
const PAGHIPER_TOKEN = process.env.PAGHIPER_TOKEN      || 'SEU_TOKEN_PAGHIPER';
const PAGHIPER_BASE  = 'https://api.paghiper.com';

exports.handler = async function(event) {
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Content-Type': 'application/json'
  };

  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 200, headers, body: '' };
  }

  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, headers, body: JSON.stringify({ error: 'Método não permitido' }) };
  }

  let body;
  try { body = JSON.parse(event.body); }
  catch(e) { return { statusCode: 400, headers, body: JSON.stringify({ error: 'Body inválido' }) }; }

  const { acao } = body;

  try {
    // ── GERAR BOLETO ───────────────────────────────────────
    if (acao === 'gerar_boleto') {
      const { nome, cpf, email, valor, vencimento, descricao, contrato_numero } = body;
      const vencFormatado = vencimento; // YYYY-MM-DD

      const payload = {
        apiKey: PAGHIPER_KEY,
        token: PAGHIPER_TOKEN,
        order_id: contrato_numero || 'FC-' + Date.now(),
        payer_name: nome,
        payer_cpf_cnpj: cpf.replace(/\D/g, ''),
        payer_email: email || '',
        amount_cents: Math.round(parseFloat(valor) * 100),
        due_date: vencFormatado,
        items: [{
          description: descricao || 'Parcela de financiamento',
          quantity: 1,
          item_id: '1',
          price_cents: Math.round(parseFloat(valor) * 100)
        }],
        notification_url: '',
        days_due_date_discount: 0,
        open_after_day_due: 10,
        late_payment_fine: '2.00',
        per_day_interest: true,
        per_day_interest_type: '0',
        per_day_interest_value: '0.033'
      };

      const resp = await fetch(`${PAGHIPER_BASE}/boleto/create/`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });

      const data = await resp.json();
      const result = data.create_request;

      if (!result || result.result !== 'success') {
        throw new Error(result ? result.response_message : 'Erro ao criar boleto');
      }

      return {
        statusCode: 200,
        headers,
        body: JSON.stringify({
          id: result.transaction_id,
          boleto_url: result.bank_slip.url_slip,
          linha_digitavel: result.bank_slip.digitable_line,
          codigo_barras: result.bank_slip.bar_code_number_to_image,
          vencimento: result.due_date,
          valor: result.value_cents / 100
        })
      };
    }

    // ── GERAR PIX ──────────────────────────────────────────
    if (acao === 'gerar_pix') {
      const { nome, cpf, email, valor, descricao, contrato_numero } = body;

      const payload = {
        apiKey: PAGHIPER_KEY,
        token: PAGHIPER_TOKEN,
        order_id: contrato_numero || 'FC-' + Date.now(),
        payer_name: nome,
        payer_cpf_cnpj: cpf.replace(/\D/g, ''),
        payer_email: email || '',
        amount_cents: Math.round(parseFloat(valor) * 100),
        items: [{
          description: descricao || 'Parcela de financiamento',
          quantity: 1,
          item_id: '1',
          price_cents: Math.round(parseFloat(valor) * 100)
        }]
      };

      const resp = await fetch(`${PAGHIPER_BASE}/pix/create/`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });

      const data = await resp.json();
      const result = data.pix_create_request;

      if (!result || result.result !== 'success') {
        throw new Error(result ? result.response_message : 'Erro ao criar PIX');
      }

      return {
        statusCode: 200,
        headers,
        body: JSON.stringify({
          id: result.transaction_id,
          pix_copia_cola: result.pix_code.qrcode_image_url,
          qrcode: result.pix_code.qrcode,
          valor: result.value_cents / 100
        })
      };
    }

    // ── CONSULTAR STATUS ───────────────────────────────────
    if (acao === 'consultar') {
      const { transaction_id } = body;
      const resp = await fetch(`${PAGHIPER_BASE}/boleto/notification/`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ apiKey: PAGHIPER_KEY, token: PAGHIPER_TOKEN, transaction_id })
      });
      const data = await resp.json();
      const result = data.status_request;
      return {
        statusCode: 200,
        headers,
        body: JSON.stringify({ status: result ? result.status : 'unknown' })
      };
    }

    return { statusCode: 400, headers, body: JSON.stringify({ error: 'Ação desconhecida: ' + acao }) };

  } catch(e) {
    console.error('PagHiper error:', e.message);
    return { statusCode: 500, headers, body: JSON.stringify({ error: e.message }) };
  }
};
