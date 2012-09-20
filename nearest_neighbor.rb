require 'gsl'
require 'sequel'
DB = Sequel.sqlite('MAL.db')

ALPHA = 2
BETA = 500
K = 15

def regularize(correlation, numUsers)
  ((numUsers * correlation) / (numUsers + BETA))
end

def getNeighbors(userId, animeId)
  # grab the user's animes
  ratingsDS= DB[:ratings];
  userAnimes = ratingsDS.filter(:user_id => userId).map {|r| r[:anime_id]}
  # grab all the correlations for animdId
  correlationsDS = DB[:correlations]
  filteredCorrelationsDS = correlationsDS.filter(:anime1_id => animeId) 
  correlations = filteredCorrelationsDS.map {|r| r}
  # keep animes seen by user
  correlations.select! {|correlation| userAnimes.include? correlation[:anime2_id] 
  onlyCorrelations = correlations.map {|correlation| correlation[:correlation]}
  num = [K, correlations.size].min
  # keep largest num indices
  neighborIndices = GSL::Vector.alloc(onlyCorrelations).sort_largest_index(num);
  return neigbhorIndices.map do |index|
    correlationData = correlations[index]
    correlation = correlationData[:correlation]
    numUsers = correlationData[:num_users]
    otherAnimeId = correlationData[:anime2_id]
    {:correlation => regularize(correlation, numUsers), :animdId => otherAnimeId}
  end
end

def predict(userId, animeId)
  neighbors = getNeighbors(animeId)
  
end

def recommend()
end
