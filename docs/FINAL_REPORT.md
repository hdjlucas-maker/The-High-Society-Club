# Relatório final — The High Society Club

**Data:** 02/11/2026
**Slogan:** “Seu mundo. Seu estilo. Sua conquista.”
**Status:** escopo de scripts das Fases 1 a 11.1 implementado. As tarefas 11.2 e 11.3 dependem do proprietário (testes no Studio e publicação). **Nada foi validado em gameplay e o jogo não está pronto para publicação.**

> Este relatório encerra a programação planejada no Master Prompt v2. Ele não afirma que o jogo funciona no Roblox Studio: afirma que o código foi escrito, revisado estaticamente e que o projeto Rojo compila. O próximo passo é o proprietário executar `docs/TESTING.md` em uma cópia publicada.

---

## 1. O que foi implementado

### 1.1 Fundação e arquitetura

- Projeto Rojo em `default.project.json` com os destinos:
  - `ServerScriptService.HSC` — Bootstrap e módulos de servidor.
  - `StarterPlayer.StarterPlayerScripts.HSC` — cliente principal.
  - `ReplicatedStorage.HSC` — configuração, logs e catálogos compartilhados.
  - `StarterGui.HSC` — reservado para GUI estática; a interface atual é criada em runtime pelo cliente.
- `Config.lua` centraliza economia, DataStore, veículos, clube, rate limits, mercado, monetização, moderação de criações e mapa.
- `Logger.lua` padroniza mensagens com prefixo `[HSC]`.
- Ciclo dia/noite global com manhã, tarde, entardecer e noite, sincronizado com a agenda dos eventos.
- `WorldBuilder` gera a cidade procedural e mantém compatibilidade com objetos já existentes no Workspace.
- Spawn seguro documentado: `Workspace.Baseplate` ou uma `SpawnLocation`; se nenhum existir, o mapa usa o nível do chão e registra aviso.

### 1.2 Economia e persistência

- Moeda única: **Society Credits**, com leaderstats.
- `DataService` separado da economia, usando o DataStore `EconomyData_v1` e as chaves `Player_<UserId>` já existentes.
- Lock de sessão por jogador, retry limitado, autosave a cada 60 s, salvamento ao sair e `BindToClose`.
- Perfil temporário e não persistente quando o DataStore falha no Studio; em servidor publicado, falha de carregamento ou lock ativo impede a entrada para proteger os dados.
- `EconomyService` é o único ponto de alteração de saldo. Valida valores, aplica a transação, registra no histórico e dispara a atualização do leaderstats.
- Histórico persistente com data, jogador, item/serviço, valor e resultado; o extrato mostra as 20 movimentações mais recentes.
- Bônus de primeiro acesso, recompensa diária com sequência e teto, conquistas e reputação informativa.
- `RateLimitService` reutilizável por jogador e por operação; limites separados para consultas e ações.
- Comandos administrativos restritos ao criador, proprietário do grupo ou IDs em `Config.AdminUserIds`; a única ação é expulsão da sessão atual, com confirmação e log.

### 1.3 Cidade, lojas e regiões

- Regiões detectadas no servidor por posição: High Society Boulevard, Garden Park, Grand Society Club, Millionaire District e Paradise Island & Royal Marina.
- Nome da região exibido temporariamente ao jogador quando ele entra em uma área.
- Catálogo de lojas por estabelecimento, com `StoreId`, ponto físico e validação de proximidade no servidor.
- Compra de roupas, acessórios e itens virtuais sem confiar em preço, saldo ou quantidade enviados pelo cliente.
- Interface de loja, inventário, extrato, jogadores, trabalho, eventos, imóveis, veículos, mercado, clube e monetização.

### 1.4 Veículos

- Catálogo compartilhado com três carros, uma motocicleta e uma lancha.
- Compra na concessionária ou marina, com validação de ponto, saldo, item e duplicidade.
- Garagem e marina para retirar e guardar veículos; máximo de um veículo ativo por jogador.
- Spawn com verificação de espaço livre, controle server-authoritative, limites de comando e network ownership no servidor.
- Test drive temporário sem conceder propriedade, com duração configurável e recolhimento automático.
- Pintura de veículos próprios na garagem, salva por veículo.
- Modelos gerados por `VehicleBuilder`; o proprietário pode substituir por modelos 3D finais mantendo os nomes documentados.

