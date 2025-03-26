class Game
  def initialize()
    @enemies = []
    @bullets = []
    @exps    = []
    spawn_enemy
  end

  def spawn_enemy()
    new_enemy new_enemy_pos
    set_timeout(rand 0.1..1.0) {spawn_enemy}
  end

  def spawn_bats()
    pos    = new_enemy_pos
    target = player.center + (player.center - pos) * 10
    bats   = 30.times.map {new_enemy pos + [rand, rand], 100, target_pos: target}
  end

  def draw()
    ox, oy = player.x - width / 2, player.y - height / 2
    screenOffset ox, oy

    background 0
    push do
      translate -ox, -oy
      fill 255, 32
      sprite player_sensor
      fill 255
      sprite player, *@enemies, *@bullets, *@exps
    end
    text "EXP: #{player.exp}", 10, 20
    if player.life == 0
      text_align CENTER, CENTER
      text_size 30
      fill 255, 100, 100
      text 'GAME OVER!', 0, 0, width, height
    end
  end

  def key_down(code)
    spawn_bats if code == ESC
  end

  def player()
    @player ||= project.chips.at(0, 0, 8, 8).sprite.tap do |sp|
      sp[:life_max] = 3
      sp[:life]     = sp.life_max
      sp[:speed]    = 20
      sp[:exp]      = 0
      sp.center     = [width / 2, height / 2]
      sp.dynamic    = true
      def sp.life=(life)
        super life.clamp(0, life_max)
      end
      def sp.exp=(n)
        super
        $game.spawn_bats if exp % 100 == 0
      end
      sp.update do
        sp.vx  -= sp.speed if key_is_down(LEFT)
        sp.vx  += sp.speed if key_is_down(RIGHT)
        sp.vy  -= sp.speed if key_is_down(UP)
        sp.vy  += sp.speed if key_is_down(DOWN)
        sp.vel *= 0.8
      end
      sp.draw do |&draw|
        draw.call
        no_stroke
        fill 255, 0, 0
        rect 0, -2, sp.w, 1
        fill 0, 255, 0
        rect 0, -2, sp.w * (sp.life / sp.life_max.to_f), 1
      end
      set_interval(1) {shoot}
      add_sprite sp
    end
  end

  def player_sensor()
    @player_sensor ||= Sprite.new(
      shape: RubySketch::Circle.new(0, 0, 50)
    ).tap do |sp|
      sp.dynamic = true
      sp.sensor  = true
      sp.update do
        sp.center = player.center
      end
      add_sprite sp
    end
  end

  def shoot()
    nearest, = @enemies.dup
      .map {|e| [e, (e.center - player.center).mag]}
      .sort {|(_, dist1), (_, dist2)| dist1 <=> dist2}
      .first
    return unless nearest

    project.chips.at(0, 32, 4, 4).to_sprite.tap do |sp|
      sp.center   = player.center
      sp.dynamic  = true
      sp.sensor   = true
      sp.velocity = (nearest.center - player.center).normalize * 100
      sp.contact? {_1[:type] == :enemy}
      sp.contact do |other|
        remove_sprite @bullets, sp
        remove_sprite @enemies, other
        project.sounds[3].play gain: 0.2
        5.times {drop_exp other}
      end
      add_sprite @bullets, sp
      project.sounds[1].play
    end
  end

  def drop_exp(enemy)
    project.chips.at(8, 32, 4, 4).to_sprite.tap do |sp|
      sp.center = enemy.center
      sp.sensor = true
      sp.contact do |other|
        case other
        when player_sensor
          set_interval(0.1, id: sp) {
            sp.vel = (player.center - sp.center).normalize * 200
          }
        when player
          player.exp += 1
          remove_sprite @exps, sp
          project.sounds[0].play
          clear_interval sp
        end
      end
      animateValue(
        0.5, from: sp.pos, to: sp.pos + Vector.random2D * rand(5..20),
        easing: :quintOut
      ) do |pos|
        sp.pos = pos
      end
      add_sprite @exps, sp
    end
  end

  def new_enemy(pos, speed = 10, target_pos: nil)
    project.chips.at(0, 16, 8, 8).to_sprite.tap do |sp|
      sp[:type]  = :enemy
      sp[:speed] = speed
      sp.center  = pos
      sp.dynamic = true
      sp.update do
        pos         = target_pos || player.center
        sp.velocity = (pos - sp.center).normalize * sp.speed
      end
      sp.contact do |other|
        if other == player
          other.life    -= 1
          other.velocity = (other.center - sp.center).normalize * 200
          project.sounds[2].play
        end
      end
      add_sprite @enemies, sp
    end
  end

  def new_enemy_pos()
    player.center + Vector.random2D * mag(width / 2, height / 2)
  end
end

setup       {$game = Game.new}
draw        {$game&.draw}
key_pressed {$game&.key_down key_code unless key_is_repeated}
