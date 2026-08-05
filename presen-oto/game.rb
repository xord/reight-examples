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

class SynthRoom < Room

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
    mod0 = B::Oscillator.new(
             freq:   osc_modulation(0)[:value].clamp(1..),
             offset: frequency,
             gain:   note2freq(12) * osc_modulation(0)[:value])
    osc0 = B::Oscillator.new(
                   osc_type(0)[:type],
             duty: osc_duty(0)[:value],
             gain: osc_gain(0)[:value],
             freq: mod0)
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
    super
    sprite osc_type(0), osc_gain(0), osc_duty(0),   osc_modulation(0)
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
    when 3  then osc_gain(0)[:value]       = value
    when 9  then osc_duty(0)[:value]       = map value, 0.0, 1.0, 0.01, 0.99
    when 12 then osc_modulation(0)[:value] = map value, 0.0, 1.0, 0, 12

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
    when 27 then volume[:value]  = value
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

  def osc_modulation(index = 0)
    (@osc_modulations ||= [])[index] ||= Sprite.new(physics: false).tap do |sp|
      add_sprite sp
      setup_value_control sp, 'Mod'
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
    margin = 4

    osc_type(0).tap do |sp|
      sp.w, sp.h = 24, 16
      sp.x, sp.y  = room_x + 40, room_y + 56
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
    osc_modulation(0).tap do |sp|
      base = osc_duty(0)
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
end# SynthRoom

class DrumRoom < Room

  def initialize(...)
    super
    @kick, @snare1, @snare2, @lotom, @midtom, @hitom, @close_hihat, @open_hihat, @crash =
      %w[Kick Snare1 Snare2 LoTom MidTom HiTom PedalHiHat OpenHiHat Crash]
        .map {loadSound project.project_dir + '/' + _1 + '.wav'}
  end

  def draw()
    super
    sprite pads
  end

  def note_pressed(note, frequency, velocity)
    pads[note - 60].play velocity if velocity > 0
  end

  def pads()
    @pads ||= (0..3).to_a.product((0..3).to_a).map do |y, x|
      Sprite.new(physics: false).tap do |sp|
        add_sprite sp
        margin, size = 2, 16
        sp.x         = room_x + 300 +       x  * (size + margin)
        sp.y         = room_y + 120  + (3 - y) * (size + margin)
        sp.w = sp.h  = size
        sp[:color]   = 0
        sp[:sound]   = case [x, y]
                       in [1, 3] then @hitom
                       in [2, 3] then @hitom
                       in [1, 2] then @lotom
                       in [2, 2] then @midtom
                       in [_, 0] then @kick
                       in [_, 1] then @open_hihat
                       in [_, 2] then @close_hihat
                       in [_, 3] then @crash
                       end
        sp.mouse_pressed {sp.play}
        sp.draw {
          fill 150 + 100 * sp[:color]
          sp[:color] *= 0.9
          rect 0, 0, sp.w, sp.h, 2
        }
        def sp.play(velocity = 1)
          self[:sound]&.play gain: velocity
          self[:color] = 1
        end
      end
    end
  end
end# DrumRoom

class WarpRoom < Room
  def initialize(...)
    super
    update_layout
  end

  def draw()
    sprite warps
    warps.each.with_index do |warp, i|
      fill 255
      text_align CENTER, TOP
      text i + 1, warp.x - warp.w, warp.y - 40, warp.w * 2, warp.h
    end
  end

  def warps()
    @warps ||= 9.times.map do |i|
      project.chips.at(0, 56, 8, 8).to_sprite.tap do |sp|
        add_sprite sp
        sp.sensor = true
        sp.contact do |o|
          o.warp i
        end
        sp.draw do |&draw|
          translate  -sp.w,  -sp.h
          scale 2, 2
          draw.call
        end
        set_interval 0.1 do
          sp.angle -= TAU / 20
        end
      end
    end
  end

  def update_layout()
    warps.each.with_index do |sp, i|
      sp.w = sp.h = 8
      sp.x, sp.y  = room_x + 30 + i * width / 10, room_y + 150
    end
  end
end

