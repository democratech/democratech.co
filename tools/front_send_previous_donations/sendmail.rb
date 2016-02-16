# encoding: UTF-8
require 'csv'
require 'mailgun'
require 'date'

donations = CSV.read('donations.csv',:col_sep=>";")
dons = []
donations.each do |line|
	recurring=(line[2]=="Don mensuel"?"oui":"non")
	date=Date.parse(line[3]).strftime("%Y/%m/%d")
	amount=line[4]
	anonyme=line[6].downcase
	firstname=line[8].capitalize
	lastname=line[9].upcase
	adresse=line[11]
	zip=line[12]
	city=(line[13].nil? ? "":line[13].capitalize)
	country=(line[14].nil? ? "":line[14].capitalize)
	email=line[15].downcase
	comment=(line[16].nil? ? "aucun":line[16])
	msg="Date: %s\nMontant: %s euros\nDon récurrent: %s\nDon anonyme: %s\nMessage: %s\n\n%s %s - %s, %s %s (%s)" % [date,amount,recurring,anonyme,comment,firstname,lastname,adresse,zip,city,country]
	dons.push({:firstname=>firstname,:lastname=>lastname,:email=>email,:city=>city,:zip=>zip,:msg=>msg,:don=>amount})
end

dons.reverse!
dons.each do |d|
	puts d[:email]
	sleep(rand(5))
	mg_client = Mailgun::Client.new "MYKEY"
	message_params = {:from    => d[:email],  
		  :to      => 'my@email.com',
		  :subject => "Nouveau don : %s euros !" % [d[:don]],
		  :text    => d[:msg]}
	mg_client.send_message "my.domain.com", message_params
end
