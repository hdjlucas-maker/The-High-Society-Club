# Revisão de qualidade do mundo — brainstorm, spec e plano

**Data:** 04/11/2026
**Entrada:** relato do seu filho + auditoria estática do código + build atual.
**Status:** proposta técnica. Nenhum script ou construção foi alterado nesta etapa.

---

## 1. Resumo executivo

O relato do seu filho está tecnicamente correto. Os problemas não são “detalhes visuais isolados”: eles vêm de cinco causas estruturais.

1. **O mundo atual muito provavelmente foi gerado por uma versão antiga do código.** O `WorldBuilder` só cria a base uma vez; se `Workspace.HighSocietyWorld` já existe, ele apenas acrescenta alguns pontos. O `WORLD_VERSION = 2` existe, mas nunca é usado. Portanto, corrigir ruas, escadas e ilha no código **pode não mudar** o mundo que está salvo no Studio. É preciso reconstruir a base de forma controlada.
2. **As alturas das superfícies são inconsistentes.** Ruas e calçadas ficam em `groundY + 0,30`; alamedas em `groundY + 0,80`; gramado em `groundY + 0,50`; praia em `groundY + 0,455`; lagoa em `groundY + 0,555`; deck em `groundY + 1,20`. Isso produz degraus, desníveis e “chão desalinhado” em todos os estabelecimentos e em Paradise Island.
3. **As escadarias dos prédios estão invertidas.** O degrau mais distante é o mais alto (0,90) e o mais próximo é o mais baixo (0,30); depois a fundação sobe para 1,20. O jogador sobe, desce e sobe de novo — ou trava na beirada.
4. **O mobiliário foi colocado sem zonas de circulação.** Há postes no eixo das alamedas, postes e palmeiras no meio das calçadas, duas fileiras de árvores quase no mesmo lugar e palmeiras “de praia” com monte de areia em calçada de mármore.
5. **As fachadas não são acessíveis.** Os prédios são blocos sólidos com uma porta decorativa; não existe interior. Quem tenta entrar bate na parede, e o desenho da porta sugere uma entrada que não existe.

Além disso, não há mapa/minimapa, os letreiros independentes flutuam sem postes e o áudio ambiente não existe (só o som do palco do DJ).

**Recomendação:** não começar alargando ruas. Primeiro estabilizar o mundo (spawn, alturas, escadas, colisão), depois organizar (ruas, mobiliário, árvores, placas), depois orientar (mapa/sinalização) e por fim ambiente (rádio). Uma reconstrução completa do layout urbano pode ser a fase seguinte, se necessária.

---

## 2. Diagnóstico por sintoma

