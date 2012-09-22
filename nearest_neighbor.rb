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
  ratingsDS.filter(:user_id => userId).each do |rating| 
    ratings[rating[:anime_id]] = rating[:score]
  end
  return ratings
end

def regularize(correlation, numUsers, alpha, beta)
  ((numUsers * correlation) / (numUsers + beta)) ** alpha
end

def getNeighbors(ratings, animeId, min_users, k)
  # grab all the correlations for animdId
  correlationsDS = DB[:correlations]
  filterString = "anime1_id = #{animeId} AND num_users > #{min_users}" 
  filteredCorrelationsDS = correlationsDS.filter(filterString) 
  if filteredCorrelationsDS.empty?
    return nil
  end
  correlations = filteredCorrelationsDS.map {|r| r}
  # keep animes seen by user
  correlations.select! {|correlation| ratings.key? correlation[:anime2_id]}
  onlyCorrelations = correlations.map {|correlation| correlation[:correlation]}
  num = [k, correlations.size].min
  # keep largest num indices
  neighborIndices = GSL::Vector.alloc(onlyCorrelations).sort_largest_index(num)
  neighbors = Array.new
  for i in 0...neighborIndices.size
    index = neighborIndices.get i
    correlationData = correlations[index]
    correlation = correlationData[:correlation]
    numUsers = correlationData[:num_users]
    otherAnimeId = correlationData[:anime2_id]
    neighbors << {:correlation => correlation, :numUsers => numUsers, :animeId => otherAnimeId}
  end
  return neighbors
end

def predict(userId, animeId, alpha, beta, gamma, k, min_users)
  ratings = userRatings(userId)
  neighbors = getNeighbors(ratings, animeId, min_users, k)
  if neighbors.nil? 
    return -1
  end
  totalCorrelationSum = 0
  subPrediction = neighbors.map do |neighbor|
    regularizedCorrelation = regularize(neighbor[:correlation], neighbor[:numUsers], alpha, beta)
    totalCorrelationSum += regularizedCorrelation
    regularizedCorrelation * ratings[neighbor[:animeId]] 
  end
  return subPrediction.reduce(:+) / (gamma + totalCorrelationSum)  
end

def recommend()
end
