# -*- coding: utf-8 -*-

# ゲームを実装したクラス
class Game

  # 初期化処理
  def initialize()
    # 敵スプライト保持用の配列
    @enemies = []
    # 弾スプライト保持用の配列
    @bullets = []
    # スコア
    @score   = 0
    # 自機のスピード
    @speed   = 20

    # スクリーンの大きさを半分にする
    size(width / 2, height / 2)

    # スクリーンのサイズ変更が反映されるのが次フレームからなので次フレームで実行
    set_timeout(0) {
      # プレイヤースプライトを物理エンジンに登録
      add_sprite(player)
      # 敵生成開始
      spawn_enemy
    }
  end

  # 敵を1体生成する
  def spawn_enemy()
    # ランダムな x 座標
    x = rand(width)
    # y 座標にマイナスの値を指定して画面外に敵を追加
    add_enemy(x, -10)
    # 0.2〜1.0 秒後に
    set_timeout(rand(0.2..1.0)) do
      # 次の敵を生成する
      spawn_enemy
    end
  end

  # 描画前にゲームの状態を更新する
  def update()
    # 各カーソルキーが押されていたらプレイヤースプライトの速度を更新
    player.vx -= @speed if key_is_down(LEFT)
    player.vx += @speed if key_is_down(RIGHT)
    player.vy -= @speed if key_is_down(UP)
    player.vy += @speed if key_is_down(DOWN)

    # プレイヤースプライトの速度を減衰させる
    player.vel *= 0.8
  end

  # 秒間60回呼ばれるのでゲーム画面を描画する
  def draw()
    # 背景を黒でクリア
    background(0)

    # 座標変換を do-end 後に復帰する
    push do
      # 経過フレーム数で y 軸の座標を決定
      y = (frame_count / 10) % 100 - 50
      # 背景を縦にスクロールする
      translate(0, y)
      # 背景用のマップを描画する
      sprite(*project.maps[0].sprites)
    end

    # プレイヤー、敵、弾のスプライトを描画
    sprite(player, *@enemies, *@bullets)

    # テキストの大きさを 8 に変更
    text_size(8)
    # スコアを表示
    text("SCORE: #{@score}", 4, 16)

    # ゲームオーバーフラグが立っているか？
    if @gameover
      # テキスト描画位置を中心に
      text_align(CENTER, CENTER)
      # テキストの大きさを 20 に
      text_size(20)
      # テキストの色を設定
      fill(255, 100, 100)
      # 画面全体を指定することで中心にテキストを描画
      text("GAME OVER!", 0, 0, width, height)
    end
  end

  # キーが押されたら呼ばれる
  def key_down(code)
    case code
    when SPACE # スペースキーの場合
      # 0.1秒間隔で
      set_interval(0.1, id: :shoot, now: true) do
        # プレイヤーの中心座標から弾を発射
        add_bullet player.center, 200
      end
    end
  end

  # キーが離されたら呼ばれる
  def key_up(code)
    case code
    when SPACE # スペースキーの場合
      # 指定した id のタイマーを停止する
      clear_interval(:shoot)
    end
  end

  # プレイヤースプライト
  def player()
    # スプライトエディターの画像から位置と大きさを指定してスプライトを生成
    # 初回呼び出し時のみプレイヤースプライトを生成して保持する
    # 次回呼び出しからは保持している生成済みのインスタンスを返す
    @player ||= project.chips.at(0, 0, 8, 8).to_sprite.tap do |sp|
      # インスタンス生成する初回のみ初期化処理を実行
      # スプライトの初期位置を設定
      sp.x = (width - sp.w) / 2
      sp.y = height - sp.h  * 2
      # 物理演算で動けるスプライトにする
      sp.dynamic = true
    end
  end

  # 敵スプライトを生成
  def add_enemy(x, y)
    # Chip#to_sprite() は呼び出しごとに新しいスプライトを生成する
    project.chips.at(8, 0, 8, 8).to_sprite.tap {|sp|
      # 生成したスプライトの初期化処理
      # スプライトの初期位置を設定
      sp.x, sp.y = x, y
      # 物理演算で動けるスプライトにする
      sp.dynamic = true
      # スピードをランダムにする
      speed      = rand(20..30)
      # x 方向はランダム、y 方向は下に向けた速度を設定する
      sp.vel     = createVector([-1, 1].sample, 1) * speed
      # 敵スプライトが何かを衝突したら呼ばれる
      sp.contact do |other|
        # 衝突した相手がプレイヤースプライトなら？
        if other == player
          # ゲームオーバーフラグを立てる
          @gameover = true
          # 1番目のサウンドを、50% の音量で再生
          project.sounds[1].play(gain: 0.5)
        end
      end
      # 0.1〜0.3秒の間隔で左右方向の速度を反転する
      set_interval(rand(0.1..0.3)) {sp.vx *= -1}
      # 敵スプライトを物理エンジンに登録する
      add_sprite(sp)
      # 敵スプライトを配列にも追加する
      @enemies.push(sp)
    }
  end

  # 弾スプライトを生成
  def add_bullet(pos, speed)
    # Chip#to_sprite() は呼び出しごとに新しいスプライトを生成する
    project.chips.at(0, 8, 3, 4).to_sprite.tap {|sp|
      # 生成したスプライトの初期化処理
      # スプライトの初期位置を設定
      sp.pos     = pos
      # y 方向の速度をマイナスにすることで上方向に飛んでいく
      sp.vy      = -speed
      # 物理演算で動けるスプライトにする
      sp.dynamic = true
      # 他の物体と衝突してもすり抜けるようにする
      sp.sensor  = true
      # 弾スプライトが何かを衝突したら呼ばれる
      sp.contact do |other|
        # 衝突相手が敵配列に含まれていなければ（敵でなければ）なにもしない
        next unless @enemies.include?(other)
        # （衝突相手が敵なので）弾スプライトを物理エンジンから削除する
        remove_sprite(sp)
        # 弾スプライトを配列からも削除する
        @bullets.delete(sp)
        # 敵スプライトも物理エンジンから削除する
        remove_sprite(other)
        # 敵スプライトを配列から削除する
        @enemies.delete(other)
        # スコアを更新
        @score += 10
        # 1番目のサウンドを 30% の音量で再生
        project.sounds[1].play(gain: 0.3)
      end
      # 1秒間隔で呼ばれる
      set_interval(1, id: sp.object_id) do
        # y 座標が画面外なら
        if sp.y < -10
          # 弾スプライトを物理エンジンから削除する
          remove_sprite(sp)
          # 弾スプライトを配列からも削除する
          @bullets.delete(sp)
          # タイマーを削除
          clear_interval(sp.object_id)
        end
      end
      # 弾スプライトを物理エンジンに登録する
      add_sprite(sp)
      # 弾スプライトを配列にも追加する
      @bullets.push(sp)
      # 0番目のサウンドを 30% の音量で再生
      project.sounds[0].play(gain: 0.5)
    }
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

# キーが離されたら呼ばれる
key_released do
  # 離されたキーのキーコード
  key = key_code
  # キーが離されたメソッドを呼ぶ
  $game&.key_up key
end