| # | O que foi visto | Causa provável no código | Correção proposta |
|---|---|---|---|
| 1 | Falta de localização dos objetos | Não existe mapa/minimapa nem diretório. O cliente só mostra o nome da região (`GameClient`, faixa `RegionBanner`). Os letreiros independentes flutuam e alguns estão no lado errado. | Mapa de bolso + diretório no spawn + placas de entrada + ícones nos pontos de interação + waypoint. |
| 2 | Ruas estreitas | Rua principal com 24 studs (`WorldBuilder` linha 2011); avenida da frente com 24 (`WorldLife` linha 937); ruas de ligação com 10 (linha 1038); calçadas com 6,5–7. | Seção de rua padrão: pista 28–32, calçada 9, faixa de mobiliário 2,5, zona livre 4,5. |
| 3 | Calçadas desalinhadas e estreitas | `makeDistrictPath` acrescenta 0,3 ao nível recebido. Chamadas com `groundY + 0,5` criam alamedas em `groundY + 0,8`, enquanto a calçada está em `groundY + 0,3`. O caminho de entrada dos prédios fica em `groundY + 0,1`. | Um único “nível de caminhada” (`groundY + 0,30`) e rampas para gramado/praia. |
| 4 | Árvores com acabamentos soltos/incompletos | Duas passadas de vegetação: `WorldBuilder` planta árvores em z=-28 (`2086-2088`); `WorldLife.decorate` planta outra fileira em z=-30 (`1346-1356`) e palmeiras em z=186 (`1358-1360`), quase em cima das palmeiras do builder em z=188. As copas são esferas separadas e colidíveis; muitas palmeiras usam “monte de areia” em calçada. | Uma única passada de vegetação, com variantes por contexto (praia/calçada/gramado), copas não colidíveis e modelos conectados. |
| 5 | Dois postes no mesmo lugar | O mobiliário é posicionado por coordenadas fixas em módulos diferentes, sem checagem de duplicidade. Em vários pontos, poste + baliza + palmeira caem no mesmo raio. O caso exato precisa de screenshot/coordenada. | Faixa de mobiliário + regra de espaçamento + auditoria de sobreposição. |
| 6 | Postes no meio da passagem | Exemplos diretos: `PromenadeLamp` no eixo das alamedas (`WorldBuilder` 2552-2562); `FrontLamp` no centro da calçada de 7 studs (`WorldLife` 1089-1093); palmeiras no centro da calçada oposta (`1094-1097`). | Mover para a faixa junto à guia; manter 4,5 studs livres de caminhada. |
| 7 | Objetos desorganizados | Layout espalhado por `WorldBuilder`, `WorldLife` e `LuxuryKit`, com coordenadas repetidas e sem “planta” central. | Centralizar o mapa em um módulo `WorldLayout` e validar com `WorldAudit`. |
| 8 | Paradise Island com chão desalinhado | `IslandBeach` topo +0,455; `IslandLagoon` +0,555; `IslandPromenade` +0,8; `BeachPromenade` +0,8; `MarinaWater` +0,505; `MarinaDock` +1,2. As lajes se sobrepõem (praia 136–206, lagoa 188–226, marina 199–237, píeres 185–237). | Um único nível de água, praia com rampa até a água, calçadão em nível único e píeres sem sobreposição. |
| 9 | Não consigo acesso e fico preso | Prédios são caixas sólidas (`WorldBuilder` 280-287); a porta é decorativa (`427-428`). As escadas estão invertidas (`256-269` e `907-916`). As fundações têm beirada de 1,2. Cercas do Garden Park cruzam a alameda (`2169-2180`). | Entrada real ou “atendimento externo” claro; escadas corrigidas; rampas; auditoria de colisão; botão “Estou preso”. |
| 10 | Placa desalinhada | `makeSign` cria só a placa e a moldura; não cria postes. As placas ParkSign, IslandSign e MarinaSign ficam flutuando em y+7/8. ParkSign está no fundo do parque (z=123), não na entrada. | Kit de placa com postes, face voltada para o fluxo principal, altura e posição padronizadas. |
| 11 | Rádio ambiente dia/noite | Só existe o som do palco do DJ (`ClubService` 121-145). Não há `SoundService` ambiente, playlist ou agenda. `Config.Club.MusicSoundId` está vazio. | Rádio local por cliente, playlist dia/noite, crossfade, volume, botão liga/desliga e ducking perto do clube. IDs fornecidos pelo proprietário. |

### Duas causas “meta” que explicam a sensação de mundo inacabado

- **O mundo salvo não é reconstruído.** `WorldBuilder.Init` (3086-3108) só complementa um mundo existente. `HSC_Life` (WorldLife 1336-1339) retorna se a pasta já existe; só `HSC_Streetscape` tem versão e é reconstruída. Resultado: base velha + acabamento novo = desalinhamento e duplicatas.
- **Não existe auditoria de planta.** Não há verificação de sobreposição, altura, zona livre, duplicidade ou conexão de caminhos. O código “desenha” e torce para ficar certo.

---

## 3. Brainstorm — caminhos possíveis

### 3.1 Como corrigir o mundo existente

