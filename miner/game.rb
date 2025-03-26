def now()
  Time.now.to_f
end

class Game
  def initialize()
    angleMode(DEGREES)
    size(width / 2, height / 2)
    gravity(0, 500)
    @particles = []
  end

  def draw()
    ox, oy = player.x - width / 2, player.y - height / 2
    screenOffset(ox, oy)

    background(50, 70, 120)
    push do
      translate(-ox, -oy)
      sprite(ground.sprites_at(ox, oy, width, height, self))
      sprite(player, *@particles)
    end
    text_size(8)
    text("GOLD: #{player[:golds]}", 10, 16)
  end

  def key_down(code)
    case code
    when SPACE then player.vy = -150
    when UP    then dig( 0, -1)
    when DOWN  then dig( 0,  1)
    when LEFT  then dig(-1,  0)
    when RIGHT then dig( 1,  0)
    end
  end

  def dig(dirx, diry)
    dir   = create_vector(dirx, diry).normalize
    angle = -> rock {
      rock_dir = (rock.center - player.center).normalize
      rad      = Vector.angleBetween(dir, rock_dir)
      degrees(rad)
    }
    rock  = player.rocks.sort {|a, b| angle[a] <=> angle[b]}.first
    return unless rock && angle[rock] < 45
    player.vx = -dirx * 200
    5.times {add_rock_particle(rock.center)}
    if rock.chip.y == 40
      project.sounds[2].play
      rock['count'] ||= 3
      rock['count']  -= 1
      return if p(rock['count']) > 0
      10.times {add_gold(rock.center)}
    else
      project.sounds[1].play
    end
    remove_sprite(ground.sprites, rock)
    player.rocks.delete(rock)
  end

  def add_rock_particle(pos)
    project.chips.at(0, 8, 5, 5).to_sprite.tap do |sp|
      sp.center   = pos
      sp.dynamic  = true
      sp.sensor   = true
      sp.velocity = create_vector(0, -1).rotate(rand -90..90) * 50
      sp.vy      *= 3
      add_sprite(@particles, sp)
      set_timeout(0.5) {remove_sprite(@particles, sp)}
    end
  end

  def add_gold(pos)
    project.chips.at(8, 8, 3, 3).to_sprite.tap do |sp|
      sp.center   = pos
      sp.dynamic  = true
      sp.velocity = Vector.random2D * 50
      sp.contact do |other|
        next unless other == player
        player[:golds] += 1 
        remove_sprite(@particles, sp)
        project.sounds[0].play
      end
      add_sprite(@particles, sp)
    end
  end

  def player()
    @player ||= project.chips.at(0, 0, 8, 8).sprite.tap do |sp|
      sp[:golds] = 0
      sp[:rocks] = []
      sp.x, sp.y = width / 2, height / 2
      sp.dynamic = true
      sp.update do
        player.vx += 20 if key_is_down(RIGHT)
        player.vx -= 20 if key_is_down(LEFT)
        player.vx *= 0.8
      end
      sp.contact do |other|
        sp.rocks.push(other) if ground.sprites.include?(other)
      end
      sp.contact_end do |other|
        sp.rocks.delete(other) if ground.sprites.include?(other)
      end
      add_sprite(sp)
    end
  end

  def ground()
    @ground ||= project.maps[0]
  end
end

setup       {$game = Game.new}
draw        {$game&.draw}
key_pressed {$game&.key_down(key_code) unless key_is_repeated}
