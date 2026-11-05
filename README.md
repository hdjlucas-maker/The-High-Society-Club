<div align="center">

# ✨ THE HIGH SOCIETY CLUB

### Seu mundo. Seu estilo. Sua conquista.

**Uma experiência social de luxo no Roblox, com cidade explorável, imóveis, veículos, moda, profissões, eventos e economia própria.**

[![Plataforma](https://img.shields.io/badge/PLATAFORMA-Roblox-111111?style=for-the-badge&logo=roblox&logoColor=white)](https://www.roblox.com/)
[![Linguagem](https://img.shields.io/badge/LINGUAGEM-Luau-00A2FF?style=for-the-badge)](https://luau.org/)
[![Pipeline](https://img.shields.io/badge/PIPELINE-Rojo-8A2BE2?style=for-the-badge)](https://rojo.space/)
[![Status](https://img.shields.io/badge/STATUS-Em%20desenvolvimento-orange?style=for-the-badge)](#-status-do-projeto)

</div>

---

## 🌆 Sobre o projeto

**The High Society Club (HSC)** é um jogo social para Roblox concebido em torno de uma cidade sofisticada, onde os jogadores podem construir sua identidade, explorar diferentes distritos, adquirir propriedades e veículos, participar da vida social e desenvolver atividades profissionais.

A proposta combina exploração urbana, personalização, experiências sociais e progressão econômica. O jogador não fica limitado a visitar um cenário: pode circular por diferentes regiões, frequentar estabelecimentos, participar de eventos, trabalhar, negociar itens e construir sua trajetória dentro da comunidade.

O projeto utiliza uma arquitetura modular em **Luau**, com lógica importante executada e validada no servidor. O código-fonte é organizado para desenvolvimento e sincronização com **Rojo**.

## 💎 O que o jogo reúne

| Área | Experiências e sistemas |
|---|---|
| 🏙️ **Cidade e exploração** | Distritos, regiões identificadas, estabelecimentos, áreas de lazer, clube, parque, ilha e marina. |
| 🏡 **Imóveis** | Catálogo de propriedades, compra, propriedade persistente, interiores privados, decoração e convites para visitantes. |
| 🚘 **Veículos** | Catálogo, compra, garagem, spawn controlado, armazenamento, personalização de pintura e test drive temporário. |
| 👗 **Moda e aparência** | Inventário, roupas e acessórios por categoria, equipagem, restauração da aparência e poses para avatares R6/R15. |
| 📸 **Fotografia** | Modo foto/selfie e álbum local de capturas, sem envio das imagens ao servidor do jogo. |
| 💼 **Profissões** | Dez carreiras com rotas, atividades, progressão por patentes e pagamento após conclusão validada. |
| 🎉 **Vida social** | Eventos, convites, presença, desfile de moda, votação e cabine de DJ com efeitos de iluminação. |
| 🛍️ **Economia e lojas** | Society Credits, recompensas diárias, lojas, inventário e histórico de transações. |
| 🤝 **Mercado entre jogadores** | Anúncios de itens de moda, presentes e doações de créditos dentro da mesma sessão, com validações e limites. |
| 🏗️ **Criação moderada** | Editor limitado a temas e composições de catálogo, com fila de revisão e aprovação autorizada. |
| 🛡️ **Segurança** | Validação no servidor, limites de requisições, verificações de propriedade/saldo/proximidade e ferramentas oficiais de denúncia e bloqueio do Roblox. |

## 🧭 Regiões e pontos de interesse

A estrutura do mundo contempla áreas como:

- **High Society Boulevard** — eixo urbano e comercial.
- **Grand Society Club** — clube e espaço de entretenimento.
- **Millionaire District** — área residencial de alto padrão.
- **Garden Park** — parque e área de convivência.
- **Paradise Island** — região de lazer e exploração.
- **Royal Marina** — marina e atividades relacionadas a veículos aquáticos.

> A composição final, acessibilidade, sinalização, colisões e acabamento visual do mapa ainda precisam ser conferidos na experiência aberta pelo Roblox Studio.

## 👔 Profissões e progressão

O projeto contempla dez atividades profissionais:

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

Cada profissão possui fluxo de início e conclusão, requisitos de deslocamento ou atividade e progressão por cinco patentes: **Aprendiz, Profissional, Especialista, Elite e Lenda**.

Os pagamentos são processados após a conclusão validada pelo servidor. Abandonar uma atividade não deve conceder a recompensa.

## 💰 Economia e monetização

A moeda interna do projeto é o **Society Credits**.

O código contempla:

- Recompensas diárias e progressão econômica.
- Compras em lojas, imóveis e veículos.
- Histórico de transações.
- Mercado entre jogadores, com comissão configurada para vendas de itens.
- Game Pass cosmético **Society VIP**.
- Developer Products de **1.000**, **5.000** e **20.000 Society Credits**.

**Importante:** os IDs de Game Pass e Developer Products permanecem configurados como `0`. Portanto, a monetização ainda depende da criação dos produtos no painel do Roblox, do cadastro dos IDs em `src/shared/Config.lua` e de testes em uma experiência publicada. Os produtos e compras não devem ser considerados ativos neste estado do projeto.

## 🧱 Arquitetura e tecnologias

- **Plataforma:** Roblox
- **Linguagem:** Luau
- **Sincronização e estruturação:** Rojo
- **Lógica de servidor:** `ServerScriptService`
- **Módulos compartilhados:** `ReplicatedStorage`
- **Cliente:** `StarterPlayerScripts`
- **Interface:** construída em runtime pelo script do cliente
- **Persistência:** DataStoreService, com serviços de dados e economia
- **Comunicação cliente-servidor:** RemoteEvents e RemoteFunctions criados pelo Bootstrap

### Estrutura do repositório

```text
The High Society Club/
├── assets/
├── docs/
│   ├── AUDIT.md
│   ├── DECISIONS.md
│   ├── FINAL_REPORT.md
│   ├── MONETIZATION.md
│   ├── TESTING.md
│   └── WORLD_QUALITY_PLAN.md
├── src/
│   ├── client/
│   │   └── GameClient.client.lua
│   ├── gui/
│   ├── server/
│   │   ├── Bootstrap.server.lua
│   │   └── Modules/
│   └── shared/
│       ├── Config.lua
│       ├── FashionCatalog.lua
│       ├── Logger.lua
│       ├── PropertyCatalog.lua
│       └── VehicleCatalog.lua
├── .gitignore
├── default.project.json
├── README.md
└── The High Society Club - Atualizado para teste.rbxlx
```

### Principais módulos de servidor

A arquitetura separa responsabilidades em serviços especializados, incluindo:

`DataService` · `EconomyService` · `ShopService` · `PropertyService` · `VehicleService` · `AppearanceService` · `EventService` · `FashionContestService` · `ClubService` · `PlayerMarketService` · `CreationService` · `MonetizationService` · `AdminService` · `WorldBuilder` · `WorldLife`.

## 🛠️ Como abrir e desenvolver

### Requisitos

- Roblox Studio.
- Rojo compatível com a versão do plugin instalado no Roblox Studio.
- Git (opcional, para controle de versão).
- Uma cópia de segurança da experiência antes de sincronizar alterações.

### Sincronização com Rojo

Na pasta raiz do projeto, execute:

```bash
rojo serve default.project.json
```

No Roblox Studio:

1. Abra uma **cópia de teste** da experiência.
2. Conecte o plugin Rojo ao servidor iniciado.
3. Confira a árvore de objetos antes de sincronizar.
4. Verifique o painel **Output** durante a inicialização.
5. Confirme que os serviços e módulos foram carregados sem erros.

Para gerar um arquivo de build, quando o Rojo estiver instalado:

```bash
rojo build default.project.json -o build.rbxlx
```

**Atenção:** Rojo sincroniza os arquivos definidos no projeto para o Studio; ele não substitui um backup do lugar completo nem exporta automaticamente o Workspace de volta para o repositório. Não sincronize diretamente sobre a experiência principal sem validar primeiro em uma cópia.

## 🧪 Status do projeto

O desenvolvimento dos sistemas previstos até a etapa 11.1 está representado no código e na documentação. Isso não significa que todos os recursos tenham sido validados em uma sessão real de jogo.

| Etapa | Situação |
|---|---|
| Arquitetura modular e configuração Rojo | Implementada no código |
| Sistemas de economia, dados e lojas | Implementados no código; teste real pendente |
| Veículos, imóveis, moda e profissões | Implementados no código; teste real pendente |
| Eventos, mercado, criações e segurança | Implementados no código; teste real pendente |
| Integração de monetização | Código preparado; IDs externos ainda não configurados |
| Qualidade final do mapa e experiência visual | Revisão e ajustes pendentes |
| Testes multiplayer, DataStore e dispositivos | Pendentes no Roblox Studio |
| Publicação comercial | Não concluída |

**Transparência:** compilação ou auditoria estática não comprovam funcionamento dentro do Roblox. Os testes de gameplay, persistência real, multiplayer, desempenho e compras precisam ser executados em uma experiência de teste publicada. Consulte `docs/TESTING.md`, `docs/FINAL_REPORT.md` e `docs/OWNER_TASKS.md`.

## 📚 Documentação

A pasta [`docs/`](./docs/) reúne o histórico técnico e os próximos passos:

- [`CHECKLIST-PROJETO.md`](./CHECKLIST-PROJETO.md) — visão geral do que está implementado e do que falta.
- [`PROGRESS.md`](./PROGRESS.md) — acompanhamento do desenvolvimento.
- [`docs/AUDIT_2026-11-04.md`](./docs/AUDIT_2026-11-04.md) — auditoria técnica do projeto.
- [`docs/WORLD_QUALITY_PLAN.md`](./docs/WORLD_QUALITY_PLAN.md) — diagnóstico e plano de qualidade do mundo.
- [`docs/TESTING.md`](./docs/TESTING.md) — roteiro de testes no Roblox Studio.
- [`docs/MONETIZATION.md`](./docs/MONETIZATION.md) — configuração dos produtos de monetização.
- [`docs/OWNER_TASKS.md`](./docs/OWNER_TASKS.md) — ações que dependem do proprietário.
- [`docs/FINAL_REPORT.md`](./docs/FINAL_REPORT.md) — relatório e preparação para publicação.

## 🔐 Segurança e configuração

- Arquivos `.env` e `.env.local` não devem ser enviados ao GitHub.
- Não publique tokens, senhas, cookies, chaves privadas ou credenciais.
- Mantenha IDs de produtos e configurações específicas nos locais apropriados.
- A lógica de transações e permissões deve continuar validada no servidor.
- Teste mudanças em uma cópia da experiência antes de atualizar a versão principal.

## 🗺️ Próximos marcos

- [ ] Corrigir e validar spawn, colisões, escadas, acessibilidade e circulação do mapa.
- [ ] Revisar sinalização, vegetação, mobiliário e identidade visual dos distritos.
- [ ] Executar a Onda 1 de testes no Roblox Studio e registrar evidências.
- [ ] Validar DataStores, multiplayer, segurança e desempenho.
- [ ] Criar e configurar Game Pass e Developer Products.
- [ ] Finalizar ícone, thumbnails, descrição e página da experiência.
- [ ] Publicar somente após aprovação dos testes.

---

<div align="center">

**THE HIGH SOCIETY CLUB**

*Seu mundo. Seu estilo. Sua conquista.*

Desenvolvido por **[@hdjlucas-maker](https://github.com/hdjlucas-maker)**

</div>
