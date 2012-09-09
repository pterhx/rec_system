require 'sequel'
require_relative 'matrix_factorization'
require 'matrix'

def printMatrix m1
  m1.to_a.each {|r| puts r.inspect}
end

DB = Sequel.sqlite('MAL.db')

NUM_USERS = 500
NUM_ANIMES = 500
NUM_REMOVED = 100
K = 100

users = DB[:users].first(NUM_USERS).map{|r| r[:id]}
animes = DB[:animes].first(NUM_ANIMES).map{|r| r[:id]}

ratingsDS = DB[:ratings].filter([:user_id, users], [:anime_id, animes])
ratings = ratingsDS.map{|r| [r[:user_id], r[:anime_id], r[:score]]}

arrR = Array.new(NUM_USERS) {Array.new(NUM_ANIMES) {0}}

ratingsDS.each do |row|
  arrR[row[:user_id] - 1][row[:anime_id] - 1] = row[:score]
end

removed = Array.new(NUM_REMOVED)

for i in 0...NUM_REMOVED
  rating = ratings.sample
  while(removed.include? rating)
    rating = ratings.sample
  end
  removed[i] = rating
  p "Removed #{rating}"
  arrR[rating[0] - 1][rating[1] - 1] = 0
end

puts "Converting matrixP0"
arrP0 = Array.new(NUM_USERS) {Array.new(K) {1}}
matrixP0 = Matrix.rows(arrP0)
puts "Converting matrixQ0"
arrQ0 = Array.new(K) {Array.new(NUM_ANIMES) {1}}
matrixQ0 = Matrix.rows(arrQ0)
puts "Converting matrixR"
matrixR = Matrix.rows(arrR)

estimatedR = matrix_factorization(matrixR, matrixP0, matrixQ0, K)

removed.each do |rating|
  user, anime, scorew = rating
  puts "User: #{user}, Anime: #{anime}"
  estimatedScore = estimatedR[user, anime]
  puts "Estimated: #{estimatedScore}"
  puts "Actual: #{score}"
end
