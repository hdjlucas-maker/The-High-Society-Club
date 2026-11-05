# Decisões técnicas

## 02/11/2026 — Preservar os arquivos-fonte durante a migração de pastas

- **Decisão:** ajustar o mapeamento do Rojo para expor a estrutura `HSC` sem mover os módulos existentes de seus caminhos em `src/`.
- **Motivo:** o prompt proíbe reestruturar arquivos sem necessidade; mapear pastas pode cumprir o destino Roblox mantendo imports relativos e minimizando risco.

## 02/11/2026 — Manter o mapa procedural existente como fallback

- **Decisão:** continuar usando `WorldBuilder` e `VehicleBuilder` para criar versões geométricas básicas, sem substituir ou apagar construções do lugar.
- **Motivo:** é a implementação existente e o projeto não inclui assets 3D finais. O proprietário poderá substituí-los por Models com os nomes documentados, sem bloquear o trabalho de scripts.

## 02/11/2026 — Separação DataService/EconomyService requer compatibilidade

- **Decisão:** extrair o acesso de DataStore e lock de sessão para `DataService`, mantendo `EconomyService` como proprietário do perfil em memória, sanitização, leaderstats e transações.
- **Motivo:** a persistência existente guarda inventário, veículos, imóveis, eventos e profissões. A extração conserva nome de DataStore, chaves e campos persistidos para não migrar nem invalidar os dados já salvos.

## 02/11/2026 — Teste no Studio após conclusão dos scripts

- **Decisão:** não solicitar que o proprietário teste fluxos de gameplay enquanto ainda houver tarefas de implementação pendentes.
- **Motivo:** ordem explicitamente definida pelo proprietário no Master Prompt v2.

## 02/11/2026 — Auditoria de moderação limitada à sessão do servidor

- **Decisão:** registrar no Output do servidor e em um buffer volátil de até 50 itens as tentativas e os resultados das expulsões e ações administrativas inválidas; o painel autorizado consulta os 20 registros mais recentes.
- **Motivo:** fornecer auditoria acessível durante a sessão sem criar retenção permanente de dados de moderação nem depender de DataStore/serviço externo. Ações bloqueadas pelo rate limit não são registradas, para evitar inundação dos logs.

## 02/11/2026 — Cooldown por endpoint nas consultas remotas

- **Decisão:** aplicar cooldown server-side de 0,5 s, com chave própria para cada consulta de leitura; manter os intervalos específicos já configurados para lista de eventos, concurso e logs administrativos.
- **Motivo:** reduzir trabalho redundante de consultas remotas sem fazer painéis independentes compartilharem limites. Ações que alteram estado mantêm validação e cooldown próprios.

## 02/11/2026 — Histórico centralizado na EconomyService

- **Decisão:** toda alteração aprovada de créditos registra uma transação na `EconomyService`, que acrescenta horário, UserId, nome do jogador e resultado; gastos recebem metadados server-side para identificar compras de itens, imóveis e veículos.
- **Motivo:** evitar registros duplicados ou incompletos entre os serviços de compra e manter o histórico compatível com os campos já persistidos. Falhas de validação/ saldo insuficiente não geram uma transação bem-sucedida nem alteram o perfil.
- **Concorrência:** um lock curto por jogador protege cada alteração e registro; as operações não fazem yield enquanto o lock está ativo.

## 02/11/2026 — Rate limits reutilizáveis por jogador e operação

- **Decisão:** centralizar os intervalos de solicitações em `RateLimitService`, com uma chave distinta por ação e tempos em `Config.RateLimits`; limpar o estado do jogador ao sair.
- **Motivo:** remover tabelas e verificações duplicadas sem fazer ações independentes compartilharem cooldown. Cooldowns funcionais de profissões e o timeout de controle do veículo permanecem nos serviços que os possuem.

## 02/11/2026 — Detecção server-side de regiões da cidade

- **Decisão:** `RegionService` determina a região pela posição X/Z do personagem em intervalos de 0,5 segundo e só notifica o cliente quando há mudança; o cliente mostra uma faixa temporária com o nome da região.
- **Motivo:** manter a identificação da região autoritativa no servidor, sem adicionar peças invisíveis ou colisões ao mapa, e preservar as regiões do mapa procedural existente.

## 02/11/2026 — Catálogo de loja vinculado ao estabelecimento

