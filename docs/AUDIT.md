# Auditoria inicial do projeto

**Data:** 02/11/2026
**Escopo:** arquivos presentes no projeto Rojo e documentação existente. O arquivo binário do lugar Roblox não foi aberto nesta auditoria; portanto, não estou afirmando que inspecionei a árvore atual do Workspace ou o Output do Studio.

## Resumo

- Projeto existente em Luau com **15 arquivos `.lua`**: `Bootstrap.server.lua`, 13 módulos em `src/server/Modules` e `GameClient.client.lua`.
- `default.project.json` mapeia o Bootstrap e módulos diretamente em `ServerScriptService`, e o cliente diretamente em `StarterPlayerScripts`. Ainda **não** segue a hierarquia `HSC` e os diretórios `shared`/`gui` descritos no Master Prompt v2.
- Não existem diretórios `docs/`, `src/shared/` ou `src/gui/` antes desta auditoria.
- O `WorldBuilder` gera regiões e pontos de interação por código. Não é necessário afirmar que prédios foram modelados no arquivo `.rbxl`.
- O código contém implementação de economia/perfil, loja, aparência básica, imóveis, veículos, profissões, iluminação, conquistas, eventos, administração e interface.
- O README existente registra que os interiores/visuais são básicos e que não houve validação integrada em Roblox Studio.
- Não foi possível confirmar a configuração real do DataStore, os objetos atuais do Workspace, o Output, nem o comportamento multiplayer sem abrir o lugar no Studio. Esses itens ficam anotados para o proprietário na etapa posterior, não são alegados como testados.

## Arquivos-fonte encontrados

### Servidor

- `src/server/Bootstrap.server.lua` — inicialização dos serviços, criação dos remotes, integração dos pedidos do cliente, rate limits e ciclo de vida de jogadores.
- `src/server/Modules/AdminService.lua` — verifica criador/proprietário de grupo e permite kick da sessão atual.
- `src/server/Modules/AchievementService.lua` — catálogo e progresso de conquistas/reputação.
- `src/server/Modules/AppearanceService.lua` — aplica visuais geométricos básicos aos avatares.
- `src/server/Modules/DailyRewardService.lua` — resgate diário e sequência.
- `src/server/Modules/DayNightService.lua` — ciclo de iluminação.
- `src/server/Modules/EconomyService.lua` — Society Credits, leaderstats, perfil, DataStore, lock de sessão, transações e salvamentos.
- `src/server/Modules/EventService.lua` — eventos agendados, presença e convites.
- `src/server/Modules/PropertyService.lua` — catálogo, compra, interiores privados, decoração, acesso e convites.
- `src/server/Modules/ShopService.lua` — catálogo, compras e itens possuídos.
- `src/server/Modules/VehicleBuilder.lua` — construção programática de veículos e expositores.
- `src/server/Modules/VehicleService.lua` — catálogo, compras, spawn, controles, garagem e pintura.
- `src/server/Modules/WorkService.lua` — percursos profissionais, validação, pagamento e progressão.
- `src/server/Modules/WorldBuilder.lua` — regiões, pontos de trabalho/evento/veículos e construções básicas.

### Cliente

- `src/client/GameClient.client.lua` — interface, chamadas dos remotes, menus de jogo, modo selfie e entrada de controles do veículo.

### Configuração e documentação preexistentes

- `default.project.json` — projeto Rojo, mapeamento plano de servidor/cliente.
- `README.md` — instruções Rojo, resumo de sistemas e ressalvas.
- `CHECKLIST-PROJETO.md` — checklist anterior criado durante a conversa; deve ser alinhado com `docs/PROGRESS.md`.
- `club da alta sociedade.rbxl` — arquivo binário do lugar Roblox; não inspecionado nesta auditoria.

## Inventário de funcionalidades no código

