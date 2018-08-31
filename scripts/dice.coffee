kind = (token) ->
  switch token
    when '+', '-' then 'OPERATOR'
    else
      if typeof token != 'string'
        undefined
      else if token.match(/^\d+$/)
        'NUMBER'
      else if token.match(/^\d+d\d+$/)
        'DICE'

parse = (source) ->
  stack = []
  result = []
  source.match(///
    ([+-])    |
    (\d+d\d+) |
    (\d+)
  ///ig).forEach (token) -> 
    switch kind(token)
      when 'OPERATOR'
        result.push stack.pop() unless stack.length == 0
        stack.push token
      when 'NUMBER', 'DICE'
        result.push token
  result.concat stack.reverse()

make_tree = (arr) ->
  stack = []
  arr.forEach (token) ->
    switch kind(token)
      when 'NUMBER', 'DICE'
        stack.push token
      when 'OPERATOR'
        right = stack.pop()
        left = stack.pop()
        stack.push [token, left, right]
  stack[0]

calc = (expression) ->
  return roll(expression) if kind(expression) == 'DICE'
  return parseInt(expression) if kind(expression) == 'NUMBER'
  [ope, left, right] = expression
  switch ope
    when '+' then calc(left) + calc(right)
    when '-' then calc(left) - calc(right)

roll = (str) ->
  m = str.match(/(\d+)d(\d+)/i)
  dices = parseInt(m[1], 10) # number of dices
  faces = parseInt(m[2], 10) # number of dice faces
  throw 'ダイスの数は1～1000' unless dices >= 1 && dices <= 1000
  throw '面の数は1～1000' unless faces >= 1 && faces <= 1000
  eyes = [1..dices].map -> Math.floor(Math.random() * faces) + 1
  eyes.reduce (l,r) -> l + r

exec = (source) ->
  try
    tree = make_tree(parse(source))
    console.log tree
    throw '何かがおかしいです…' if undefined in tree
    calc(tree)
  catch error
    console.error(error.stack)
    "エラー！ #{error}"

debug = (source, option) ->
  return '' unless option['debug']
  try
    out = "```\n#DEBUG\n"
    out += "入力   [#{JSON.stringify(source)}]\n"
    parsed = parse(source)
    out += "逆ポ   #{JSON.stringify(parsed)}\n"
    tree = make_tree(parsed)
    out += "構文木 #{JSON.stringify(tree)}\n"
    result = calc(tree)
    out += "結果   [#{JSON.stringify(result)}]"
  catch error
    out += "ここでエラー！\n#{error}\n"
  finally
    out += "```\n"
  out

module.exports = (robot) ->

  robot.respond /(.*)/, (msg) ->
    input = msg.match[1]
    return unless m = input.match(/(\d+d\d+|\d+|[+-]| +)+/i)
    source = m[0].trim().replace(/\s+/g, ' ')
    option = {}
    option['debug'] = input.match(/\bdebug\b/)?
    msg.send "#{source} -> #{exec(source, option)}"
    msg.send debug(source, option) if option['debug']
