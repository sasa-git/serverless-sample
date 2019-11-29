require 'json'
require 'aws-record'

# def hello(event:, context:)
#   {
#     statusCode: 200,
#     body: {
#       message: 'Go Serverless v1.0! Your function executed successfully!',
#       input: event
#     }.to_json
#   }
# end

class TaskModel
  include Aws::Record
  set_table_name ENV["DDB_TABLE"]
  string_attr :id, hash_key: true
  string_attr :title
  string_attr :desc
  integer_attr :status
  epoch_time_attr :created_at
  epoch_time_attr :updated_at

  def self.put_item(body:)
    time_now = Time.now.to_i
    item = new(
      id: SecureRandom.uuid,
      title: body["title"],
      desc: body["desc"],
      status: body["status"],
      created_at: time_now,
      updated_at: time_now
    )
    item.save!
    item.to_h
  end

  def self.update_item(id:, body:)
    update_ops = {id: id, updated_at: Time.now.to_i}
    [:title, :desc, :status].each do |k|
      update_ops[k] = body[k.to_s] if body[k.to_s]
    end
    update(update_ops)
  end

  def self.get_item(id:)
    find(id: id).to_h
  end

  def self.delete(id:)
    find(id: id).delete!
  end

  def self.list_item
    res = []
    scan.each do |item|
      res << item.to_h
    end
    res
  end
end



def ping(event:, context:)
  {
    statusCode: 200,
    body: "ok!"
  }
end

def list(event:, context:)
  list = TaskModel.list_item
  {
    statusCode: 200,
    body: list.to_json
  }
end

def get(event:, context:)
  id = event["pathParameters"]["id"] # tasks/(id)←ココ
  item = TaskModel.get_item(id: id)
  {
    statusCode: 200,
    body: item.to_json
  }
end

def create(event:, context:)
  item = TaskModel.put_item(body: JSON.parse(event["body"]))
  {
    statusCode: 200,
    body: item.to_json
  }
end

def update(event:, context:)
  id = event["pathParameters"]["id"]
  item = TaskModel.update_item(id: id, body: JSON.parse(event["body"]))
  {
    statusCode: 200,
    body: item.to_json
  }
end

def delete(event:, context:)
  id = event["pathParameters"]["id"]
  TaskModel.delete(id: id)
  {
    statusCode: 200,
    body: "deleted"
  }
end

def done(event:, context:)
  id = event["pathParameters"]["id"]
  item = TaskModel.update_item(id: id, body: {status: 1})
  {
    statusCode: 200,
    body: "done!"
  }
end

# レスポンスの内容はbodyで行うこと！差もなくばinternal errorに