### 1.5 Propriedades

- Catálogo de três imóveis (cobertura, villa e suíte), com compra, ownership persistido e atualização da interface.
- Entrada, saída, convites e limite de quatro visitantes validados no servidor.
- Interiores privados temporários por jogador, sem expor a decoração de um proprietário a outro.
- Estilos de interior e conjuntos de decoração salvos no perfil; somente o proprietário altera dentro da própria instância.
- Regras de acesso, expiração de convite e retorno à cidade ao sair, morrer ou desconectar.

### 1.6 Avatares, moda e fotografia

- Inventário persistente e equipagem/desequipagem por slot.
- Catálogo compartilhado de roupas e acessórios com visual procedural (sem assets de terceiros).
- Restauração da aparência equipada após carregar o avatar.
- Três poses procedurais para R6/R15: Elegante, Brinde e Editorial.
- Modo foto/selfie com `CaptureService`, álbum local de até 20 capturas e salvamento individual na galeria do dispositivo; nenhuma imagem é enviada ao servidor.

### 1.7 Entretenimento e social

- Eventos com agenda no relógio do jogo, presença validada, pontos diários e convites de sessão com expiração.
- Desfile de moda com inscrição única por dia, voto único, bloqueio de voto próprio e resultado com empate.
- Cabine de DJ no Grand Society Club com três estilos de show de luzes; áudio opcional somente se o proprietário configurar uma faixa autorizada em `Config.Club.MusicSoundId`.
- Denúncia e bloqueio usando as ferramentas oficiais do Roblox (`PromptReportPlayer` e `PromptBlockPlayer`), sem chat privado paralelo.
- Logs de moderação no Output e buffer volátil de até 50 registros por servidor; painel autorizado consulta os 20 mais recentes.
- Nenhum sistema de namoro, conteúdo sexual, família, apostas, chat privado irregular ou promessa de dinheiro real.

### 1.8 Profissões

Dez profissões com início, destino, duração, distância, progressão e pagamento validados no servidor:

1. Chauffeur
2. Guia turístico
3. DJ
4. Animador de eventos
5. Empresário
6. Proprietário de estabelecimento
7. Designer de roupas
8. Criador de mundos
9. Fotógrafo virtual
10. Organizador de eventos

- Cinco patentes por profissão: Aprendiz, Profissional, Especialista, Elite e Lenda.
- Promoções aumentam a remuneração-base em 5% por nível, até 20%.
- Pagamento somente após concluir a rota e as atividades exigidas; abandonar não concede créditos.
- Chauffeur exige veículo próprio ativo; as demais rotas validam deslocamento plausível.
- Proprietário de estabelecimento e Criador de mundos usam escolhas presenciais em sequência, sem texto livre.

### 1.9 Mercado, editor e monetização

- Mercado entre jogadores da mesma sessão para itens de moda, presentes e doações de Society Credits.
- Anúncios com duração de 15 minutos, limite por jogador e por servidor, preço máximo e exigência de proximidade.
- Comissão de 5% em vendas de itens, arredondada para baixo e descontada do vendedor; presentes e doações não pagam comissão.
- Veículos e imóveis não são negociáveis nesta versão.
- Editor limitado de cenários: temas e composições de catálogo fechado, fila persistente no DataStore `CreationModeration_v1`, aprovação apenas por criador/admin e maquetes físicas na Galeria.
- Game Pass **Society VIP** cosmético e três Developer Products de créditos (1.000, 5.000 e 20.000).
- Recibos de Developer Products persistidos e idempotentes; o servidor só confirma depois de gravar o recibo e o crédito.
- IDs de monetização permanecem em `0` até o proprietário criar os produtos no painel Roblox.

### 1.10 Inventário técnico

