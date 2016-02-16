# encoding: UTF-8
require 'csv'
require 'date'
require 'mongo'

Mongo::Logger.logger.level = Logger::WARN
db=Mongo::Client.new(DBURL)

supporteurs = CSV.read('supporteurs.csv')
updates={}
supporteurs.each do |line|
	updates[line[2].downcase]=DateTime.parse(line[6]).to_time.utc
end

nb_updates=0
updates.each do |k,v|
	res=db[:test].find({:email=>k}).update_one({"$set"=>{"created"=>v}})
	nb_updates+=res.n
end
puts "nb updates: %s" % [nb_updates]