- **Decisão:** cada item de loja recebe um `StoreId`; o catálogo é filtrado/clonado por loja, e a compra exige que o item pertença à loja informada e que o jogador esteja no ponto de interação correspondente.
- **Motivo:** impedir que o cliente escolha preços ou compre itens de outra loja, mantendo o código extensível para estabelecimentos futuros sem alterar o formato salvo do inventário.

## 02/11/2026 — Catálogo de veículos como fonte única

- **Decisão:** colocar IDs, categorias, preços, nomes de modelos, desempenho e dados visuais do catálogo em `ReplicatedStorage.HSC.VehicleCatalog`; `VehicleService` e `VehicleBuilder` consomem essa lista.
- **Motivo:** evitar divergência entre opções compráveis, modelos gerados e veículos expostos, preservando IDs, preços e nomes atuais para compatibilidade dos perfis salvos.
- **Exposição ao cliente:** `VehicleService.GetCatalog` retorna apenas campos necessários para interface, sem enviar nomes de modelos internos nem velocidades de controle.

## 02/11/2026 — Test drive temporário sem propriedade

- **Decisão:** permitir um test drive por jogador a partir do ponto de compra correspondente; o veículo usa o spawn/controle existentes, não grava propriedade, não habilita profissão que exige veículo próprio e é recolhido após a duração definida em `Config.Vehicles.TestDriveDuration`.
- **Motivo:** oferecer avaliação sem criar um segundo fluxo de veículo ou alterar o perfil persistido. O jogador deve guardar ou aguardar o fim do teste antes de comprar.

## 02/11/2026 — Catálogo de imóveis como fonte única

- **Decisão:** IDs, nomes, tipos, preços, níveis de acesso e posicionamento dos imóveis ficam em `ReplicatedStorage.HSC.PropertyCatalog`; `PropertyService` e `WorldBuilder` usam a mesma lista.
- **Motivo:** manter imóveis compráveis alinhados aos modelos gerados sem mudar os campos já persistidos nos perfis. A resposta de compra também atualiza a tela de imóveis e o extrato.

## 02/11/2026 — Ownership e decoração de imóveis permanecem no perfil

- **Decisão:** não criar um DataStore separado para propriedades; IDs, ownership e opções interiores continuam no perfil persistente existente. A autorização de entrada, convites, decoração e saída continua no servidor.
- **Motivo:** preservar os dados atuais e impedir que visitantes alterem a decoração ou entrem por um fluxo sem ownership/convite validado.

## 02/11/2026 — Catálogo de moda compartilhado com aparência

- **Decisão:** catálogo de moda compartilhado é a origem única para IDs, preços, categorias, slots e cores; serviço de loja e serviço de aparência derivam seus dados dele.
- **Motivo:** evitar itens que podem ser comprados mas não podem ser equipados, sem depender de asset IDs externos nem mudar as entradas salvas no inventário.

## 02/11/2026 — Poses sem assets de animação externos

- **Decisão:** oferecer poses procedurais locais para fotos, combinadas sobre as articulações do avatar, e remover o estado ao encerrar ou trocar de personagem.
- **Motivo:** implementar uma experiência utilizável sem inventar IDs de animação nem exigir que o proprietário envie assets.

## 02/11/2026 — Concurso de moda por sessão

- **Decisão:** a inscrição e a votação do desfile exigem proximidade do ponto validada pelo `EventService` durante o horário do evento; cada jogador pode se inscrever uma vez e votar em um concorrente uma vez por dia UTC, sem poder votar em si mesmo.
- **Motivo:** entregar o fluxo de concurso sem permitir que o cliente declare presença ou escolha resultados. O placar é mantido em memória por servidor e dia; não há prêmio monetário nem sincronização global entre servidores.

## 02/11/2026 — Cabine do DJ sem áudio de terceiros embutido

- **Decisão:** a apresentação do clube oferece três estilos de iluminação server-side e pode reproduzir uma faixa em loop se `Config.Club.MusicSoundId` receber um asset Roblox no formato `rbxassetid://<ID>`.
- **Motivo:** não incluir músicas nem IDs sem autorização. Sem asset configurado, a cabine continua funcional e informa que a apresentação é apenas visual; a operação exige completar a rota de DJ e estar junto ao palco.

## 02/11/2026 — Convites de evento não concedem presença

