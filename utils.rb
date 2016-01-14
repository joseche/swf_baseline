
require 'aws-flow'

# Load the user's credentials from a file, if it exists.
begin
  config_file = File.open('creds.yml') { |f| f.read }
rescue
  puts "creds.yml not found, please set the credentials..."
end

if config_file.nil?
  options = { }
else
  options = YAML.load(config_file)
end

AWS.config(options)

def init_domain
  domain_name = 'SWFDomain'
  domain = nil
  swf = AWS::SimpleWorkflow.new

# First, check to see if the domain already exists and is registered.
  swf.domains.registered.each do | d |
    if(d.name == domain_name)
      domain = d
      break
    end
  end

  if domain.nil?
    # Register the domain for one day.
    domain = swf.domains.create(
        domain_name, 1, { :description => "#{domain_name} domain" })
    puts domain_name + ' registered'
  end

  return domain
end

