class SemaphoreApp
  constructor: (@msg) ->

  requester: (endpoint) ->
    @msg.robot.http("https://semaphoreapp.com/api/v1/#{endpoint}")
      .query(auth_token: "#{process.env.HUBOT_SEMAPHOREAPP_AUTH_TOKEN}")

  get: (endpoint, callback) ->
    # console.log "GET #{endpoint}"
    @requester(endpoint).get() (err, res, body) =>
      try
        json = JSON.parse body
      catch error
        @msg.reply "Semaphore error: #{err}"
      # console.log json
      callback json

  post: (endpoint, callback) ->
    # console.log "POST #{endpoint}"
    data = JSON.stringify {}
    @requester(endpoint).post(data) (err, res, body) =>
      try
        json = JSON.parse body
      catch error
        @msg.reply "Semaphore error: #{error} / #{res} / #{body}"
      callback json

  getProjects: (callback) ->
    @get 'projects', callback

  getBranches: (project, callback) ->
    @get "projects/#{project}/branches", callback

  getServers: (project, callback) ->
    @get "projects/#{project}/servers", callback

  createDeploy: (project, branch, build, server, callback) ->
    @post "projects/#{project}/#{branch}/builds/#{build}/deploy/#{server}", callback

module.exports = SemaphoreApp
