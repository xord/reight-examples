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
    add_sp cannon
    add_sp sensor
    @enemies, @bullets, @cars = [], [], []
    @gameover                 = false
    spawn_enemy
  end

  def spawn_enemy()
    add_enemy width, 40
    set_timeout(rand 2..5) {spawn_enemy}
  end

  def update()
  end

  def draw()
    background 0
    sprite sensor, *walls, *@bullets, cannon, *@enemies
    if @gameover
      text_align CENTER, CENTER
      fill 255, 0, 0
      text "Game Over!", 0, 0, width, height
    end
  end

  def key(code)
  end

  def walls()
    @walls ||= project.maps.first.map(&:to_sprite).tap {|sprites|
      sprites.each {add_sp _1}
    }
  end

  def cannon()
    @cannon ||= project.chips.at(0, 0, 16, 16).to_sprite.tap do |sp|
      sp.x, sp.y = (width - sp.w) / 2, (height - sp.h) / 2
      sp.pivot   = [0.5, 0.5]
      set_interval(1) do
        if @cars.first
          add_bullet(sp.center, sp.angle, 100)
          project.sounds[0].play
        end
      end
      set_interval(0.1) do
        car      = @cars.first or next
        sp2car   = (car.center - sp.center).dup.normalize
        angle    = Vector.angleBetween createVector(0, -1), sp2car
        sp.angle = car.x > sp.x ? angle : -angle
      end
    end
  end

  def sensor()
    @sensor ||= Sprite.new(shape: RubySketch::Circle.new(0, 0, 200)).tap do |sp|
      sp.center = createVector(width / 2, height / 2)
      sp.pivot  = [0.5, 0.5]
      sp.sensor = true
      sp.contact do |o|
        @cars << o if @enemies.include? o
      end
      sp.contact_end do |o|
        @cars.delete o
      end
    end
  end

  def add_enemy(x, y)
    add_sp @enemies, project.chips.at(32, 0, 16, 16).to_sprite.tap {|sp|
      life       = rand 3..8
      sp.x, sp.y = x, y
      sp.z       = life
      sp.dynamic = true
      sp.vx      = -10
      sp.draw do |&draw|
        draw.call
        no_stroke
        fill 255, 0, 0
        rect 0, -5, sp.w, 3
        fill 0, 255, 0
        rect 0, -5, sp.w * (sp.z / life.to_f), 3
      end
      set_interval(1) do
        if sp.right < 0
          delete_sp @enemies, sp
          @gameover = true
        end
      end
    }
  end

  def add_bullet(pos, angle, speed)
    add_sp @bullets, project.chips.at(0, 16, 4, 4).to_sprite.tap {|sp|
      sp.x, sp.y  = pos.x - sp.w / 2, pos.y - sp.h / 2
      sp.angle    = angle
      sp.velocity = createVector(0, -1).rotate(angle) * speed
      sp.dynamic  = true
      sp.sensor   = true
      sp.contact do |other|
        case other
        when *walls    then delete_sp @bullets, sp
        when *@enemies then
          delete_sp @bullets, sp

          car = other
          car.z -= 1
          if car.z <= 0
            delete_sp @enemies, car
            @cars.delete car
            project.sounds[2].play
          else
            project.sounds[1].play
          end
        end
      end
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
