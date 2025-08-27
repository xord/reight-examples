# -*- coding: utf-8 -*-

class Room
  def initialize(game, xi, yi)
    @game, @xindex, @yindex          = game, xi, yi
    @texts, @lines, @curves, @images = [], [], [], []
  end

  attr_reader :xindex, :yindex

  def room_x()
    width * @xindex
  end

  def room_y()
    height * @yindex
  end

  def t(x, y, font, str:, center: false)
    @texts.push [str, x, y, font, center]
  end

  def l(x1, y1, x2, y2, color: nil, weight: 1)
    @lines.push [x1, y1, x2, y2, color, weight]
  end

  def c(x1, y1, x2, y2, x3, y3, x4, y4, color: nil, weight: 1)
    @curves.push [x1, y1, x2, y2, x3, y3, x4, y4, color, weight]
  end

  def i(x, y, w = nil, h = nil, img:)
    w ||= img.width
    h ||= img.height
    @images.push [img, x, y, w, h]
  end

  def draw()
    @font_sizes ||= {
      @game.regular_10 => 10,
      @game.regular_12 => 12,
      @game.bold_10    => 10,
      @game.bold_12    => 12
    }
    rx, ry = room_x, room_y
    @images.each do |(img, x, y, w, h)|
      image img, rx + x, ry + y, w, h
    end
    no_fill
    @lines.each do |(x1, y1, x2, y2, color, weight)|
      stroke(*color)
      stroke_weight(weight || 1)
      line rx+x1, ry+y1, rx+x2, ry+y2
    end
    @curves.each do |(x1, y1, x2, y2, x3, y3, x4, y4, color, weight)|
      stroke(*color)
      stroke_weight(weight || 1)
      curve rx+x1, ry+y1, rx+x2, ry+y2, rx+x3, ry+y3, rx+x4, ry+y4
    end
    fill 255
    no_stroke
    @texts.each do |(str, x, y, font, center)|
      size = @font_sizes[font]
      text_font font, size
      text_align center ? CENTER : LEFT
      if center
        text str, rx,     ry + y, width, size
      else
        draw_colored_text str, rx + x, ry + y
      end
    end
  end

  def draw_colored_text(str, x, y)
    xx = 0
    str.split('**').each.with_index do |s, i|
      fill(*(i % 2 == 0 ? 255 : [243, 186, 3]))
      text s, x + xx, y
      xx += text_width s
    end
  end
end

class PlaygroundRoom < Room
  def draw()
    super
    text_font @game.bold_12, 12
    fill 255
    text "SCORE: #{@game.score}", room_x + width - 100, room_y + 30
  end
end

