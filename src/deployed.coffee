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
#   HUBOT_SEMAPHOREAPP_DEFAULT_PROJECT
#     Your default semaphore project or `proj`.
#
#   HUBOT_SEMAPHOREAPP_DEFAULT_SERVER
#     Your default semaphore server or `prod`.
#
# Commands
#   hubot deployed commit on project to server - check if commit has been deployed to server on project
#   hubot deployed commit - check if commit has been deployed to default server on default project
#   hubot deployed commit on project - check if commit has been deployed to default server on project
#   hubot deployed msg on project to server - check if commit message has been deployed to server on project
#   hubot deployed msg - check if commit message has been deployed to default server on default project
#   hubot deployed msg on project - check if commit message has been deployed to default server on project
#
# Author:
#   gottfrois

SemaphoreApp = require './lib/app'

module.exports = (robot)->
  default_project = process.env.HUBOT_SEMAPHOREAPP_DEFAULT_PROJECT || 'proj'
  default_server = process.env.HUBOT_SEMAPHOREAPP_DEFAULT_SERVER || 'prod'

  robot.respond /deployed (.*)/, (msg)->
    unless process.env.HUBOT_SEMAPHOREAPP_AUTH_TOKEN?
      return msg.reply "I need HUBOT_SEMAPHOREAPP_AUTH_TOKEN for this to work."

    command = msg.match[1]
    commitOnProject = command.match /(.*)\s+on\s+(.*)/ # 1ea1c683dc5d6f1e5ce959f8bb40ba0d223ba0a1 on project
    commitOnProjectToServer = command.match /(.*)\s+on\s+(.*)\s+to\s+(.*)/ # 1ea1c683dc5d6f1e5ce959f8bb40ba0d223ba0a1 on project to server

    [commit, project, server] = switch
      when commitOnProjectToServer? then commitOnProjectToServer[1..3]
      when commitOnProject?         then [commitOnProject[1], commitOnProject[2], default_server]
      else [command, default_project, default_server]

    robot.logger.debug "SEMAPHOREAPP deployed #{commit} on #{project} to #{server}"

    module.exports.deployed msg, commit, project, server

module.exports.deployed = (msg, commit, project, server)->
  msg.send "Searching if #{server} has commit #{commit} on #{project}..."

  app = new SemaphoreApp(msg)
  app.getProjects (allProjects)->
    [project_obj] = (p for p in allProjects when p.name == project)
    unless project_obj
      return msg.reply "Can't find project #{project}"

    [server_obj] = (s for s in project_obj.servers when s.server_name == server)
    unless server_obj
      return msg.reply "Can't find server #{server} for project #{project}"

    app.getServers project_obj.hash_id, (allServers)->
      [server_id] = (s.id for s in allServers when s.name == server)

      app.getServerHistory project_obj.hash_id, server_id, (json)->
        regexp = new RegExp(".*#{commit}.*", "i")
        [deploy_obj] = (d for d in json.deploys when d.commit.id.match(regexp))

        if deploy_obj
          msg.send successMessage(deploy_obj)
        else
          [deploy_obj] = (d for d in json.deploys when d.commit.message.match(regexp))
          if deploy_obj
            msg.send successMessage(deploy_obj)
          else
            msg.send "Sorry bro, can't find any matching commit"

successMessage = (deploy_obj)->
  switch deploy_obj.result
    when "passed" then ":white_check_mark: Successfuly deployed on #{deploy_obj.finished_at} (#{deploy_obj.html_url})"
    when "failed" then ":x: Unsuccessfuly deployed on #{deploy_obj.finished_at} (#{deploy_obj.html_url})"
    when "pending" then ":warning: Deploying since #{deploy_obj.started_at} (#{deploy_obj.html_url})"
