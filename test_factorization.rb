require 'rubygems'
require 'sequel'
require_relative 'matrix_factorization'
require 'matrix'
require 'benchmark'

def printMatrix m1
  m1.to_a.each {|r| puts r.inspect}
end

DB = Sequel.connect('jdbc:sqlite:MAL.db')

NUM_USERS = 30
NUM_ANIMES = 30
NUM_REMOVED = 10
K = 10

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
  arrR[rating[0] - 1][rating[1] - 1] = 0
end

arrP0 = Array.new(NUM_USERS) {Array.new(K) {0.5}}
matrixP0 = Matrix.rows(arrP0)
arrQ0 = Array.new(K) {Array.new(NUM_ANIMES) {0.5}}
matrixQ0 = Matrix.rows(arrQ0)
matrixR = Matrix.rows(arrR)

estimatedR = nil
time = Benchmark.realtime do
  estimatedR = matrix_factorization(matrixR, matrixP0, matrixQ0, K)
end
puts "============= RESULTS ============="
puts "Factorization took #{time*1000} milliseconds"
puts "================ R ================"
printMatrix matrixR
puts "=============== eR ================"
printMatrix estimatedR
puts "============== Stats =============="
diff = 0
removed.each do |rating|
  user, anime, score = rating
  puts "User: #{user}, Anime: #{anime}"
  estimatedScore = estimatedR[user-1, anime-1]
  puts "Estimated:\t #{estimatedScore}"
  puts "Actual: \t #{score}"
  diff += (estimatedScore - score).abs
  puts "==============j"
end
puts "Average difference: #{diff / NUM_REMOVED}"
