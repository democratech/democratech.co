require 'net/http'
require 'uri'
require 'json'
require 'csv'
require 'digest/md5'
require 'mongo'
require_relative 'config/keys.local.rb'

db=Mongo::Client.new(DBURL)
uri = URI.parse(MCURL)
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE
request = Net::HTTP::Get.new("/3.0/lists/"+MCLIST+"/interest-categories/"+MCGROUPCAT+"/interests?count=100&offset=0")
request.basic_auth 'hello',MCKEY
res=http.request(request)
response=JSON.parse(res.body)["interests"]
groups={}
response.each do |i|
	groups[i["name"].downcase]=i["id"]
end

updates={}
contribs=CSV.read('contributeurs.csv')
contribs.each do |c|
	next if c[25].empty?
	tags=[]
	tags.push("journaliste") if not c[6].empty?
	tags.push("relations presse") if not c[7].empty?
	tags.push("je suis un elu") if not c[14].empty?
	tags.push("je connais un elu") if not c[15].empty?
	tags.push("je suis candidat") if not c[16].empty?
	tags.push("je connais un candidat") if not c[17].empty?
	tags.push("frontend") if not c[20].empty?
	tags.push("backend") if not c[21].empty?
	updates[c[25]]={"hash"=>Digest::MD5.hexdigest(c[25]),"tags"=>tags} if not tags.empty?
end

updates.each do |k,v|
	email=k
	doc=updates[email]
	tags=doc["tags"]
	interests={}
	tags.each do |t|
		puts "OOPSIE" if groups[t].nil?
		interests[groups[t]]=true
	end
	tags.each do |t|
		supporter=db[:supporteurs].find({:email=>email}).find_one_and_update({'$addToSet'=>{'tags'=>t}}) # returns the document found
		puts "OOPS" if supporter.nil?
	end

	uri = URI.parse(MCURL)
	http = Net::HTTP.new(uri.host, uri.port)
	http.use_ssl = true
	http.verify_mode = OpenSSL::SSL::VERIFY_NONE
	request = Net::HTTP::Patch.new("/3.0/lists/"+MCLIST+"/members/"+doc['hash'])
	request.basic_auth 'hello',MCKEY
	request.add_field('Content-Type', 'application/json')
	request.body = JSON.dump({
		'interests'=>interests
	})
	res=http.request(request)
end
