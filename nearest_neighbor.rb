require 'gsl'
require 'sequel'
DB = Sequel.sqlite('MAL.db')

ALPHA = 2
BETA = 50
GAMMA = 0.015
K = 25
MIN_USERS = 40

def userRatings(userId) 
  ratingsDS = DB[:ratings]
  ratings = {}
  ratingsDS.filter(:user_id => userId).each{|rating| ratings[rating[:anime_id]] = rating[:score]}
  return ratings
end

def regularize(correlation, numUsers)
  ((numUsers * correlation) / (numUsers + BETA)) ** ALPHA
end

def getNeighbors(ratings, animeId)

  # grab all the correlations for animdId
  correlationsDS = DB[:correlations]
  filteredCorrelationsDS = correlationsDS.filter("anime1_id = #{animeId} AND num_users > #{MIN_USERS}") 
  correlations = filteredCorrelationsDS.map {|r| r}
  # keep animes seen by user
  correlations.select! {|correlation| ratings.key? correlation[:anime2_id]}
  onlyCorrelations = correlations.map {|correlation| correlation[:correlation]}
  num = [K, correlations.size].min
  # keep largest num indices
  neighborIndices = GSL::Vector.alloc(onlyCorrelations).sort_largest_index(num)
  neighbors = Array.new
  for i in 0...neighborIndices.size
    index = neighborIndices.get i
    correlationData = correlations[index]
    correlation = correlationData[:correlation]
    numUsers = correlationData[:num_users]
    otherAnimeId = correlationData[:anime2_id]
    neighbors << {:correlation => regularize(correlation, numUsers), :animeId => otherAnimeId}
  end
  return neighbors
end

def predict(userId, animeId)
  ratings = userRatings(userId)
  p ratings
  neighbors = getNeighbors(ratings, animeId)
  p neighbors
  totalCorrelationSum = neighbors.map {|neighbor| neighbor[:correlation]}.reduce(:+)
  puts totalCorrelationSum
  subPrediction = neighbors.map do |neighbor|
    neighbor[:correlation] / (GAMMA + totalCorrelationSum) * ratings[neighbor[:animeId]] 
  end
  puts subPrediction
  return subPrediction.reduce(:+)
end

def recommend()
end
