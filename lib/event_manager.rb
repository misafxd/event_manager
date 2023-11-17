require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

puts 'Event Manager Initialized!'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone(phone)
  digits = phone.scan(/\d/).join
  if digits.size == 11 && digits[0] == '1'
    digits[1..10]
  elsif digits.size == 10
    digits
  else
    "Wrong number"
  end
end

def clean_date(date)
  begin
    Date.strptime(date, '%m/%d/%y %H:%M')
  rescue StandardError
    'Invalid Date Format'
  end
end

def print_register_day_count(register_count)
  sorted_register_count = register_count.sort_by { |_, value| -value }.to_h
  puts 'Registration Day List'
  sorted_register_count.each do |element|
    puts "On #{element[0]}, #{element[1]} people registered"
  end
end

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol)

register_count = Hash.new(0)
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter)

  phone = clean_phone(row[:homephone])
  puts "#{name}: #{phone}"
  register_date = clean_date(row[:regdate])
  register_count[register_date.strftime('%A')] += 1
end

print_register_day_count(register_count)
