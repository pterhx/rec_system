require 'gsl'
require 'sequel'
DB = Sequel.sqlite('MAL.db')

ALPHA = 2
BETA = 500
K = 15

def regularize(correlation, numUsers)
  ((numUsers * correlation) / (numUsers + BE
end

def getNeighbors(animeId)
  correlationsDS = DB[:correlations]
  correlations = correlationsDS.filter(:anime1_id => animeId).map {|r| r[:correlation]}
  num = [K, correlations.size].min
  GSL::Vector.alloc(correlations).sort_largest(num).map{|correlation| regularize(correlation, )}
end

def predict()
end

def recommend()
end