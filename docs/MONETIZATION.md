# Monetização

## Produtos implementados

- **Society VIP (Game Pass):** passe permanente e cosmético. Jogadores que o possuem recebem a identificação VIP na lista social; não há bônus de créditos nem vantagem econômica.
- **Developer Product — 1.000 Society Credits**
- **Developer Product — 5.000 Society Credits**
- **Developer Product — 20.000 Society Credits**

Os três pacotes são compras consumíveis. O servidor só concede os créditos depois de confirmar o recibo Roblox e registra a compra no extrato. O processamento salva o identificador do recibo junto do perfil antes de confirmar a compra, impedindo crédito duplicado quando o Roblox reenvia o mesmo recibo.

## Configuração pelo proprietário

1. Crie/publique a experiência Roblox e crie um Game Pass chamado **Society VIP** no painel da experiência.
2. Crie três Developer Products com os nomes/pacotes listados acima. Defina os preços em Robux no painel Roblox; os valores em Robux não são fixados pelo código.
3. Copie os IDs numéricos criados e substitua os valores `0` em `Config.Monetization` (`src/shared/Config.lua`): `VIPGamePassId` para o Game Pass e `Id` do produto correspondente para cada pacote.
4. Não reutilize o mesmo ID em dois produtos e mantenha os produtos antigos cadastrados após começar a vender; recibos pendentes de IDs removidos não poderão ser reconhecidos.
5. Publique primeiro uma cópia de teste, habilite acesso às APIs do Studio para o DataStore e faça compras de teste na experiência publicada antes de configurar a experiência principal.

Com os IDs ainda em `0`, os botões ficam desativados e nenhuma compra é iniciada. IDs e preços Robux são dependências externas; não foram criados nem testados neste pacote.
