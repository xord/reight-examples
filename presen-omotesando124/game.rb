# -*- coding: utf-8 -*-

require 'reflex-terminal'

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
end

class TextbringerRoom < Room
  MARGIN = 24

  def draw()
    super
    @terminal_view ||= Reflex::TerminalView.new(font_size: 10).tap do |v|
      v.frame = [
        room_x + MARGIN,
        room_y + MARGIN,
        width - MARGIN * 2,
        height - MARGIN * 2
      ]
      v.after(:on_pointer_down) {|e| e.block}
      v.after(:on_attach) do |e|
        v.terminal.default_background_color = [0.4, 0.5]
        v.terminal.write "simplify_prompt\nclear\n"
      end
      v.after(:on_key_down) do |e|
        case [e.code, e.modifiers]
        when [Reflex::KEY_UP,   [:command]] then v.font_size += 2
        when [Reflex::KEY_DOWN, [:command]] then v.font_size -= 2
        end
      end
      # the world's view is scrolled by screen_offset, so a child of it
      # tracks the camera without mirroring the transform here
      spriteWorld__.getInternal__.add v
    end
  end
end

def define_rooms()
  rooms = []
  rooms.push Room.new(0, 0).tap {|r|
    r.t 0,  80, center: true, size: 16, str: 'libghostty-vt と自作 GUI ライブラリーで'
    r.t 0, 110, center: true, size: 16, str: '夢の自作ターミナル生活'
    r.t 0, 180, center: true, size: 10, str: '@tokujiros'
  }
  rooms.push Room.new(1, 0).tap {|r|
    r.t 30,  40, size: 16, str: '自己紹介'
    r.i loadImage(project.project_dir + '/face.png'), 40, 60, 64, 64
    r.t  40, 154, size: 20, str: '@tokujiros'
    r.t  40, 180, size: 12, str: 'x.com/tokujiros'
    r.t  40, 200, size: 12, str: 'github.com/xord'
    r.t 150,  70, size: 12, str: '2Dレトロゲームエンジンを作ってます'
    r.t 150,  84, size: 8,  str: ' https://github.com/xord/reight'
    r.t 150, 110, size: 12, str: 'GUI ライブラリーも作ってます'
    r.t 150, 124, size: 8,  str: ' https://github.com/xord/reflex'
    r.t 150, 150, size: 12, str: 'ほかにも色々作ってます'
    r.t 150, 164, size: 8,  str: '  - サウンドエンジン'
    r.t 150, 178, size: 8,  str: '  - Processing Gem'
    r.t 150, 192, size: 8,  str: '  - CRuby CocoaPod などなど'
  }
  rooms.push Room.new(2, 0).tap {|r|
    r.t 30,  40, size: 16, str: '自作 GUI ライブラリー'
    r.t 30,  70, str: '  - Window に View のツリーを構成するよくある形'
    r.t 30, 100, str: '  - ゲームエンジンのベースにも利用'
    r.t 30, 130, str: '  - 作り始めてもう15年くらい'
  }
  rooms.push Room.new(3, 0).tap {|r|
    r.t 30,  40, size: 16, str: 'libghostty-vt とは'
    r.t 30,  70, str: '  - 最近人気の Ghostty ターミナルの'
    r.t 30,  90, str: '     端末エミュレーション部分を切り出したライブラリー'
    r.t 30, 120, str: '  - VTコア部分・エスケープ解析・画面状態・スクロールバック'
    r.t 30, 150, str: '  - エスケープシーケンスの解釈を自前で書くのは沼'
  }
  rooms.push Room.new(4, 0).tap {|r|
    r.t 30,  40, size: 16, str: '自作ターミナル'
    r.t 30,  70,           str: '  - libghostty-vt で Terminal クラスを実装'
    r.t 30,  85, size: 10, str: '       → ヘッドレス端末エミュレーション'
    r.t 30, 110,           str: '  - GUI ライブラリーに TerminalView を追加'
    r.t 30, 140,           str: '  - Terminal クラスを TerminalView で表示'
    r.t 30, 170,           str: '  - Mac / Windows / Linux で動作確認'
    r.t 30, 200,           str: '  - Emacs, Textbringer, herdr などが一応動いている'
  }
  rooms.push TextbringerRoom.new(5, 0)
  rooms.push Room.new(6, 0).tap {|r|
    r.t 30,  40,           str: '参考'
    r.t 30,  70,           str: '- Terminal/TerminalView を実装したリポジトリ'
    r.t 30,  84, size: 12, str: '    https://github.com/xord/reflex-terminal'
    r.t 30, 110,           str: '- このプレゼンのソースコード'
    r.t 30, 124, size: 12, str: '    https://github.com/xord/reight-examples'
    r.t 30, 150,           str: '- ゼロからの、レトロゲームエンジンの作り方'
    r.t 30, 164, size: 12, str: '    https://tinyurl.com/3dbzd6aj'
  }
  rooms.push Room.new(7, 0).tap {|r|
    r.t 0,  100, center: true, size: 16, str: 'O W A R I'
  }
end

class Game
  def initialize()
    pixel_density :auto
    @sprites = []
    @rooms   = define_rooms.each.with_object({}) {|room, h|
      h[[room.xindex, room.yindex]] = room
    }
    set_title '【 Omotesando.rb #124 】 夢の自作ターミナル生活  (@tokujiros)'
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
      add_sprite sp, to: @sprites
      sp.contact {|o|
        next if o.chip.y != 0
        remove_sprite sp, from: @sprites
        remove_sprite o,  from: stage.sprites
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
      add_sprite sp, to: @sprites
      anim = 0
      timer = set_interval 0.1 do
        sp.ox = anim % 2 == 0 ? 0 : 8
        anim += 1
      end
      set_timeout 2 do
        clear_interval timer
        remove_sprite sp, from: @sprites
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
        add_sprite sp, to: @sprites
        sp.draw do |&draw|
          translate -sp.w * 2, -sp.h * 2
          scale 4, 4
          draw.call
        end
        sp.contact do |o|
          next if o.chip.y != 0
          remove_sprite o, from: stage.sprites
        end
        anim = rand(0..4)
        timer = set_interval 0.02 do
          sp.ox = 16 + anim % 5 * 8
          anim += 1
        end
        set_timeout rand(0.1..0.4) do
          clear_interval timer
          remove_sprite sp, from: @sprites
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

setup         {$game = Game.new}#; put_stage_frames}
draw          {$game&.draw}
key_pressed   {$game&.key_down key_code unless key_is_repeated}
mouse_pressed {}
