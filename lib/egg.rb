require 'rubygems'
require 'mechanize'

class Egg
  attr_accessor :page
  LOGIN_URL = 'https://your.egg.com/security/customer/login.aspx'

  def initialize
    @ua = Mechanize.new {|ua| ua.user_agent_alias = 'Windows IE 7'}
  end

  def login
    credentials = YAML.load(File.read(File.expand_path("~/.accounts.yml"))) rescue {}

    login_form = @ua.get(LOGIN_URL).forms.first
    login_form['firstName'] = credentials[:egg][:first_name]
    login_form['lastName']  = credentials[:egg][:last_name]
    login_form['dobDay']    = credentials[:egg][:dob_day]
    login_form['dobMonth']  = credentials[:egg][:dob_month]
    login_form['dobYear']   = credentials[:egg][:dob_year]
    login_form['postcode']  = credentials[:egg][:postcode]
    login_form['mmn']       = credentials[:egg][:mmn]
    login_form['password']  = credentials[:egg][:password]
    self.page = login_form.submit
  end
  
  def account_balance
    accounts = self.page.parser.xpath('//table[@id="tblAccounts"]//tr[@class="rowVisible"]')
    accounts.map do |account|
      negative = account.xpath('//td[@class="negativebalance money"]').children.first ? account.xpath('//td[@class="negativebalance money"]').children.first.text.match(/[0-9.]+/)[0] : ""
      positive = account.xpath('//td[@class="positivebalance money"]').children.first ? account.xpath('//td[@class="positivebalance money"]').children.first.text.match(/[0-9.]+/)[0] : ""
      {
        :account_name     => account.xpath('//td[@class="accountname"]').children.first.text.strip,
        :account_type     => account.xpath('//td[@class="accounttype"]').children.first.text.strip,
        :negative_balance => negative,
        :positive_balance => positive
      }
    end
  end
end

egg = Egg.new
egg.login
accounts = egg.account_balance
accounts.each do |acc|
  print acc[:account_name] + "\t-" + acc[:negative_balance] + "\n"
end
  
