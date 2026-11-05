# Progresso do projeto

Status: `[ ]` pendente; `[~]` em andamento; `[x]` concluído no código/documentação segundo o critério da tarefa; `[!]` depende de ação do proprietário ou bloqueio externo.

**Regra:** não marcar código como testado no Studio. O dono fará o teste de jogo somente após a conclusão dos scripts.

## FASE 1 — FUNDAÇÃO

- [x] 1.1 Ler o projeto e registrar auditoria inicial em `docs/AUDIT.md` (somente inspeção nesta tarefa).
- [x] 1.2 Ajustar/validar `default.project.json` e a estrutura `src/server`, `src/client`, `src/shared`, `src/gui` para os destinos `HSC` definidos no prompt v2, preservando arquivos e comportamento existente.
- [x] 1.3 Criar os documentos obrigatórios de acompanhamento.
- [x] 1.4 Criar módulo compartilhado de configuração global e módulo de logs `[HSC]`.
- [x] 1.5 Revisar e integrar ciclo dia/noite existente à arquitetura final.
- [x] 1.6 Documentar requisito de SpawnLocation e dependências do Workspace em `docs/OWNER_TASKS.md`.

## FASE 2 — ECONOMIA

- [x] 2.1 Extrair DataStore para `DataService`; mantém o nome do DataStore, chaves `Player_<UserId>`, campos persistidos, lock de sessão, retry, autosave e `BindToClose`.
- [x] 2.2 Revisar `EconomyService`, validação de valores, saldo/leaderstats e registro central de ganhos e gastos; os perfis persistidos mantêm seus campos existentes.
- [x] 2.3 Completar histórico com data, jogador, referência do item/serviço, valor e resultado; compras agora registram débito e referência na mesma chamada central.
- [x] 2.4 Integrar autorização administrativa com `Config.AdminUserIds` e a opção de acesso do criador; ações continuam validadas no servidor.
- [x] 2.5 Criar `RateLimitService` reutilizável e migrar os limites de solicitações do Bootstrap, profissões, eventos e administração, mantendo intervalos configuráveis e limpeza por jogador.

## FASE 3 — CIDADE (SCRIPTS + ESPECIFICAÇÃO)

- [x] 3.1 Documentar regiões e objetos/nomes que os scripts esperam em `docs/OWNER_TASKS.md`.
- [x] 3.2 Implementar detecção server-side de zonas e exibição temporária do nome da região ao jogador ao entrar.
- [x] 3.3 Consolidar catálogo por loja, associar itens à loja, clonar dados públicos e validar no servidor a loja, o item e a proximidade antes do débito.

## FASE 4 — VEÍCULOS

- [x] 4.1 Consolidar catálogo de carros, motocicleta e lancha em `src/shared/VehicleCatalog.lua`; serviço e gerador usam a mesma definição de IDs, preços, modelos e dados de apresentação.
- [x] 4.2 Validar compra no ponto da concessionária/marina, saldo, veículo desconhecido e duplicidade; compras bem-sucedidas registram histórico.
- [x] 4.3 Validar propriedade antes de spawn, bloquear espaço ocupado e permitir guardar no ponto correto da garagem/marina.
- [x] 4.4 Manter controle server-authoritative: validar motorista no assento, limitar comandos, zerar controle inativo e manter network ownership no servidor.
- [x] 4.5 Implementar test drive temporário de carros, moto e lancha, com duração configurável, remoção automática e sem conceder propriedade; pintura permanece restrita a veículos próprios e ao ponto da garagem.

## FASE 5 — PROPRIEDADES

- [x] 5.1 Consolidar catálogo de propriedades em `src/shared/PropertyCatalog.lua`, usado pelo serviço e gerador de imóveis; preservar IDs, preços e nomes salvos e atualizar a interface após compra.
- [x] 5.2 Integrar compra/ownership ao perfil persistido e atualizar a interface após a resposta de compra.
- [x] 5.3 Validar propriedade, entrada/saída, convites, permanência do proprietário e limite de visitantes no servidor.
- [x] 5.4 Salvar estilos e conjuntos de decoração no perfil e restringir alterações ao proprietário dentro do interior.

## FASE 6 — AVATARES E MODA

- [x] 6.1 Consolidar inventário/equipagem em perfil persistente; manter itens antigos sem visual como itens visíveis, mas não equipáveis.
- [x] 6.2 Centralizar catálogo de roupas/acessórios com slot/visual, validar compra na loja correspondente e restaurar itens equipados após carregar o avatar.
- [x] 6.3 Implementar três poses procedurais locais (Elegante, Brinde e Editorial) para R6/R15, sem dependência de IDs de assets; limpar ao encerrar ou trocar o personagem.

## FASE 7 — ENTRETENIMENTO

- [x] 7.1 DJ: rota profissional server-side, cabine integrada ao palco, três estilos de show de luzes, controle validado e reprodução opcional configurável para áudio autorizado. `Config.Club.MusicSoundId` fica vazio até o proprietário configurar uma faixa.
- [x] 7.2 Eventos com agenda sincronizada ao relógio do jogo, presença e pontos validados pelo servidor; convites de sessão expiram, limpam ao sair e não concedem participação automaticamente.
- [x] 7.3 Implementar desfile de moda com inscrição única por dia, voto único por eleitor, bloqueio de voto próprio, resultado com empate e validação server-side durante o evento.
- [x] 7.4 Modo foto com captura oficial do Roblox, álbum local limitado às 20 capturas recentes e ação para salvar cada imagem na galeria do dispositivo; não envia imagens ao servidor nem ao perfil.

## FASE 8 — PROFISSÕES