| Item | Quantidade |
|---|---|
| Arquivos `.lua` | 29 |
| Bootstrap de servidor | 1 |
| ModuleScripts de servidor | 22 |
| Módulos compartilhados | 5 |
| Script de cliente | 1 |
| Remotes criados pelo servidor | 70 (48 RemoteEvents + 22 RemoteFunctions) |
| DataStores | 2 (`EconomyData_v1`, `CreationModeration_v1`) |
| Profissões | 10 |
| Veículos no catálogo | 5 |
| Imóveis no catálogo | 3 |

---

## 2. O que depende do proprietário

Nenhum item abaixo pode ser executado por um agente que só edita arquivos. Eles estão detalhados em `docs/OWNER_TASKS.md` e `docs/MONETIZATION.md`.

### 2.1 Antes de qualquer teste

- [ ] Fazer uma cópia de segurança de `club da alta sociedade.rbxl`.
- [ ] Abrir a cópia no Studio e conferir `Workspace.Baseplate` ou uma `SpawnLocation`.
- [ ] Publicar a cópia como experiência de teste separada.
- [ ] Em **Game Settings > Security**, habilitar **Enable Studio Access to API Services** para testar DataStore.
- [ ] Sincronizar o projeto Rojo e confirmar que `ServerScriptService.HSC`, `ReplicatedStorage.HSC` e `StarterPlayerScripts.HSC` existem.
- [ ] Confirmar no Output que não há erros de inicialização com prefixo `[HSC]`.

### 2.2 Monetização

- [ ] Criar o Game Pass **Society VIP** e copiar o ID para `Config.Monetization.VIPGamePassId`.
- [ ] Criar os três Developer Products de 1.000, 5.000 e 20.000 Society Credits.
- [ ] Definir os preços em Robux no painel Roblox.
- [ ] Copiar cada ID para o produto correspondente em `Config.Monetization.DeveloperProducts`.
- [ ] Publicar novamente e testar as compras em uma experiência de teste.
- [ ] Confirmar que IDs em `0` mantêm os botões desativados.

### 2.3 Assets e conteúdo

- [ ] Fornecer modelos 3D finais de prédios, carros, roupas, móveis e paisagismo, se quiser substituir a cidade procedural.
- [ ] Enviar ao Roblox somente assets próprios ou autorizados e informar os IDs.
- [ ] Opcional: fornecer uma música autorizada e preencher `Config.Club.MusicSoundId` com `rbxassetid://<ID>`.
- [ ] Definir proprietário/grupo e permissões da experiência.
- [ ] Revisar classificação etária, privacidade, descrição e política de conteúdo.

### 2.4 Publicação

- [ ] Executar todos os testes da seção 3 em uma cópia publicada.
- [ ] Corrigir falhas encontradas e repetir os testes afetados.
- [ ] Criar ícone, thumbnails, descrição e página comercial.
- [ ] Responder ao questionário de classificação etária.
- [ ] Publicar a versão final e monitorar Output, erros e feedback.
- [ ] Manter uma versão anterior para rollback.

---

## 3. Lista completa de testes no Studio

> **Regra:** nenhum item abaixo foi executado. Marque cada caixa somente após testar na cópia publicada. O roteiro detalhado e atualizado está em `docs/TESTING.md`; esta seção é a lista de aceite final.

### 3.1 Preparação e inicialização

- [ ] Fazer backup do lugar e sincronizar o Rojo sem substituir o Workspace existente.
- [ ] Abrir o Output e confirmar que Bootstrap, módulos, UI, remotes e mapa iniciam sem erros.
- [ ] Confirmar `ServerScriptService.HSC.Bootstrap`, os 22 ModuleScripts e os 5 módulos compartilhados.
- [ ] Confirmar que `ReplicatedStorage.HSC.Remotes` contém os 70 remotes esperados.
- [ ] Confirmar que o jogador nasce em local seguro, sobre o chão, sem cair ou ficar preso.
- [ ] Confirmar que a interface abre, fecha e não duplica ao respawnar.
- [ ] Confirmar que o ciclo manhã/tarde/entardecer/noite funciona e que o horário exibido corresponde ao relógio do jogo.

### 3.2 Economia, perfil e DataStore

