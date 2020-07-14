require 'fileutils'
require 'singleton'
require 'csv'

require 'sinatra/base'
require 'sinatra/reloader'
require 'slim'
require 'sass'

Encoding.default_external = 'UTF-8'

class DB
  include Singleton

  DIR = File.expand_path("db/", __dir__)
  PATH = File.expand_path("shilling.csv", DIR)

  def initialize
    FileUtils.touch(PATH)
  end

  def append!(line)
    save(read + [line])
  end

  def prepend!(line)
    save([line] + read)
  end

  def read
    File.read(PATH).lines.map(&:chomp)
  end

  def save(lines, path=PATH)
    File.write(path, lines.join("\n"))
  end
end

class MyApp < Sinatra::Base
  helpers do
    def db
      DB.instance
    end
  end

  configure(:development){ register Sinatra::Reloader }

  get '/' do
    slim :index
  end

  post '/add' do
    date = params[:date].strip
    date = Date.today.to_s if date.empty?
    amount = params[:amount].to_i
    note = params[:note].strip
    category = params[:category].strip
    category = "食費" if category.empty?

    if amount > 0
      line = [
        date,
        "Asset/サイフ",
        -amount,
        "Expense/#{category}",
        +amount,
        note,
      ].to_csv.chomp
      db.prepend!(line)
    end
    redirect back
  end

  get '/screen.css' do
    sass :screen
  end
end
