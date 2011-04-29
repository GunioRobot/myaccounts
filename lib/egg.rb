require 'rubygems'
require 'mechanize'

module Egg
  URL = 'https://your.egg.com/security/customer/login.aspx'

  module Login
    attr_reader :ua
    attr_accessor :first_name, :last_name, :dob_day, :dob_month, :dob_year, :postcode, :mmn, :password

    def logged_in?
      @logged_in ||= false
    end

    def login credentials
      credentials.each_pair{|name, value| send("#{name}=".to_sym, value)}
      login_form = @ua.get(URL).forms.first
      login_form['firstName'] = first_name
      login_form['lastName']  = last_name
      login_form['dobDay']    = dob_day
      login_form['dobMonth']  = dob_month
      login_form['dobYear']   = dob_year
      login_form['postcode']  = postcode
      login_form['mmn']       = mmn
      login_form['password']  = password
      self.page = login_form.submit
      @logged_in = true
    end
  end


  class Customer
    include Login
    NO_DETAILS = 'No further transaction details held'
    attr_accessor :page

    def initialize
      @ua = Mechanize.new {|ua| ua.user_agent_alias = 'Windows IE 7'}
    end
  
    def accounts
      accounts = []
      page.parser.xpath('//table[@id="tblAccounts"]//tr[@class="rowVisible"]').each do |table|
        accounts << Account.new.tap do |acc|
          if table.xpath('//td[@class="negativebalance money"]').children.first
            acc.balance = table.xpath('//td[@class="negativebalance money"]').children.first.text.match(/[0-9.]+/)[0]
          end
          if table.xpath('//td[@class="positivebalance money"]').children.first
            acc.available = table.xpath('//td[@class="positivebalance money"]').children.first.text.match(/[0-9.]+/)[0]
          end
          acc.name = table.xpath('//td[@class="accountname"]').children.first.text.strip
          acc.number = table.xpath('//td[@class="accounttype"]').children.first.text.strip
        end
      end
      accounts
    end
  end
  
  class Account 
    attr_accessor :name, :number, :sort_code, :balance, :available, :transactions
  end
end
