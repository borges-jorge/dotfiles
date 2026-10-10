# Padrões de qualidade de engenharia

Aplique cada pilar **quando aplicável ao componente** (vários assumem serviço/backend
e podem não valer para todos). Quando pilares conflitam, explicite o trade-off e
recomende pelo contexto.

## 1. Adequação Funcional *(ISO 25010)*
Faz o que deve, correta e completamente?
- A funcionalidade corresponde ao que foi especificado?
- Há casos de uso implícitos (assumidos, não ditos) não cobertos?
- O comportamento em edge cases é correto (nulos, limites, entradas inesperadas)?
- Faz o apropriado para o contexto — nem mais, nem menos?

## 2. Eficiência de Performance *(ISO 25010)*
Usa recursos com eficiência e suporta o volume esperado?
- Qual é a latência aceitável? A implementação atinge esse target?
- Há operações custosas ocultas (N+1 queries, full scans, O(n²))?
- O que pode ser cacheado? Com qual TTL e estratégia de invalidação?
- Operações pesadas (I/O, rede, chamadas externas) são assíncronas quando faz sentido?
- Escala quando o volume dobrar? Há estado compartilhado que impeça múltiplas instâncias?
- Qual é o gargalo sob carga (CPU, memória, I/O, rede, dados)?

## 3. Compatibilidade *(ISO 25010)*
Coexiste e interopera com outros sistemas sem interferência?
- Os contratos de API (formatos, versões) estão bem definidos e estáveis?
- Mudanças neste componente quebram consumidores existentes?
- Há versionamento de API para breaking changes?
- A integração com serviços externos é resiliente a variações de versão?
- O compartilhamento de recursos (portas, filas, buckets) é controlado?

## 4. Usabilidade *(ISO 25010)*
É fácil de usar — para o usuário final e para quem consome a API?
- As mensagens de erro são informativas e acionáveis?
- A API é consistente (nomes, formatos, comportamentos previsíveis)?
- O fluxo principal exige o mínimo de passos necessários?
- A documentação é suficiente para um dev novo usar sem suporte?
- As validações indicam exatamente o que está errado e onde?

## 5. Confiabilidade *(ISO 25010)*
Opera sob condições normais e adversas, e se recupera de falhas?
- Degrada graciosamente quando uma dependência falha (fallback, circuit breaker)?
- Há timeout e retry com backoff em chamadas externas?
- Dados críticos são preservados em falha parcial (transação, idempotência)?
- É idempotente onde precisa ser?
- A disponibilidade esperada é suportada pelo design (health checks, restart)?
- Recupera-se sem intervenção manual?

## 6. Segurança *(ISO 25010)*
Protege dados e operações contra acesso não autorizado e ataques?
- Quais são as superfícies de ataque?
- Há validação rigorosa de entrada em todas as fronteiras?
- O princípio do menor privilégio está aplicado?
- Dados sensíveis estão protegidos em trânsito (TLS) e em repouso (hash/cripto)?
- Há risco de injeção (SQL, command, path traversal, SSRF)?
- Os logs não contêm dados sensíveis (senhas, tokens, PII)?
- AuthN/AuthZ estão em todas as rotas que precisam?

## 7. Manutenibilidade *(ISO 25010 — inclui Testabilidade e Observabilidade)*
Pode ser modificado, testado e diagnosticado com eficiência?

**Modularidade e modificabilidade:**
- Um dev novo entenderia a estrutura em ~30 minutos?
- Cada módulo tem uma única razão para mudar?
- Há duplicação que vai gerar inconsistência futura?
- As abstrações estão no nível certo (nem baixo demais, nem prematuro)?

**Testabilidade:**
- As dependências estão injetadas (não instanciadas internamente)?
- A lógica de negócio está isolada de I/O e frameworks?
- É possível testar os casos de erro sem infra real (mocks, fakes)?
- Dados que cruzam fronteiras de processo (HTTP, fila, arquivo) têm teste de
  ida-e-volta que **preserva tipos**? (serializar/desserializar e assertar tipos)
- Ao mockar, asserte o **contrato** (argumentos e valores passados), não apenas um
  comportamento que espelha o próprio código.

**Observabilidade:**
- É possível diagnosticar um problema em produção só com os logs?
- Os logs têm contexto suficiente (id de request/usuário, operação, duração)?
- Erros são logados com stack trace e contexto, sem dados sensíveis?
- Há métricas para operações críticas (latência, taxa de erro, throughput)?

## 8. Portabilidade *(ISO 25010)*
Pode ser implantado e executado em diferentes ambientes?
- A configuração está em variáveis de ambiente (sem hardcode por ambiente)?
- Roda igual em dev/staging/produção trocando apenas a configuração?
- Há dependências de SO, arquitetura (x86/ARM) ou serviços locais?
- (Se containerizado) a imagem é reproduzível / build determinístico?
- Pode ser migrado/substituído com impacto mínimo nos consumidores?

## 9. Conformidade *(extensão pragmática — LGPD)*
> Aplicável **se o sistema tratar dados pessoais**.
- Os dados pessoais são coletados com base legal definida?
- Há mecanismo para os direitos do titular (acesso, correção, exclusão)?
- Os dados são retidos apenas pelo período necessário?
- Há logs de auditoria para operações sensíveis (quem, o quê, quando)?
- Existe processo de notificação à ANPD em caso de incidente (72h)?
- A transferência a terceiros tem base contratual adequada?

## 10. Custo *(extensão pragmática — eficiência financeira)*
As decisões consideram o impacto financeiro em operação?
- O modelo de precificação dos serviços usados escala bem com o volume esperado?
- Há operações que geram custo desnecessário (chamadas redundantes a APIs pagas,
  storage não limpo)?
- As instâncias/containers estão dimensionados para o uso real, não para o pico teórico?
- Há estratégia para dados frios vs. quentes (storage tiers, TTL de cache)?
- (Se usar LLM) o prompt está otimizado? Há cache para respostas repetidas?