- [ ] Confirmar leaderstats de Society Credits no primeiro acesso e após reconectar.
- [ ] Confirmar o bônus de primeiro acesso uma única vez.
- [ ] Resgatar a recompensa diária; confirmar uma vez por dia UTC, sequência e teto de 300.
- [ ] Confirmar que ganhos e gastos aparecem uma única vez no extrato com data, jogador, referência, valor e resultado.
- [ ] Confirmar que saldo insuficiente e validação inválida não alteram o saldo nem geram registro de sucesso.
- [ ] Testar autosave, saída e `BindToClose`; confirmar persistência após reconectar.
- [ ] Testar falha transitória de DataStore, retry e bloqueio de sessão simultânea.
- [ ] Confirmar que o perfil temporário do Studio não sobrescreve dados persistentes.
- [ ] Confirmar que um segundo servidor não abre o mesmo perfil enquanto o lock estiver ativo.

### 3.3 Cidade, regiões e lojas

- [ ] Entrar e sair de High Society Boulevard, Garden Park, Grand Society Club, Millionaire District e Paradise Island & Royal Marina; confirmar nome ao entrar, troca ao mudar de região e limpeza ao sair/morrer.
- [ ] Confirmar que a cidade procedural não gera peças flutuantes nem sobrepõe construções existentes.
- [ ] Abrir cada loja no ponto correto e confirmar o catálogo filtrado por estabelecimento.
- [ ] Comprar item no ponto correto; confirmar débito, item no inventário e registro no extrato.
- [ ] Tentar comprar à distância, item de outra loja, item desconhecido e item já possuído; confirmar recusa sem cobrança.
- [ ] Equipar/desequipar item e confirmar substituição no mesmo slot e persistência após respawn/reconexão.

### 3.4 Veículos

- [ ] Comprar cada carro na concessionária, a motocicleta e a lancha na marina; confirmar preço do catálogo, débito e ownership.
- [ ] Retirar e guardar veículo nos pontos corretos; confirmar bloqueio de segundo veículo ativo.
- [ ] Confirmar spawn livre, direção, frenagem, parada e controle somente pelo motorista proprietário.
- [ ] Testar pintura na garagem, persistência da cor e recusa para veículo não possuído ou jogador distante.
- [ ] Iniciar test drive de carro, moto e lancha; confirmar duração, recolhimento automático e ausência de propriedade após reconectar.
- [ ] Tentar comprar/retirar durante test drive; confirmar bloqueio.
- [ ] Confirmar flutuação e controles da lancha apenas na água identificada.
- [ ] Confirmar que veículos não podem ser usados para validar a rota de Chauffeur, exceto carro próprio ativo do jogador.

### 3.5 Imóveis

- [ ] Comprar cobertura, villa e suíte nos pontos físicos; confirmar ownership, saldo e extrato.
- [ ] Entrar/sair do próprio imóvel e confirmar instância privada e retorno à cidade.
- [ ] Tentar entrar sem ownership ou convite; confirmar recusa.
- [ ] Convidar jogador, aceitar/recusar, expirar em 60 s e limitar a quatro visitantes.
- [ ] Confirmar que convite é cancelado quando o proprietário sai e que visitantes retornam à cidade.
- [ ] Alternar estilos Clássico, Oceano e Jardim e conjuntos de decoração; confirmar persistência.
- [ ] Confirmar que visitante não altera decoração e que imóveis de jogadores diferentes ficam isolados.

### 3.6 Avatares, moda e poses

- [ ] Confirmar que todo item equipável corresponde ao catálogo e que itens legados sem visual permanecem visíveis, mas não equipáveis.
- [ ] Confirmar que um item substitui outro no mesmo slot.
- [ ] Confirmar aparência após respawn e reconexão.
- [ ] Testar poses Elegante, Brinde e Editorial em R6 e R15; alternar, encerrar, trocar personagem e usar junto do modo foto sem articulações presas.

### 3.7 Eventos, desfile, DJ e fotografia