| Opção | O que é | Prós | Contras | Recomendação |
|---|---|---|---|---|
| A. Patch no mundo atual | Corrigir partes específicas no lugar | Rápido; não perde o que existe | Não resolve a base velha; continua frágil; difícil testar | Só para emergências |
| B. Reconstrução versionada em paralelo | Gerar `HighSocietyWorld_v3` ao lado, validar, arquivar o antigo e trocar | Seguro; permite comparar; mantém backup; resolve a raiz | Exige ferramenta de rebuild e teste | **Recomendado** |
| C. Cidade nova do zero | Novo layout completo | Liberdade total | Muito tempo; risco alto; refaz pontos de interação | Fase futura, se necessário |

### 3.2 Layout urbano

| Opção | O que é | Prós | Contras | Recomendação |
|---|---|---|---|---|
| A. Manter as duas ruas e alargar | Rua principal atrás + avenida da frente | Menor mudança | A rua principal continua sem fachadas; wayfinding ruim | Correção mínima |
| B. Promover a avenida da frente a boulevard principal | Lojas/hotel/galeria passam a ter a rua principal na frente; rua de trás vira secundária/jardim | Corrige a raiz; valoriza as fachadas; melhora a orientação | Move pontos, calçadas e placas; exige rebuild | **Recomendado para a fase estrutural** |
| C. Grade urbana nova | Quarteirões, avenidas, praças | Profissional | Muito escopo | Não agora |

### 3.3 Acesso aos prédios

| Opção | O que é | Prós | Contras | Recomendação |
|---|---|---|---|---|
| A. Atendimento externo | Balcão/vitrine na fachada; sem porta falsa | Rápido; sem interior; funciona | Menos imersivo | **Primeira entrega** |
| B. Interiores heróis | Shopping, hotel, concessionária e clube com lobby real | Imersão | Escopo médio/alto | Depois da base estável |
| C. Todos os interiores | Cada loja com interior | Máximo | Muito tempo | Não agora |

### 3.4 Localização / wayfinding

| Opção | O que é | Prós | Contras | Recomendação |
|---|---|---|---|---|
| A. Mapa esquemático + diretório + placas | Mapa de bolso com distritos e pontos; postes de direção no spawn | Barato, legível, funciona sem imagem | Menos “GPS” | **Primeiro** |
| B. Minimapa dinâmico | Mapa que lê o mundo e desenha ruas | Preciso | Mais complexo; pode pesar | Depois, se necessário |
| C. Só placas no mundo | Sem UI | Imersivo | Não resolve “onde fica?” | Complemento |

### 3.5 Árvores e palmeiras

| Opção | O que é | Prós | Contras | Recomendação |
|---|---|---|---|---|
| A. Melhorar o procedural | Conectar copa, variantes, sem colisão nas folhas | Sem asset externo; controle | Ainda estilizado | **Imediato** |
| B. Modelos licenciados | Árvores do Creator Store | Bonito | Depende do proprietário; licença; peso | Opcional |
| C. Híbrido | Procedural + modelos escolhidos | Melhor dos dois | Precisa catálogo | **Recomendado no futuro** |

### 3.6 Áudio ambiente

| Opção | O que é | Prós | Contras | Recomendação |
|---|---|---|---|---|
| A. Som global no servidor | Um `Sound` no `SoundService` | Simples; todos ouvem | Volume individual limitado; rede | Não |
| B. Rádio local no cliente | `Sound` local, playlist dia/noite | Volume por jogador; sem rede; fácil testar | Precisa de UI | **Recomendado** |
| C. Rádios por zona | Volume por proximidade (praia, clube, hotel) | Imersivo | Mais complexo | Fase 2 do áudio |

---

## 4. Spec — “World Quality v1”

### 4.1 Objetivo

Transformar o mundo procedural em um espaço **acessível, legível, alinhado e agradável**, sem refazer a economia, os veículos, as propriedades ou os eventos. O jogador deve conseguir sair do spawn, encontrar cada estabelecimento, entrar/ser atendido e circular sem travar.

### 4.2 Fora de escopo nesta versão

- Novos sistemas de gameplay.
- Novos modelos 3D comprados/importados (exceto se o proprietário fornecer).
- Interiores completos de todos os prédios.
- Monetização.
- Reescrita total do `GameClient`.

