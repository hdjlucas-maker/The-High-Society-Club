# Plano de testes no Roblox Studio

> O checklist de aceite final e os passos de publicação estão em [FINAL_REPORT.md](./FINAL_REPORT.md). Este documento continua sendo o roteiro detalhado de testes.

Os testes de gameplay abaixo são **futuros**. O proprietário pediu para executar essa etapa somente depois que os scripts previstos estiverem concluídos. Não considerar nenhum cenário desta lista como já executado.

## Pré-requisitos para a etapa futura

1. Fazer uma cópia de segurança do lugar `club da alta sociedade.rbxl`.
2. Sincronizar a cópia com a configuração Rojo final.
3. Publicar a cópia como jogo de teste e habilitar acesso às APIs do Studio apenas nesse jogo, se for validar DataStore.
4. Abrir o Output e confirmar que inicialização e remotes não apresentam erros.

## Onda 1 — teste rápido do mundo (fazer primeiro)

Este é o roteiro curto para validar a Onda 1 antes de continuar o polimento.
Detalhes e rollback estão em [ONDA1_CHANGELOG.md](./ONDA1_CHANGELOG.md).

1. Abrir **uma cópia** do lugar com o Workspace salvo e iniciar o sync do Rojo.
2. Conferir no Output da inicialização:
   - `[HSC][INFO][WorldBuilder] Reparo do mundo existente: N degrau(s) e N placa(s).`
   - `[HSC][INFO][WorldAudit] Auditoria v1: ...`
   - Nenhum `[HSC][ERROR]` de Bootstrap.
3. **Spawn:** clicar em Play e confirmar que o avatar nasce em pé, sobre a praça,
   sem cair no vazio, sem loop de queda e sem começar dentro de uma peça.
4. **Escadas:** subir a escadaria da Fashion Avenue, do hotel, da galeria e de
   uma residência do Millionaire District. O degrau mais baixo deve ser o mais
   distante da porta; não deve haver degrau invertido.
5. **Marcadores:** passar por cima dos pontos dourados/rosados de loja, de
   trabalho e de veículo; eles não devem bloquear o caminho.
6. **Estou preso:** encostar em uma parede/quina e tentar andar por 3 s para
   ver o resgate automático. Depois, usar o botão `ESTOU PRESO` → `CONFIRMAR`
   e confirmar o teleporte ao spawn. Repetir antes de 15 s deve mostrar a espera.
7. **Placas:** visitar `GARDEN PARK`, `PARADISE ISLAND` e `ROYAL MARINA`.
   As três devem ter dois postes e bases apoiados no chão.
8. **Ajuda:** abrir o menu e conferir o card “Ficou preso?” com o botão de
   voltar ao spawn.
9. Copiar o Output completo e enviar prints das placas/escadas com a Position
   do objeto e a Position do jogador.

Observação: avisos de altura e de vegetação duplicada são esperados nesta fase;
eles viram tarefa das Ondas 2 e 3.

## Cenários pendentes

