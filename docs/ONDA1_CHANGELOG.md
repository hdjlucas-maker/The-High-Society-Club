# Onda 1 — destravar o mundo (changelog e teste)

Data: 2026-11-04
Status: implementado no código; **teste no Studio pendente**.
Base: `docs/WORLD_QUALITY_PLAN.md` (Onda 0 + Onda 1) e `docs/AUDIT_2026-11-04.md`.

## Objetivo da onda

Corrigir os problemas que impedem o jogador de andar pelo mundo antes de mexer
em layout, ruas e decoração:

- nascer em pé, sobre a praça, sem cair nem ficar preso no spawn;
- subir as escadas dos prédios e das residências sem degrau invertido;
- ter uma saída de emergência clara quando o personagem ficar preso;
- deixar as placas de distrito apoiadas no chão;
- alinhar o passeio de entrada das lojas ao nível da calçada;
- medir o mundo com uma auditoria automática para as próximas ondas.

Nada foi apagado do Workspace. O mundo salvo no Studio continua sendo a base.

## Onde cada script fica (Rojo)

| Arquivo no projeto | Destino no Roblox | Tipo |
| --- | --- | --- |
| `src/shared/Config.lua` | `ReplicatedStorage.HSC.Config` | ModuleScript |
| `src/server/Modules/WorldBuilder.lua` | `ServerScriptService.HSC.Modules.WorldBuilder` | ModuleScript |
| `src/server/Modules/LuxuryKit.lua` | `ServerScriptService.HSC.Modules.LuxuryKit` | ModuleScript |
| `src/server/Modules/WorldLife.lua` | `ServerScriptService.HSC.Modules.WorldLife` | ModuleScript |
| `src/server/Modules/PlayerSafetyService.lua` | `ServerScriptService.HSC.Modules.PlayerSafetyService` | ModuleScript (novo) |
| `src/server/Modules/WorldAudit.lua` | `ServerScriptService.HSC.Modules.WorldAudit` | ModuleScript (novo) |
| `src/server/Bootstrap.server.lua` | `ServerScriptService.HSC.Bootstrap` | Script |
| `src/client/GameClient.client.lua` | `StarterPlayer.StarterPlayerScripts.HSC.GameClient` | LocalScript |

O `default.project.json` já mapeia essas pastas; não foi necessário alterar o
mapeamento.

## O que mudou

### 1. Spawn seguro

- `WorldBuilder.ensureSpawn` passou a ser chamado tanto na criação quanto na
  complementação de um mundo existente.
- O spawn gerado (`HSC_Spawn`) fica dentro da `CentralPlaza`, com o topo 0,05
  acima do piso da praça.
- Se o mundo salvo já tem um `SpawnLocation` dentro da área da praça, o topo
  dele é alinhado ao mesmo piso em tempo de execução (sem apagar o objeto).
- O spawn recebe o atributo `HSC_SafeSpawn = true`.

### 2. Escadas corrigidas

- `makeBuilding` e `makeResidence`: o degrau mais distante agora é o mais baixo
  e o mais próximo da fundação é o mais alto (0,30 por degrau).
- `repairWorld` corrige as escadas do mundo já salvo, sem reconstruir o prédio.
  Ele ordena os degraus pelo Z e calcula a altura pelo topo da fundação.
- A correção é idempotente: rodar de novo não move o que já está certo.

### 3. Placas de distrito apoiadas

- `Garden Park`, `Paradise Island` e `Royal Marina` agora usam
  `makeStandingSign`, com dois postes e duas bases de metal.
- As posições foram levadas para as entradas dos distritos.
- `repairWorld` move as placas antigas do mundo salvo e acrescenta os postes
  que faltam, sem recriar o letreiro.

### 4. Passeio de entrada alinhado

- `WorldLife.polishFrontAvenue`: `EntrancePath` passou a ter topo em
  `groundY + 0,29`, praticamente o mesmo nível da calçada e do primeiro degrau
  (`+0,30`). O 0,01 abaixo evita z-fighting onde o passeio encosta no degrau.
- `STREETSCAPE_VERSION` subiu de 3 para 4; a pasta `HSC_Streetscape` é
  reconstruída sozinha na próxima execução.

### 5. Porta e atendimento externo

- A porta de vidro dos prédios decorativos ficou mais opaca
  (`glassTransparency = 0,62`), deixando claro que não há interior.
- Placa `ATENDIMENTO EXTERNO` acima da entrada principal.
- Pontos de loja, de trabalho e de veículo agora são marcadores
  atravessáveis (`CanCollide = false`). Antes, alguns eram blocos sólidos no
  meio da escadaria ou da calçada e podiam prender o jogador.

### 6. Botão “Estou preso”

