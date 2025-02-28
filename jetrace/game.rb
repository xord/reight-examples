def now()
  Time.now.to_f
end


class Game
  def initialize()
    setTitle 'JetRace!'
    angleMode DEGREES
    @keys  = []
    @state = :ready
  end

  def count_down(count = 3, &block)
    if count == 0
      project.sounds[1].play
      block.call
    else
      project.sounds[0].play
      @count_down_text = count.to_s
      set_timeout(1) {count_down count - 1, &block}
    end
  end

  def goal!()
    return if @state == :goal
    project.sounds[2].play
    @goal_time = now
    @state     = :goal
  end

  def goal?()
    @goal
  end

  def jetting?()
    @state == :race && !@keys.empty?
  end

  def update()
    player.vel += create_vector(0, -5).rotate(player.angle) if jetting?
    player.vel *= 0.98

    jet.center = player.center + create_vector(0, 8).rotate(player.angle)
    jet.angle  = player.angle

    project.sounds[3].play gain: 0.2 if jetting? && (frame_count / 5) % 2 == 0

    screenOffset player.center.x - width / 2, player.center.y - height / 2
  end

  def draw()
    update
    background 0
    push do
      sx, sy, = screenOffset.to_a
      translate -sx, -sy
      stages  = project.maps[0].sprites_at sx, sy, width, height, self
      sprite *stages, jet, player
    end
    draw_time
    draw_state
  end

  def draw_time()
    return unless @start_time
    seconds = (@goal_time || now) - @start_time
    text_align CENTER, TOP
    text_size 12
    fill 255
    text "%02.3f" % seconds, 0, 16, width, height
  end

  def draw_state()
    state_text =
      case @state
      when :ready      then 'Ready?'
      when :count_down then @count_down_text
      when :goal       then 'Goal!'
      else return
      end
    text_align CENTER, CENTER
    text_size 30
    fill 255, (frame_count % 4 < 2 ? 255 : 200)
    text state_text, 0, 0, width, height
  end

  def key_down(code)
    @keys.delete code
    @keys.unshift code
    update_player

    case @state
    when :ready
      @state = :count_down
      count_down {@state, @start_time = :race, now}
    end
  end

  def key_up(code)
    @keys.delete code
    update_player
  end

  def update_player()
    player.angle =
      case @keys.first
      when LEFT  then -90
      when RIGHT then  90
      when UP    then   0
      when DOWN  then 180
      else player.angle
      end
  end

  def player()
    @player ||= project.chips.at(0, 0, 8, 8).sprite.tap do |sp|
      sp.pos     = project.maps[0].find {[_1.x, _1.y] == [120, 0]}.pos
      sp.pivot   = [0.5, 0.5]
      sp.angle   = 90
      sp.dynamic = true
      sp.contact {|other| player_contact other}
      add_sprite sp
    end
  end

  def player_contact(other)
    case [other.chip.x, other.chip.y]
    when [120, 8] then goal!
    end
  end

  def jet()
    @jet ||= project.chips.at(0, 8, 8, 8).sprite.tap do |sp|
      sp.pivot = [0.5, 0.5]
      sp.draw {|&draw| draw.call if jetting? && frame_count % 4 < 2}
    end
  end

  def stage()
    @stage ||= project.maps[0]
  end
end

setup        {$game = Game.new}
draw         {$game&.draw}
key_pressed  {$game&.key_down key_code unless key_is_repeated}
key_released {$game&.key_up   key_code}
