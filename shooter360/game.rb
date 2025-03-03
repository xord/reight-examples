# -*- coding: utf-8 -*-

# ゲームを実装したクラス
class Game

  # 初期化処理
  def initialize()
    # スコア
    @score         = 0
    # 自機のスピード
    @speed         = 5
    # 自機の回転速度
    @angular_speed = TAU / 90
    # 敵スプライト保持用の配列
    @enemies       = []
    # 弾スプライト保持用の配列
    @bullets       = []

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
    # x 座標をランダムに決定する
    x    = rand(10..(width  - 20))
    # y 座標をランダムに決定する
    y    = rand(10..(height - 20))
    # 敵の種別を 0 または 1 にランダムに決定する
    type = [0, 1].sample
    # 敵を追加
    add_enemy(x, y, type)
    # 1.0〜2.0 秒後に
    set_timeout(rand 1.0..2.0) do
      # 次の敵を生成する
      spawn_enemy
    end
  end

  # 描画前にゲームの状態を更新する
  def update()
    # 左右カーソルキーが押されていたらプレイヤースプライトを回転させる
    player.angle -= @angular_speed if key_is_down(LEFT)
    player.angle += @angular_speed if key_is_down(RIGHT)

    # プレイヤーの角度に合わせて進行方向の単位ベクトルを作成する
    dir = createVector(0, -1).rotate(player.angle)
    # 上カーソルキーがおされていたら速度を設定する
    player.velocity += dir * @speed if key_is_down(UP)

    # プレイヤースプライトの速度を減衰させる
    player.vel *= 0.95
  end

  # 秒間60回呼ばれるのでゲーム画面を描画する
  def draw()
    # 背景を黒でクリア
    background(0)
    # 全スプライトを指定順に描画
    sprite(*walls, player, *@enemies, *@bullets)
    # スコアを表示
    text("SCORE: #{@score}", 10, 16)
  end

  # キーが押されたら呼ばれる
  def key_down(code)
    if code == SPACE # 押されたのがスペースキーの場合
      # 0.1秒間隔でブロックを実行する
      set_interval(0.1, id: :shoot, now: true) do
        # プレイヤースプライトの位置と角度から弾を発射する
        shoot(player.center, player.angle)
      end
    end
  end

  # キーが離されたら呼ばれる
  def key_up(code)
    # 離されたのがスペースキーなら、弾発射用のタイマーを停止
    clear_interval :shoot if code == SPACE
  end

  # プレイヤースプライト
  def player()
    # スプライトエディターの画像から位置と大きさを指定してスプライトを生成
    # 初回呼び出し時のみプレイヤースプライトを生成して保持する
    # 次回呼び出しからは保持している生成済みのインスタンスを返す
    @player ||= project.chips.at(0, 0, 8, 8).to_sprite.tap do |sp|
      # インスタンス生成する初回のみ初期化処理を実行
      # スプライトの初期位置を設定
      sp.x       = (width  - sp.w) / 2
      sp.y       = (height - sp.h) / 2
      # 回転の中心をスプライトの中心に設定
      sp.pivot   = [0.5, 0.5]
      # 物理演算で動けるスプライトにする
      sp.dynamic = true
    end
  end

  # 敵スプライトを生成
  def add_enemy(x, y, type = 0)
    # Chip#to_sprite() は呼び出しごとに新しいスプライトを生成する
    project.chips.at(8 + 8 * type, 0, 8, 8).to_sprite.tap do |sp|
      # 生成したスプライトの初期化処理
      # スプライトの初期位置を設定
      sp.x, sp.y = x, y
      # 物理演算で動けるスプライトにする
      sp.dynamic = true
      # 敵スプライトを物理エンジンに登録する
      add_sprite(sp)
      # 敵スプライトを配列にも追加する
      @enemies.push(sp)
    end
  end

  # 弾スプライトを発射
  def shoot(pos, angle)
    # Chip#to_sprite() は呼び出しごとに新しいスプライトを生成する
    project.chips.at(0, 8, 2, 2).to_sprite.tap do |sp|
      # 生成したスプライトの初期化処理
      # スプライトの初期位置を設定
      sp.pos      = pos
      # スプライトの角度を設定
      sp.angle    = angle
      # 上向きの単位ベクトルを回転させて発射方向のベクトルを作る
      dir         = createVector(0, -1).rotate(angle)
      # 単位ベクトルに速さを掛けて速度ベクトルにする
      sp.velocity = dir * 200
      # 物理演算で動けるスプライトにする
      sp.dynamic  = true
      # 他の物体と衝突してもすり抜けるようにする
      sp.sensor   = true
      # 弾スプライトが何かを衝突したら呼ばれる
      sp.contact do |other|
        case other
        when *walls    # 壁スプライト（= 壁スプライト配列に含まれる）なら
          # 弾スプライトを物理エンジンから削除する
          remove_sprite(sp)
          # 弾スプライトを配列からも削除する
          @bullets.delete(sp)
        when *@enemies # 敵スプライト（= 敵スプライト配列に含まれる）なら
          # スコアを更新
          @score += 10
          # 敵スプライトを物理エンジンから削除する
          remove_sprite(other)
          # 敵スプライトを配列からも削除する
          @enemies.delete(other)
          # 弾スプライトも物理エンジンから削除する
          remove_sprite(sp)
          # 弾スプライトを配列からも削除する
          @bullets.delete(sp)
        end
      end
      # 弾スプライトを物理エンジンに登録する
      add_sprite(sp)
      # 弾スプライトを配列にも追加する
      @bullets.push(sp)
    end
  end

  # 壁スプライト
  def walls()
    # 初回呼び出し時のみプレイヤースプライトを生成して保持
    # 次回からは保持している生成済みのインスタンスを返す
    @walls ||= project.maps[0].to_sprites.tap do |sprites|
      # Map#sprites は複数のスプライトを返すので、すべて物理エンジンに登録する
      sprites.each {add_sprite(_1)}
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

# キーが離されたら呼ばれる
key_released do
  # 離されたキーのキーコード
  key = key_code
  # キーが離されたメソッドを呼ぶ
  $game&.key_up key
end