def define_rooms()
  rooms = []
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
    r.t 150,  70, str: '2Dレトロゲームエンジンを作ってます'
    r.t 150, 100, str: '好きな言語は Ruby と C++'
    r.t 150, 130, str: '最近はサウンド周りの実装が楽しい'
  }
  rooms.push Room.new(2, 0).tap {|r|
    r.t 30,  40, size: 16, str: '2D レトロゲームエンジン Reight (R8)'
    r.t 30,  70, str: '  - ドット絵の低解像度のレトロ風ゲームが簡単に作れる'
    r.t 30, 100, str: '  - ゲームロジックを Ruby で書ける'
    r.t 30, 130, str: '  - スプライト、マップエディターなど組み込み'
    r.t 30, 160, str: '  - 8ビットサウンドも簡単に鳴らせる'
  }
  rooms.push DrumRoom.new(3, 0).tap {|r|
    r.t 30,  40, str: '最近 MIDI 入力に対応した'
    r.t 30,  70, str: '  - RtMidi を利用'
    r.t 30, 100, str: '  - MIDI キーボードやPADコントローラーで音が鳴らせる'
    r.t 30, 130, str: '  - ノブをグリグリ回して音を調節できる'
    r.t 30, 160, str: '  - 専用ハードウェア楽しい'
  }
  rooms.push Room.new(4, 0).tap {|r|
    r.t 30,  40, str: 'サウンド周りの実装'
    r.t 30,  70, str: '  - サウンドの再生 OpenAL'
    r.t 30, 100, str: '  - 音声信号処理 Synthesis ToolKit'
    r.t 30, 130, str: '  - Processor を繋げて信号処理を作成'
    r.t 30, 150, str: '    - Generator (Oscillator, Sequencer, FileIn, MicIn)'
    r.t 30, 170, str: '    - Filter (Gain, Mixer, Envelope, LPF, HPF, ...)'
    r.t 30, 200, str: '  - https://github.com/xord/beeps'
  }
  rooms.push Room.new(5, 0).tap {|r|
    r.t 30,  40, str: '使い方'
    r.t 30,  70, str: '   o, e, g = Oscillator.new, Envelope.new, Gain.new'
    r.t 30, 100, str: '   src = o >> e >> g'
    r.t 30, 130, str: '   Sound.new(src).play'
  }
  rooms.push SynthRoom.new(6, 0).tap {|r|
    r.t 30, 30,           str: 'シンセサイザーを作ってみた'
    r.t 30, 44, size: 12, str: 'LFO >> Oscillator >> Mixer >> LPF >> Envelope >> Gain'
  }
  rooms.push Room.new(7, 0).tap {|r|
    r.t 30,  40,           str: '参考'
    r.t 30,  70,           str: '- ゲームエンジン'
    r.t 30,  84, size: 12, str: '    https://github.com/xord/reight'
    r.t 30, 110,           str: '- ゲームエンジン サンプルゲーム集'
    r.t 30, 124, size: 12, str: '    https://github.com/xord/reight-examples'
    r.t 30, 150,           str: '- サウンドライブラリー'
    r.t 30, 164, size: 12, str: '    https://github.com/xord/beeps'
    r.t 30, 190,           str: '- ゼロからの、レトロゲームエンジンの作り方'
    r.t 30, 204, size: 12, str: '    https://tinyurl.com/3dbzd6aj'
  }
  rooms.push Room.new(8, 0).tap {|r|
    r.t 0,  100, center: true, size: 16, str: 'O W A R I'
  }
  rooms.push WarpRoom.new(0, 1)
end

