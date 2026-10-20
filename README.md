# Marioatt

A versão principal é a fase lunar original da `main`, desenvolvida por Jotaveeo.
A dungeon e os novos poderes são contribuições de Felipe, integradas à mesma
base. A fase lunar continua sendo a cena inicial do projeto.

Projeto de plataforma para Godot 4.7. Abra `project.godot` e pressione F5.

- Setas esquerda/direita: mover.
- Seta para cima: pular; soltar antes reduz a altura.
- R: reiniciar (ação `restart` no InputMap).

## Editar a fase

Abra `cenas/main.tscn` no editor 2D. Selecione `Terrain` para pintar ou apagar
blocos no TileMapLayer. O TileSet compartilhado está em
`resources/level_tileset.tres`, com colisões de chão, tijolo e bloco rígido.

Duplique instâncias em `Coins` e `Enemies` para adicionar moedas e inimigos.
Mantenha cada entidade dentro do respectivo nó: a fase conecta seus sinais em
`_ready()`. Edite `coin.tscn`, `goomba.tscn` ou `koopa.tscn` para mudar todas as
instâncias. A interface está em `hud.tscn`.

`Finish/Goal` define a área de chegada. Ao mudar o tamanho do mapa, ajuste
`level_width`, as paredes em `Boundaries` e a chegada. `time_limit`,
`fall_limit` e `activation_distance` são configuráveis no nó principal.

## Responsabilidades

- `level.gd`: tempo, pontuação, conexão de eventos, câmera e reinício.
- `player.gd`: movimento, contato com inimigos e animação de morte; emite
  `points_awarded` e `death_finished`, sem recarregar a cena por conta própria.
- `enemy.gd`: movimento com CharacterBody2D; colisão física somente com o
  terreno. `Hitbox` é uma Area2D para contato com jogador e outros inimigos.
- `koopa.gd`: transformação, chute e parada do casco.
- `coin.gd`: coleta única e sinal `collected`.
- `hud.gd`: apresentação dos valores e da conclusão.

Os inimigos começam inativos e são ativados pela proximidade do jogador.
Eles não são apagados apenas por sair da câmera. A câmera só avança: Mario
pode andar para a esquerda dentro da tela, mas não voltar às áreas que ficaram
para trás.
O jogador e os inimigos avisam a fase quando há pontos; a fase cria o efeito
visual dentro de `Effects`. Entidades não dependem de `current_scene`.

## Verificação automatizada

Com o executável Godot no PATH:

```sh
godot --headless --fixed-fps 60 --path . --script res://tests/level_checks.gd
```

O teste verifica colisão inicial, instâncias reutilizáveis, moedas, pisão,
chute/parada/dano do casco, casco atingindo inimigo, queda, tempo esgotado e
limites físicos. Também percorre a fase até a chegada com controles simulados,
desativando inimigos somente nesse teste para isolar a geometria.

Isso não substitui avaliação visual e de dificuldade por uma pessoa.

Referências oficiais:

- https://docs.godotengine.org/en/4.7/tutorials/best_practices/scene_organization.html
- https://docs.godotengine.org/en/4.7/tutorials/2d/using_tilemaps.html
- https://docs.godotengine.org/en/4.7/tutorials/physics/using_character_body_2d.html
- https://docs.godotengine.org/en/4.7/tutorials/inputs/input_examples.html


## Integração da dungeon

O jogo começa em `cenas/main.tscn`. As duas fases usam limite de **60 segundos**
e meta de **2.000 pontos**, ajustáveis no Inspector. O bônus de conclusão não
conta para liberar a chegada. A câmera não retorna. Colete a pontuação mínima durante o avanço; se deixar
pontos para trás, será necessário tentar novamente com R.

Após concluir a fase lunar, pressione **Enter** para entrar na dungeon.
Cada fase começa com seu próprio tempo, pontuação e jogador. R reinicia a fase
atual. Também é possível abrir `cenas/dungeon_level.tscn` e usar F6 para testá-la.

`dungeon_level.gd` herda o controlador `GameLevel` de `level.gd`, incluindo
pontuação mínima, cronômetro, conexão da chegada e interface. Seu layout e
recursos visuais ficam na cena da dungeon, sem substituir a fase principal.

Contribuições integradas de Felipe:

- WASD como alternativa às setas e moedas animadas.
- Koopa vira o sprite ao mudar de direção.
- Blocos misteriosos: fontes 11 (moeda), 12 (cogumelo) e 13 (flor) do TileSet.
- Cogumelo aumenta Mario; flor permite atirar com Espaço.
- Dano reduz fogo para grande, grande para pequeno, e então mata o jogador.
- Power-ups aguardam o fim de uma transformação antes de serem consumidos.

Testes adicionais de integração:

```sh
godot --headless --fixed-fps 60 --path . --script res://tests/integration_checks.gd
```

Esses testes verificam a preservação das regras principais, recompensas,
transformações, descarte de projéteis, passagem entre as fases e conclusão da
dungeon. O teste automático de percurso completo cobre a fase lunar; o caminho
e a dificuldade da dungeon ainda precisam de validação jogando.
