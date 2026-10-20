# Marioatt

Projeto de plataforma para Godot 4.7. Abra `project.godot` e pressione F5.

- Setas esquerda/direita: mover.
- Seta para cima: pular; soltar antes reduz a altura.
- Espaço: lançar fireball quando Mario estiver com poder de fogo.
- R: reiniciar (ação `restart` no InputMap).

## Editar a fase

Abra `cenas/main.tscn` no editor 2D. Selecione `Terrain` para pintar ou apagar
blocos no TileMapLayer. O TileSet compartilhado está em
`resources/level_tileset.tres`, com colisões de chão, tijolo e bloco rígido.

Duplique instâncias em `Coins` e `Enemies` para adicionar moedas e inimigos.
Mantenha cada entidade dentro do respectivo nó: a fase conecta seus sinais em
`_ready()`. Edite `coin.tscn`, `goomba.tscn` ou `koopa.tscn` para mudar todas as
instâncias. A interface está em `hud.tscn`.

## Blocos de recompensa

No seletor de tiles do `Terrain`, escolha um dos três sources do bloco
misterioso no TileSet: source 11 entrega moeda, source 12 entrega cogumelo e
source 13 entrega flor de fogo. Pinte cada source na posição desejada; cada tile
pintado é uma recompensa individual. O source 14 é o bloco vazio que substitui
o bloco após ser cabeceado. Os sources usam o custom data `reward` do TileSet
para registrar a recompensa.

Os blocos só ativam quando Mario os acerta por baixo. A moeda usa `Coin2.png`,
vale 200 pontos e incrementa o contador de moedas. O cogumelo transforma Mario
em adulto; a flor ativa o poder de fogo. Um dano reduz fogo para adulto e
adulto para pequeno antes de matar Mario. Com o poder de fogo, pressione Espaço
para lançar fireballs que ricocheteiam no chão e eliminam inimigos.

A animação do bloco usa `MysteryBlock.png`, `MysteryBox1.png` e
`MysterBox2.png` em loop.

`Finish/Goal` define a área de chegada. Ao mudar o tamanho do mapa, ajuste
`level_width`, as paredes em `Boundaries` e a chegada. `time_limit`,
`fall_limit` e `activation_distance` são configuráveis no nó principal.

## Responsabilidades

- `level.gd`: tempo, pontuação, conexão de eventos, câmera e reinício.
- `player.gd`: movimento, contato com inimigos e animação de morte; emite
  `points_awarded` e `death_finished`, sem recarregar a cena por conta própria.
- `enemy.gd`: movimento com CharacterBody2D; colisão física somente com o
  terreno. `Hitbox` é uma Area2D para contato com jogador e outros inimigos.
- `koopa.gd`: transformação, chute, parada do casco e orientação do sprite ao
  inverter a direção.
- `mystery_block_manager.gd`: ativação dos blocos por cabeçada e entrega das
  recompensas configuradas no TileSet.
- `power_up.gd` e `fireball.gd`: surgimento, física, coleta de poderes e
  projéteis do Mario com poder de fogo.
- `coin.gd`: coleta única e sinal `collected`; `coin.tscn` anima seis imagens
  em loop, com um ciclo de aproximadamente um segundo.
- `hud.gd`: apresentação dos valores e da conclusão.

Os inimigos começam inativos e são ativados pela proximidade do jogador.
Eles não são apagados apenas por sair da câmera. A câmera avança sem retornar
às áreas já exploradas, e o jogador pode recuar até 14 pixels da borda esquerda
da área visível.
O jogador e os inimigos avisam a fase quando há pontos; a fase cria o efeito
visual dentro de `Effects`. Entidades não dependem de `current_scene`.

## Verificação automatizada

Com o executável Godot no PATH:

```sh
godot --headless --fixed-fps 60 --path . --script res://tests/level_checks.gd
```

O teste verifica colisão inicial, instâncias reutilizáveis, animação e coleta
de moedas, variantes dos blocos misteriosos e suas recompensas, poderes, dano,
fireball, câmera e recuo, pisão, orientação do Koopa, chute/parada/dano do casco,
casco atingindo inimigo, queda, tempo esgotado e limites físicos. Também
percorre a fase até a chegada com controles simulados, desativando inimigos
somente nesse teste para isolar a geometria.

Isso não substitui avaliação visual e de dificuldade por uma pessoa.

Referências oficiais:

- https://docs.godotengine.org/en/4.7/tutorials/best_practices/scene_organization.html
- https://docs.godotengine.org/en/4.7/tutorials/2d/using_tilemaps.html
- https://docs.godotengine.org/en/4.7/tutorials/physics/using_character_body_2d.html
- https://docs.godotengine.org/en/4.7/tutorials/inputs/input_examples.html
