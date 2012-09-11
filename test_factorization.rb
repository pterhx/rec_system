require 'rubygems'
require 'sequel'
require_relative 'matrix_factorization'
require 'matrix'
require 'benchmark'

# Constants
NUM_USERS = 30
NUM_ANIMES = 30
NUM_REMOVED = 10
K = 20
MIN_ANIMES = 50
MIN_USERS = 100

# Retrieve users, animes, and ratings
DB = Sequel.connect('jdbc:sqlite:MAL.db')

usersDS = DB[:users]
animesDS = DB[:animes]
ratingsDS = DB[:ratings]

filteredAnimesDS = animesDS.join(:ratings, :anime_id => :id).group_and_count(:anime_id).having('count > ?', MIN_USERS).first(NUM_ANIMES)
filteredUsersDS = usersDS.join(:ratings, :user_id => :id).group_and_count(:user_id).having('count > ?', MIN_ANIMES).first(NUM_USERS)

users = filteredUsersDS.map{|r| r[:user_id]}
animes = filteredAnimesDS.map{|r| r[:anime_id]}
filteredRatingsDS = ratingsDS.filter([:user_id, users], [:anime_id, animes])
ratings = filteredRatingsDS.map{|r| [r[:user_id], r[:anime_id], r[:score]]}

# Build look up hashes to convert anime_id
userLookUp = Hash.new
animeLookUp = Hash.new

users.each_index do |i|
  userLookUp[users[i]] = i
end
animes.each_index do |i|
  animeLookUp[animes[i]] = i
end

# Fill in R
arrR = Array.new(NUM_USERS) {Array.new(NUM_ANIMES) {0}}

filteredRatingsDS.each do |row|
  userIndex = userLookUp[row[:user_id]]
  animeIndex = animeLookUp[row[:anime_id]]
  arrR[userIndex][animeIndex] = row[:score]
end

# Randomly remove elements
removed = Array.new(NUM_REMOVED)

for i in 0...NUM_REMOVED
  rating = ratings.sample
  while(removed.include? rating)
    rating = ratings.sample
  end
  removed[i] = rating
  arrR[userLookUp[rating[0]]][animeLookUp[rating[1]]] = 0
end

arrP0 = Array.new(NUM_USERS) {Array.new(K) {Random.rand}}
matrixP0 = Matrix.rows(arrP0)
arrQ0 = Array.new(K) {Array.new(NUM_ANIMES) {Random.rand}}
matrixQ0 = Matrix.rows(arrQ0)
matrixR = Matrix.rows(arrR)

time = Benchmark.realtime do
  P,Q = matrix_factorization(matrixR, K)
end
estimatedR = P*Q


puts "============= RESULTS ============="
puts "Factorization took #{time} seconds"

puts "============== Stats =============="
diff = 0
removed.each do |rating|
  user, anime, score = rating
  puts "User: #{user}, Anime: #{anime}"
  estimatedScore = estimatedR[userLookUp[user], animeLookUp[anime]]
  puts "Estimated:\t #{estimatedScore}"
  puts "Actual: \t #{score}"
  diff += (estimatedScore - score).abs
  puts "==============j"
end
puts "Average difference: #{diff / NUM_REMOVED}"