class Game
  def initialize()
    @sprites = []
    @rooms   = define_rooms.each.with_object({}) {|room, h|
      h[[room.xindex, room.yindex]] = room
    }
    set_title '【 RubyKaigi 2025 事後勉強会 oto 】   2D ゲームエンジンを MIDI 入力に対応させたのでシンセサイザーを作りたい話 (tokujiros)'
    gravity 0, 1000
  end

  attr_reader :prev_room

  def current_room()
    pos  = screen_pos
    room = @rooms[[pos.x.to_i, pos.y.to_i]]
    if room != @current_room
      @prev_room    = @current_room
      @current_room = room
    end
    room
  end

  def shake(size = 20)
    @shake = size
  end

  def screen_pos()
    create_vector(
      (player.x / width) .to_i,
      (player.y / height).to_i)
  end

  def shake_screen()
    return if !@shake || @shake <= 0
    vec = Vector.random2D * @shake
    translate vec.x, vec.y
    @shake = @shake > 1 ? @shake * 0.9 : 0
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
    prev_room&.draw
    current_room&.tap do |room|
      room.draw
      fill 100
      text_size 10
      text "#{screen_pos.x.to_i + 1}", room.room_x + width - 20, room.room_y + 20
    end
  end

  def draw()
    background 0
    push do
      shake_screen
      offset_screen
      draw_rooms
      draw_sprites
    end
    #text_size 8
    #text frame_rate.to_i, width - 20, 32
  end

  def key_down(code)
    case code
    when *jump_keys
      if player[:jump] == 0
        player.vy = -400
        player[:jump] += 1
        project.sounds[4].play gain: 0.3
      end
    when *shot_keys
      dir = player[:dir] < 0 ? -1 : 1
      shoot player.center, create_vector(dir * 200, 0)
    when *bomb_keys
      dir = player[:dir] < 0 ? -1 : 1
      place_bomb player.center
    when :'1' then player.warp 0
    when :'2' then player.warp 1
    when :'3' then player.warp 2
    when :'4' then player.warp 3
    when :'5' then player.warp 4
    when :'6' then player.warp 5
    when :'7' then player.warp 6
    when :'8' then player.warp 7
    when :'9' then player.warp 8
    when :'0' then player.warp 9
    end
  end

  def note_pressed(...)
    current_room&.note_pressed(...)
  end

  def note_released(...)
    current_room&.note_released(...)
  end

  def control_change(...)
    current_room&.control_change(...)
  end

  def   left_keys = [LEFT,  :gamepad_left]
  def  right_keys = [RIGHT, :gamepad_right]
  def   jump_keys = [UP,    :gamepad_button_1]
  def crouch_keys = [DOWN,  :gamepad_down]
  def   shot_keys = [:z,    :gamepad_button_0]
  def   bomb_keys = [:x,    :gamepad_button_3]

  def   left_key? =   left_keys.any? {key_is_down _1}
  def  right_key? =  right_keys.any? {key_is_down _1}
  def   jump_key? =   jump_keys.any? {key_is_down _1}
  def crouch_key? = crouch_keys.any? {key_is_down _1}
  def   shot_key? =   shot_keys.any? {key_is_down _1}
  def   bomb_key? =   bomb_keys.any? {key_is_down _1}

  def player()
    @player ||= project.chips.at(0, 24, 8, 8).sprite.tap do |sp|
      add_sprite sp
      sp.center  = create_vector width / 2, height / 2
      sp.dynamic = true

      sp[:dir]  = 1
      sp[:jump] = 0
      sp.update {
        sp.vx -= 20 if  left_key?
        sp.vx += 20 if right_key?
        sp.vx *= 0.9
        sp.vy -= 30 if sp[:jump] > 0 && sp.vy > -100 && jump_key?
        sp[:dir] = sp.vx if sp.vx != 0
      }
      sp.draw {|&draw|
        if sp.vx < 0
          scale -1, 1
          translate -sp.w, 0
        end
        draw.call
      }
      sp.contact {|o|
        sp[:jump] = 0 if o.chip&.y == 0
      }
      anim = 0
      set_interval(0.1) {
        sp.ox = case
          when crouch_key?                then 32
          when jump_key? && sp[:jump] > 0 then anim % 2 == 0 ? 40 : 48
          when sp.vx.abs > 3              then anim % 2 == 0 ? 16 : 24
          else                                 anim % 2 == 0 ? 0 : 8
          end
        anim += 1
      }
      def sp.warp(page)
        self. x, self. y = $game.width * page + $game.width / 2, $game.height / 2
        self.vx, self.vy = 0, -200
      end
    end
  end

  def shoot(center, vel)
    project.chips.at(0, 34, 8, 2).to_sprite.tap do |sp|
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
        project.sounds[3].play
        shake 3
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
        explosion sp.center
      end
      project.sounds[1].play
    end
  end

  def explosion(center, count = 20)
    count.times do
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
      end
      project.sounds[2].play
      shake 10
    end
  end

  def stage()
    @stage = project.maps[0]
  end
end

def put_stage_frames()
  w, h, count = width, height, 10
  m           = project.maps[0]
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

setup          {$game = Game.new}#; put_stage_frames}
draw           {$game&.draw}
key_pressed    {$game&.key_down key_code unless key_is_repeated}
note_pressed   {$game.note_pressed note_number, note_frequency, note_velocity}
note_released  {$game.note_released note_number}
control_change {$game.control_change controller_index, controller_value}
