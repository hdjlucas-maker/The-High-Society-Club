# Guia: código no Linux (VSCode), jogo no Windows (Roblox Studio) e publicação

Pasta do projeto no Linux:
`/media/devlucas/BA66714E66710BFF/Documents/Estudos/The High Society Club`

## 1. O que foi corrigido nesta versão

| Problema visto nas fotos | Causa | Correção |
|---|---|---|
| Avatar em queda livre, "loop" | O lugar não tem `Baseplate`; o mapa tinha ruas e prédios, mas nenhum chão | `WorldBuilder.EnsureGround` cria grama, mar e leito do mar logo no início |
| "Society Credits: aguardando servidor" | O cliente desistia de esperar o saldo depois de 10 s | O cliente espera sem limite; o DataStore falha rápido no Studio e usa perfil temporário |
| Loja vazia | Um erro em qualquer módulo parava o servidor inteiro | `safeInit` no Bootstrap: o erro vai para o Output e o resto continua |
| Erro escondido | `VehicleService` usava `Players` sem declarar | Declarado |
| Mundo sem vida | Só prédios e ruas | Novo módulo `WorldLife` (seção 4) |
| Dia/noite fixo em 24 min | Ciclo acelerado | Segue o relógio real (`Config.DayNight`) |

## 2. Copiar os arquivos para o Linux

1. Extraia o zip recebido.
2. Copie por cima da pasta do projeto (mantém seus arquivos, troca só os alterados):
   ```bash
   cd "/media/devlucas/BA66714E66710BFF/Documents/Estudos"
   cp -r "The High Society Club" "The High Society Club.backup"   # backup antes
   unzip -o ~/Downloads/The_High_Society_Club_corrigido.zip -d "/media/devlucas/BA66714E66710BFF/Documents/Estudos"
   ```
3. Arquivos novos ou alterados: `src/server/Bootstrap.server.lua`, `src/server/Modules/WorldBuilder.lua`,
   `src/server/Modules/WorldLife.lua` (novo), `src/server/Modules/DayNightService.lua`,
   `src/server/Modules/DataService.lua`, `src/server/Modules/VehicleService.lua`,
   `src/client/GameClient.client.lua`, `src/shared/Config.lua`.

## 3. Ligar o VSCode (Linux) ao Studio (Windows) com Rojo

Os dois computadores precisam estar na mesma rede Wi-Fi.

No **Linux**:
```bash
cd "/media/devlucas/BA66714E66710BFF/Documents/Estudos/The High Society Club"
rojo serve default.project.json --address 0.0.0.0
hostname -I                      # anote o primeiro número, ex.: 192.168.0.15
sudo ufw allow 34872/tcp         # só se o firewall (ufw) estiver ativo
```

No **Windows**:
1. Abra o Studio com o seu lugar (o arquivo `.rbxl`/`.rbxlx` do mapa).
2. Instale o plugin **Rojo** (o oficial) e use a mesma versão do `rojo` do Linux (`rojo --version`).
3. Plugins → Rojo → coloque o endereço `192.168.0.15` (o seu) e a porta `34872` → **Connect**.
4. Cada vez que você salvar um arquivo no VSCode, o Studio atualiza sozinho.

Faça uma cópia do lugar antes da primeira conexão. O Rojo atualiza `ServerScriptService.HSC`,
`ReplicatedStorage.HSC` e `StarterPlayerScripts.HSC`, e não mexe no resto do Workspace.

## 4. O que o mundo ganhou (módulo `WorldLife`)

- Chão de grama, mar ao redor da Paradise Island e da Marina.
- Céu com estrelas, nuvens, brilho e raios de sol.
- Dia e noite pelo relógio real (Brasília, `UTCOffsetHours = -3` em `Config.lua`).
  Às 18h as luzes da rua e as janelas dos prédios acendem; às 6h apagam.
- Alameda de árvores, palmeiras na praia, canteiros de flores, bancos no parque.
- Chafariz do Garden Park com água e um chafariz novo na praça do clube.
- Dois outdoors de luxo na avenida.
- 12 visitantes (NPCs) que passeiam pela cidade (`Config.World.NpcCount`; use 0 para desligar).

