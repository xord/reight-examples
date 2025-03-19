class Button
  def initialize(x, y, w, h, label, &clicked)
    super()
    @x, @y, @w, @h, @label, @clicked = x, y, w, h, label, clicked
  end

  attr_accessor :label

  def draw()
    w, h = sprite.w, sprite.h

    no_stroke
    fill @pressing ? 220 : 200
    rect 0, 0, w, h

    fill 0
    text_align CENTER, CENTER
    text @label, 0, 0, w, h
  end

  def pressed(x, y)
    @pressing = true
  end

  def released(x, y)
    @pressing = false
    @clicked&.call self if hit? x, y
  end

  def dragged(x, y)
    @pressing = hit? x, y
  end

  def hit?(x, y)
    0 <= x && x < sprite.w &&
    0 <= y && y < sprite.h
  end

  def sprite()
    @sprite ||= Sprite.new(@x, @y, @w, @h).tap do |sp|
      sp.draw           {draw}
      sp.mouse_pressed  {pressed  sp.mouse_x, sp.mouse_y}
      sp.mouse_released {released sp.mouse_x, sp.mouse_y}
      sp.mouse_dragged  {dragged  sp.mouse_x, sp.mouse_y}
    end
  end
end

class Game
  def initialize()
    @button1 = Button.new 10, 10, 100, 20, 'Button1' do |button|
      p "#{button.label} is clicked!"
    end
    @button2 = Button.new 10, 40, 100, 20, 'Button2' do |button|
      p "#{button.label} is clicked!"
    end
    add_sprite @button1.sprite
    add_sprite @button2.sprite
  end

  def draw()
    background 0
    sprite @button1.sprite, @button2.sprite
  end
end

setup {$game = Game.new}
draw  {$game&.draw}
