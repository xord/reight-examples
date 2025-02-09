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
    @enemies, @bullets = [], []
    @score, @speed = 0, 20
    add_sprite player
    spawn_enemy
  end

  def sw # screen width
    width / 2
  end

  def sh # screen height
    height / 2
  end

  def update()
    player.vx  -= @speed if key_is_down(LEFT)
    player.vx  += @speed if key_is_down(RIGHT)
    player.vy  -= @speed if key_is_down(UP)
    player.vy  += @speed if key_is_down(DOWN)
    player.vel *= 0.8
  end

  def draw()
    background 0
    scale 2, 2
    sprite player, *@enemies, *@bullets
    text "SCORE: #{@score}", 4, 8
  end

  def key(code)
    case code
    when SPACE then add_bullet(player.center).tap {_1.vy = -200}
    end
  end

  def player()
    @player ||= project.chips.at(0, 0, 8, 8).to_sprite.tap do |sp|
      sp.x, sp.y = (sw - sp.w) / 2, sh - sp.h * 2
      sp.dynamic = true
      sp.pivot   = [0.5, 0.5]
      set_interval(0.01) {sp.angle += 2 * 3.1415926 / 100}
    end
  end

  def spawn_enemy()
    add_enemy rand(sw), -10
    set_timeout(rand 0.2..1) {spawn_enemy}
  end

  def add_enemy(x, y)
    add_sp @enemies, project.chips.at(8, 0, 8, 8).to_sprite.tap {|sp|
      sp.x, sp.y = x, y
      sp.dynamic = true
      speed      = rand 20..30
      sp.vel     = createVector speed * [-1, 1].sample, speed
      set_interval(rand 0.1..0.3) {sp.vx *= -1}
    }
  end

  def add_bullet(pos)
    add_sp @bullets, project.chips.at(0, 8, 3, 4).to_sprite.tap {|sp|
      sp.pos     = pos
      sp.dynamic = true
      sp.sensor  = true
      sp.contact do |o|
        next unless @enemies.include? o
        delete_sp @bullets, sp
        delete_sp @enemies, o
        @score += 10
        project.sounds[1].play
      end
      set_interval(1) {delete_sp @bullets, sp if sp.y < -10}
      project.sounds[0].play
    }
  end
end


setup        {$game = Game.new}
draw         {$game.update; $game.draw}
key_released {$prev_key = nil}
key_pressed  {
  $game.key key_code if key_code != $prev_key
  $prev_key = key_code
}
