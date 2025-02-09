def add_sp(array = nil, sp)
  add_sprite sp
  array&.push sp
  sp
end

def delete_sp(array = nil, sp)
  remove_sprite sp
  array&.delete sp
  sp
end


class Game
  def initialize()
  end

  def update()
  end

  def draw()
    background 0
  end

  def key(code)
  end
end


setup        {$game = Game.new}
draw         {$game.update; $game.draw}
key_released {$prev_key = nil}
key_pressed  {
  $game.key key_code if key_code != $prev_key
  $prev_key = key_code
}