- [ ] Confirmar agenda no relógio do jogo, abertura, tempo até o próximo evento, participantes e pontos.
- [ ] Participar de evento no local por 60 s; confirmar pontos uma vez por evento/dia e recusa fora do horário ou à distância.
- [ ] Enviar, aceitar, recusar e deixar expirar convite de evento; confirmar que aceitar apenas marca o local e não concede presença.
- [ ] No desfile, inscrever-se uma vez, votar em outro participante presente uma vez e confirmar recusa de voto próprio, repetido, distante ou fora do evento.
- [ ] Confirmar vencedor/empate e que o resultado é por servidor/dia, sem prêmio monetário.
- [ ] Completar a rota de DJ e acessar a cabine; testar os três estilos, alteração, encerramento, tempo limite e limpeza ao se afastar.
- [ ] Se houver áudio autorizado configurado, confirmar reprodução/loop e encerramento junto do show.
- [ ] Ativar/encerrar modo foto, capturar até 20 imagens, conferir álbum da sessão e salvar uma imagem na galeria do Roblox.
- [ ] Confirmar tratamento de cancelamento/falha de captura e que nenhuma imagem é enviada ao perfil.

### 3.8 Profissões

- [ ] Iniciar e concluir cada uma das dez profissões; confirmar pagamento somente após rota e atividades válidas.
- [ ] Confirmar recusa por distância, tempo insuficiente, deslocamento implausível, destino errado ou abandono.
- [ ] Confirmar progressão de patente, aumento de 5% até 20% e persistência após reconexão.
- [ ] Chauffeur: confirmar exigência de veículo próprio ativo e contagem de distância ao volante.
- [ ] Proprietário de estabelecimento: escolher prioridade operacional e avaliar atendimento; confirmar recusa fora de ordem/distância e ausência de pagamento antecipado.
- [ ] Criador de mundos: escolher tema/composição, apresentar maquete, confirmar recusa fora de ordem/distância e ausência de pagamento antecipado.

### 3.9 Mercado e editor

- [ ] Anunciar item próprio não equipado; confirmar rejeição de item alheio, equipado, preço inválido, acima do limite e cotas excedidas.
- [ ] Comprar/presentear somente perto do vendedor; confirmar ausência de duplicação de item/créditos.
- [ ] Confirmar cancelamento, expiração em 15 minutos e remoção do anúncio quando o vendedor sai.
- [ ] Em uma venda, confirmar comprador paga o preço anunciado, vendedor recebe preço menos `floor(preço × 5 / 100)`, comissão sai da circulação e aparece separada no extrato.
- [ ] Confirmar arredondamento para baixo e nenhuma comissão em presentes/doações.
- [ ] Doações: validar mesma sessão, proximidade, saldo, mínimo/máximo e limite do destinatário; confirmar registros nas duas partes e nenhuma alteração parcial em falha.
- [ ] Enviar conceito de cenário pela profissão Criador de mundos; confirmar fila persistente, bloqueio de duplicidade e rejeição de texto/modelo não catalogado.
- [ ] Aprovar/rejeitar como criador/admin; confirmar que somente aprovados aparecem e geram maquetes físicas na Galeria (máximo seis no mapa).
- [ ] Confirmar que jogador sem permissão não consulta pendências nem revisa propostas.

### 3.10 Segurança e moderação

- [ ] Enviar payloads malformados, tipos errados e valores adulterados em todos os remotes; confirmar recusa sem erro no Output.
- [ ] Repetir solicitações para confirmar rate limits por endpoint e por ação, sem cooldowns compartilhados indevidamente.
- [ ] Confirmar validação server-side de saldo, propriedade, proximidade, presença, permissão e limite de itens.
- [ ] Confirmar que jogador que sai não deixa estado de rate limit.
- [ ] Testar denúncia e bloqueio pelos menus oficiais do Roblox.
- [ ] Confirmar logs de expulsão aprovada/recusada no Output, painel restrito aos 20 mais recentes e buffer de 50 por servidor.
- [ ] Confirmar que spam limitado não inunda os logs e que logs não persistem após reiniciar o servidor.

### 3.11 Monetização (somente após configurar IDs)

