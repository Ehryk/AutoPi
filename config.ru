require 'rubygems'
require 'sinatra'
require 'sinatra/reloader' if development?
require './AutoPi.rb'

enable :logging
set :environment, :development
set :port, 4000
run AutoPi
