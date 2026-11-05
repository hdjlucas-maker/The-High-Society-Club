# Checklist principal do projeto

O andamento detalhado e canônico está em [docs/PROGRESS.md](./docs/PROGRESS.md). Este resumo separa o que já está implementado das tarefas que dependem do proprietário e dos testes futuros. **Código implementado não significa teste concluído.**

## Concluído no código

- [x] Fases 1–2: fundação Rojo, configuração/logs, dados, economia, histórico e limites de solicitações.
- [x] Fase 3: mapa/regiões, lojas vinculadas aos estabelecimentos e validação de compra no servidor.
- [x] Fase 4: catálogo de veículos, propriedade, garagem, controle server-side, pintura e test drive.
- [x] Fase 5: catálogo de imóveis, compra/visita, interiores, decoração e convites.
- [x] Fase 6: inventário, catálogo de moda, aparência e poses.
- [x] Fase 7: eventos/convites, desfile com votação, palco/cabine de DJ, modo foto e álbum local.
- [x] Fase 8: dez profissões com rotas/pagamentos validados; proprietário de estabelecimento e criador de mundos têm atividades presenciais com escolhas e conclusão verificadas no servidor.
- [x] Fase 9: denúncia/bloqueio oficial Roblox, logs de moderação e revisão estática dos Remotes/proteções concluídos no código; teste no Studio continua pendente.
- [x] Fase 10.1: mercado na mesma sessão para itens de moda, presentes e doações de créditos; transações validadas pelo servidor, limitadas por valor/proximidade e registradas no extrato.
- [x] Fase 10.2: editor limitado de tema/composição, aprovação pelo criador/admin e construção server-side de maquetes aprovadas na Galeria; sem upload de modelos/texto livre.
- [x] Fase 10.3: comissão configurável de 5% nas vendas, descontada do vendedor e registrada no extrato; comprador paga o preço anunciado; presentes/doações sem comissão e regras comerciais documentadas.
- [x] Fase 11.1: Game Pass VIP cosmético e três pacotes de créditos com confirmação de recibo persistente/idempotente; IDs permanecem desativados até o proprietário criá-los e configurá-los.

## Próximas ações — dependem do proprietário

- [ ] Criar o Game Pass Society VIP e os três Developer Products, definir preços Robux e cadastrar IDs em `Config.Monetization` conforme [docs/MONETIZATION.md](./docs/MONETIZATION.md).
- [ ] Testar primeiro em uma cópia publicada no Roblox Studio, com acesso às APIs habilitado; seguir [docs/TESTING.md](./docs/TESTING.md).
- [ ] Conferir e concluir as tarefas de publicação e página comercial em [docs/OWNER_TASKS.md](./docs/OWNER_TASKS.md).

## Validação futura — ainda não realizada

- [ ] Validar multiplayer, DataStore, segurança, desempenho e dispositivos.
- [ ] Realizar compras reais/de teste depois de cadastrar os IDs.

**Status atual:** Todo o escopo de scripts planejado (Fases 1–11.1) está codado. Falta o proprietário criar/configurar os produtos Roblox, seguir as tarefas externas de publicação e testar no Studio. Não enviar/sincronizar no jogo principal nem considerar pronto para jogar. Nenhum teste de gameplay ou compra foi realizado.

## Documentação

- [Relatório final e passos de publicação](./docs/FINAL_REPORT.md)
- [Progresso detalhado por tarefa](./docs/PROGRESS.md)
- [Auditoria do código](./docs/AUDIT.md)
- [Plano de testes futuro](./docs/TESTING.md)
- [Tarefas do proprietário](./docs/OWNER_TASKS.md)
- [Decisões técnicas](./docs/DECISIONS.md)
- [Ideias fora do escopo](./docs/IDEAS.md)
- [Monetização](./docs/MONETIZATION.md)
