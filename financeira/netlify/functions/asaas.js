// ============================================================
// FACILITA CELL — Netlify Function: Proxy Asaas
// Roda no servidor Netlify — sem problema de CORS
// ============================================================

const ASAAS_KEY = process.env.ASAAS_API_KEY || '$aact_prod_000MzkwODA2MWY2OGM3MWRlMDU2NWM3MzJlNzZmNGZhZGY6OmU3NzAzNGQ1LWQ2NmQtNDk4Yi1iNzlkLTI3YWI3MmE3ZjEwODo6JGFhY2hfMDNkN2I2YTgtYmY0OS00M2M1LTk1YTItMWNkMzNjMzRmNzRk';
const ASAAS_BASE = 'https://www.asaas.com';

exports.handler = async function(event) {
  // Libera CORS para o seu domínio Netlify
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
    'Content-Type': 'application/json'
  };

  // Responde ao preflight OPTIONS
  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 200, headers, body: '' };
  }

  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, headers, body: JSON.stringify({ error: 'Método não permitido' }) };
  }

  let body;
  try {
    body = JSON.parse(event.body);
  } catch(e) {
    return { statusCode: 400, headers, body: JSON.stringify({ error: 'Body inválido' }) };
  }

  const { acao } = body;

  try {
    // ── CRIAR CLIENTE NO ASAAS ─────────────────────────────
    if (acao === 'criar_cliente') {
      const { nome, cpf, telefone, email } = body;
      const resp = await fetch(`${ASAAS_BASE}/api/v3/customers`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'access_token': ASAAS_KEY
        },
        body: JSON.stringify({
          name: nome,
          cpfCnpj: cpf.replace(/\D/g, ''),
          mobilePhone: telefone.replace(/\D/g, ''),
          email: email || undefined
        })
      });
      const data = await resp.json();
      if (!resp.ok) throw new Error(data.errors ? data.errors[0].description : 'Erro ao criar cliente');
      return { statusCode: 200, headers, body: JSON.stringify({ id: data.id, nome: data.name }) };
    }

    // ── CRIAR COBRANÇA (BOLETO + PIX) ─────────────────────
    if (acao === 'criar_cobranca') {
      const { asaas_id, valor, vencimento, descricao } = body;
      const resp = await fetch(`${ASAAS_BASE}/api/v3/payments`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'access_token': ASAAS_KEY
        },
        body: JSON.stringify({
          customer: asaas_id,
          billingType: 'BOLETO',
          value: valor,
          dueDate: vencimento,
          description: descricao,
          fine: { value: 2 },
          interest: { value: 1 }
        })
      });
      const data = await resp.json();
      if (!resp.ok) throw new Error(data.errors ? data.errors[0].description : 'Erro ao criar cobrança');
      return {
        statusCode: 200,
        headers,
        body: JSON.stringify({
          id: data.id,
          bankSlipUrl: data.bankSlipUrl,
          nossoNumero: data.nossoNumero,
          pixCopiaECola: data.pixCopiaECola,
          status: data.status
        })
      };
    }

    // ── CRIAR COBRANÇA PIX ─────────────────────────────────
    if (acao === 'criar_pix') {
      const { asaas_id, valor, vencimento, descricao } = body;
      const resp = await fetch(`${ASAAS_BASE}/api/v3/payments`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'access_token': ASAAS_KEY
        },
        body: JSON.stringify({
          customer: asaas_id,
          billingType: 'PIX',
          value: valor,
          dueDate: vencimento,
          description: descricao
        })
      });
      const data = await resp.json();
      if (!resp.ok) throw new Error(data.errors ? data.errors[0].description : 'Erro ao criar PIX');
      // Busca o QR Code
      const qrResp = await fetch(`${ASAAS_BASE}/api/v3/payments/${data.id}/pixQrCode`, {
        headers: { 'access_token': ASAAS_KEY }
      });
      const qrData = await qrResp.json();
      return {
        statusCode: 200,
        headers,
        body: JSON.stringify({
          id: data.id,
          pixCopiaECola: qrData.payload,
          pixQrCode: qrData.encodedImage,
          status: data.status
        })
      };
    }

    // ── CONSULTAR STATUS PAGAMENTO ─────────────────────────
    if (acao === 'consultar_pagamento') {
      const { pagamento_id } = body;
      const resp = await fetch(`${ASAAS_BASE}/api/v3/payments/${pagamento_id}`, {
        headers: { 'access_token': ASAAS_KEY }
      });
      const data = await resp.json();
      return { statusCode: 200, headers, body: JSON.stringify({ status: data.status, valor: data.value }) };
    }

    // ── CANCELAR COBRANÇA ──────────────────────────────────
    if (acao === 'cancelar_cobranca') {
      const { pagamento_id } = body;
      const resp = await fetch(`${ASAAS_BASE}/api/v3/payments/${pagamento_id}`, {
        method: 'DELETE',
        headers: { 'access_token': ASAAS_KEY }
      });
      const data = await resp.json();
      return { statusCode: 200, headers, body: JSON.stringify({ deleted: data.deleted }) };
    }

    return { statusCode: 400, headers, body: JSON.stringify({ error: 'Ação desconhecida: ' + acao }) };

  } catch(e) {
    console.error('Asaas error:', e.message);
    return { statusCode: 500, headers, body: JSON.stringify({ error: e.message }) };
  }
};
