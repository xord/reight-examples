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
    @score             = 0
    @speed             = 5
    @angular_speed     = TAU / 90
    @enemies, @bullets = [], []
    add_sp player
    spawn_enemy
  end

  def update()
    player.angle -= @angular_speed if key_is_down(LEFT)
    player.angle += @angular_speed if key_is_down(RIGHT)

    dir = createVector(0, -1).rotate(player.angle)
    player.velocity += dir * @speed if key_is_down(UP)

    player.vel *= 0.95
  end

  def draw()
    background 0
    scale 2, 2
    sprite *walls, player, *@enemies, *@bullets
    text "SCORE: #{@score}", 10, 16
  end

  def key_down(code)
    if code == SPACE
      set_interval(0.1, id: :shoot) {shoot player.center, player.angle}
    end
  end

  def key_up(code)
    clear_interval :shoot if code == SPACE
  end

  def spawn_enemy()
    add_enemy rand(10..(sw - 20)), rand(10..(sh - 20)), [0, 1].sample
    set_timeout(rand 1.0..2.0) {spawn_enemy}
  end

  def walls()
    @walls ||= project.maps.first.map(&:to_sprite).tap do |sprites|
      sprites.each {add_sp _1}
    end
  end

  def player()
    @player ||= project.chips.at(0, 0, 8, 8).to_sprite.tap do |sp|
      sp.x       = (sw - sp.w) / 2
      sp.y       = (sh - sp.h) / 2
      sp.pivot   = [0.5, 0.5]
      sp.dynamic = true
    end
  end

  def add_enemy(x, y, type = 0)
    project.chips.at(8 + 8 * type, 0, 8, 8).to_sprite.tap do |sp|
      sp.x, sp.y = x, y
      sp.dynamic = true
      add_sp @enemies, sp
    end
  end

  def shoot(pos, angle)
    project.chips.at(0, 8, 2, 2).to_sprite.tap do |sp|
      sp.pos     = pos
      sp.angle   = angle
      sp.dynamic = true
      sp.sensor  = true
      sp.contact do
        case _1
        when *walls    then delete_sp @bullets, sp
        when *@enemies then
          @score += 10
          delete_sp @enemies, _1
          delete_sp @bullets, sp
        end
      end
      sp.velocity = createVector(0, -1).rotate(angle) * 200
      add_sp @bullets, sp
    end
  end

  def sw = width / 2 # screen width
  def sh = height / 2 # sreen height
end


setup        {$game = Game.new}
draw         {$game.update; $game.draw}
key_pressed  {
  $game.key_down key_code if key_code != $prev_key
  $prev_key = key_code
}
key_released {
  $game.key_up key_code
  $prev_key = nil
}