def define_rooms(game)
  r10, r12, b10, b12 = game.regular_10, game.regular_12, game.bold_10, game.bold_12
  face               = loadImage(project.project_dir + '/face.png')
  editors            = loadImage(project.project_dir + '/editors.png')

  rooms  = []
  xindex = 0
  rooms.push Room.new(game, xindex, 0).tap {|r|
    r.t 0,  50, b12, center: true, str: 'P r o c e s s i n g  G e m  ベ ー ス の'
    r.t 0,  80, b12, center: true, str: '2 D レ ト ロ ゲ ー ム エ ン ジ ン の 開 発'
    r.t 0, 140, r10, center: true, str: 'Ruby Association Activity Report'
    r.t 0, 160, r10, center: true, str: '2025 / 8 / 28'
    r.t 0, 180, r10, center: true, str: '@tokujiros'
  }
  xindex += 1
  rooms.push Room.new(game, xindex, 0).tap {|r|
    r.t 20,  30, b12, str: '全体の流れ'
    r.t 30,  60, r10, str: '・レトロゲームエンジン **Reight** の紹介'
    r.t 30,  80, r10, str: '・レトロゲームエンジン **Reight** でのゲーム開発の実演'
    r.t 30, 100, r10, str: '・今後の予定について'
  }
  xindex += 1
  rooms.push Room.new(game, xindex, 0).tap {|r|
    r.t  20,  30, b12, str: '自己紹介'
    r.i  30,  50, 64, 64, img: face
    r.t  30, 135, r12, str: '@tokujiros'
    r.t  30, 165, r10, str: 'x.com/tokujiros'
    r.t  30, 185, r10, str: 'github.com/xord'
    r.t 140,  40, r10, str: 'テキストエディター作りたい！（約20年前）'
    r.t 140,  55, r10, str: ' ↓'
    r.t 140,  70, r10, str: 'GUIライブラリーから作り始める'
    r.t 140,  85, r10, str: ' ↓'
    r.t 140, 100, r10, str: 'グラフィックスエンジン自作（OpenGLラッパー）'
    r.t 140, 115, r10, str: ' ↓'
    r.t 140, 130, r10, str: 'Processing互換ライブラリー化'
    r.t 140, 145, r10, str: ' ↓'
    r.t 140, 160, r10, str: 'オーディオエンジンも自作（OpenALラッパー）'
    r.t 140, 175, r10, str: ' ↓'
    r.t 140, 190, r10, str: 'ゲームエンジン化（← いまここ）'
  }
  xindex += 1
  rooms.push Room.new(game, xindex, 0).tap {|r|
    r.t 20,  30, b12, str: 'プロジェクト概要'

    r.t 30,  60, r10, str: '昨年度採択された「CRuby 用 Processing Gem の、本家 Processing との'
    r.t 30,  80, r10, str: '互換性向上に向けた取り組み」を基に、その成果物である Processing Gem'
    r.t 30, 100, r10, str: 'を活用し、**新たに 2Dレトロゲームエンジンを開発する**。'
  }
  xindex += 1
  rooms.push Room.new(game, xindex, 0).tap {|r|
    r.t 20,  30, b12, str: '成果物としてのレトロゲームエンジン **Reight** の紹介 (1)'
    r.t 30,  60, r10, str: '・レトロ風な 2D ゲームを手軽に作って遊ぶことができるアプリ'
    r.t 30,  80, r10, str: '　・ゲームを Ruby でプログラミングできる'
    r.t 30, 100, r10, str: '・グラフィックス周りは、広く知られた Processing API と互換'
    r.t 30, 120, r10, str: '　・2D のゲームやインタラクティブなアプリを作るのに必要十分な機能を持つ'
    r.t 30, 140, r10, str: '　・Processing の学習リソースがほぼそのまま使える'
    r.t 30, 160, r10, str: '・効果音も手軽に作れて鳴らすのも簡単'
  }
  xindex += 1
  rooms.push Room.new(game, xindex, 0).tap {|r|
    r.t  20,  30, b12, str: '成果物としてのレトロゲームエンジン **Reight** の紹介 (2)'
    r.t  30,  60, r10, str: '・2D ゲームを手軽に作れる**統合開発環境**'
    r.t  30,  80, r10, str: '　・**スプライト**エディター'
    r.t  30, 100, r10, str: '　・**マップ**エディター'
    r.t  30, 120, r10, str: '　・**サウンド**エディター'
    r.i 170, 100, img: editors
  }
  xindex += 1
  rooms.push Room.new(game, xindex, 0).tap {|r|
    r.t 20,  30, b12, str: '成果物としてのレトロゲームエンジン **Reight** の紹介 (3)'
    r.t 30,  60, r10, str: '・ファミコンからスーパーファミコン世代風のゲームが手軽に作れる'
    r.t 30,  80, r10, str: '　・低解像度グラフィックとピコピコサウンド'
    r.t 30, 100, r10, str: '・ゲーム制作の敷居が低い'
    r.t 30, 120, r10, str: '　・色数や解像度などが意図的に制限されており、ゲームデザイン'
    r.t 30, 140, r10, str: '　　そのものに集中できる'
    r.t 30, 160, r10, str: '　・ゲームを作りやすく、完成させやすい'
  }
  xindex += 1
  rooms.push Room.new(game, xindex, 0).tap {|r|
    r.t 20,  30, b12, str: '成果物としてのレトロゲームエンジン **Reight** の紹介 (4)'
    r.t 30,  60, r10, str: '・ゲームエンジン全体も Ruby で実装'
    r.t 30,  80, r10, str: '・対応プラットフォームは Mac、Windows など'
    r.t 30, 100, r10, str: '　・gem install reight でインストール可能'
  }
  xindex += 1
  rooms.push PlaygroundRoom.new(game, xindex, 0).tap {|r|
    r.t 20,  30, b12, str: 'ゲーム開発の実演'
  }
  xindex += 1
  rooms.push Room.new(game, xindex, 0).tap {|r|
    r.t 20,  30, b12, str: '今後の予定 (1)'
    r.t 30,  60, r10, str: 'ゲーム実行環境のブラウザー（WebAssembly）対応'
    r.t 30,  80, r10, str: '　・ゲームエンジンで制作したゲームを手軽に配布可能に'
    r.t 30, 100, r10, str: '　　・URL を共有するだけで遊んでもらえる'
    r.t 30, 120, r10, str: '　・ruby.wasm は Emscripten 版を利用予定'
    r.t 30, 140, r10, str: '　　・WASI 版は OpenGL に対応していないとのこと'
  }
  xindex += 1
  rooms.push Room.new(game, xindex, 0).tap {|r|
    r.t 20,  30, b12, str: '今後の予定 (2)'
    r.t 30,  60, r10, str: 'エンジン自体のアプリ化'
    r.t 30,  80, r10, str: '　・現状ではコマンドラインから起動'
    r.t 30, 100, r10, str: '　・Mac、Windows のデスクトップアプリとしても公開したい'
    r.t 30, 120, r10, str: '　・インタープリターも組み込みにしてアプリをインストールするだけ'
    r.t 30, 140, r10, str: '　　・環境構築の敷居を下げる'
  }
  xindex += 1
  rooms.push Room.new(game, xindex, 0).tap {|r|
    r.t 20,  30, b12, str: '今後の予定 (3)'
    r.t 30,  60, r10, str: 'テキストエディターの搭載'
    r.t 30,  80, r10, str: '　・現状では、ゲームのソースコード編集は外部テキストエディター利用を'
    r.t 30, 100, r10, str: '　　前提としているが、将来的にはテキストエディターも搭載したい'
    r.t 30, 120, r10, str: '　・統合環境内でスクリプトを書き換えたらゲーム実行に即反映など'
  }
  xindex += 1
  rooms.push Room.new(game, xindex, 0).tap {|r|
    r.t 20,  30, b12, str: '今後の予定 (4)'
    r.t 30,  60, r10, str: 'Ruby でゲームを作ろう系コンテンツの作成'
    r.t 30,  80, r10, str: '　・ゲーム開発入門の記事や本、動画を作って公開したい'
    r.t 30, 100, r10, str: '　・ワークショップ等もやってみたい'
    r.t 30, 120, r10, str: '　・ゲーム制作は楽しいのでぜひ広めたい'
    r.t 30, 140, r10, str: '　・（ただしエンジンの仕様がある程度安定するまでは厳しい）'
  }
  xindex += 1
  rooms.push Room.new(game, xindex, 0).tap {|r|
    r.t 20,  30, b12, str: '参考'
    r.t 30,  60, r10, str: '- ゲームエンジン'
    r.t 30,  80, r10, str: '    https://github.com/xord/reight'
    r.t 30, 100, r10, str: '- ゲームエンジン サンプルゲーム集'
    r.t 30, 120, r10, str: '    https://github.com/xord/reight-examples'
    r.t 30, 140, r10, str: '- ゼロからの、レトロゲームエンジンの作り方'
    r.t 30, 160, r10, str: '    https://tinyurl.com/3dbzd6aj'
  }
  xindex += 1
  rooms.push Room.new(game, xindex, 0).tap {|r|
    r.t 0, 100, b12, center: true, str: 'E O P'
  }