- [ ] Confirmar que IDs `0` desativam os botões e nenhuma compra é iniciada.
- [ ] Com IDs de teste, confirmar Society VIP cosmético após compra/reconexão e que o Game Pass não altera o saldo.
- [ ] Confirmar que cada Developer Product concede exatamente o pacote.
- [ ] Confirmar que recibo repetido não duplica créditos.
- [ ] Confirmar `NotProcessedYet` quando perfil/DataStore estiver indisponível.
- [ ] Confirmar registro da compra no extrato e persistência do recibo.

### 3.12 Multiplayer, desempenho e dispositivos

- [ ] Testar com pelo menos 2 jogadores em servidor local e em experiência publicada.
- [ ] Confirmar compras, convites, mercado, eventos, propriedades e veículos entre jogadores diferentes.
- [ ] Confirmar que um jogador não vê nem altera dados privados de outro.
- [ ] Medir desempenho com a cidade, veículos e vários jogadores; procurar quedas de FPS, peças soltas e uso excessivo de memória.
- [ ] Testar em PC, celular e tablet; confirmar que a interface é utilizável em telas pequenas.
- [ ] Revisar o Output durante 10–15 minutos de jogo contínuo; nenhum erro recorrente deve permanecer.

### 3.13 Teste final antes de publicar

- [ ] Repetir o roteiro completo em uma cópia publicada, com APIs habilitadas.
- [ ] Confirmar que não há dados de teste, créditos infinitos, IDs `0` ativos ou logs de erro no Output.
- [ ] Confirmar que a página comercial, classificação etária e privacidade estão corretas.
- [ ] Confirmar que a versão publicada é a mesma validada e que existe backup para rollback.

---

## 4. Passos para publicar no Roblox

> Não publique a experiência principal antes de concluir os testes da seção 3. Use uma experiência de teste separada.

### Etapa A — Preparação local

1. Faça uma cópia de segurança de `club da alta sociedade.rbxl`.
2. Abra a cópia no Roblox Studio.
3. Instale o plugin oficial do Rojo, se ainda não estiver instalado.
4. No terminal, dentro desta pasta, execute:

   ```bash
   rojo serve default.project.json
   ```

5. No Studio, conecte o plugin ao servidor local e sincronize.
6. Confirme a árvore `HSC` no Explorer e abra o Output.

### Etapa B — Experiência de teste

1. No Studio, use **File > Publish to Roblox As…** e publique a cópia como uma experiência de teste privada.
2. Abra **Game Settings > Security** e habilite **Enable Studio Access to API Services**.
3. Confirme que o lugar publicado usa o mesmo universo que você está testando.
4. Execute os testes das seções 3.1 a 3.12 em **Test > Start** com pelo menos dois jogadores.
5. Corrija qualquer falha e repita os testes afetados antes de avançar.

### Etapa C — Configuração da experiência

1. Defina nome, descrição, gênero e número máximo de jogadores.
2. Revise as configurações de avatar e permissões.
3. Configure o proprietário/grupo correto.
4. Responda ao questionário de classificação etária.
5. Revise privacidade, uso de dados e políticas de conteúdo.

### Etapa D — Monetização

1. Crie o Game Pass **Society VIP**.
2. Crie os três Developer Products de créditos.
3. Defina os preços em Robux.
4. Insira os IDs em `src/shared/Config.lua`, seção `Monetization`.
5. Sincronize, publique novamente e repita os testes da seção 3.11.
6. Confirme que compras reais só são habilitadas quando os IDs estiverem corretos.

### Etapa E — Página comercial

1. Crie um ícone de 512×512 px.
2. Crie thumbnails em 16:9 (por exemplo, 1920×1080).
3. Escreva uma descrição clara, sem prometer dinheiro real e sem conteúdo proibido.
4. Adicione tags e links permitidos pelas políticas do Roblox.
5. Revise a página em desktop e celular.

### Etapa F — Publicação

1. Faça uma última execução do checklist da seção 3.13.
2. Use **File > Publish to Roblox** para publicar a versão validada.
3. Defina a experiência como pública somente quando todos os testes estiverem concluídos.
4. Monitore o Output, os erros e o feedback nas primeiras horas.
5. Mantenha a versão anterior e o arquivo `.rbxl` de backup para rollback.

