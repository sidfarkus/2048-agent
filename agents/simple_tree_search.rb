class SimpleTreeSearch
  InitialLookahead = 5

  def initialize
    @i = 0
  end

  def next_move gameboard
  	@i += 1

  	# search the movement space to see where we should go
  	ranks = calculate_ranks gameboard, InitialLookahead
  	max_rank = ranks.max_by(&:last)
  	puts "Searching move #{@i} - score #{gameboard.score} (#{max_rank.last})"
  	max_rank.first
  end

  def calculate_ranks board, lookahead
  	valid_moves = board.valid_moves.select {|move| board.would_tiles_move? move }
    valid_moves.public_send(lookahead == InitialLookahead ? :pmap : :map) {|move| 
      [move, rank_hypothetical(board.move(move), lookahead)] 
    }
  end

  def rank_hypothetical board, lookahead
  	criteria = [
      Math.log(monotonic_value(board)), 
      regularity(board), 
      Math.log(board.score), 
      cornerosity(board),
      emptiness(board)
    ]
    # puts criteria.inspect
  	weights = [5.0, 3.5, 4.0, 1.4, 1.5]
  	rank = criteria.zip(weights).map {|x, w| x * w }.reduce &:+
  	return rank if lookahead == 0

  	rank + (calculate_ranks(board, lookahead - 1).max_by(&:last) || [0]).last
  end

  def monotonic_value board
  	# sum pairwise differences for each direction
  	x_sum_right = board.horizontal_pairs.map {|a, b| (a.value || 0) + (b.value || 0)}.reduce &:+
  	x_sum_left = board.horizontal_pairs.to_a.reverse.map {|a, b| (a.value || 0) + (b.value || 0)}.reduce &:+
  	y_sum_down = board.vertical_pairs.map {|a, b| (a.value || 0) + (b.value || 0)}.reduce &:+
  	y_sum_up = board.vertical_pairs.to_a.reverse.map {|a, b| (a.value || 0) + (b.value || 0)}.reduce &:+
  	[x_sum_right, x_sum_left].max + [y_sum_down, y_sum_up].max
  end

  def regularity board
  	tiles = board.tiles.map {|tile| tile.value || 0 }
  	mean = tiles.reduce(&:+) / tiles.size
  	-Math.sqrt(tiles.map {|t| (t - mean) ** 2}.reduce(&:+) / (tiles.size - 1).to_f)
  end

  def emptiness board
    # look for at least 8 tiles free
    board.tiles.count {|tile| tile.value.nil? }
  end

  def cornerosity board
    highest_tile = board.tiles.max_by {|tile| tile.value || 0 }
    row, col = highest_tile.row, highest_tile.column
    row_score = corner_dist row, board.size
    col_score = corner_dist col, board.size
    10 - (row_score + col_score) * 5
  end

  def corner_dist v, size
     v >= size / 2 ? size - v - 1 : v
  end
end