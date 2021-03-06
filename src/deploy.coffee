# Description
#   Uses Semaphore's API to start deployments.
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_SEMAPHOREAPP_AUTH_TOKEN
#     Your authentication token for Semaphore API
#
#   HUBOT_SEMAPHOREAPP_DEPLOY
#     If this variable is set and is non-zero, this script will register the `hubot deploy` commands.
#
#   HUBOT_SEMAPHOREAPP_DEFAULT_SERVER
#     Your default semaphore server or `prod`.
#
#   HUBOT_SEMAPHOREAPP_DEFAULT_BRANCH
#     Your default semaphore branch or `master`.
#
# Commands
#   hubot deploy project/branch to server - deploys project/branch to server
#   hubot deploy project to server - deploys project/master to server
#   hubot deploy project/branch - deploys project/branch to 'prod'
#   hubot deploy project - deploys project/master to 'prod'
#
# Author:
#   ben

SemaphoreApp = require './lib/app'

module.exports = (robot) ->
  default_branch = process.env.HUBOT_SEMAPHOREAPP_DEFAULT_BRANCH || 'master'
  default_server = process.env.HUBOT_SEMAPHOREAPP_DEFAULT_SERVER || 'prod'

  unless process.env.HUBOT_SEMAPHOREAPP_DEPLOY?
    console.log 'Semaphore deploy commands disabled; export HUBOT_SEMAPHOREAPP_DEPLOY to turn them on'
    return

  robot.respond /deploy (.*)/, (msg) =>
    unless process.env.HUBOT_SEMAPHOREAPP_AUTH_TOKEN?
      return msg.reply "I need HUBOT_SEMAPHOREAPP_AUTH_TOKEN for this to work."

    command = msg.match[1]
    aSlashBToC = command.match /(.*?)\/(.*)\s+to\s+(.*)/ # project/branch to server
    aToB = command.match /(.*)\s+to\s+(.*)/ # project to server
    aSlashB = command.match /(.*?)\/(.*)/ # project/branch

    [project, branch, server] = switch
      when aSlashBToC? then aSlashBToC[1..3]
      when aToB? then [aToB[1], default_branch, aToB[2]]
      when aSlashB? then [aSlashB[1], aSlashB[2], default_server]
      else [command, default_branch, default_server]

    robot.logger.debug "SEMAPHOREAPP deploy #{project}/#{branch} to #{server}"

    module.exports.deploy msg, project, branch, server

module.exports.deploy = (msg, project, branch, server) ->
  app = new SemaphoreApp(msg)
  app.getProjects (allProjects) ->
    [project_obj] = (p for p in allProjects when p.name == project)
    unless project_obj
      return msg.reply "Can't find project #{project}"
    [branch_obj] =  (b for b in project_obj.branches when b.branch_name == branch)
    unless branch_obj
      return msg.reply "Can't find branch #{project}/#{branch}"
    # unless branch_obj.result == 'passed'
    #   return msg.reply "#{project}/#{branch} – last build is #{branch_obj.result}. Aborting deploy."
    [server_obj] = (s for s in project_obj.servers when s.server_name == server)
    unless server_obj
      return msg.reply "Can't find server #{server} for project #{project}"

    app.getBranches project_obj.hash_id, (allBranches) ->
      app.getServers project_obj.hash_id, (allServers) ->
        [branch_id] = (b.id for b in allBranches when b.name == branch)
        [server_id] = (s.id for s in allServers when s.name == server)
        app.createDeploy project_obj.hash_id, branch_id, branch_obj.build_number, server_id, (json) ->
          msg.send "Deploying #{project}/#{branch} to #{server} \n  #{json.html_url}"
