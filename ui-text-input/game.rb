class TextInput
  def initialize(x, y, w, h, text:, regexp: nil, &changed)
    super()
    @x, @y, @w, @h, @regexp, @changed = x, y, w, h, regexp, changed
    self.value = text
  end

  attr_reader :value

  def value=(value)
    str = value.to_s
    return if str == @value
    return unless valid? str
    @value = str
  end

  def valid?(value)
    case
    when !value   then false
    when !@regexp then true
    else value =~ @regexp
    end
  end

  def begin_editing()
    return if sprite.capturing?
    sprite.capture = true
    @old_value = @value.dup
  end

  def end_editing()
    sprite.capture = false
    @changed&.call self if value != @old_value
  end

  def draw()
    sp = sprite

    no_stroke
    fill 200
    rect 0, 0, sp.w, sp.h, 3

    padding = 2
    fill 0
    text_align LEFT, CENTER
    text value.to_s, padding, 0, sp.w - padding * 2, sp.h

    if sp.capturing? && (frame_count % 60) < 30
      fill 100
      bounds = text_font.text_bounds value
      rect padding + bounds.w - 1, (sp.h - bounds.h) / 2, 2, bounds.h
    end
  end

  def key_pressed(key, code)
    case code
    when ENTER             then end_editing
    when DELETE, BACKSPACE then self.value = value.split('').tap {_1.pop}.join
    else                        self.value += key if key && valid?(key)
    end
  end

  def sprite()
    @sprite ||= Sprite.new(@x, @y, @w, @h).tap do |sp|
      sp.draw          {draw}
      sp.mouse_clicked {begin_editing}
      sp.key_pressed   {key_pressed sp.key, sp.key_code}
    end
  end
end


class Game
  def initialize()
    @text_input = TextInput.new(
      10, 10, 100, 20, text: 'hello-world', regexp: /^[\w\-_]*$/
    ) do |text_input|
      puts "Text is changed! - '#{text_input.value}'"
    end
    add_sprite @text_input.sprite
  end

  def draw()
    background 0
    sprite @text_input.sprite
  end
end


setup {$game = Game.new}
draw  {$game&.draw}
