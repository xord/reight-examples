class Game
  def draw()
    background 0
  end

  def key_down(code)
  end

  def key_up(code)
  end
end

setup        {$game = Game.new}
draw         {$game&.draw}
key_pressed  {$game&.key_down key_code unless key_is_repeated}
key_released {$game&.key_up   key_code}