- [x] 8.1 Revisado framework server-side: validação de ponto/rota/tempo/deslocamento, requisito de veículo próprio para chauffeur, pagamento registrado pela EconomyService, progressão por profissão persistida e recompensas calculadas no servidor. A rota DJ ainda dá acesso temporário à cabine somente perto do destino.
- [x] 8.2 Todas as dez profissões têm início, destino, duração, distância e pagamento validados no servidor. Proprietário de estabelecimento agora escolhe prioridades operacionais e avalia o atendimento; criador de mundos escolhe tema e composição de maquete. As opções são interações presenciais em sequência, os resultados são registrados durante o trabalho e exibidos na conclusão; não há pagamento antes de concluir as etapas e a rota.

## FASE 9 — SOCIAL, SEGURANÇA E MODERAÇÃO

- [x] 9.1 Integrar denúncia e bloqueio com `StarterGui:SetCore` e as ações oficiais `PromptReportPlayer`/`PromptBlockPlayer`; erros de inicialização são tentados novamente e exibidos ao jogador.
- [x] 9.2 Logs server-side de tentativas/resultados da expulsão e ações inválidas: linhas estruturadas no Output, buffer limitado aos 50 registros mais recentes por servidor e consulta dos 20 últimos pelo painel autorizado. Registros não persistem entre servidores; tentativas bloqueadas pelo rate limit não geram log para evitar inundar o Output.
- [x] 9.3 Revisão estática dos 42 manipuladores originais (19 RemoteFunctions e 23 RemoteEvents) do Bootstrap: operações de escrita mantêm rate limit, proximidade, propriedade e validação no serviço/servidor; consultas de leitura agora têm cooldown independente por endpoint de 0,5 s (eventos, concurso e logs mantêm seus limites existentes). `VehicleService.StartTestDrive` também preserva e devolve a razão real caso o spawn seja recusado. Os três remotes adicionados pelo mercado na Fase 10.1 foram revisados separadamente. Sem testes de gameplay; repetir a revisão no Roblox Studio depois que toda a programação terminar.

## FASE 10 — MERCADO E EDITOR

- [x] 10.1 Mercado de itens de moda e doações de Society Credits na mesma sessão: anúncios server-side expiram em 15 minutos, limite de cinco por jogador/100 por servidor e preço limitado a 100.000; compra, presente e doação exigem proximidade de até 20 studs. O servidor valida posse, item equipado, saldo, limite do destinatário e duplicidade, transfere itens/créditos e registra as duas partes no extrato. `RequestMarketData` e `MarketAction` têm cooldowns próprios; `MarketActionResult` comunica as respostas. Transações mostram a referência do item e o UserId da outra parte. Anúncios são removidos quando o vendedor sai; veículos e imóveis não são negociáveis. Implementado, sem teste de gameplay.
- [x] 10.2 Aprovação/moderação e editor limitado de cenários: a profissão Criador de mundos envia combinações de tema/layout do catálogo fixo para fila persistente; apenas criador/admin pode aprovar/rejeitar. Conceitos pendentes não aparecem; aprovados geram maquetes físicas no espaço da Galeria (até seis exibidas no mapa), e a Galeria lista até 20 propostas aprovadas. Sem upload de modelos nem texto livre; sem teste de gameplay.
  - [x] Implementar fila persistente, validação por catálogo e painel de revisão.
  - [x] Implementar editor limitado via escolhas presenciais da profissão e construção server-side de maquetes aprovadas usando peças do catálogo.
  - [x] Atualizar a Galeria e reconstruir maquetes aprovadas quando um conceito é aprovado ou a lista pública é consultada.
- [x] 10.3 Comissão de 5% sobre vendas de itens, arredondada para baixo em créditos inteiros e descontada do vendedor; o comprador paga o preço anunciado. Presentes e doações não têm comissão. A comissão é removida da circulação, aparece separadamente no extrato do vendedor e as regras ficam informadas na interface/documentação. Sem teste de gameplay.

## FASE 11 — MONETIZAÇÃO E PUBLICAÇÃO

- [x] 11.1 Integrar Game Pass Society VIP cosmético e três Developer Products (1.000/5.000/20.000 créditos), com recibos persistentes/idempotentes, confirmação server-side e extrato. IDs ficam em `0` e aguardam cadastro pelo proprietário; preços Robux e compras reais não foram configurados/testados.
- [!] 11.2 Checklist de testes multiplayer, segurança e otimização — execução no Studio é exclusiva do proprietário e fica para depois de os scripts estarem completos.
- [!] 11.3 Checklist de publicação/página comercial preparado em `docs/OWNER_TASKS.md`; criar e configurar a página dependem do proprietário.

## RELATÓRIO FINAL

- [x] Gerar `docs/FINAL_REPORT.md` com o que foi implementado, dependências do proprietário, checklist completo de testes no Studio e passos de publicação.
- [x] Validação estática: `rojo build default.project.json` concluído com Rojo 7.7.1; StyLua 2.6.0 analisou os 29 arquivos sem erro de sintaxe (restam diferenças de formatação em dois arquivos, sem impacto de execução).

## Próxima tarefa

Nenhuma tarefa de código pendente. Restam as ações `[!]` do proprietário: criar/configurar os IDs de monetização, executar os testes em uma cópia publicada e concluir a publicação. Não sincronizar o jogo principal antes da validação.

## Atualização 2026-11-03
- [x] Correção do chão, do Bootstrap, do saldo no cliente e do `VehicleService`.
- [x] `WorldLife` e dia/noite pelo relógio real, implementados.
- [!] Testar no Studio e enviar o Output ao desenvolvedor. Guia em `docs/GUIA_LINUX_WINDOWS.md`.
