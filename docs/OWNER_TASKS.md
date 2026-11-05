# Tarefas que dependem do proprietário

Esta lista não impede a continuação de tarefas de código independentes. Os itens de teste e publicação só devem ser executados depois que os scripts planejados forem concluídos.

## Lugar e objetos físicos

O projeto atual gera a cidade e os veículos básicos por script. Não é obrigatório criar prédios 3D manualmente para permitir que os serviços atuais inicializem.

- [!] Depois da conclusão dos scripts, abrir uma cópia de `club da alta sociedade.rbxl` no Studio e conferir o `Workspace`; a auditoria do arquivo binário não foi possível neste ambiente.
- [!] Para a cidade começar no nível esperado, manter `Workspace.Baseplate` como `BasePart` ancorada. Alternativamente, incluir em `Workspace` um objeto da classe `SpawnLocation` no nível do chão. Se nenhum existir, `WorldBuilder` registra `[HSC][WARN][WorldBuilder]` e gera a cidade com chão em Y=0.
- [!] O sistema de spawn padrão do Roblox deve usar uma `SpawnLocation` dentro do `Workspace`. O script de mapa procura qualquer instância dessa classe para ajustar a altura; chamar a peça `SpawnLocation` facilita a conferência.
- [!] Se substituir construções geradas por modelos 3D próprios, preservar os pontos de interação criados por `WorldBuilder` ou atualizar os caminhos abaixo e o código que os consulta.
- [!] Modelos 3D finais (mansões, carros, roupas/avatares, paisagismo) precisam ser criados ou importados pelo proprietário; não há assets finais no pacote-fonte auditado.

## Dependências de publicação — não executar ainda

- [!] Criar/publicar o jogo de teste em uma experiência Roblox própria antes de testar DataStore real.
- [!] Antes de testar propostas da Galeria no Studio, publicar a cópia e habilitar acesso às APIs do Studio; a fila usa o DataStore `CreationModeration_v1`, separado dos perfis de economia.
- [!] As maquetes aprovadas são geradas junto à área do ponto `WorkPoints.WorldCreatorFinish`; preservar esse ponto ao substituir a cidade procedural ou ajustar as posições de exibição em `CreationBuilder.lua`.
- [!] Opcional para o DJ: fornecer um áudio próprio/autorizado já enviado à Roblox e preencher `Config.Club.MusicSoundId` com `rbxassetid://<ID>`; sem isso, a cabine funciona com show de luzes e sem áudio.
- [!] Criar o Game Pass Society VIP e os três Developer Products; definir preços Robux e inserir os IDs em `Config.Monetization` conforme [docs/MONETIZATION.md](./MONETIZATION.md). Com os IDs em `0`, as compras ficam desativadas.
- [!] Enviar ao Roblox os assets 3D/roupas/animações autorizados que forem escolhidos para a versão final e fornecer os respectivos IDs.
- [!] Definir proprietário/grupo e permissões da experiência para que o controle administrativo e publicação usem o dono correto.
- [!] Publicar a página comercial e revisar classificação etária, privacidade e políticas da experiência antes do lançamento.

## Nomes e caminhos usados pelos scripts atuais

O mapa atual é gerado automaticamente em `Workspace.HighSocietyWorld`. A estrutura básica e os pontos de interação são criados por `WorldBuilder`; o proprietário não precisa construir manualmente cada Part para os scripts iniciarem.

- `Workspace.HighSocietyWorld.HighSocietyBoulevard.AutomotiveGallery.Foundation` — base da galeria usada para posicionar expositores.
- `Workspace.HighSocietyWorld.ParadiseIslandAndRoyalMarina.MarinaWater` — superfície de água usada pela lancha e pelo expositor.
- `Workspace.HighSocietyWorld.EventPoints` — Folder com `club_festival`, `garden_photo_walk`, `fashion_show` e `marina_exhibition`, cada ponto com `EventPrompt`.
- O concurso de moda usa o ponto `fashion_show`; inscrição, voto e resultado são mantidos por servidor/dia e não exigem objetos adicionais no Workspace.
- `Workspace.HighSocietyWorld.WorkPoints` — Folder com pontos de início/fim das profissões, cada ponto com `WorkPrompt`.
- `Workspace.HighSocietyWorld` cria pontos de veículo: `DealershipPurchasePoint` (`PurchasePrompt`), `GaragePoint` (`GaragePrompt`), `VehicleSpawnPoint` (`SpawnVehiclePrompt`), `BoatPurchasePoint` (`BoatPurchasePrompt`), `BoatStorePoint` (`BoatStorePrompt`) e `BoatSpawnPoint`.
- `Workspace.HighSocietyWorld.MillionaireDistrict` contém modelos de imóveis com atributo `PropertyId` e ponto `PropertyPurchasePoint` e/ou `SpawnPoint`. `PropertyService` também aceita a pasta opcional `Workspace.Properties` com modelos de propriedade equivalentes.
- `Workspace.HighSocietyWorld` recebe `EventDecorations` e as regiões `HighSocietyBoulevard`, `MillionaireDistrict` e `ParadiseIslandAndRoyalMarina`.
- `RegionService` identifica por posição as áreas `High Society Boulevard`, `Garden Park`, `Grand Society Club`, `Millionaire District` e `Paradise Island & Royal Marina`; não requer peças invisíveis nem configuração manual no Workspace.
- Pontos de compra de loja devem ser `BasePart` com `ShopPrompt` e os atributos `ShopId`/`ShopName`; cada `StoreId` precisa estar cadastrado em `ShopService` e associado aos itens daquele catálogo.
- `ServerStorage.VehicleModels` é criada pelo `VehicleBuilder`; inclui `SocietySedanPlayable`, `RoyalSportPlayable`, `GrandTourerPlayable`, `SocietyRoadster` e `SocietySpeedboat`. Os modelos dirigíveis possuem `PrimaryPart` e `DriverSeat`.
- `ReplicatedStorage.HSC.VehicleCatalog` é a fonte dos IDs, preços, categorias e nomes dos modelos de veículos; os nomes listados acima devem permanecer alinhados com essa definição.
- `ReplicatedStorage.HSC.PropertyCatalog` mantém os IDs, nomes, preços, tipos e modelos gerados de imóveis usados por `PropertyService` e `WorldBuilder`.
- `ReplicatedStorage.HSC.FashionCatalog` é compartilhado por loja e aparência; assets de roupas/animações finais podem substituir os visuais procedurais quando o proprietário fornecer IDs autorizados.
- `ReplicatedStorage.HSC` contém módulos compartilhados e `ReplicatedStorage.HSC.Remotes`, criados/mapeados pelo projeto Rojo.
- `StarterPlayer.StarterPlayerScripts.HSC.GameClient` é o cliente principal; os controles legados reconhecidos pelo cliente devem ficar como irmãos de `HSC` em `StarterPlayerScripts` para serem desativados.
- `StarterGui.HSC` é reservado para conteúdo de GUI fornecido pelo projeto; a interface atual é construída pelo cliente em runtime.

Antes do primeiro teste futuro no Studio, o proprietário deve confirmar o SpawnLocation e baseplate no Explorer, além de manter cópia de segurança do lugar original.
