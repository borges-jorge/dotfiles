---
name: check-qty-pos-tim
description: >-
  Valida se todos os PDFs de purchase orders referenciados num e-mail .msg estão
  salvos num diretório. Compara os números de PO extraídos dos nomes de arquivo
  PDF contra o conteúdo textual do .msg e reporta o que falta ou sobra. Use quando
  o usuário pedir para "validar os PDFs desse diretório", "conferir se os pedidos
  estão salvos", ou apontar uma pasta com PDFs de PO + um .msg "Confirmar pedidos
  de seus compradores" (ou similar) para checagem.
---

# check-qty-pos-tim — Validar PDFs de Purchase Orders (Tim) contra .msg

> **Contexto:** o processo `purchase-orders-processor` recebe e-mails Outlook (`.msg`)
> com pedidos de compra a confirmar, cujos PDFs anexos (nomeados pelo número da PO,
> ex. `4504736450.PDF`) são salvos numa pasta por data. Esta skill confere se todo PDF
> salvo no diretório também está referenciado no `.msg`, e vice-versa.

## Quando usar
- Usuário aponta um diretório `.../purchase-orders-processor/files/<data>` e pede para
  validar/conferir os PDFs.
- Usuário quer saber se algum PDF de PO está faltando ou sobrando em relação ao e-mail.

## Argumento
- **Path do diretório** contendo os PDFs e o arquivo `.msg`. Deve ser passado pelo
  usuário (ex.: `C:\Users\...\files\2026 07 08`, convertido para `/mnt/c/Users/...`
  se rodando em WSL).

## Procedimento

1. **Resolva o path.** Se o usuário passar um caminho estilo Windows
   (`C:\Users\...`), converta para o formato WSL (`/mnt/c/Users/...`), preservando
   espaços no nome de pastas com aspas.

2. **Localize os arquivos no diretório:**
   ```bash
   ls -la "<dir>"
   find "<dir>" -iname "*.msg" -type f
   ```
   Deve haver exatamente um `.msg`. Se houver mais de um ou nenhum, avise o usuário
   e peça esclarecimento em vez de adivinhar.

3. **Extraia os números de PO dos nomes de PDF** no diretório (prefixo numérico do
   nome do arquivo, ex. `4504736450` de `4504736450.PDF`).

4. **Extraia o texto do `.msg`** com `strings` (arquivos `.msg` são OLE/CDFV2 binários
   — `strings` é suficiente para achar números de PO em texto plano; não é necessário
   parsing completo do formato OLE para este caso de uso).

5. **Compare:** para cada PDF do diretório, verifique se o número de PO aparece no
   texto extraído do `.msg`. Reporte:
   - ✅ PDFs cujo número foi encontrado no `.msg`
   - ❌ PDFs cujo número **não** foi encontrado no `.msg` (possível PDF fora do
     escopo do e-mail, ou nomeado de forma diferente)
   - Total de PDFs no diretório vs. total encontrados no `.msg`

6. **Reporte o resultado** em português, de forma objetiva: lista de PDFs validados,
   contagem total, e destaque claro de qualquer PDF faltante ou não correspondido.
   Não gere arquivos de relatório em disco a menos que o usuário peça — a resposta
   no chat é suficiente.

## Script de referência

Use este script Python (via Bash) como base — adapte apenas o path do diretório:

```python
import subprocess
import re
import os

files_dir = "<DIR>"  # ex: "/mnt/c/Users/Jorge Borges/OneDrive - Italtel Spa/.../2026 07 08"

msg_candidates = [f for f in os.listdir(files_dir) if f.lower().endswith('.msg')]
if len(msg_candidates) != 1:
    raise SystemExit(f"Esperado 1 arquivo .msg, encontrado {len(msg_candidates)}: {msg_candidates}")
msg_file = os.path.join(files_dir, msg_candidates[0])

pdfs_in_dir = {}
for file in sorted(os.listdir(files_dir)):
    if file.upper().endswith('.PDF'):
        match = re.match(r'(\d+)', file)
        if match:
            pdfs_in_dir[match.group(1)] = file

result = subprocess.run(['strings', msg_file], capture_output=True, text=True)
content = result.stdout

found, not_found = {}, []
for number, filename in sorted(pdfs_in_dir.items()):
    if number in content:
        found[number] = filename
    else:
        not_found.append((number, filename))

print(f"PDFs no diretório: {len(pdfs_in_dir)}")
print(f"PDFs encontrados no .msg: {len(found)}")
print(f"PDFs NÃO encontrados no .msg: {len(not_found)}")
for num, filename in not_found:
    print(f"  ❌ {filename}")
```

## Limitações conhecidas
- A checagem é por **presença do número da PO como substring** no texto extraído do
  `.msg`, não uma comparação estrutural de anexos reais (o parsing OLE completo de
  `.msg` exigiria `extract-msg`/`olefile`, que podem não estar instalados). Isso é
  suficiente na prática porque os números de PO são únicos e longos (10+ dígitos),
  mas pode gerar falso-positivo/negativo em casos extremos — se o resultado for
  ambíguo, avise o usuário.
- Não valida o **conteúdo** dos PDFs, apenas a correspondência de nomes/números.