### 4.3 Padrões técnicos do mundo

#### Níveis e superfícies

- `WalkTop = groundY + 0,30` para ruas, calçadas, praças, calçadões e passarelas.
- `LawnTop = groundY + 0,50` para gramados; transição por rampa de 0,2–0,3 em pelo menos 2 studs.
- `BeachTop = groundY + 0,30` na areia; rampa suave até a água.
- `WaterTop` único por corpo d’água; sem duas superfícies transparentes sobrepostas.
- `FoundationTop = WalkTop + 0,90` (ou 1,20 acima do ground), com 3–4 degraus de 0,30 e patamar.
- Nenhum degrau isolado maior que 0,45 em área de circulação.
- Nenhuma laje caminhável sem apoio visual (sem “floating slab”).

#### Seção de rua

| Tipo | Pista | Calçada | Faixa de mobiliário | Zona livre | Total aproximado |
|---|---:|---:|---:|---:|---:|
| Boulevard principal | 28–32 | 9 | 2,5 | 4,5 | 46–50 |
| Avenida secundária | 22–24 | 7–8 | 2 | 4 | 37–42 |
| Rua de ligação | 14–16 | 6 | 1,5 | 3,5 | 29–33 |
| Calçadão / promenade | — | 10–12 | 1,5 | 4 | 12–15 |
| Passarela de praia | — | 8 | 1 | 3,5 | 8–10 |

- Mobiliário (poste, palmeira, banco, lixeira) sempre na faixa junto à guia, nunca no eixo.
- Portas/entradas: 5 studs livres à frente; nenhum objeto na zona.
- Cruzamentos: 8 studs livres; nenhum poste a menos de 8 studs.
- Duplicidade: dois itens iguais só podem ficar a menos de 8 studs se forem um conjunto intencional (ex.: par de balizas).

#### Escadas e entradas

- 3–4 degraus de 0,30; largura mínima 8; profundidade 1,6–2,0; patamar de 2,0.
- Degrau mais baixo alinhado ao `WalkTop`; mais alto alinhado ao `FoundationTop`.
- Corrimão decorativo only se não bloquear a passagem.
- Se o prédio não tiver interior, **não usar porta que pareça aberta**. Usar vitrine + balcão “ATENDIMENTO EXTERNO” ou porta fechada com placa “ACESSO PELO BALCÃO”.
- Se tiver interior, criar vão real, piso no nível da fundação, soleira <=0,1 e interior livre.

#### Vegetação

- Uma única passada; remover duplicatas do `WorldBuilder`/`WorldLife`.
- Palmeira `beach` só em areia; em calçada usar `urban` (vaso/grelha, sem monte de areia).
- Copa, folhas, flores, cocos e galhos: `CanCollide = false`.
- Tronco: colisão apenas se estiver fora da zona livre.
- Copa começa no mínimo 7 studs acima do piso; sem galho atravessando passagem.
- Espaçamento mínimo: 12 studs entre árvores; 8 entre palmeiras.
- Árvore precisa de berço/grelha no calçamento, não buraco solto.

#### Placas e letreiros

- Fachada: placa centrada, 0,15–0,25 à frente da parede, com suportes.
- Entrada de distrito: placa com dois postes, base no chão, face voltada para o fluxo de chegada.
- Nada de placa flutuando em y+7/8 sem suporte.
- ParkSign na entrada do parque (z≈39), não no fundo (z=123).
- IslandSign na chegada da ilha, MarinaSign na entrada da marina.
- Texto curto, alto contraste, mesma família visual.

#### Água e costa

- Um plano de água por corpo; sem sobreposição de `MarinaWater` e `IslandLagoon`.
- Praia com talude/rampa até a água; sem laje de areia flutuando sobre o vazio.
- Píeres no nível `WaterTop + 1,2`, com postes; sem sobreposição de decks.
- Fundo do mar contínuo; sem buraco visível.

#### Segurança e “não ficar preso”

