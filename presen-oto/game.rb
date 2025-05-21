# -*- coding: utf-8 -*-

class Room
  def initialize(xi, yi)
    @xindex, @yindex = xi, yi
    @texts, @images  = [], []
  end

  attr_reader :xindex, :yindex

  def room_x()
    width * @xindex
  end

  def room_y()
    height * @yindex
  end

  def t(x, y, str:, size: 14, center: false)
    @texts.push [str, x, y, size, center]
  end

  def i(img, x, y, w = nil, h = nil)
    w ||= img.width
    h ||= img.height
    @images.push [img, x, y, w, h]
  end

  def draw()
    rx, ry = room_x, room_y
    @texts.each do |(str, x, y, size, center)|
      text_size size
      text_align center ? CENTER : LEFT
      if center
        text str, rx,     ry + y, width, size
      else
        text str, rx + x, ry + y
      end
    end
    @images.each do |(img, x, y, w, h)|
      image img, room_x + x, room_y + y, w, h
    end
  end

  def note_pressed(note, frequency, velocity) = nil
  def note_released(note)                     = nil
  def control_change(index, value)            = nil
end

class StepSequencer < Room

  B = Beeps

  NROW, NCOL = 4, 16

  def initialize(...)
    super
    update_layout
  end

  def osc(type, freq = 440)
    B::Oscillator.new(type, freq: freq)
  end

  def const(value, freq: 1, amp: 1)
    B::Oscillator.new(offset: value, freq: freq, gain: amp)
  end

  def env(a, d, s = 0, r = 0)
    B::Envelope.new(a, d, s, r) {note_on}
  end

  def gain(gain, velocity = 1)
    B::Gain.new gain * velocity
  end

  def mix(*inputs)
    B::Mixer.new(*inputs)
  end

  def kick(velocity: 1, gain: 1, freq: 40, decay: 0.5, **)
    triangle = osc(:triangle, const(freq) >> env(0, decay)) >> env(0, decay)
    noise    = osc(:noise,    const(1000) >> env(0, 0.3)) >> env(0, 0.3) >> gain(0.01)
    #mix(triangle, noise) >> gain(gain, velocity) >> gain(0.2)
    triangle >> env(0.01, 0, 1, 0) >> gain(gain, velocity) >> gain(0.2)
  end

  def draw()
    sprite play_or_stop, bpm, *toggles
  end

  def control_change(index, value)
    case index
    when 3 then bpm[:value] = map(value, 0.0, 1.0, 60, 240).to_i
    end
  end

  def play()
    unit      = 60.0 / bpm[:value]
    duration  = unit * NCOL
    sequencer = B::Sequencer.new.tap do |seq|
      each_toggle do |sp, x, y|
        seq.add kick, x * unit, 1 if sp[:on]
      end
    end
    set_timeout duration, id: :play do
      play
    end
    @playing = B::Sound.new(sequencer, duration).play
  end

  def playing?
    @playing
  end

  def stop()
    @playing&.stop
    @playing = nil
    clear_timeout :play
  end

  def play_or_stop()
    @play_or_stop ||= Sprite.new(physics: false).tap do |sp|
      add_sprite sp
      sp.draw do
        fill 255
        rect 0, 0, sp.w, sp.h, 3

        fill 0
        text_align CENTER, CENTER
        text (playing? ? 'Stop' : 'Play'), 0, 0, sp.w, sp.h
      end
      sp.mouse_clicked do
        playing? ? stop : play
      end
    end
  end

  def bpm()
    @bpm ||= Sprite.new(physics: false).tap do |sp|
      add_sprite sp
      sp[:value] = 120
      sp.draw do
        fill 255
        rect 0, 0, sp.w, sp.h, 3

        fill 0
        text_align CENTER, CENTER
        text "BPM: #{sp[:value]}", 0, 0, sp.w, sp.h
      end
    end
  end

  def toggles()
    @toggles ||= (0...NROW).to_a.product((0...NCOL).to_a).map {|(y, x)|
      Sprite.new(physics: false).tap do |sp|
        add_sprite sp
        sp[:on] = y == 0
        sp.draw do
          fill (x / 4 % 2 == 0) ? 255 : 150
          rect 0, 0, sp.w, sp.h, 1
          if sp[:on]
            fill 0
            text_align CENTER, CENTER
            text 'X', 0, 0, sp.w, sp.h
          end
        end
        sp.mouse_clicked do
          sp[:on] = !sp[:on]
        end
      end
    }
  end

  def each_toggle(&block)
    toggles.each.with_index do |sp, i|
      block.call sp, i % NCOL, i / NCOL
    end
  end

  def update_layout()
    padding, margin = 32, 4
    play_or_stop.tap do |sp|
      sp.w, sp.h  = 48, 20
      sp.x = sp.y = padding
    end
    bpm.tap do |sp|
      base       = play_or_stop
      sp.w, sp.h = 64, 16
      sp.x, sp.y = base.right + margin, base.bottom - sp.h
    end

    each_toggle do |sp, x, y|
      sp.w = sp.h = 16
      sp.x, sp.y  = 32 + x * 20, 100 + y * 20
    end
  end
