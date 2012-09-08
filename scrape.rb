require 'net/http'
require 'json'
require 'sequel'

DB = Sequel.sqlite('MAL.db')

DB.create_table? :animes do
  primary_key :id
  String :title, :unique=>true
end

DB.create_table? :users do
  primary_key :id
  String :username, :unique=>true
end

DB.create_table? :ratings do
  primary_key :id
  foreign_key :user_id, :users
  foreign_key :anime_id, :animes 
  unique [:user_id, :anime_id]
  integer :score
end

usersTable = DB[:users]
animesTable = DB[:animes]
ratingsTable = DB[:ratings]

uri = URI("http://mal-api.com/")
Net::HTTP.start(uri.host, uri.port) do |httpAPI|
  uri = URI('http://myanimelist.net/')
  Net::HTTP.start(uri.host, uri.port) do |httpMAL|
    start = usersTable.max(:id) / 25
    for i in start..400
      response = httpMAL.get("/users.php?q=&show=#{i*25}")
      users = response.body.scan(/\/profile\/(\w+)"><img/)
      users.each do |user|
        userId = 0
        userSet = usersTable.filter(:username => user[0])
        if userSet.count == 1
          userId = userSet.get(:id)
        else
          userId = usersTable.insert(:username => user[0])
        end
        list = JSON.parse(httpAPI.get("/animelist/" + user[0]).body)
        list["anime"].each do |anime|
          animeId = 0
          animeSet = animesTable.filter(:title => anime["title"])
          if animeSet.count == 1
            animeId = animeSet.get(:id)
          else
            animeId = animesTable.insert(:title => anime["title"])
          end
          if ratingsTable.filter(:user_id => userId, :anime_id => animeId).count == 0 && anime["score"] > 0
            ratingsTable.insert(:user_id => userId, :anime_id => animeId, :score => anime["score"])
          end
          puts "(" + userId.to_s + "," + animeId.to_s + "," + anime["score"].to_s + ")" unless anime["score"] == 0
        end        
      end
    end
  end
end