end

class Game
  STATE_PATH = 'state.json'

  def initialize()
    load_fonts
    @score   = 0
    @sprites = []
    @rooms   = define_rooms(self).each.with_object({}) {|room, h|
      h[[room.xindex, room.yindex]] = room
    }
    set_title '【Ruby Association Activity Report 】    Processing Gem ベースの2D レトロゲームエンジンの開発 (tokujiros)'
    gravity 0, 1000

    if page = load[:room_xindex]
      set_timeout do
        player.warp page
        screen_offset page * width, 0
      end
    end
  end

  attr_accessor :score

  attr_reader :prev_room

  attr_reader :regular_10, :regular_12, :bold_10, :bold_12

  def load_fonts()
    @regular_10, @regular_12, @bold_10, @bold_12 = %w[10-Regular 12-Regular 10-Bold 12-Bold]
      .map {|type, size| load_font(project.project_dir + "/PixelMplus#{type}.ttf", smooth: false)}
  end

  def save()
    File.write STATE_PATH, {room_xindex: screen_index.x.to_i}.to_json
  end

  def load()
    JSON.parse(File.read(STATE_PATH), symbolize_names: true) rescue {}
  end

  def current_room()
    index = screen_index
    room  = @rooms[[index.x.to_i, index.y.to_i]]
    if room != @current_room
      @prev_room    = @current_room
      @current_room = room
      save
    end
    room
  end

  def last_room?()
    (player.x / width) >= @rooms.size - 1
  end

  def screen_index()
    x = (player.x / width) .to_i
    y = (player.y / height).to_i
    create_vector(x, last_room? ? 0 : y)
  end

  def shake(size = 20)
    @shake = size
  end

  def shake_screen()
    return if !@shake || @shake <= 0
    vec = Vector.random2D * @shake
    translate vec.x, vec.y
    @shake = @shake > 1 ? @shake * 0.9 : 0
  end

  def offset_screen()
    pos    = screen_index
    pos.x *= width
    pos.y *= height

    so = screen_offset
    screen_offset so + (pos - so) * 0.1

    so = screen_offset
    translate -so.x, -so.y
  end

  def draw_rooms()
    prev_room&.draw
    current_room&.tap do |room|
      room.draw
      fill 100
      text_size 10
      text "#{screen_index.x.to_i + 1}", room.room_x + width - 20, room.room_y + 20
    end
  end

  def draw_sprites()
    so = screen_offset
    sprite stage.sprites_at(
      so.x - 100, so.y - 100, width + 200, height + 200
    ) {|actives, inactives|
      actives.each {add_sprite _1}
      inactives.each {remove_sprite _1}
    }
    sprite player, *@sprites
  end

  def draw()
    shader background_shader.tap {|sh|
      sh.set :time, frame_count.to_f / 100.0
      sh.set :color1, 0.12, 0.12, 0.12,  1.0
      sh.set :color2, 0.15, 0.15, 0.15, 1.0
    }
    rect 0, 0, width, height
    shader nil

    push do
      shake_screen
      offset_screen
      draw_rooms
      draw_sprites
    end
  end

  def key_down(code)
    case code
    when *jump_keys
      if player[:jump] == 0
        player.vy = -400
        player[:jump] += 1
        project.sounds[0].play gain: 0.5
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
    when :lbracket then player.warp screen_index.x.to_i - 1
    when :rbracket then player.warp screen_index.x.to_i + 1
    end
  end

  def   left_keys = [LEFT,  :gamepad_left]
  def  right_keys = [RIGHT, :gamepad_right]
  def   jump_keys = [UP,    :gamepad_button_1, :gamepad_a, :gamepad_b]
  def crouch_keys = [DOWN,  :gamepad_down]
  def   shot_keys = [:z,    :gamepad_button_0, :gamepad_x]
  def   bomb_keys = [:x,    :gamepad_button_3, :gamepad_y]

  def   left_key? =   left_keys.any? {key_is_down _1}
  def  right_key? =  right_keys.any? {key_is_down _1}
  def   jump_key? =   jump_keys.any? {key_is_down _1}
  def crouch_key? = crouch_keys.any? {key_is_down _1}
  def   shot_key? =   shot_keys.any? {key_is_down _1}
  def   bomb_key? =   bomb_keys.any? {key_is_down _1}

  def player()
    @player ||= project.chips.at(0, 8, 8, 8).sprite.tap do |sp|
      add_sprite sp
      sp.center  = create_vector width / 2, height - 50
      sp.dynamic = true

      sp[:dir]     = 1
      sp[:jump]    = 0
      sp[:enlarge] = 0
      sp.update {
        sp.vx -= 20 if  left_key?
        sp.vx += 20 if right_key?
        sp.vx *= 0.9
        if sp[:jump] > 0 && sp.vy > -100 && jump_key?
          sp.vy -= 30
          project.sounds[7].play(gain: 0.3) if frame_count % 5 == 0
        end
        sp[:dir] = sp.vx if sp.vx != 0
      }
      sp.draw {|&draw|
        enlarge = sp[:enlarge]
        if enlarge > 0 && (!sp[:sick] || frame_count % 8 < 4)
          translate -sp.w * enlarge / 2, -sp.h * enlarge
          scale enlarge + 1, enlarge + 1
        end
        if sp.vx < 0
          scale -1, 1
          translate -sp.w, 0
        end
        draw.call
      }
      sp.contact {|o|
        ch = o.chip
        if ch.x == 64 && ch.y == 32
          #remove_sprite stage.sprites, o
          #@score += 10
          #project.sounds[11].play
        end
        if ch.x == 72 && ch.y == 32
          sp[:enlarge] += 1
          remove_sprite stage.sprites, o
          project.sounds[4].play
        end
        if ch.x == 80 && ch.y == 32
          sp[:sick] = true
          remove_sprite stage.sprites, o
          project.sounds[5].play
          set_timeout(2) do
            sp[:sick]    = false
            sp[:enlarge] = 0
            project.sounds[6].play
          end
        end
        if ch.x == 8 && ch.y == 32
          pos = sp.pos
          set_timeout(3) {firework pos.x, pos.y}
          set_timeout(0.3) {project.sounds[8].play}
        end
        sp[:jump] = 0 if ch&.y == 0
      }
      anim = 0
      set_interval(0.05) {
        sp.ox = case
          when sp[:sick] && frame_count % 8 < 4 then (anim / 1) % 2 == 0 ? 56 : 64
          when crouch_key?                then 32
          when jump_key? && sp[:jump] > 0 then (anim / 1) % 2 == 0 ? 40 : 48
          when sp.vx.abs > 3              then (anim / 2) % 2 == 0 ? 16 : 24
          else                                 (anim / 5) % 2 == 0 ? 0 : 8
          end
        anim += 1
      }
      def sp.warp(page)
        return if page < 0
        self. x, self. y = $game.width * page + $game.width / 2, $game.height - 20
        self.vx, self.vy = 0, -200
      end
    end
  end

  def shoot(center, vel)
    project.chips.at(0, 18, 8, 2).to_sprite.tap do |sp|
      sp.center        = center
      sp.dynamic       = true
      sp.sensor        = true
      sp.vel           = vel
      sp.gravity_scale = 0
      add_sprite @sprites, sp
      sp.contact {|o|
        next unless o.chip.y == 0 && o.chip.x < 32
        remove_sprite @sprites, sp
        remove_sprite stage.sprites, o
        project.sounds[3].play
        shake 3
      }
      project.sounds[1].play
    end
  end

  def place_bomb(center)
    project.chips.at(0, 24, 8, 8).to_sprite.tap do |sp|
      project.sounds[1].play

      add_sprite @sprites, sp
      sp.center  = center
      sp.dynamic = true

      anim  = 0
      timer = set_interval 0.1 do
        sp.ox = anim % 2 == 0 ? 0 : 8
        anim += 1
      end

      sp[:trigger_bomb] = proc do
        sp[:trigger_bomb] = nil
        clear_interval timer
        remove_sprite @sprites, sp
        explosion sp.center
      end

      set_timeout 3 do
        sp[:trigger_bomb]&.call
      end
    end
  end

  def explosion(center, count = 20)
    count.times do
      project.chips.at(24, 24, 8, 8).to_sprite.tap do |sp|
        sp.center        = center + Vector.random2D * rand(5..(last_room? ? 100 : 20))
        sp.dynamic       = true
        sp.sensor        = true
        sp.gravity_scale = 0
        add_sprite @sprites, sp
        sp.draw do |&draw|
          translate -sp.w * 2, -sp.h * 2
          (last_room? ? 10 : 4).tap {scale _1, _1}
          draw.call
        end
        sp.contact do |o|
          case
          when o.chip.y == 0    then remove_sprite stage.sprites, o
          when o[:trigger_bomb] then set_timeout(0.1) {o[:trigger_bomb]&.call}
          end
        end
        anim = rand(0..4)
        timer = set_interval 0.02 do
          sp.ox = 24 + anim % 5 * 8
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

  def firework(x, y, gain: 1, count: 0)
    gain = 0 if count > 5
    fire x, y, gain: gain
    project.sounds[9].play gain: 0.1 * gain
    set_timeout rand(1.0..3.0) do
      x = current_room.room_x + rand(10..(width - 10))
      firework x, y, gain: gain, count: count + 1
    end
  end

  def fire(x, y, gain: 1)
    project.chips.at(0, 72, 8, 8).to_sprite.tap do |sp|
      add_sprite @sprites, sp
      sp.dynamic       = true
      sp.gravity_scale = 0
      sp.pos           = [x, y]
      sp.vy            = -rand(200..500)
      sp.update do
        sp.vy *= 0.96
        if sp.vel.mag.abs < 3
          remove_sprite @sprites, sp
          fires sp.center, gain: gain
        end
      end
      anim = 0
      set_interval 0.1 do
        sp.ox = anim % 2 == 0 ? 0 : 8
        anim += 1
      end
    end
  end

  def fires(pos, gain: 1)
    set_timeout(0.5) {project.sounds[10].play gain: 0.5 * gain}
    20.times do
      project.chips.at(0, 80, 8, 8).to_sprite.tap do |sp|
        add_sprite @sprites, sp
        sp.center = pos
        sp.vel    = Vector.random2D * rand(20.0..24.0) * 2
        sp.angle  = TAU * rand
        sp.update do
          sp.vel *= 0.94
          sp.vy  += 0.1
        end
        set_timeout rand(2.0..3.0) do
          remove_sprite @sprites, sp
        end
      end
    end
    30.times do
      project.chips.at(0, 88, 8, 8).to_sprite.tap do |sp|
        add_sprite @sprites, sp
        sp.center = pos
        sp.vel    = Vector.random2D * rand(50.0..55.0) * 2
        sp.angle  = TAU * rand
        sp.update do
          sp.vel *= 0.95
          sp.vy  += 0.1
        end
        set_timeout rand(2.0..3.0) do
          remove_sprite @sprites, sp
        end
      end
    end
    40.times do
      project.chips.at(0, 96, 8, 8).to_sprite.tap do |sp|
        add_sprite @sprites, sp
        sp.center = pos
        sp.vel    = Vector.random2D * rand(70.0..80.0) * 2
        sp.angle  = TAU * rand
        sp.update do
          sp.vel *= 0.96
          sp.vy  += 0.1
        end
        set_timeout rand(3.0..4.0) do
          remove_sprite @sprites, sp
        end
      end
    end
  end

  def stage()
    @stage = project.maps[0]
  end

  def background_shader()
    @background_shader ||= createShader(nil, <<~END)
      varying vec4 vertTexCoord;
      uniform float time;
      uniform vec4 color1;
      uniform vec4 color2;
      void main() {
        float t  = mod(time, 10.) * 8.;
        float x  = ( vertTexCoord.x + t) / 20.;
        float y  = (-vertTexCoord.y + t) / 20.;
        float fx = fract(x);
        float fy = fract(y);
        float xx = fx < 0.5 ? fx * 2. : 1. - (fx - 0.5) * 2.;
        float yy = fy < 0.5 ? fy * 2. : 1. - (fy - 0.5) * 2.;
        float m  = smoothstep(0.45, 0.55, (xx + yy) / 2.);
        gl_FragColor = mix(color1, color2, m);
      }
    END
  end
end

setup        {$game = Game.new}
draw         {$game&.draw}
key_pressed  {$game&.key_down key_code unless key_is_repeated}