| Sistema | Evidência no código | Situação de auditoria |
|---|---|---|
| Inicialização e remotes | `Bootstrap.server.lua` | Existe; arquitetura/nome de pastas não corresponde ao destino `HSC` do prompt v2. |
| Moeda, leaderstats e persistência | `EconomyService.lua` | Existe um serviço combinado. Usa `GetDataStore`, `UpdateAsync`, retry limitado, autosave e `BindToClose`; revisar os invariantes e integração antes de marcar fase completa. |
| Histórico de transações | `EconomyService.lua` | Existe limite de histórico e log no Output; formato/registro final devem ser revisados contra os campos obrigatórios do prompt. |
| Loja/inventário/mercado | `ShopService.lua`, `AppearanceService.lua`, `PlayerMarketService.lua`, `EconomyService.lua`, cliente | Compra/equipamento e mercado de itens de moda/presentes/doações existem no código. Vendas descontam 5% do vendedor (arredondado para baixo); comprador paga o preço anunciado, presentes/doações não pagam comissão e o desconto aparece no extrato. Mercado não transfere veículos/imóveis nem trata dinheiro real; ainda não foi testado no Studio. |
| Cidade | `WorldBuilder.lua` | Construções procedurais básicas existem; a árvore física do `.rbxl` e o acabamento visual não foram inspecionados. |
| Dia/noite | `DayNightService.lua` | Implementação existe; requer seguir integração/configuração final. |
| Veículos | `VehicleService.lua`, `VehicleBuilder.lua`, cliente | Três carros, moto, lancha, garagem e pinturas aparecem no código; test drive e iate não aparecem como recursos implementados. Física não foi executada. |
| Imóveis | `PropertyService.lua`, `WorldBuilder.lua` | Compra, interiores, estilos e visitas existem; transferência/negociação não está implementada no catálogo/serviço identificado. |
| Profissões e editor/curadoria | `WorkService.lua`, `CreationService.lua`, `CreationBuilder.lua`, cliente | Dez percursos e progressão existem. Criador de mundos envia tema/layout fechados para aprovação persistente; somente criador/admin revisa e propostas aprovadas são montadas como maquetes físicas do catálogo na Galeria. Não há upload de modelos nem editor livre. Fluxo ainda não testado no Studio. |
| Eventos | `EventService.lua`, cliente | Agenda, participação, pontos e convite existem; concurso/votação e calendário sazonal não identificados. |
| Segurança social/administração | `AdminService.lua`, cliente, `Bootstrap.server.lua` | Há rate limits e kick do criador; denúncia/bloqueio usam recursos Roblox. Não foi encontrado log dedicado de moderação ou sistema próprio de denúncia. |
| Monetização | `MonetizationService.lua`, `EconomyService.lua`, `DataService.lua`, cliente | Game Pass Society VIP cosmético e três Developer Products de créditos foram integrados. Recibos são salvos e idempotentes; compra permanece desativada enquanto os IDs estiverem em `0`. IDs, preços Roblox e teste de compra dependem do proprietário. |
| Testes automatizados | inventário de `src/` e arquivos do projeto | Nenhum arquivo de teste foi encontrado. |

## Diferenças da arquitetura exigida no Master Prompt v2

- Na auditoria inicial, o projeto mapeava servidor diretamente em `ServerScriptService`, cliente diretamente em `StarterPlayerScripts` e não tinha `src/shared`/`src/gui`.
- Na tarefa 1.2, `default.project.json` foi ajustado para `ServerScriptService.HSC`, `StarterPlayerScripts.HSC`, `ReplicatedStorage.HSC` e `StarterGui.HSC`; Bootstrap e cliente agora procuram os remotes em `ReplicatedStorage.HSC.Remotes`.
- `src/gui` está mapeado, mas a interface continua construída pelo `GameClient` em runtime; não há arquivos estáticos de GUI nessa pasta.
- `EconomyService` atualmente combina perfil/DataStore/economia; o prompt enumera `DataService` separado. A extração ainda é pendente e deve preservar os dados/API existentes.
- `Config.lua` e `Logger.lua` foram criados em `src/shared`; configuração já é consumida por economia, Bootstrap, administração e WorldBuilder. Logs de serviços integrados usam o prefixo `[HSC]`.

## Limites desta auditoria

- O binário `club da alta sociedade.rbxl` não foi aberto; não confirmar construções, ancoragem, SpawnLocation, shopping ou duplicatas atuais.
- Não houve execução Roblox Studio, multiplayer, DataStore real ou inspeção do Output.
- A existência do arquivo de mapa não comprova que o projeto Rojo o contém ou que uma build do Rojo o preserva.
- “Existe no código” não significa “funciona em jogo”; a validação de gameplay fica para depois da conclusão dos scripts, conforme a ordem definida pelo proprietário.

## Atualização de implementação — tarefas 1.2 a 2.1

- `default.project.json` agora publica `ServerScriptService.HSC`, `StarterPlayer.StarterPlayerScripts.HSC`, `ReplicatedStorage.HSC` e `StarterGui.HSC`.
- `Config.lua` e `Logger.lua` estão em `src/shared`; os logs integrados usam `[HSC]`.
- `WorldBuilder` registra aviso com fallback Y=0 se não encontrar `Workspace.Baseplate` nem uma `SpawnLocation`.
- `DataService.lua` separa DataStore da economia sem alterar o nome `EconomyData_v1`, as chaves `Player_<UserId>`, o formato de campos de perfil ou o lock de sessão existentes.
- O inventário atual após essa extração é de **16 arquivos Luau**: Bootstrap, 14 módulos de servidor e GameClient.
- Stylua e build Rojo passaram após as alterações de arquitetura e a extração; nenhuma execução de gameplay no Studio foi feita.