end

class Synth < Room

  B = Beeps

  def initialize(...)
    super
    @pressings = {}
    update_layout
  end

  def note2freq(note)
    a4 = 69
		440 * 2.0 ** ((note - a4) / 12.0)
  end

  def play(note, frequency, velocity)
    osc0 = B::Oscillator.new(
                   osc_type(0)[:type],
             duty: osc_duty(0)[:value],
             gain: osc_gain(0)[:value],
             freq: frequency)
    osc1 = B::Oscillator.new(
                   osc_type(1)[:type],
             gain: osc_gain(1)[:value],
             freq: note2freq(
                     note +
                     osc_detune(1)[:value] +
                     osc_octave(1)[:value].to_i * 12))
    osc2 = B::Oscillator.new(
                   osc_type(2)[:type],
             gain: osc_gain(2)[:value],
             freq: note2freq(
                     note +
                     osc_detune(2)[:value] +
                     osc_octave(2)[:value].to_i * 12))
    mix  = B::Mixer.new osc0, osc1, osc2
    lpf  = B::LowPass.new lowpass[:value]
    src  = lpf.cutoff >= 10000 ? mix : (mix >> lpf)
    env  = B::Envelope.new(
             attack[:value],
             decay[:value],
             sustain[:value],
             release[:value]) {note_on}
    gain = B::Gain.new 0.5 * velocity * volume[:value]
    B::Sound.new(src >> env >> gain).play
    env
  end

  def draw()
    sprite osc_type(0), osc_gain(0), osc_duty(0)
    sprite osc_type(1), osc_gain(1), osc_detune(1), osc_octave(1)
    sprite osc_type(2), osc_gain(2), osc_detune(2), osc_octave(2)
    sprite volume, lowpass
    sprite attack, decay, sustain, release
    sprite keyboard
  end

  def note_pressed(note, freq, vel)
    if vel == 0
      note_released note
    else
      @pressings[note] = play note, freq, vel
    end
  end

  def note_released(note)
    @pressings[note].note_off
    @pressings.delete note
  end

  def control_change(index, value)
    case index
    when 3  then osc_gain(0)[:value] = value
    when 9  then osc_duty(0)[:value] = map value, 0.0, 1.0, 0.01, 0.99
    when 12 then volume[:value]      = value

    when 13 then osc_gain(1)[:value]   = value
    when 14 then osc_detune(1)[:value] = map value, 0.0, 1.0, -1.0, 1.0
    when 15 then osc_octave(1)[:value] = map value, 0.0, 1.0, -2, 2

    when 16 then osc_gain(2)[:value]   = value
    when 17 then osc_detune(2)[:value] = map value, 0.0, 1.0, -1.0, 1.0
    when 18 then osc_octave(2)[:value] = map value, 0.0, 1.0, -2, 2

    when 19 then lowpass[:value] = map value, 0.0, 1.0, 100, 10000

    when 22 then attack[:value]  = map value, 0.0, 1.0, 0.0, 3.0
    when 23 then decay[:value]   = value
    when 24 then sustain[:value] = value
    when 25 then release[:value] = map value, 0.0, 1.0, 0.0, 3.0
    end
  end

  OSC_TYPES = {sine: :Sin, triangle: :Tri, sawtooth: :Saw, square: :Sqr}

  def osc_type(index = 0)
    (@osc_types ||= [])[index] ||= Sprite.new(physics: false).tap do |sp|
      add_sprite sp
      types = OSC_TYPES.keys.dup.rotate.rotate
      sp[:type] = types.first
      sp.mouse_clicked do
        types.rotate!
        sp[:type] = types.first
      end
      sp.draw do
        fill 255
        rect 0, 0, sp.w, sp.h, 2

        fill 0
        text_align CENTER, CENTER
        text_size 8
        text OSC_TYPES[sp[:type]], 0, 0, sp.w, sp.h
      end
    end
  end

  def setup_value_control(sp, label, initial_value = 0)
    sp[:value] = initial_value
    sp.draw do
      fill 255
      rect 0, 0, sp.w, sp.h, 2

      fill 0
      text_align CENTER, CENTER
      text_size 8
      text "#{label}:#{'%.2f' % sp[:value]}", 0, 0, sp.w, sp.h
    end
  end

  def osc_duty(index = 0)
    (@osc_duties ||= [])[index] ||= Sprite.new(physics: false).tap do |sp|
      add_sprite sp
      setup_value_control sp, 'Duty', 0.5
    end
  end

  def osc_gain(index = 0)
    (@osc_gains ||= [])[index] ||= Sprite.new(physics: false).tap do |sp|
      add_sprite sp
      setup_value_control sp, 'Gain', index == 0 ? 1 : 0
    end
  end

  def osc_detune(index = 0)
    (@osc_detunes ||= [])[index] ||= Sprite.new(physics: false).tap do |sp|
      add_sprite sp
      setup_value_control sp, 'Det'
    end
  end

  def osc_octave(index = 0)
    (@osc_octaves ||= [])[index] ||= Sprite.new(physics: false).tap do |sp|
      add_sprite sp
      setup_value_control sp, 'Oct'
    end
  end

  def volume()
    @volume ||= Sprite.new(physics: false).tap do |sp|
      add_sprite sp
      setup_value_control sp, 'Vol', 1
    end
  end

  def lowpass()
    @lowpass ||= Sprite.new(physics: false).tap do |sp|
      add_sprite sp
      setup_value_control sp, 'LPF', 10000
    end
  end

  def attack()
    @attack ||= Sprite.new(physics: false).tap do |sp|
      add_sprite sp
      setup_value_control sp, 'A', 0
    end
  end

  def decay()
    @decay ||= Sprite.new(physics: false).tap do |sp|
      add_sprite sp
      setup_value_control sp, 'D', 0
    end
  end

  def sustain()
    @sustain ||= Sprite.new(physics: false).tap do |sp|
      add_sprite sp
      setup_value_control sp, 'S', 1
    end
  end

  def release()
    @release ||= Sprite.new(physics: false).tap do |sp|
      add_sprite sp
      setup_value_control sp, 'R', 0
    end
  end

  BLACKS = Set.new [1, 3, 6, 8, 10]

  def keyboard()
    @keyboard ||= Sprite.new(physics: false).tap do |sp|
      add_sprite sp
      sp.draw do
        (0...sp.w).step(4).with_index do |x, i|
          note  = i + 24
          black = BLACKS.include? note % 12
          stroke 50
          fill @pressings[note] ? 150 : (black ? 100 : 250)
          rect x, 0, 4, sp.h
        end
      end
    end
  end

  def update_layout()
    padding, margin = 16, 4

    osc_type(0).tap do |sp|
      sp.w, sp.h = 24, 16
      sp.x, sp.y  = room_x + padding, room_y + padding
    end
    osc_gain(0).tap do |sp|
      base = osc_type(0)
      sp.w, sp.h = base.w * 2, base.h
      sp.x, sp.y = base.right + margin, base.y
    end
    osc_duty(0).tap do |sp|
      base = osc_gain(0)
      sp.w, sp.h = base.w, base.h
      sp.x, sp.y = base.right + margin, base.y
    end

    osc_type(1).tap do |sp|
      base = osc_type(0)
      sp.w, sp.h = base.w, base.h
      sp.x, sp.y = base.x, base.bottom + margin
    end
    osc_gain(1).tap do |sp|
      base = osc_type(1)
      sp.w, sp.h = base.w * 2, base.h
      sp.x, sp.y = base.right + margin, base.y
    end
    osc_detune(1).tap do |sp|
      base = osc_gain(1)
      sp.w, sp.h = base.w, base.h
      sp.x, sp.y = base.right + margin, base.y
    end
    osc_octave(1).tap do |sp|
      base = osc_detune(1)
      sp.w, sp.h = base.w, base.h
      sp.x, sp.y = base.right + margin, base.y
    end

    osc_type(2).tap do |sp|
      base = osc_type(1)
      sp.w, sp.h = base.w, base.h
      sp.x, sp.y = base.x, base.bottom + margin
    end
    osc_gain(2).tap do |sp|
      base = osc_type(2)
      sp.w, sp.h = base.w * 2, base.h
      sp.x, sp.y = base.right + margin, base.y
    end
    osc_detune(2).tap do |sp|
      base = osc_gain(2)
      sp.w, sp.h = base.w, base.h
      sp.x, sp.y = base.right + margin, base.y
    end
    osc_octave(2).tap do |sp|
      base = osc_detune(2)
      sp.w, sp.h = base.w, base.h
      sp.x, sp.y = base.right + margin, base.y
    end

    volume.tap do |sp|
      base = osc_type(2)
      sp.w, sp.h = base.w * 2, base.h
      sp.x, sp.y = base.x, base.bottom + margin * 2
    end
    lowpass.tap do |sp|
      base = volume
      sp.w, sp.h = base.w * 2, base.h
      sp.x, sp.y = base.right + margin, base.y
    end

    attack.tap do |sp|
      base = volume
      sp.w, sp.h = base.w, base.h
      sp.x, sp.y = base.x, base.bottom + margin * 2
    end
    decay.tap do |sp|
      base = attack
      sp.w, sp.h = base.w, base.h
      sp.x, sp.y = base.right + margin, base.y
    end
    sustain.tap do |sp|
      base = decay
      sp.w, sp.h = base.w, base.h
      sp.x, sp.y = base.right + margin, base.y
    end
    release.tap do |sp|
      base = sustain
      sp.w, sp.h = base.w, base.h
      sp.x, sp.y = base.right + margin, base.y
    end

    keyboard.tap do |sp|
      sp.x, sp.y = room_x + 20, room_y + height - 50
      sp.w, sp.h = width - 40, 16
    end
  end
