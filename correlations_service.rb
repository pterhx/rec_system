require 'gsl'
require 'sequel'
DB = Sequel.sqlite('MAL.db')

DB.create_table? :correlations do
  primary_key :id
  foreign_key :anime1_id, :animes
  foreign_key :anime2_id, :animes 
  float :correlation
  unique [:anime1_id, :anime2_id]
end

ratingsDS = DB[:ratings]
animesDS = DB[:animes]
correlationsDS = DB[:correlations]

firstAnimeId = correlationsDS.first[:anime1_id]
lastAnimeId = animesDS.order(:id).last[:id]

for anime in firstAnimeId..lastAnimeId
  for otherAnime in 1..lastAnimeId
    next unless anime != otherAnime
    next unless correlationsDS.filter(:anime1_id => anime, :anime2_id => otherAnime).empty?
    usersSeenAnime2 = ratingsDS.select(:user_id).filter(:anime_id => otherAnime)
    users = ratingsDS.filter(:anime_id=> anime,:user_id => usersSeenAnime2).select(:user_id)
    next unless users.count > 5
    animeRatings = []
    otherAnimeRatings = []

    users.each do |row| 
      animeRatings << ratingsDS.filter(:anime_id => anime, :user_id => row[:user_id]).first[:score]
      otherAnimeRatings << ratingsDS.filter(:anime_id => otherAnime, :user_id => row[:user_id]).first[:score]
    end
    correlation = GSL::Stats::correlation(GSL::Vector.alloc(animeRatings),GSL::Vector.alloc(otherAnimeRatings))
    puts "corr(#{anime}, #{otherAnime}) = #{correlation}"
    correlationsDS.insert(:anime1_id => anime, :anime2_id => otherAnime, :correlation => correlation)
    correlationsDS.insert(:anime1_id => otherAnime, :anime2_id => anime, :correlation => correlation)
  end
end