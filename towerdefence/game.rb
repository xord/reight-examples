class Game
  def initialize()
    @sprites  = []
    @enemies  = []
    @bullets  = []
    @gameover = false
    3.times do |i|
      ww, hh = width / 5, height / 3
      add_cannon ww * (i + 1),   hh * 1, 100
      add_cannon ww * (i + 1.8), hh * 2, 100
    end
    spawn_enemy width, 104
  end

  def spawn_enemy(x, y)
    add_enemy(x, y)
    set_timeout(rand 2..5) do
      spawn_enemy x, y
    end
  end

  def draw()
    background 0
    sprite(*walls, *@bullets, *@sprites, *@enemies)
    if @gameover
      text_align(CENTER, CENTER)
      text_size(30)
      fill(255, 0, 0)
      text("Game Over!", 0, 0, width, height)
    end
  end

  def add_cannon(x, y, radius)
    sensed_enemies = []

    Sprite.new(shape: RubySketch::Circle.new(0, 0, radius)).tap do |sp|
      sp.center = [x, y]
      sp.pivot  = [0.5, 0.5]
      sp.sensor = true
      sp.draw do |&draw|
        fill(255, 32)
        draw.call
      end
      sp.contact do |other|
        sensed_enemies.push(other)   if @enemies.include?(other)
      end
      sp.contact_end do |other|
        sensed_enemies.delete(other) if @enemies.include?(other)
      end
      add_sprite(@sprites, sp)
    end

    project.chips.at(0, 0, 16, 16).to_sprite.tap do |sp|
      sp.center = [x, y]
      sp.pivot  = [0.5, 0.5]
      set_interval(1) do
        sensed_enemies &= @enemies
        if sensed_enemies.first
          add_bullet(sp.center, sp.angle, 100)
          project.sounds[0].play
        end
      end
      set_interval(0.1) do
        enemy    = sensed_enemies.first or next
        sp2enemy = (enemy.center - sp.center).dup.normalize
        angle    = Vector.angleBetween createVector(0, -1), sp2enemy
        sp.angle = enemy.x > sp.x ? angle : -angle
      end
      add_sprite(@sprites, sp)
    end
  end

  def add_enemy(x, y)
    project.chips.at(32, 0, 16, 16).to_sprite.tap {|sp|
      sp[:life_max] = rand(3..20)
      sp[:life]     = sp.life_max
      sp.x, sp.y    = x, y
      sp.dynamic    = true
      sp.vx         = -20
      sp.draw do |&draw|
        draw.call
        no_stroke
        fill(255, 0, 0)
        rect(0, -5, sp.w, 3)
        fill(0, 255, 0)
        rect(0, -5, sp.w * (sp.life / sp.life_max.to_f), 3)
      end
      set_interval(1) do
        if sp.right < 0
          remove_sprite(@enemies, sp)
          @gameover = true
        end
      end
      add_sprite(@enemies, sp)
    }
  end

  def add_bullet(pos, angle, speed)
    project.chips.at(0, 16, 4, 4).to_sprite.tap {|sp|
      sp.center   = pos
      sp.angle    = angle
      sp.velocity = createVector(0, -1).rotate(angle) * speed
      sp.dynamic  = true
      sp.sensor   = true
      sp.contact do |other|
        case other
        when *walls
          remove_sprite(@bullets, sp)
        when *@enemies
          remove_sprite(@bullets, sp)
          other.life -= 1
          if other.life <= 0
            remove_sprite(@enemies, other)
            project.sounds[2].play
          else
            project.sounds[1].play
          end
        end
      end
      add_sprite(@bullets, sp)
    }
  end

  def walls()
    @walls ||= project.maps[0].to_sprites.each {add_sprite _1}
  end
end


setup {$game = Game.new}
draw  {$game&.draw}
