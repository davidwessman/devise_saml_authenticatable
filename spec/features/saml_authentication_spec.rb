require 'spec_helper'
require 'net/http'
require 'uri'
require 'capybara/rspec'
require 'capybara/webkit'
Capybara.default_driver = :webkit

describe "SAML Authentication", type: :feature do
  let(:idp_port) { 8009 }
  let(:sp_port)  { 8020 }

  shared_examples_for "it authenticates and creates users" do
    it "authenticates an existing user on a SP via an IdP" do
      create_user("you@example.com")

      visit 'http://localhost:8020/'
      expect(current_url).to match(%r(\Ahttp://localhost:8009/saml/auth\?SAMLRequest=))
      fill_in "Email", with: "you@example.com"
      fill_in "Password", with: "asdf"
      click_on "Sign in"
      expect(page).to have_content("you@example.com")
      expect(current_url).to eq("http://localhost:8020/")
    end

    it "creates a user on the SP from the IdP attributes" do
      visit 'http://localhost:8020/'
      expect(current_url).to match(%r(\Ahttp://localhost:8009/saml/auth\?SAMLRequest=))
      fill_in "Email", with: "you@example.com"
      fill_in "Password", with: "asdf"
      click_on "Sign in"
      expect(page).to have_content("you@example.com")
      expect(page).to have_content("A User")
      expect(current_url).to eq("http://localhost:8020/")
    end
  end

  context "when the attributes are used to authenticate" do
    before(:each) do
      create_app('idp', %w(y))
      create_app('sp', %w(n))
      @idp_pid = start_app('idp', idp_port)
      @sp_pid  = start_app('sp',  sp_port)
    end
    after(:each) do
      stop_app(@idp_pid)
      stop_app(@sp_pid)
    end

    it_behaves_like "it authenticates and creates users"
  end

  context "when the subject is used to authenticate" do
    before(:each) do
      create_app('idp', %w(n))
      create_app('sp', %w(y))
      @idp_pid = start_app('idp', idp_port)
      @sp_pid  = start_app('sp',  sp_port)
    end
    after(:each) do
      stop_app(@idp_pid)
      stop_app(@sp_pid)
    end

    it_behaves_like "it authenticates and creates users"
  end

  def create_user(email)
    response = Net::HTTP.post_form(URI('http://localhost:8020/users'), email: email)
    expect(response.code).to eq('201')
  end
end
