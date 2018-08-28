module.exports = (robot) ->

  robot.respond /(\d+)d(\d+)/i, (msg) ->
    dices = parseInt(msg.match[1], 10) # number of dices
    faces = parseInt(msg.match[2], 10) # number of dice faces
    return unless dices >= 1 && dices <= 1000 && faces >= 1 && faces <= 1000
    eyes = [1..dices].map -> Math.floor(Math.random() * faces) + 1
    total = eyes.reduce (l,r) -> l + r
    msg.send "#{dices}d#{faces} -> #{total}"
