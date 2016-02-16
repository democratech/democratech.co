# encoding: UTF-8
require 'csv'
require 'date'
require 'mongo'
require 'time'

Mongo::Logger.logger.level = Logger::WARN
db=Mongo::Client.new(DBURL)
donations = CSV.read(ARGV[0],:col_sep=>",")
dons = []
donations.each do |line|
	if line[0]=="NON" then
		from=line[1]
		recurring=(line[2]=="Don mensuel"?"1":"0")
		date=Time.parse(line[3])
		amount=line[4]
		anonyme=(line[6].downcase=="non" ? "0":"1")
		firstname=line[8].capitalize
		lastname=line[9].upcase
		adresse=line[11]
		zip=line[12]
		city=(line[13].nil? ? "":line[13].upcase)
		country=(line[14].nil? ? "":line[14].upcase)
		email=line[15].downcase unless line[15].nil?
		comment=line[16]
		dons.push({:from=>from,:recurring=>recurring,:created=>date,:anonymous=>anonyme,:amount=>amount.to_f,:currency=>"eur",:firstName=>firstname,:lastName=>lastname,:email=>email,:adresse1=>adresse,:city=>city,:postalCode=>zip,:comment=>comment})
	end
end

dons.each do |doc|
	puts doc
	insert_res=db[:donateurs].insert_one(doc)
end