## 5. Testar no Studio

1. Salve o lugar. Se o Output mostrar erro de DataStore, publique o lugar (seção 7) e ative
   Game Settings → Security → **Enable Studio Access to API Services**.
2. Botão **Play** (F5). Esperado:
   - o avatar nasce em pé, com chão em volta;
   - a barra de cima mostra "Society Credits: 250" (bônus de boas-vindas);
   - a Loja lista itens quando você chega perto de uma loja;
   - os NPCs aparecem aos poucos (a cada ~1,5 s).
3. Para ver a noite sem esperar: no Command Bar (View → Command Bar) rode, durante o Play,
   `game.Lighting.ClockTime = 20` e olhe as luzes. O relógio volta ao horário real em até 5 s.
   Para testar por mais tempo, ponha `UseRealTime = false` em `Config.DayNight`.
4. Abra View → **Output**. Linhas `[HSC][ERROR]...` são erros de módulo; me mande o texto.

## 6. Assets gratuitos do Roblox (Creator Store)

Os modelos, imagens e sons gratuitos só podem ser inseridos pelo Studio no Windows.

- **Modelos (mansões, carros, mobília, plantas):** View → Toolbox → Modelos → procure
  "luxury mansion", "sports car", "palm tree". Antes de usar, abra o modelo no Explorer e
  **apague todo `Script` que você não reconhece**. Modelos gratuitos podem trazer código malicioso.
  Coloque os modelos numa pasta `Workspace.MeusAssets`; os scripts do jogo não mexem nela.
- **Imagens de luxo (outdoors):** crie a imagem, envie em create.roblox.com → Assets → Images,
  copie o número do ID e coloque em `Config.World.BillboardImageIds = { 123456789, 987654321 }`.
- **Música do clube:** escolha um áudio liberado pela Roblox, copie o ID e coloque em
  `Config.Club.MusicSoundId = "rbxassetid://ID"`. Teste se toca dentro do seu jogo.
- **Avatares:** cada jogador entra com o próprio avatar. Os NPCs são criados por código com cores
  diferentes; para vesti-los com roupas do catálogo, use IDs de roupas no `HumanoidDescription`
  de `WorldLife.lua`.
- Use só material seu, da Roblox ou com licença. O jogo não pode usar marcas, carros, roupas ou
  músicas protegidos.

## 7. Publicar no Roblox (hospedagem gratuita)

Publicar e hospedar o jogo nos servidores da Roblox não tem custo.

1. Studio: File → **Publish to Roblox** → crie a experiência (nome, descrição, gênero "Roleplay/Social").
2. Home → Game Settings:
   - **Basic Info:** nome, descrição, ícone e miniaturas (as miniaturas pesam muito na entrada de jogadores).
   - **Permissions:** Public (só depois de testar com amigos).
   - **Maturity:** preencha o questionário de classificação etária.
   - **Security:** ative Studio Access to API Services e Allow HTTP Requests só se precisar.
   - **Avatar:** permita o avatar do jogador (Player Choice).
   - **Servers:** máximo de jogadores por servidor (comece com 20–30).
3. Monetização (opcional): create.roblox.com → sua experiência → Monetization. Crie o Game Pass
   "Society VIP" e os 3 Developer Products, copie os IDs para `Config.Monetization`
   (veja `docs/MONETIZATION.md`). Com ID `0` a compra fica desligada.
4. Teste multiplayer: Test → Local Server com 2 a 4 jogadores; depois publique e chame amigos.
5. Quando estiver estável, ponha em Public.

## 8. Fazer os jogadores quererem ficar

O que já existe no código: recompensa diária, eventos agendados, desfile de moda, clube com DJ,
profissões, imóveis, carros e conquistas. Ajudam a reter jogadores:

- Ícone e miniaturas bonitos (é o que decide o clique no jogo).
- Evento fixo toda noite em horário de pico (por exemplo, 20h de Brasília).
- Atualizações pequenas e frequentes, com um item novo por semana.
- Convidar amigos: o Roblox mostra jogos onde os amigos estão.
- Ideias que não implementei, por estarem fora do escopo, estão em `docs/IDEAS.md`.