- Botão **“Estou preso”** no celular/menu: confirma, cooldown de 15 s, teleporta para o spawn ou entrada do distrito mais próximo.
- `PlayerSafetyService`: se o `HumanoidRootPart` estiver dentro de parte colidível por 2 s, teleporta para o ponto seguro mais próximo e registra `[HSC]`.
- Nenhuma parte decorativa deve prender o jogador; colliders de cenário revisados.
- Teste obrigatório: caminhar do spawn até cada POI; nenhum travamento.

### 4.4 Wayfinding

- `WorldDirectory` (shared): lista de distritos, POIs, ícones, posições e região.
- Diretório físico no spawn e na praça: placas com setas para Shopping, Hotel, Concessionária, Marina, Paradise Island, Garden Park, Clube, Imóveis e Trabalho.
- Mapa de bolso (aba “Mapa” no celular): desenho esquemático com ruas, distritos e pontos; ponto do jogador; botão “Ir” que cria um waypoint (feixe/coluna dourada), não teleporte.
- Ícone flutuante (BillboardGui) sobre cada ponto de interação, com nome curto e ícone.
- Cores por categoria: loja (rosa), veículo (azul), imóvel (verde), evento (roxo), trabalho (dourado).
- Critério: um jogador novo encontra cada POI em até 60 s usando só a interface e as placas.

### 4.5 Rádio ambiente

- `Config.Audio`:
  - `Enabled`, `DaySoundIds`, `NightSoundIds`, `Volume`, `CrossfadeSeconds`, `ClubDuckDistance`.
- Cliente cria `Sound` local no `SoundService`, em loop, com `SoundGroup` “Ambient”.
- Dia (06:00–18:00): playlist tranquila; noite (18:00–06:00): playlist balada.
- Crossfade de 4 s; sem sobreposição de faixas; shuffle sem repetir a última.
- Botão no celular: ligar/desligar e volume; preferência local.
- Perto do palco do clube (60 studs), abaixar a rádio para não competir com o DJ.
- IDs vazios = rádio desligada com aviso “Rádio não configurada”.
- Usar somente áudios autorizados/licenciados; nada de músicas protegidas.

### 4.6 Rebuild e versionamento

- `WORLD_VERSION = 3` no `WorldBuilder` e atributo `Version` no mundo.
- Se o mundo existente for versão menor, **não apagar automaticamente**: gerar `HighSocietyWorld_v3` em paralelo, rodar `WorldAudit`, comparar, e só então arquivar o antigo em `ServerStorage.HSC_Archive` e renomear o novo.
- `HSC_Life` recebe `Version`; `decorate` reconstrói somente a decoração se a versão mudar.
- `HSC_Streetscape` mantém o sistema de versão atual.
- Fazer backup do lugar `.rbxlx` antes de qualquer rebuild.

### 4.7 Arquitetura proposta

| Módulo | Tipo | Responsabilidade |
|---|---|---|
| `WorldStandards` | ModuleScript shared | Constantes de altura, largura, clearance, cores. |
| `WorldLayout` | ModuleScript shared | Dados de ruas, calçadas, prédios, entradas, POIs e zonas. |
| `WorldDirectory` | ModuleScript shared | Lista pública de distritos/POIs para mapa e placas. |
| `WorldAudit` | ModuleScript server (dev) | Varredura de sobreposição, flutuação, duplicidade, altura e conectividade. |
| `WorldBuilder` | ModuleScript server | Constrói a base a partir do `WorldLayout`. |
| `WorldLife` | ModuleScript server | Decoração, NPCs, ruas e vegetação (dividir em submódulos se crescer). |
| `AmbientRadio` | ModuleScript client | Playlist dia/noite, crossfade, volume. |
| `MapUI` | ModuleScript client | Mapa de bolso + waypoint. |
| `PlayerSafetyService` | ModuleScript server | Botão “Estou preso” e detecção de aprisionamento. |

### 4.8 Critérios de aceite