- Servidor: `PlayerSafetyService`.
  - `StuckRequest` / `StuckResult` (RemoteEvents).
  - Cooldown de 15 s (`Config.Safety.StuckCooldown`).
  - Resgate manual e detecção automática: jogador tentando andar, sem sair do
    lugar e com o corpo sobreposto a uma peça colidível por 3 s.
  - Teleporta para o `HSC_Spawn` (ou para o spawn padrão, se necessário).
- Cliente: botão `ESTOU PRESO` no topo, com confirmação em duas etapas, e card
  “Ficou preso?” na aba de ajuda.

### 7. Auditoria do mundo

- `WorldAudit` roda 2 s após o início, por padrão somente no Studio.
- Escreve no Output:
  - contagem de peças, modelos, áreas de caminhada, postes e vegetação;
  - postes/vegetação no meio de calçadas;
  - duplicatas de postes e vegetação;
  - placas sem apoio;
  - superfícies em altura diferente do padrão.
- Também grava atributos no folder do mundo:
  `HSC_AuditIssues`, `HSC_AuditPartCount`, `HSC_AuditLastRun`.

## O que ainda não foi feito (ondas seguintes)

- Alturas de `GardenWalk*`, `IslandPromenade`, `IslandBeach`, `ClubPlaza` e
  praça ainda são inconsistentes. A auditoria vai avisar; é esperado.
- Postes e palmeiras no meio de calçadas e árvores duplicadas continuam.
- `HSC_Life` ainda não é reconstruída quando já existe, então a vegetação
  duplicada só será limpa na Onda 3.
- Mapa/minimapa, rádio ambiente e layout v3 continuam para as Ondas 4–6.
- O mundo salvo no Studio não é regenerado pelo Rojo. O `repairWorld` corrige
  escadas e placas em runtime; o rebuild versionado da base é uma onda futura.

## Como testar no Studio

Use **uma cópia** do lugar. O build `output/hsc_onda1_test.rbxlx` contém os
scripts, mas não contém o Workspace salvo; para testar o mundo real, sincronize
o Rojo com a cópia que tem o mapa.

1. Abrir a cópia do lugar e iniciar o sync do Rojo.
2. Conferir o Output na inicialização. Procurar:
   - `[HSC][INFO][WorldBuilder] Reparo do mundo existente: ...`
   - `[HSC][INFO][WorldAudit] Auditoria v1: ...`
3. Clicar em **Play** e confirmar que o avatar nasce em pé, sobre a praça, sem
   cair nem entrar em loop de queda.
4. Ir até a Fashion Avenue e subir a escadaria da loja, do hotel e da galeria.
   Testar também uma residência no Millionaire District.
5. Encostar em uma parede/quina, tentar andar por 3 s e confirmar o resgate
   automático (ou usar `ESTOU PRESO` → `CONFIRMAR`).
6. Confirmar o cooldown: pedir de novo antes de 15 s deve mostrar a espera.
7. Visitar as três placas: Garden Park, Paradise Island e Royal Marina. Todas
   devem ter postes e bases apoiados no chão.
8. Abrir a aba de ajuda e conferir o card “Ficou preso?”.
9. Copiar o Output completo e tirar prints dos pontos com problema, com as
   coordenadas (Position) do objeto e do jogador.

### Avisos esperados no Output

A auditoria v1 ainda vai avisar sobre:

- alturas fora do padrão em `GardenWalk*`, `IslandPromenade`, `IslandBeach`,
  `ClubPlaza` e outras superfícies;
- postes/palmeiras em calçadas;
- árvores/palmeiras duplicadas entre `WorldBuilder` e `WorldLife`.

Esses avisos são o mapa de trabalho das Ondas 2 e 3; não são falhas novas da
Onda 1.

## Rollback

Os arquivos anteriores estão em `backups/onda1_2026-11-04/`. Para desfazer:

```bash
cp backups/onda1_2026-11-04/WorldBuilder.lua src/server/Modules/
cp backups/onda1_2026-11-04/LuxuryKit.lua src/server/Modules/
cp backups/onda1_2026-11-04/Bootstrap.server.lua src/server/
cp backups/onda1_2026-11-04/GameClient.client.lua src/client/
cp backups/onda1_2026-11-04/Config.lua src/shared/
rm -f src/server/Modules/PlayerSafetyService.lua src/server/Modules/WorldAudit.lua
```

Depois, rebuildar com `rojo build default.project.json -o output/hsc_onda1_test.rbxlx`.

## Validação feita

- `luau-parser`: 33/33 arquivos `.lua` sem erro de sintaxe.
- `rojo build default.project.json -o output/hsc_onda1_test.rbxlx`: concluído.
- Ainda **não** houve teste de gameplay no Studio.
