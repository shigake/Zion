# ADR-003 — Multiplayer host-client via ENet (Steam no futuro)

**Status:** Aceito
**Data:** 2024-02

---

## Contexto

Zion suporta co-op online para até 4 jogadores. Precisávamos definir:
1. Topologia de rede (peer-to-peer, servidor dedicado, ou host-client)
2. Protocolo de transporte
3. Estratégia para NAT traversal

## Decisão

**Topologia:** Host-client (listen server) — um dos jogadores é simultaneamente servidor e jogador.

**Transporte atual:** ENet (embutido no Godot 4) para testes e LAN.

**Transporte futuro (produção):** Steam Networking Sockets via GodotSteam GDExtension.

A troca de backend é feita via enum `NetworkBackend { ENET, STEAM }` no `MultiplayerManager`, sem alterar a lógica de jogo.

## Justificativa

### Host-client vs outras topologias

| Topologia | Prós | Contras |
|-----------|------|---------|
| **Host-client** ✅ | Sem custo de servidor; host controla authoridade | Vantagem leve ao host; host migration necessário |
| Servidor dedicado | Latência igual para todos | Custo operacional; complexidade |
| Peer-to-peer puro | Sem servidor central | Complexidade de consenso; NAT traversal manual |

### ENet → Steam

- **ENet agora**: zero custo, funciona em LAN, ideal para desenvolvimento e testes
- **Steam depois**: NAT traversal resolvido pela infraestrutura da Valve (sem relay dedicado nosso), matchmaking via Steam Lobby, autenticação de jogadores incluída
- A abstração por enum garante que a lógica de jogo não precisa mudar ao trocar o backend

### Features implementadas

- **Host Migration**: quando o host desconecta, o próximo peer assume com estado sincronizado
- **Ping RPC**: medição a cada 2 segundos, exibida no HUD
- **Reconexão automática**: 3 tentativas com intervalo de 2s
- **LAN Discovery**: broadcast UDP na porta 7778 para descoberta de servidores locais
- **Lobby protegido**: suporte a senha no lobby
- **Seed determinística**: spawns de inimigos sincronizados via seed compartilhada (sem replicar cada spawn individualmente)

## Sincronização

- **Posições de jogadores**: enviadas como inputs do client para o host; host retorna posição autoritativa
- **Inimigos**: gerenciados apenas pelo host; clients recebem atualizações de posição
- **Cross-Combo**: detectado no host quando projeteis de elementos diferentes colidem

## Consequências

- Máximo de 4 jogadores (`MAX_PLAYERS = 4`)
- Porta padrão: 7777 (TCP/UDP)
- O código Steam está 100% pronto — falta apenas instalar o plugin GodotSteam GDExtension
- Jogo funciona offline em modo solo sem nenhuma dependência de rede