1. Build Rojo sem erro; nenhum `[HSC][ERROR]` no Output ao iniciar.
2. Jogador nasce em pé, sobre piso, sem loop de queda.
3. Caminhada spawn → Shopping → Hotel → Concessionária → Clube → Garden → Marina → Paradise Island sem travar.
4. Nenhuma superfície caminhável com degrau > 0,45; nenhuma laje flutuante.
5. Nenhum poste/árvore na zona livre de 4,5 studs; nenhuma duplicata a menos de 8 studs.
6. Nenhuma placa flutuando; ParkSign/IslandSign/MarinaSign nas entradas corretas.
7. Mapa lista todos os POIs; waypoint funciona; novo jogador encontra cada POI em até 60 s.
8. Rádio alterna dia/noite, sem sobreposição, com botão de desligar; sem áudio não autorizado.
9. `WorldAudit` retorna zero violações críticas.
10. Teste multiplayer 2–4 jogadores sem erros.

---

## 5. Plano de execução

> Estimativas de esforço de desenvolvimento; não são prazos de calendário. Cada onda termina com teste no Studio e relatório. Não avançar sem o teste da onda anterior.

### Onda 0 — Segurança e evidências (0,5–1 dia)

- Backup do lugar no Studio (`Save to File As`) e exportação `.rbxlx` com Workspace.
- Confirmar `Baseplate` e `SpawnLocation`.
- Copiar Output do primeiro Play.
- Registrar screenshots/coordenadas dos pontos citados pelo seu filho, principalmente o local onde ele fica preso.
- Opcional: criar repositório Git e primeiro commit.

**Saída:** backup + Output + prints + local exato do travamento.

### Onda 1 — Destravar o mundo (R1, 1–2 dias)

- `PlayerSafetyService` + botão “Estou preso”.
- Corrigir `ensureSpawn` (chamar após a praça, sem duplicar).
- `WorldAudit` v1: sobreposição, flutuação, duplicidade, alturas.
- Corrigir escadas invertidas de `makeBuilding` e `makeResidence`.
- Alinhar `EntrancePath` ao `WalkTop`.
- Remover portas falsas ou sinalizar “atendimento externo”.
- Teste: spawn, caminhada curta, Output, audit.

**Saída:** jogador não cai, não fica preso, sobe escadas corretamente; relatório de auditoria.

### Onda 2 — Alinhar superfícies e Paradise Island (R2a, 2–3 dias)

- Padronizar `WalkTop`; corrigir chamadas de `makeDistrictPath`.
- Corrigir Garden Park, clube, Marina e Paradise Island.
- Um plano de água; praia com rampa; píeres alinhados; sem lajes sobrepostas.
- Ajustar cercas do Garden que cruzam alamedas.
- Teste: percurso completo; audit zero violações críticas de altura.

**Saída:** chão alinhado em todos os estabelecimentos e na ilha.

### Onda 3 — Ruas, mobiliário e vegetação (R2b, 3–5 dias)

- Seção de rua padrão; alargar pista/calçada onde couber.
- Mover postes/palmeiras/bench para a faixa de mobiliário.
- Remover duplicatas de árvores e palmeiras; variantes por contexto.
- Copas não colidíveis; corrigir montes de areia em calçada.
- Placas com postes, face e posição corretas.
- Teste: caminhar e dirigir; screenshots antes/depois; audit.

**Saída:** ruas largas, calçadas limpas, sem postes no meio, árvores completas.

### Onda 4 — Localização e wayfinding (R3, 2–3 dias)

- `WorldDirectory` + diretório físico.
- Aba “Mapa” no celular + ponto do jogador + waypoint.
- Ícones nos pontos de interação; placas de entrada dos distritos.
- Teste com jogador novo (ou você fingindo não conhecer): encontrar cada POI.

**Saída:** ninguém mais se perde.

### Onda 5 — Rádio ambiente (R4, 1–2 dias)

- `Config.Audio`; `AmbientRadio` client; UI de liga/desliga/volume.
- Playlists dia/noite; crossfade; ducking no clube.
- IDs fornecidos pelo proprietário; fallback silencioso.
- Teste com `Config.DayNight.UseRealTime = false` para simular manhã/noite.

