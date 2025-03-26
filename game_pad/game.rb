# frozen_string_literal: true

# ゲームを実装したクラス
class Game
  def initialize
    @key_code = 'Press any key'
  end

  def draw
    background(0)
    scale(2, 2)

    fill(255, 255, 255)
    text_size(32)
    text_align(CENTER, CENTER)
    text(@key_code.to_s, 0, 0, width / 2, height / 2)
  end


  def key_pressed(key_code)
    @key_code = key_code
  end
end

setup do
  $game = Game.new
end

draw do
  $game&.draw
end

key_pressed do
  $game&.key_pressed key_code
end
