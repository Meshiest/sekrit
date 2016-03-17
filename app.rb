require 'sinatra'
require 'mongo'
require 'json/ext'
require 'json'

$dbCreds = JSON.parse(open('creds.json').read)

set :port, ENV['PORT'] || 4567 

configure do
  db = Mongo::Client.new([ "ds023088.mlab.com:23088" ], {
    database: 'sekrit',
    user: $dbCreds["user"],
    password: $dbCreds["pass"] 
  })
  set :mongo_db, db[:sekrits]
end

get '/' do
  erb :index
end

helpers do
  # a helper method to turn a string ID
  # representation into a BSON::ObjectId
  def object_id val
    begin
      BSON::ObjectId.from_string(val)
    rescue BSON::ObjectId::Invalid
      nil
    end
  end

  def document_by_id id
    id = object_id(id) if String === id
    if id.nil?
      []
    else
      document = settings.mongo_db.find(:_id => id).to_a
    end
  end
end

get '/posts' do
  content_type :json
  settings.mongo_db.find(:type => 'q').to_a.map{|a|
    numPosts = settings.mongo_db.find(:post_id=>a[:_id].to_s, :type => 'a').to_a.length
    {
      msg: a[:msg],
      votes: a[:votes],
      comments: numPosts,
      id: a[:_id]
    }
  }.to_json
end

get '/comments' do
  content_type :json
  id = params[:id]
  comments = settings.mongo_db.find(:post_id => id, :type => 'a').to_a
  if comments.length >= 5
    comments.to_json
  else
    [].to_json
  end
end

post '/post' do
  content_type :json
  msg = params[:msg]
  if msg.nil? || msg.length < 10
    status 400
    return
  end
  db = settings.mongo_db
  result = db.insert_one({type: 'q', msg: msg, votes: 0})

  db.find(:_id => result.inserted_id).to_a.first.to_json
end

post '/answer' do
  content_type :json
  id = params[:id]
  msg = params[:msg]
  db = settings.mongo_db
  puts "id: #{id}"
  if msg.nil? || msg.length < 10 || document_by_id(id).to_a.first.nil?
    status 400
    return
  end
  result = db.insert_one({type: 'a', msg: msg, post_id: id})

  db.find(:_id => result.inserted_id).to_a.first.to_json
end