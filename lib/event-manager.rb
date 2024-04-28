require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
    legislators = legislators.officials
    legislator_names = legislators.map(&:name)
    legislator_names.join(", ")
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone)
  phone = phone.to_s.delete("/\D/")
  if phone.length == 10
    return phone 
  end
  if phone.to_s.length == 11 && phone[0] == 1
    return phone[1..-1]
  end
  return "Invalid Number"
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"
  File.open(filename,'w') do |file|
    file.puts form_letter
  end
end

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

hours = []
days = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  hour = Time.strptime(row[:regdate], "%m/%d/%Y %k:%M").hour
  hours.push(hour)
  day_week = Time.strptime(row[:regdate], "%m/%d/%Y %k:%M").wday
  days.push(day_week)
  phone = clean_phone_number(row[:homephone])
  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id,form_letter)
end

puts "popular hours: #{hours.tally}"
puts "popular days: #{days.tally}"

