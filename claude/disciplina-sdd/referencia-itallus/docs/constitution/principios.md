# Princípios de qualidade do sistema

## I. Adequação e Experiência *(ISO/IEC 25010)*
O sistema entrega o que foi especificado — completo, correto e cobrindo edge cases
(nulos, limites, entradas inesperadas) — e o faz de forma **usável**: erros
acionáveis, API/UX consistente e previsível, e documentação suficiente para operar
sem suporte.
**Racional:** fazer a coisa certa e fazê-la de forma compreensível são faces da mesma
entrega; software correto porém inusável (ou o inverso) falha com o usuário.

## II. Eficiência de Performance *(ISO/IEC 25010)*
Não se introduz custo oculto (N+1, full scan, O(n²)); operações pesadas são assíncronas
quando faz sentido e o caminho escala com o volume previsto. Onde o uso justifica, o
**caminho crítico** tem um alvo de latência/throughput **explícito e controlável** — o alvo
vem de uma **decisão registrada**, não de um número inventado para satisfazer o gate.
**Racional:** performance precisa ser projetada contra um alvo real; um alvo fabricado só para
passar no gate não mede nada.

## III. Compatibilidade *(ISO/IEC 25010)*
Contratos de API são bem definidos, versionados e estáveis; mudanças não quebram
consumidores existentes sem um processo explícito de breaking change.
**Racional:** integrações silenciosamente quebradas propagam falhas entre features e serviços.

## IV. Confiabilidade *(ISO/IEC 25010)*
Toda chamada que **sai do processo** (banco, gateway, integração) tem **prazo** (timeout/
deadline); **retry só em operação idempotente**, com backoff e teto; o sistema **degrada
graciosamente** quando uma dependência falha, é idempotente onde precisa e se recupera **sem
intervenção manual**. (Circuit breaker é mecanismo distinto e fica para quando a maturidade exigir.)
**Racional:** falhas são inevitáveis; o que diferencia é a recuperação sem perda de dados nem
operador. "Chamada externa" é ambíguo — o que importa é **sair do processo** e poder pendurar.

## V. Segurança *(ISO/IEC 25010)*
Entrada validada em todas as fronteiras, princípio do **menor privilégio**, **sem segredos nem
PII em log**. Proteção criptográfica (em trânsito/em repouso) entra quando um **requisito
concreto a exigir** — não como mandato cego; num alvo on-prem só por VPN, sem ingress, o
transporte é tratado na camada de rede.
**Racional:** superfície de ataque é introduzida a cada decisão; segurança não é retrofit — mas
um MUST que ninguém implementa não protege nada, só mascara o gate.

## VI. Manutenibilidade *(ISO/IEC 25010)*
Código modular e testável (dependências injetadas, lógica de negócio isolada de I/O
e frameworks), com observabilidade suficiente para diagnosticar um problema em produção só pelos logs.
**Racional:** a maior parte do custo de software é mudança posterior; código opaco trava a evolução.

## VII. Portabilidade *(ISO/IEC 25010)*
Configuração **100% externalizada** (sem hardcode por ambiente; nenhum valor de ambiente
embutido na imagem). A imagem validada é **promovida sem rebuild** — dev e produção diferem
**só no empacotamento** (dev constrói e monta a fonte; produção roda a imagem versionada), não
na configuração.
**Racional:** "funciona na minha máquina" é sintoma de acoplamento ao ambiente.

## VIII. Conformidade (LGPD) *(extensão pragmática)*
> Aplicável se o sistema tratar dados pessoais.

Dados pessoais têm base legal definida, os direitos do titular (acesso, correção,
exclusão) são atendíveis, a retenção é mínima e operações sensíveis são auditadas.
**Racional:** conformidade ignorada vira passivo legal e risco de incidente com prazo de notificação.

## IX. Custo *(extensão pragmática)*
Decisões arquiteturais consideram o custo operacional: **recursos não superdimensionados**,
**um único stack** (sem ambiente always-on redundante), **storage limpo**. Evita-se
**over-engineering** — abstração só onde há troca plausível.
**Racional:** custo que não é decisão explícita vira surpresa na fatura e limita a viabilidade.
