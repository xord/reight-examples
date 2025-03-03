# -*- coding: utf-8 -*-

# ゲームを実装したクラス
class Game
  def initialize()
    # 画面を揺らす量
    @shake = 0

    # 全スプライトを追加して物理演算処理用に登録しておく
    [*stage, player].each do
      add_sprite(_1)
    end

    # 重力を (x, y) で設定
    gravity(0, 500)
  end

  # 描画前にゲームの状態を更新する
  def update()
    # 左右カーソルキーでプレイヤースプライトのx軸方向の速度を更新
    player.vx -= 10 if player.vx > -50 && key_is_down(LEFT)
    player.vx += 10 if player.vx < +50 && key_is_down(RIGHT)

    # プレイヤースプライトの速度を減衰させる
    player.vx *= 0.9

    # 画面を揺らす量を減衰させる
    @shake *= 0.8

    # 画面を揺らす量が十分に小さな値になったらゼロにしておく
    @shake = 0 if @shake < 0.1
  end

  # 秒間60回呼ばれるのでゲーム画面を描画する
  def draw()
    # 背景を黒でクリア
    background(0)

    # 画面を縦横それぞれ2倍に拡大する
    scale(2, 2)

    # 画面を揺らす
    if @shake != 0
      shake = Vector.random2D * @shake
      translate(shake.x, shake.y)
    end

    # 座標変換を do-end 後に復帰する
    push do
      # プレイヤーの座標に合わせてX方向の描画位置をずらす
      translate(width / 4 - player.x, 0)
      # ステージのスプライト、プレイヤーの順に描画する
      sprite(*stage, player)
    end

    # ゲームオーバーなら表示する
    if @gameover
      # 塗りつぶしの色を赤に
      fill(255, 0, 0)
      # 文字サイズ
      text_size(16)
      # text(str, x, y, w, h) の x, y, w, h の中心にテキストを表示する
      text_align(CENTER, CENTER)
      # Game Over! の文字を画面の中心に描画する
      text("Game Over!", 0, 0, width / 2, height / 2)
    end
  end

  def key_down(key)
    # SPACE キーが押されたら
    if key == SPACE
      # 上方向の速度を与えてジャンプ
      @player.vy = -150
      # 0番目のサウンドを再生する
      project.sounds[0].play
    end
  end

  def stage()
    # ステージ用のマップデータからスプライトを生成
    @stage ||= project.maps.first.sprites
  end

  def player()
    # スプライト画像から位置と大きさを指定してスプライトを生成
    @player ||= project.chips.at(0, 0, 8, 8).sprite.tap do |sp|
      # スプライトの初期位置を指定
      sp.x, sp.y = 100, 50
      # 物理演算で動けるスプライトにする
      sp.dynamic = true
      # スプライトが他のスプライトと衝突した際に呼ばれる
      sp.contact do |o|
        # 衝突した相手を、スプライト画像の位置をもとに判別
        case [o.ox, o.oy] # ox, oy は offsetx, offsety
        when [8, 32]
          # 相手がコインならコインを消す
          stage.delete o
          remove_sprite o
          # 1番目のサウンドを再生する
          project.sounds[1].play
        when [0, 32]
          # 相手がトゲなら、弾かれるようにプライヤーの速度ベクトルを更新
          sp.vel    = (sp.pos - o.pos).dup.normalize * 200
          # 画面を揺らす
          @shake    = 5
          # ゲームオーバーフラグを立てる
          @gameover = true
          # 2番目のサウンドを再生する
          project.sounds[2].play
        end
      end
      count = 0
      # 0.5秒単位で繰り返す
      set_interval(0.5) do
        # スプライトの画像の位置（ox -> offset x）を変更しアニメーションさせる
        sp.ox = (count += 1) % 2 == 0 ? 0 : 24
      end
    end
  end
end

# 起動時に一度だけ呼ばれる
setup do
  # ゲーム実装のインスタンスを生成
  $game = Game.new
end

# 毎秒60回呼ばれる
draw do
  # ゲームの状態を更新
  $game&.update
  # ゲームを描画
  $game&.draw
end

# キーが押されたら呼ばれる
key_pressed do
  # 押されたキーのキーコード
  key = key_code
  # キーが押されたメソッドを呼ぶ（キーリピートは無視）
  $game&.key_down key unless key_is_repeated
end