**Saída:** manhã tranquila, noite de balada, sem sobreposição com o DJ.

### Onda 6 — Rebuild/layout v3 (opcional, 1–2 semanas)

- Se, depois das ondas 1–3, o layout ainda parecer apertado ou o boulevard continuar atrás das lojas, executar o layout v3.
- Congelar o layout atual em `WorldLayout` (sem mudança visual), depois ajustar dados, gerar em paralelo, validar e trocar.
- Só fazer com backup e aprovação.

**Saída:** cidade com planta profissional; pontos de interação preservados.

### Onda 7 — Teste final e performance (2–3 dias)

- Multiplayer 2–4 jogadores; DataStore; mobile; contagem de partes; StreamingEnabled.
- Revisão de segurança dos remotes.
- Relatório final.

---

## 6. Matriz de prioridade (impacto x esforço)

| Item | Impacto | Esforço | Prioridade |
|---|---|---|---|
| Spawn seguro / não cair | Alto | Baixo | P0 |
| Escadas/entradas alinhadas | Alto | Médio | P0 |
| “Estou preso” | Alto | Baixo | P0 |
| Chão da ilha e estabelecimentos | Alto | Médio | P0 |
| Postes no meio / duplicatas | Médio | Baixo | P1 |
| Ruas/calçadas largas | Alto | Médio/alto | P1 |
| Árvores completas | Médio | Médio | P1 |
| Placas com postes | Médio | Baixo | P1 |
| Mapa/diretório | Alto | Médio | P1 |
| Rádio dia/noite | Médio | Baixo/médio | P2 |
| Layout v3 | Alto | Alto | P2 (decisão futura) |

---

## 7. Riscos e cuidados

- **Reconstruir o mundo pode apagar objetos que o proprietário colocou manualmente.** O rebuild deve afetar apenas pastas com atributo `GeneratedBy = WorldBuilder`/`HSC_Life`/`HSC_Streetscape`; assets manuais em `Workspace.MeusAssets` ficam intactos. Backup antes.
- **Alargar ruas pode deslocar pontos de interação.** Por isso o layout precisa ser centralizado antes de mover medidas.
- **Áudio**: usar somente IDs autorizados; testar em lugar publicado; IDs vazios mantêm a rádio desligada.
- **Performance**: a cidade procedural tem milhares de partes; auditar contagem e considerar `StreamingEnabled`. Não aumentar detalhe sem medir.
- **Teste no Studio é insubstituível.** Nenhuma onda será declarada concluída sem Output e caminhada real.
- **Escopo**: é melhor entregar R1–R2 bem testadas do que R1–R6 pela metade.

---

## 8. O que preciso do proprietário / do seu filho

1. O local exato onde fica preso: nome do estabelecimento, print e, se possível, posição `(X, Y, Z)` do personagem.
2. Print do Explorer com `Workspace` aberto mostrando `Baseplate` e `SpawnLocation`.
3. Output completo do primeiro Play (linhas `[HSC]` e erros em vermelho).
4. Exportação `.rbxlx` do lugar atual, com Workspace, para eu auditar as construções reais.
5. Prioridade: começamos por **R1 (destravar)** ou por **R3 (mapa)**? Recomendo R1.
6. Áudio: você já tem IDs de músicas autorizadas? Se não, a rádio fica desligada até você escolher.
7. Autorização para criar o `PlayerSafetyService`, o `WorldAudit` e o rebuild versionado.

---

## 9. Próximo passo recomendado

**Aprovar a Onda 0 + Onda 1.** É a menor entrega que resolve o mais grave: o jogador não cai, não trava e o mundo começa a ser auditado. Depois do teste, seguimos para o alinhamento de superfícies e ilha (Onda 2).

Sem o Output e o local exato do travamento, consigo implementar a correção sistêmica, mas não consigo confirmar que o ponto específico que seu filho viu foi resolvido.