- **Decisão:** aceitar um convite de evento ativa somente o marcador do local; o convidado ainda precisa chegar ao ponto e iniciar participação, com agenda, proximidade e presença validadas pelo servidor.
- **Motivo:** convites facilitam encontrar amigos, mas não devem ignorar os requisitos do evento nem conceder pontos sem presença.

## 02/11/2026 — Álbum de fotos local ao dispositivo

- **Decisão:** capturar imagens pelo `CaptureService` do Roblox, manter somente as 20 capturas recentes na memória da sessão e oferecer salvamento individual na galeria do dispositivo.
- **Motivo:** não enviar screenshots privados ao servidor nem armazenar referências locais no perfil persistente; a galeria do Roblox mantém as cópias que o usuário decidir salvar.

## 02/11/2026 — Mercado inicial restrito a moda e créditos

- **Decisão:** permitir anúncios e presentes dos itens únicos do catálogo de moda, além de doações de Society Credits, somente entre jogadores da mesma sessão. Trocas exigem proximidade, perfil carregado e item não equipado; anúncios expiram em 15 minutos e são removidos quando o vendedor sai. Veículos e imóveis não entram no mercado inicial.
- **Motivo:** os perfis atuais não têm transferência persistente/atômica para ownership de veículos ou imóveis. O mercado limita exposição a duplicação, registra transferências de créditos para as duas partes e mantém o alcance controlado.

## 02/11/2026 — Comissão e regras comerciais do mercado

- **Decisão:** cobrar comissão de 5% apenas em vendas de itens, calculada por `floor(preço × 5 / 100)` e descontada dos créditos do vendedor; o comprador paga o preço anunciado. A comissão é retirada da circulação e registrada separadamente no extrato do vendedor. Presentes (preço zero) e doações não têm comissão.
- **Motivo:** definir claramente o valor líquido da venda, preservar o preço exibido ao comprador e deixar os créditos dos presentes/doações sem tarifa. O mercado continua restrito à mesma sessão, itens de moda catalogados, limites server-side e sem negociação de créditos por dinheiro real.

## 02/11/2026 — Monetização cosmética e compras de créditos

- **Decisão:** o Game Pass Society VIP concede somente identificação cosmética; Developer Products concedem pacotes de 1.000, 5.000 ou 20.000 Society Credits. O servidor só confirma produtos consumíveis depois de gravar atomicamente o recibo e o crédito no perfil. IDs ficam desativados até o proprietário criar e configurar os produtos Roblox.
- **Motivo:** oferecer um benefício social sem vantagem econômica permanente e garantir concessão idempotente dos pacotes, inclusive em reenvios do recibo pelo Roblox. Preços Robux e configuração da experiência dependem do proprietário.

## 02/11/2026 — Aprovação de conceitos de cenário com catálogo fechado

- **Decisão:** a profissão Criador de mundos permite escolher tema e composição predefinidos, que são salvos em fila persistente. O criador/admin aprova ou rejeita pelo painel; apenas aprovadas são listadas e construídas como maquetes de peças fixas na área da Galeria (até seis maquetes no mapa). A fila tem limite, evita propostas pendentes duplicadas por usuário e não aceita texto livre nem modelos enviados por jogadores.
- **Motivo:** permitir edição limitada, curadoria e publicação sem expor o servidor a conteúdo arbitrário ou não filtrado. A Galeria instancia somente layouts construídos por código a partir do catálogo do jogo.

## 2026-11-03 — Correções após o primeiro teste no Studio
- **Chão:** o lugar não tinha `Baseplate`. `WorldBuilder.EnsureGround` cria `Workspace.HSC_Ground` (grama, mar e leito do mar) só se não houver `Baseplate` nem `HSC_Ground`.
- **Bootstrap:** cada `Init` roda dentro de `pcall` (`safeInit`); um erro vira `[HSC][ERROR][Bootstrap]` e o servidor continua.
- **Cliente:** o saldo não desiste mais após 10 s; espera o `leaderstats` indefinidamente.
- **DataService:** no Studio, erros de "publicar o lugar"/"acesso às APIs" interrompem as tentativas e usam perfil temporário.
- **DayNightService:** novo `Config.DayNight.UseRealTime` (padrão `true`, fuso `-3`).
- **WorldLife (novo):** céu, luzes noturnas, decoração, chafarizes, outdoors e visitantes (NPCs) por código; sem assets externos.
- **Não testado no Studio.**
