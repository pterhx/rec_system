require 'gsl'
require 'sequel'
DB = Sequel.sqlite('MAL.db')

DB.create_table? :correlations do
  primary_key :id
  foreign_key :anime1_id, :animes
  foreign_key :anime2_id, :animes 
  float :correlation
  integer :num_users
  unique [:anime1_id, :anime2_id]
end

ratingsDS = DB[:ratings]
animesDS = DB[:animes]
correlationsDS = DB[:correlations]

firstAnimeId = correlationsDS.order(:id).last[:anime1_id]
lastAnimeId = animesDS.order(:id).last[:id]

for anime in firstAnimeId..lastAnimeId
  for otherAnime in (anime + 1)..lastAnimeId
    next unless correlationsDS.filter(:anime1_id => anime, :anime2_id => otherAnime).empty?
    usersSeenAnime2 = ratingsDS.select(:user_id).filter(:anime_id => otherAnime)
    users = ratingsDS.filter(:anime_id=> anime,:user_id => usersSeenAnime2).select(:user_id)
    next unless users.count > 10
    animeRatings = []
    otherAnimeRatings = []
    users.each do |row| 
      animeRatings << ratingsDS.filter(:anime_id => anime, :user_id => row[:user_id]).first[:score]
      otherAnimeRatings << ratingsDS.filter(:anime_id => otherAnime, :user_id => row[:user_id]).first[:score]
    end
    correlation = GSL::Stats::correlation(GSL::Vector.alloc(animeRatings),GSL::Vector.alloc(otherAnimeRatings))
    next if correlation.nan?
    puts "corr(#{anime}, #{otherAnime}) = #{correlation}"
    correlationsDS.insert(:anime1_id => anime, :anime2_id => otherAnime, :correlation => correlation, :num_users => users.count)
    correlationsDS.insert(:anime1_id => otherAnime, :anime2_id => anime, :correlation => correlation, :num_users => users.count)
  end
end