end

def define_rooms()
  rooms = []
  #rooms.push StepSequencer.new(0, 0)
  rooms.push Room.new(0, 0).tap {|r|
    r.t 0,  80, center: true, size: 16, str: '2D ゲームエンジンを MIDI 入力に対応させたので'
    r.t 0, 110, center: true, size: 16, str: 'シンセサイザーを作りたい話'
    r.t 0, 180, center: true, size: 10, str: '@tokujiros'
  }
  rooms.push Room.new(1, 0).tap {|r|
    r.t 30,  40, size: 16, str: '自己紹介'
    r.i loadImage(project.project_dir + '/face.png'), 40, 60, 64, 64
    r.t  40, 154, size: 20, str: '@tokujiros'
    r.t  40, 180, size: 12, str: 'x.com/tokujiros'
    r.t  40, 200, size: 12, str: 'github.com/xord'
    r.t 150,  70, str: '好きな言語は Ruby と C++'
    r.t 150, 100, str: '最近はサウンド周りの実装が楽しい'
  }
  rooms.push Room.new(2, 0).tap {|r|
    r.t 30,  40, size: 16, str: '2D レトロゲームエンジン Reight (R8)'
    r.t 30,  70, str: '  - ドット絵の低解像度ゲームが簡単に作れる'
    r.t 30, 100, str: '  - 8ビットサウンドも簡単に鳴らせる'
  }
  rooms.push Room.new(3, 0).tap {|r|
    r.t 30,  40, str: 'サウンド周りの実装'
    r.t 30, 70, str: '  - サウンドの再生 OpenAL'
    r.t 30, 100, str: '  - 音声信号処理 Synthesis ToolKit'
    r.t 30, 130, str: '  - Processor を繋げて信号処理を作成'
    r.t 30, 150, str: '    - Generator (Oscillator, Sequencer, FileIn, MicIn)'
    r.t 30, 170, str: '    - Filter (Gain, Mixer, Envelope, LPF, HPF, ...)'
    r.t 30, 200, str: '  - https://github.com/xord/beeps'
  }
  rooms.push Room.new(4, 0).tap {|r|
    r.t 30,  40, str: '利用例'
    r.t 30,  70, str: ' - o, e, g = Oscillator.new, Envelope.new, Gain.new'
    r.t 30, 100, str: ' - Sound.new(o >> e >> g).play'
  }
  rooms.push Synth.new(5, 0)