- [ ] Inicialização de Bootstrap, módulos, UI, remotes e mapa.
- [ ] Zonas: entrar e sair de High Society Boulevard, Garden Park, Grand Society Club, Millionaire District e Paradise Island & Royal Marina; confirmar que o nome aparece uma vez ao entrar, atualiza ao trocar de região e some ao sair ou morrer.
- [ ] SpawnLocation/baseplate e chegada segura do jogador.
- [ ] Ciclo de iluminação: transição manhã/tarde/entardecer/noite e horário sincronizado com a agenda dos eventos.
- [ ] Leaderstats, ganhos e gastos; confirmar que cada operação bem-sucedida aparece uma única vez no histórico com data, jogador, referência, valor e resultado, e que falhas de validação/saldo não alteram saldo nem geram registro de sucesso.
- [ ] Compras de loja, imóvel e veículo: validar débito e referência correspondente no histórico, sem registros duplicados.
- [ ] Lojas: confirmar catálogo filtrado por estabelecimento, compra apenas no ponto correto, rejeição de item/loja incompatível, rejeição de compra à distância e ausência de cobrança em qualquer falha.
- [ ] DataService: falha transitória, retry, bloqueio simultâneo de sessão, renovação do lock, autosave, saída e `BindToClose`.
- [ ] Recompensa diária e limite de uma reivindicação por dia UTC.
- [ ] Veículos: compra, ownership, spawn livre, controle, parada, armazenamento, pintura e limite por jogador.
- [ ] Catálogo de veículos: conferir IDs, preços, categorias e modelos dos três carros, Society Roadster e Society Speedboat; confirmar que a lista da loja e os modelos gerados correspondem ao catálogo compartilhado.
- [ ] Test drive: iniciar cada tipo no ponto correspondente, dirigir, confirmar bloqueio de segundo veículo/compra durante o teste, recolhimento automático no tempo configurado e ausência de propriedade após reconectar.
- [ ] Rate limits: confirmar que solicitações repetidas de loja, imóvel, eventos, veículos, profissões e administração são limitadas no intervalo configurado, que ações independentes não compartilham cooldown e que jogadores que saem não deixam estado de limite.
- [ ] Imóveis: compra, entrada/saída, decoração, isolamento entre jogadores e convites.
- [ ] Catálogo de imóveis: verificar IDs, nomes, tipos, preços e modelos gerados para cobertura, villa e suíte; concluir uma compra e confirmar atualização de ownership, saldo e extrato na interface.
- [ ] Imóveis: reconectar e confirmar ownership/estilos salvos; tentar entrar sem ownership/convite, decorar como visitante, usar convite expirado e exceder quatro visitantes; confirmar saída e limpeza do interior privado.
- [ ] Loja/inventário: compra, equipar/desequipar e persistência.
- [ ] Moda: confirmar que todos os itens equipáveis correspondem ao catálogo, que um item substitui outro no mesmo slot e que aparência retorna após respawn/reconexão sem afetar itens legados.
- [ ] Mercado: anunciar item próprio não equipado; verificar rejeição de item alheio, item equipado, preço fracionário/negativo/acima do limite e anúncios além das cotas; comprar/presentear somente perto do vendedor, sem duplicar item/créditos; verificar cancelamento, expiração em 15 minutos e remoção ao vendedor sair.
- [ ] Comissão do mercado: em uma venda, confirmar que o comprador perde exatamente o preço anunciado, o vendedor recebe preço menos `floor(preço × 5 / 100)`, a comissão sai da circulação e aparece separada no extrato; confirmar arredondamento para baixo e nenhuma comissão em presentes/doações, inclusive falhas de transferência sem cobrança parcial.
- [ ] Doações no mercado: validar jogador da mesma sessão, proximidade, saldo, quantia mínima/máxima e limite de saldo do destinatário; verificar que falhas não alteram perfis e que remetente/destinatário recebem registros correspondentes no extrato.
- [ ] Monetização (cópia publicada): confirmar que IDs `0` desativam compras; com IDs de teste, confirmar identificação VIP após compra/reconexão, que o Game Pass não altera o saldo, que cada Developer Product concede exatamente o pacote, recibos repetidos não duplicam créditos, `NotProcessedYet` é retornado se o perfil/DataStore estiver indisponível e que a compra aparece no extrato.
- [ ] Editor/moderação de criações: completar uma rota de Criador de mundos e confirmar envio de tema/layout permitido para a fila persistente; bloquear texto/modelo não catalogado, submissão pendente duplicada, consulta de pendências sem permissão e revisão repetida; aprovar/rejeitar como criador/admin, conferir que somente aprovadas geram maquetes físicas de catálogo na Galeria (máximo seis no mapa) e verificar falha/indisponibilidade de DataStore sem conceder falso sucesso.
- [ ] Poses: testar Elegante, Brinde e Editorial nos rigs R6 e R15, alternar/encerrar, trocar personagem e usar junto do modo foto sem deixar articulações presas.
- [ ] Fotografia/álbum: ativar e encerrar o modo foto, capturar até 20 imagens, verificar a lista da sessão, salvar uma imagem na galeria Roblox com permissão e conferir o tratamento de cancelamento/falha. As capturas não são salvas no perfil do jogo.
- [ ] Profissões: progressão, validação de rota, cancelamento e pagamento apenas após conclusão válida.
- [ ] Proprietário de estabelecimento: iniciar no hotel, escolher uma prioridade operacional, aprovar padrão ou recomendar treinamento no clube; confirmar que opção fora de ordem/distância é rejeitada e não há pagamento antes da auditoria, da rota e da entrega.
- [ ] Criador de mundos: escolher um tema e uma composição entre as opções presenciais, apresentar a maquete na galeria; confirmar que opções fora de ordem/distância são rejeitadas, a escolha aparece na conclusão e não há pagamento antecipado.
- [ ] DJ/clube: iniciar a rota na Royal Marina, completar o percurso e acessar a cabine; testar os três estilos de iluminação, alteração e encerramento, tempo limite, limpeza ao afastar-se e rejeição de comando sem concluir a rota. Se um áudio autorizado for configurado, confirmar reprodução/loop e encerramento junto do show.
- [ ] Eventos: confirmar agenda no relógio do jogo, presença/pontos uma vez por evento e por dia; aceitar e recusar convites, conferir expiração após 60 s e saída do remetente/destinatário. Aceitar só define o marcador: entrar no evento deve continuar exigindo aproximação e início pelo prompt.
- [ ] Desfile: ficar junto ao ponto da Fashion Avenue durante o horário, inscrever-se uma vez, votar em outro participante presente uma vez e confirmar rejeição de voto próprio, repetido, de eleitor/concorrente distante ou enviado fora do evento; conferir vencedor/empate após o fechamento. O resultado atual é mantido por dia e por servidor, sem prêmio monetário.
- [ ] Segurança: spam/remotes inválidos, valores adulterados, proximidade, propriedade e permissões.
- [ ] Moderação: confirmar logs de expulsão aprovada e recusada no Output; painel mostra somente os 20 registros mais recentes para criador/admin autorizado; jogador não autorizado não consulta o histórico; buffer mantém no máximo 50 eventos por servidor, elimina os mais antigos e não persiste após reiniciar o servidor. Confirmar que spam limitado não inunda os logs.
- [ ] Remotes: para todos os pedidos de leitura, confirmar cooldown isolado por endpoint (0,5 s nos catálogos/estado geral; limites próprios de eventos, concurso e logs); para pedidos de alteração, confirmar limites configurados e validações server-side de tipos, propriedade, saldo, presença e proximidade. Repetir solicitações e enviar payloads malformados sem conceder alterações nem deixar erros no Output.
- [ ] Multijogador, desempenho e diferentes dispositivos.

## Resultado esperado

Nenhuma transação ou permissão é concedida somente por informação do cliente; os dados persistem no jogo de teste; todos os fluxos são executáveis sem erros no Output; quaisquer falhas encontradas são registradas e corrigidas antes da publicação.