### Etapa G — Pós-publicação

1. Acompanhe métricas de retenção, erros e reclamações.
2. Não altere preços ou produtos sem testar novamente.
3. Registre correções em `docs/DECISIONS.md` e atualize `docs/TESTING.md`.
4. Nunca publique dados de teste, créditos concedidos manualmente ou IDs de produtos inválidos.

---

## 5. Verificação estática realizada nesta sessão

- **Rojo 7.7.1:** `rojo build default.project.json` concluído com sucesso, gerando uma árvore `.rbxlx` de aproximadamente 395 KB. Isso valida o mapeamento do projeto e a leitura dos arquivos, não o gameplay.
- **StyLua 2.6.0:** todos os 29 arquivos `.lua` foram analisados sem erro de sintaxe. Existem diferenças de formatação em `GameClient.client.lua` e `WorkService.lua`, que não impedem a execução.
- **Remotes:** os 69 nomes usados pelo cliente existem no servidor; o servidor também expõe `RequestSpawnVehicle` como compatibilidade legada.
- **Documentação:** `PROGRESS.md`, `DECISIONS.md`, `TESTING.md`, `IDEAS.md`, `OWNER_TASKS.md`, `MONETIZATION.md` e este relatório estão atualizados.
- **Não realizado:** execução no Studio, DataStore real, física de veículos, multiplayer, compras Roblox e validação visual.

---

## 6. Limitações conhecidas e itens fora do escopo

- A cidade, os interiores, os veículos e os acessórios são geométricos e procedurais; não são assets finais.
- Não há upload de modelos, roupas ou animações de terceiros.
- O mercado e o concurso de moda funcionam por sessão/servidor; não há sincronização global entre servidores.
- Logs de moderação são voláteis e limitados a 50 registros por servidor.
- Não há banimento permanente; a administração usa expulsão da sessão e as ferramentas oficiais do Roblox.
- Veículos e imóveis não são negociáveis entre jogadores nesta versão.
- Não há chat privado paralelo ao chat oficial do Roblox.
- Não há promessa de dinheiro real, apostas, conteúdo sexual, namoro ou família.
- A monetização permanece desativada até o proprietário criar e configurar os produtos.
- A interface é construída em runtime; `src/gui` está reservado, mas não contém telas estáticas.
- O mapa procedural não substitui construções existentes do Workspace.
- Nenhum teste de gameplay foi executado; portanto, não há garantia de que todos os fluxos funcionam no Studio.

---

## 7. Status final por fase

| Fase | Status | Observação |
|---|---|---|
| 1 — Fundação | `[x]` | Estrutura, docs, Config/Logger, ciclo dia/noite e spawn documentados. |
| 2 — Economia | `[x]` | DataService, EconomyService, histórico, admin e rate limit. |
| 3 — Cidade | `[x]` | Regiões, mapa procedural e lojas validadas no servidor. |
| 4 — Veículos | `[x]` | Catálogo, compra, garagem, spawn, controle, test drive e pintura. |
| 5 — Propriedades | `[x]` | Compra, ownership, acesso, convites e decoração. |
| 6 — Avatares e moda | `[x]` | Inventário, catálogo, aparência e poses. |
| 7 — Entretenimento | `[x]` | DJ, eventos, desfile e fotografia. |
| 8 — Profissões | `[x]` | Dez profissões com progressão e pagamento validados. |
| 9 — Social/segurança | `[x]` | Denúncia/bloqueio oficiais, logs e revisão estática dos remotes. |
| 10 — Mercado/editor | `[x]` | Mercado, comissão, fila de aprovação e maquetes. |
| 11.1 — Monetização | `[x]` | Código integrado; IDs e preços dependem do proprietário. |
| 11.2 — Testes | `[!]` | Exclusivo do proprietário no Studio. |
| 11.3 — Publicação | `[!]` | Página, classificação e publicação dependem do proprietário. |

**Conclusão:** o escopo de scripts está concluído. O projeto está pronto para a etapa de testes no Studio, não para publicação. O próximo passo é executar a seção 3 em uma cópia publicada e registrar os resultados em `docs/TESTING.md`.