end

class Game
  def initialize()
    @sprites = []
    @rooms   = define_rooms.each.with_object({}) {|room, h|
      h[[room.xindex, room.yindex]] = room
    }
    gravity 0, 1000
  end

  def room()
    pos = screen_pos
    @rooms[[pos.x.to_i, pos.y.to_i]]
  end

  def screen_pos()
    create_vector(
      (player.x / width) .to_i,
      (player.y / height).to_i)
  end

  def offset_screen()
    pos    = screen_pos
    pos.x *= width
    pos.y *= height

    so = screen_offset
    screen_offset so + (pos - so) * 0.1

    so = screen_offset
    translate -so.x, -so.y
  end

  def draw_sprites()
    so = screen_offset
    sprite stage.sprites_at(so.x, so.y, width, height) {|actives, inactives|
      actives.each {add_sprite _1}
      inactives.each {remove_sprite _1}
    }
    sprite player, *@sprites
  end

  def draw_rooms()
    @rooms.each_value {_1.draw}
  end

  def draw()
    background 0
    push do
      offset_screen
      draw_sprites
      draw_rooms
    end
    text frame_rate.to_i, width - 32, 24
  end

  def key_down(code)
    case code
    when UP
      if player[:jump] < 2
        player.vy = -400
        #player[:jump] += 1
      end
    when :z
      dir = player[:dir] < 0 ? -1 : 1
      shoot player.pos, create_vector(dir * 200, 0)
    when :x
      dir = player[:dir] < 0 ? -1 : 1
      place_bomb player.center
    end
  end

  def note_pressed(...)
    room&.note_pressed(...)
  end

  def note_released(...)
    room&.note_released(...)
  end

  def control_change(...)
    room&.control_change(...)
  end

  def player()
    @player ||= project.chips.at(0, 24, 8, 8).sprite.tap do |sp|
      sp.center  = create_vector width / 2, height / 2
      sp.dynamic = true
      add_sprite sp

      sp[:dir]  = 1
      sp[:jump] = 0
      sp.update do
        sp.vx += 20 if key_is_down RIGHT
        sp.vx -= 20 if key_is_down LEFT
        sp.vx *= 0.9
        sp[:dir] = sp.vx if sp.vx != 0
      end

      sp.contact do
        sp[:jump] = 0
      end

      anim = 0
      set_interval(0.3) do
        sp.ox = anim % 2 == 0 ? 0 : 8
        anim += 1
      end
    end
  end

  def shoot(center, vel)
    project.chips.at(0, 32, 8, 8).to_sprite.tap do |sp|
      sp.center        = center
      sp.dynamic       = true
      sp.sensor        = true
      sp.vel           = vel
      sp.gravity_scale = 0
      add_sprite @sprites, sp
      sp.contact {|o|
        next if o.chip.y != 0
        remove_sprite @sprites, sp
        remove_sprite stage.sprites, o
      }
      project.sounds[0].play
    end
  end

  def place_bomb(center)
    project.chips.at(0, 40, 8, 8).to_sprite.tap do |sp|
      sp.center  = center
      sp.dynamic = true
      add_sprite @sprites, sp
      anim = 0
      timer = set_interval 0.1 do
        sp.ox = anim % 2 == 0 ? 0 : 8
        anim += 1
      end
      set_timeout 2 do
        clear_interval timer
        remove_sprite @sprites, sp
        20.times do
          explosion sp.center
        end
      end
      project.sounds[1].play
    end
  end

  def explosion(center)
    project.chips.at(16, 40, 8, 8).to_sprite.tap do |sp|
      sp.center        = center + Vector.random2D * rand(5..20)
      sp.dynamic       = true
      sp.sensor        = true
      sp.gravity_scale = 0
      add_sprite @sprites, sp
      sp.draw do |&draw|
        translate -sp.w * 2, -sp.h * 2
        scale 4, 4
        draw.call
      end
      sp.contact do |o|
        next if o.chip.y != 0
        remove_sprite stage.sprites, o
      end
      anim = rand(0..4)
      timer = set_interval 0.02 do
        sp.ox = 16 + anim % 5 * 8
        anim += 1
      end
      set_timeout rand(0.1..0.4) do
        clear_interval timer
        remove_sprite @sprites, sp
      end
      project.sounds[2].play
    end
  end

  def stage()
    @stage = project.maps[1]
  end
