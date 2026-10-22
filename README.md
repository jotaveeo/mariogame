# Space & Dungeon

**Jogo de plataforma 2D desenvolvido em equipe como atividade acadêmica, utilizando Godot 4.7 e GDScript.**

Inspirado nas mecânicas clássicas de Super Mario Bros., o projeto apresenta duas fases: uma superfície lunar e uma dungeon. O jogador deve superar obstáculos, enfrentar inimigos e coletar pontos para alcançar a chegada antes do tempo acabar.

## Integrantes

| Integrante | Principais contribuições |
| --- | --- |
| JOÃO VITOR OLIVEIRA | Fase lunar, ambientação espacial, organização da base principal e integração das versões. |
| FELIPE CLEMENTE DA SILVA | Dungeon, blocos interativos, menu inicial e melhorias nas animações. |

A versão final reúne as contribuições dos dois integrantes na branch `main`.

## Como executar

**Requisito:** Godot Engine 4.7, com suporte a GDScript. O projeto utiliza o renderizador Compatibility.

1. Clone ou baixe este repositório.
2. Abra o Godot, selecione **Importar** e escolha o arquivo `project.godot`.
3. Aguarde a importação dos recursos e pressione **F5** para executar o projeto.
4. Clique em **Press Start** na tela inicial para começar.

Para abrir pelo terminal, com o executável Godot disponível no PATH:

```sh
git clone https://github.com/jotaveeo/mariogame.git
cd mariogame
godot --editor --path .
```

## Objetivo e regras

| Fase | Cenário | Limite de tempo | Pontuação mínima |
| --- | --- | --- | --- |
| 1 | Superfície lunar | 1 minuto | 2.000 pontos |
| 2 | Dungeon | 2 minutos | 2.000 pontos |

- Atingir a pontuação mínima e alcançar a bandeira antes de o cronômetro zerar.
- A câmera avança somente para a direita. É possível recuar dentro da tela, mas não retornar às áreas que ficaram para trás.
- Ao chegar sem pontos suficientes, a interface informa quanto falta. As oportunidades deixadas para trás não podem ser recuperadas; **R** permite tentar novamente.
- Cair no vazio, esgotar o tempo ou receber dano na forma pequena causa a morte e o reinício da fase.
- Após concluir a fase lunar, **Enter** inicia a dungeon. Cada fase começa com seu próprio jogador, pontuação e cronômetro.
- O bônus de conclusão é concedido somente depois de cumprir a pontuação mínima.

### Pontuação

| Ação | Pontos |
| --- | --- |
| Coletar moeda, inclusive de bloco de recompensa | 200 |
| Derrotar inimigo ou pisar no Koopa para transformá-lo em casco | 100 |
| Concluir a fase | 1.000 + 10 por segundo restante |

## Controles

| Ação | Controle |
| --- | --- |
| Iniciar o jogo | Clique em **Press Start** |
| Mover para a esquerda / direita | **← / →** ou **A / D** |
| Pular | **↑** ou **W** |
| Controlar a altura do salto | Soltar o botão de pulo antes para saltar mais baixo |
| Atirar, após obter a flor | **Espaço** |
| Reiniciar durante a partida | **R** |
| Avançar após concluir a primeira fase | **Enter** |
| Reiniciar após concluir a dungeon | **R** |
| Voltar ao menu após concluir uma fase | **Esc** |

## Mecânicas implementadas

- **Movimentação e colisões:** aceleração, desaceleração, salto com altura variável e limites de câmera.
- **Inimigos:** Goombas e Koopas, com patrulha, mudança de direção e derrota por pisão.
- **Casco do Koopa:** pode ser chutado, parado com um pisão e usado para atingir outros inimigos; causa dano ao jogador por contato lateral enquanto se move.
- **Cogumelo:** transforma o jogador pequeno em grande. Golpear o bloco abaixo do item faz o cogumelo quicar e inverter a direção.
- **Flor:** concede o poder de lançar bolas de fogo que ricocheteiam no chão e eliminam inimigos.
- **Dano e transformação:** perder um poder reduz a forma de fogo para grande, e de grande para pequena, antes de causar a morte.
- **Blocos de recompensa:** liberam moeda, cogumelo ou flor, com conteúdo predeterminado.
- **Tijolos interativos:** o jogador pequeno faz o tijolo subir levemente; grande ou com poder de fogo pode quebrá-lo. O golpe também atinge inimigos sobre o bloco.
- **Apresentação:** céu estrelado, decoração variada, animações de moedas, efeitos de pontuação e interface com tempo, moedas e progresso da meta.
- **Fluxo de jogo:** menu inicial, transição entre fases, conclusão e reinício.

## Organização técnica

O projeto utiliza cenas reutilizáveis e sinais para comunicar eventos entre o jogador, os inimigos e o controlador da fase. O terreno é editado com `TileMapLayer` e um `TileSet` compartilhado.

| Arquivo ou pasta | Responsabilidade |
| --- | --- |
| `project.godot` | Configuração do projeto e mapeamento dos controles. |
| `cenas/main.tscn` | Cena inicial, menu e fase lunar. |
| `cenas/dungeon_level.tscn` | Layout da dungeon. |
| `cenas/level.gd` | Controlador compartilhado: pontuação, tempo, câmera e fluxo da partida. |
| `cenas/dungeon_level.gd` | Especialização do controlador para os limites da dungeon. |
| `cenas/player.gd` | Movimento, poderes, dano e interações do jogador. |
| `cenas/enemy.gd`, `goomba.gd` e `koopa.gd` | Comportamento dos inimigos. |
| `cenas/mystery_block_manager.gd` | Recompensas, cabeçadas e destruição de tijolos. |
| `cenas/power_up.gd` e `fireball.gd` | Itens de poder e projéteis. |
| `cenas/hud.tscn` e `hud.gd` | Interface e mensagens da partida. |
| `resources/level_tileset.tres` | Blocos, colisões e dados das recompensas. |
| `Assets Super Mario Bros/` | Recursos gráficos, fontes e demais arquivos de apoio. |
| `tests/` | Verificações automatizadas. |

Para inspecionar uma fase separadamente, abra sua cena e pressione **F6**. Selecione o nó `Terrain` para editar o mapa. Os blocos de recompensa usam as fontes **11 — moeda**, **12 — cogumelo** e **13 — flor** do TileSet.

## Verificações automatizadas

Na raiz do projeto, com o Godot disponível no PATH:

```sh
godot --headless --fixed-fps 60 --path . --script res://tests/level_checks.gd
godot --headless --fixed-fps 60 --path . --script res://tests/integration_checks.gd
godot --headless --fixed-fps 60 --path . --script res://tests/block_contact_checks.gd
```

As verificações cobrem movimentação, coleta, pontuação, dano, cascos, poderes, menu, transição entre fases, cronômetro e contatos dos inimigos com os blocos. O teste de percurso automatizado da fase lunar desativa os inimigos para verificar a geometria separadamente dos testes de combate.

## Referências

- **Super Mario Bros.** — referência de mecânicas e dos personagens presentes nos recursos visuais utilizados na atividade.
- [Documentação do Godot 4.7](https://docs.godotengine.org/en/4.7/)
- [Organização de cenas](https://docs.godotengine.org/en/4.7/tutorials/best_practices/scene_organization.html)
- [Mapas com TileMapLayer](https://docs.godotengine.org/en/4.7/tutorials/2d/using_tilemaps.html)
- [Movimento com CharacterBody2D](https://docs.godotengine.org/en/4.7/tutorials/physics/using_character_body_2d.html)