end

def put_stage_frames()
  w, h, count = width, height, 10
  m           = project.maps[1]
  bricks      = [0, 8].map {|x| project.chips.at(x, 0, 8, 8)}
  count.times do |cx|
    count.times do |cy|
      (0...w).step 8 do |x|
        m.put w * cx + x,       h * cy,           bricks.sample rescue nil
      end
      (0...w).step 8 do |x|
        m.put w * cx + x,       h * (cy + 1) - 8, bricks.sample rescue nil
      end
      (0...h).step 8 do |y|
        m.put w * cx,           h * cy + y,       bricks.sample rescue nil
      end
      (0...h).step 8 do |y|
        m.put w * (cx + 1) - 8, h * cy + y,       bricks.sample rescue nil
      end
    end
  end
end

def put_stage_grasses()
  w, h, count = width, height, 10
  m           = project.maps[1]
  bricks      = [0, 8, 16].map {|x| project.chips.at(64 + x, 0, 8, 8)}
  xs, ys      = (0...w).step(8).to_a, (0...h).step(8).to_a
  count.times do |cx|
    count.times do |cy|
      10.times do
        m.put w * cx + xs.sample, h * cy + ys.sample, bricks.sample rescue nil
      end
    end
  end
end

setup          {$game = Game.new}#; put_stage_grasses}
draw           {$game&.draw}
key_pressed    {$game&.key_down key_code unless key_is_repeated}
note_pressed   {$game.note_pressed note_number, note_frequency, note_velocity}
note_released  {$game.note_released note_number}
control_change {$game.control_change controller_index, controller_value}
